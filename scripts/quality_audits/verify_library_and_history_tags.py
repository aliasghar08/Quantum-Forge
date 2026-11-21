#!/usr/bin/env python3
"""Verify and capture screenshots of Library & History subfield tags and curriculum badges."""

import json
import base64
import urllib.request
import websocket
import time
import os

SAVE_DIR = os.path.expanduser('~/Library/Mobile Documents/com~apple~CloudDocs/Mac Screenshots')
os.makedirs(SAVE_DIR, exist_ok=True)

pages = json.loads(urllib.request.urlopen('http://localhost:9222/json/list').read())
qf_pages = [p for p in pages if 'quantom-forge.web.app' in p.get('url', '') and p.get('type') == 'page']
if not qf_pages:
    print('Error: Quantum Forge tab not found on localhost:9222!')
    exit(1)

ws_url = qf_pages[0]['webSocketDebuggerUrl']
print(f'Connecting to Chrome tab: {ws_url}')
ws = websocket.create_connection(ws_url)

msg_counter = 0

def call_cdp(method, params=None):
    global msg_counter
    msg_counter += 1
    req = {'id': msg_counter, 'method': method}
    if params:
        req['params'] = params
    ws.send(json.dumps(req))
    while True:
        raw = ws.recv()
        data = json.loads(raw)
        if data.get('id') == msg_counter:
            return data

# Enable domains
call_cdp('Page.enable')
call_cdp('Emulation.setDeviceMetricsOverride', {
    'width': 1920,
    'height': 1080,
    'deviceScaleFactor': 1,
    'mobile': False,
})

def capture_page(url, filename, wait_seconds=5):
    print(f'Navigating to {url}...')
    call_cdp('Page.navigate', {'url': url})
    call_cdp('Page.reload', {'ignoreCache': True})
    time.sleep(wait_seconds)
    
    shot_resp = call_cdp('Page.captureScreenshot', {'format': 'png'})
    img_data = base64.b64decode(shot_resp['result']['data'])
    filepath = os.path.join(SAVE_DIR, filename)
    with open(filepath, 'wb') as f:
        f.write(img_data)
    print(f'Saved: {filepath} ({len(img_data):,} bytes)')

# 1. Capture Library Screen
capture_page('https://quantom-forge.web.app/#/library', 'Library_Subfields_And_Curriculum_Tags.png', wait_seconds=6)

# 2. Capture History Screen
capture_page('https://quantom-forge.web.app/#/history', 'History_Subfields_And_Curriculum_Tags.png', wait_seconds=6)

ws.close()
print('Verification and screenshots complete!')

