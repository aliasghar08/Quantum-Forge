#!/usr/bin/env python3
"""Capture high-resolution screenshots of CardioCath 5-Channel Oscilloscope Realism Modes."""

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

# Set high-definition desktop viewport (1920x1080)
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
    time.sleep(0.5)

def click_at(x, y):
    call_cdp('Input.dispatchMouseEvent', {'type': 'mousePressed', 'x': x, 'y': y, 'button': 'left', 'clickCount': 1})
    time.sleep(0.06)
    call_cdp('Input.dispatchMouseEvent', {'type': 'mouseReleased', 'x': x, 'y': y, 'button': 'left', 'clickCount': 1})
    time.sleep(0.6)

def capture(filename):
    time.sleep(0.5)
    resp = call_cdp('Page.captureScreenshot', {'format': 'png'})
    img_bytes = base64.b64decode(resp['result']['data'])
    path = os.path.join(SAVE_DIR, filename)
    with open(path, 'wb') as f:
        f.write(img_bytes)
    print(f'✔ Saved: {filename} ({len(img_bytes):,} bytes)')
    return path

print('Reloading page to fetch latest deployed version...')
call_cdp('Page.reload', {'ignoreCache': True})
time.sleep(4.5)

# Reset to top
for _ in range(8):
    scroll_by(-800)
time.sleep(1.0)

# Scroll to 5-Channel Hospital Oscilloscope
scroll_by(520)
time.sleep(1.5)

# 1. Capture Real Bedside Signal on ICU Phosphor CRT
print('Capturing 1: Real Bedside Signal (Phosphor CRT)...')
capture('CardioCath_RealBedside_PhosphorCRT.png')

# Find the toggles in header
# The header row is at ~y=375 when scrolled 520px
# Let's use horizontal scroll on the header or find the toggles
# First, let's scroll the telemetry header to the right to reveal the 3 toggles:
# Dispatch mouse wheel horizontally on header at y=375
call_cdp('Input.dispatchMouseEvent', {
    'type': 'mouseWheel',
    'x': 600,
    'y': 375,
    'deltaX': 1200,
    'deltaY': 0
})
time.sleep(0.8)

# 2. Click the Thermal Paper button (around x=1420, y=375)
print('Clicking Thermal Paper display toggle...')
# Let's inspect or click across the header buttons
click_at(1460, 375)
time.sleep(1.0)

# Capture Hospital Thermal Paper
print('Capturing 2: Hospital Thermal Paper Mode...')
capture('CardioCath_Hospital_ThermalPaper.png')

# 3. Click 60 Hz Mains Hum toggle (around x=1320, y=375)
print('Clicking 60 Hz Mains Hum toggle...')
click_at(1330, 375)
time.sleep(1.0)

# Capture 60 Hz Hum interference
print('Capturing 3: 60 Hz Mains Hum Electrical Interference...')
capture('CardioCath_60HzHum_Interference.png')

print('\n=== Audit Summary ===')
errors = [l for l in console_logs if '[ERROR]' in l or 'RenderFlex overflowed' in l]
if errors:
    print(f'⚠ Warnings/Errors found: {len(errors)}')
    for e in errors[:5]:
        print('  ', e)
else:
    print('✔ 0 Console errors & 0 RenderFlex overflows.')

ws.close()
print('Audit complete.')

