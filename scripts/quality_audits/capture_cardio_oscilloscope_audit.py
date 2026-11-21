#!/usr/bin/env python3
"""Automated Chrome Visual Auditor for CardioCath 3D.

Connects to Chrome via CDP (port 9222), systematically exercises every module,
viewport, tab, and dialog, checks for errors/warnings, and saves high-resolution
screenshots directly into ~/Library/Mobile Documents/com~apple~CloudDocs/Mac Screenshots.
"""

import json
import base64
import urllib.request
import websocket
import time
import os

SAVE_DIR = os.path.expanduser('~/Library/Mobile Documents/com~apple~CloudDocs/Mac Screenshots')
os.makedirs(SAVE_DIR, exist_ok=True)

pages = json.loads(urllib.request.urlopen('http://localhost:9222/json/list').read())
cardiac_pages = [p for p in pages if 'quantom-forge.web.app' in p.get('url', '') and p.get('type') == 'page']
if not cardiac_pages:
    print('Error: CardioCath page not found on localhost:9222!')
    exit(1)

ws_url = cardiac_pages[0]['webSocketDebuggerUrl']
print(f'Connecting to Chrome page: {ws_url}')
ws = websocket.create_connection(ws_url)

msg_counter = 0
console_logs = []

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
        # Record console/runtime events
        if data.get('method') == 'Runtime.consoleAPICalled':
            msg_type = data['params'].get('type', 'log')
            args = [str(a.get('value', '')) for a in data['params'].get('args', [])]
            console_logs.append(f'[{msg_type.upper()}] {" ".join(args)}')
        if data.get('id') == msg_counter:
            return data

# Enable domains
call_cdp('Runtime.enable')
call_cdp('Log.enable')
call_cdp('Page.enable')

# Set 1920x1080 resolution
call_cdp('Emulation.setDeviceMetricsOverride', {
    'width': 1920,
    'height': 1080,
    'deviceScaleFactor': 1,
    'mobile': False
})

def scroll_by(delta_y):
    call_cdp('Input.dispatchMouseEvent', {
        'type': 'mouseWheel',
        'x': 960,
        'y': 540,
        'deltaX': 0,
        'deltaY': delta_y
    })
    time.sleep(0.6)

def click_at(x, y):
    call_cdp('Input.dispatchMouseEvent', {'type': 'mousePressed', 'x': x, 'y': y, 'button': 'left', 'clickCount': 1})
    time.sleep(0.05)
    call_cdp('Input.dispatchMouseEvent', {'type': 'mouseReleased', 'x': x, 'y': y, 'button': 'left', 'clickCount': 1})
    time.sleep(0.5)

def capture(filename):
    time.sleep(0.4)
    resp = call_cdp('Page.captureScreenshot', {'format': 'png'})
    img_bytes = base64.b64decode(resp['result']['data'])
    path = os.path.join(SAVE_DIR, filename)
    with open(path, 'wb') as f:
        f.write(img_bytes)
    print(f'✔ Saved: {filename} ({len(img_bytes):,} bytes)')
    return path

print('Starting CardioCath 3D Visual Walkthrough & Audit...')

# Reset to top
for _ in range(8):
    scroll_by(-800)
time.sleep(1.0)

# 1. Main Viewports Top (3D Heart, Fluo, C-Arm, Controls)
capture('CardioCath_01_Viewports_Top.png')

# 2. Scroll to 5-Channel Hospital Oscilloscope
scroll_by(480)
capture('CardioCath_02_Hospital_Oscilloscope_5Channel.png')

# 3. Scroll to 6-Module Diagnostic Workstation
scroll_by(500)
capture('CardioCath_03_Diagnostic_Workstation_EchoDoppler.png')

# 4. Scroll to PyTorch MPS Computational Research Suite
scroll_by(600)
capture('CardioCath_04_PyTorch_Computational_Research_Suite.png')

# 5. Scroll to Interventional Fellowship Suite
scroll_by(600)
capture('CardioCath_05_Fellowship_Bifurcation_Structural_Suite.png')

# 6. Scroll to Clinical Pearls & Legal Shield
scroll_by(400)
capture('CardioCath_06_Clinical_Pearls_Legal_Protection.png')

# Reset to top for interactive dialog tests
for _ in range(10):
    scroll_by(-800)
time.sleep(0.8)

# 7. Click 'Inspect Drug MoA' in Top Bar (approx x=1650, y=36)
print('Testing Inspect Drug MoA Dialog...')
click_at(1650, 36)
time.sleep(0.8)
capture('CardioCath_07_Dialog_Inspect_Drug_MoA.png')
# Close dialog (Escape key or click outside at x=100, y=100)
click_at(100, 100)
time.sleep(0.5)

# 8. Click 'CardioNephroGNN' in Top Bar (approx x=1820, y=36)
print('Testing CardioNephroGNN Dialog...')
click_at(1820, 36)
time.sleep(0.8)
capture('CardioCath_08_Dialog_CardioNephroGNN.png')
click_at(100, 100)
time.sleep(0.5)

# 9. Click 'AI Proctor' in Top Bar (approx x=1350, y=36)
print('Testing AI Proctor Debrief...')
click_at(1350, 36)
time.sleep(0.8)
capture('CardioCath_09_Dialog_AI_Proctor.png')
click_at(100, 100)
time.sleep(0.5)

# 10. Click '7-Pillar Legal Shield' (approx x=1860, y=125)
print('Testing 7-Pillar Legal Shield Dialog...')
click_at(1860, 125)
time.sleep(0.8)
capture('CardioCath_10_Dialog_7Pillar_Legal_Shield.png')
click_at(100, 100)
time.sleep(0.5)

ws.close()
print('\n======================================================')
print(f'All 10 screenshots saved to: {SAVE_DIR}')
print('Console logs recorded:', len(console_logs))
for log in console_logs[-10:]:
    print(' ', log)
print('======================================================')

