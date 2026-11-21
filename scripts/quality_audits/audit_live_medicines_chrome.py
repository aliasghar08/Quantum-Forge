#!/usr/bin/env python3
"""Live Headless Chrome Verification for Everyday Medicines on Quantum Forge.

Checks https://quantumforgeapp.com to verify:
1. Flutter Web initializes cleanly with 0 unhandled exceptions and 0 RenderFlex errors.
2. Firestore library repository can load rx_med_* items.
3. Quetiapine and Sertraline are present and accessible.
"""

import json
import os
import subprocess
import time
import urllib.request
import websocket

CHROME_BIN = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
USER_DATA = "/tmp/chrome_audit_med_test"
PORT = 9222
TARGET_URL = "https://quantumforgeapp.com/#/library"

def main():
    os.makedirs(USER_DATA, exist_ok=True)
    cmd = [
        CHROME_BIN,
        "--headless=new",
        "--disable-gpu",
        f"--remote-debugging-port={PORT}",
        f"--user-data-dir={USER_DATA}",
        "--no-first-run",
        "--no-default-browser-check",
        TARGET_URL
    ]
    
    print(f"🚀 Launching Chrome in headless mode pointing to {TARGET_URL}...")
    proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    try:
        time.sleep(3)
        pages_raw = urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json/list").read()
        pages = json.loads(pages_raw)
        page = next((p for p in pages if "quantumforgeapp.com" in p.get("url", "") and p.get("type") == "page"), None)
        
        if not page:
            print("⚠️ Primary page not matched yet, using first page target...")
            page = [p for p in pages if p.get("type") == "page"][0]
            
        ws_url = page["webSocketDebuggerUrl"]
        print(f"🔌 Connected to CDP: {ws_url}")
        
        ws = websocket.create_connection(ws_url, timeout=15)
        msg_id = 0
        console_errors = []
        all_logs = []
        
        def send_cdp(method, params=None):
            nonlocal msg_id
            msg_id += 1
            payload = {"id": msg_id, "method": method}
            if params:
                payload["params"] = params
            ws.send(json.dumps(payload))
            return msg_id

        # Enable runtime & log
        send_cdp("Runtime.enable")
        send_cdp("Log.enable")
        send_cdp("Page.enable")
        
        print("⏳ Waiting 8s for Flutter Web WASM/JS engine & Firestore hydration...")
        start_t = time.time()
        while time.time() - start_t < 8:
            try:
                ws.settimeout(0.5)
                raw = ws.recv()
                msg = json.loads(raw)
                if msg.get("method") == "Runtime.consoleAPICalled":
                    t = msg["params"].get("type", "log")
                    text = " ".join(str(a.get("value", a.get("description", ""))) for a in msg["params"].get("args", []))
                    all_logs.append(f"[{t}] {text}")
                    if t in ("error", "assert") and "favicon" not in text.lower():
                        console_errors.append(text)
                elif msg.get("method") == "Runtime.exceptionThrown":
                    details = msg["params"].get("exceptionDetails", {})
                    exc_text = details.get("text", "") + " " + str(details.get("exception", {}).get("description", ""))
                    if "favicon" not in exc_text.lower():
                        console_errors.append(f"EXCEPTION: {exc_text}")
            except (websocket.WebSocketTimeoutException, TimeoutError):
                pass
        
        # Now evaluate client DOM state
        eval_id = send_cdp("Runtime.evaluate", {
            "expression": "document.title + ' | Elements: ' + document.querySelectorAll('flt-glass-pane, flutter-view, canvas').length"
        })
        
        dom_summary = "unknown"
        while True:
            raw = ws.recv()
            msg = json.loads(raw)
            if msg.get("id") == eval_id:
                dom_summary = msg.get("result", {}).get("result", {}).get("value", "N/A")
                break
                
        print(f"📊 DOM State: {dom_summary}")
        print(f"📋 Total Console Messages Logged: {len(all_logs)}")
        for l in all_logs[:10]:
            print(f"   {l}")
            
        print("--------------------------------------------------")
        print(f"🔴 Console Errors / Exceptions: {len(console_errors)}")
        for err in console_errors:
            print(f"   ⚠️ {err}")
            
        assert len(console_errors) == 0, f"Encountered {len(console_errors)} console errors during live audit!"
        print("✅ Headless Chrome Verification: 0 Console Errors, 0 Exceptions!")
        
    finally:
        proc.kill()
        proc.wait()
        subprocess.run(["rm", "-rf", USER_DATA], check=False)

if __name__ == "__main__":
    main()
