#!/usr/bin/env python3
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
print(f'Connecting to: {ws_url}')
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

call_cdp('Runtime.enable')
call_cdp('Page.enable')

# Set desktop viewport 1920x1080
call_cdp('Emulation.setDeviceMetricsOverride', {
    'width': 1920,
    'height': 1080,
    'deviceScaleFactor': 1,
    'mobile': False
})

# Navigate cleanly to #/cardiac
call_cdp('Page.navigate', {'url': 'https://quantom-forge.web.app/#/cardiac'})
time.sleep(7.0)

def capture_screenshot(filename):
    res = call_cdp('Page.captureScreenshot', {'format': 'png'})
    data = base64.b64decode(res['result']['data'])
    path = os.path.join(SAVE_DIR, filename)
    with open(path, 'wb') as f:
        f.write(data)
    print(f'Saved: {path} {len(data)} bytes')

def click_at(x, y):
    print(f'Clicking at ({x}, {y})')
    call_cdp('Input.dispatchMouseEvent', {'type': 'mousePressed', 'x': x, 'y': y, 'button': 'left', 'clickCount': 1})
    time.sleep(0.08)
    call_cdp('Input.dispatchMouseEvent', {'type': 'mouseReleased', 'x': x, 'y': y, 'button': 'left', 'clickCount': 1})
    time.sleep(1.0)

# 1. Normal baseline screenshot showing the Heart Situation Trigger strip and AUTO-VITALS badge
capture_screenshot('CardioCath_09_Clinical_Situations_Normal_Baseline.png')

# 2. Click "Cardiogenic Shock" chip in the situation strip
# The situation strip is at y ~ 362 px. "Cardiogenic Shock" chip is roughly at x ~ 370-420.
click_at(400, 362)
time.sleep(1.5)
capture_screenshot('CardioCath_10_Situation_Cardiogenic_Shock.png')

# 3. Click "+" step up button on the Heart Rate slider to trigger MANUAL OVERRIDE
# HR slider is roughly at x ~ 200, y ~ 410. Step up button is at x ~ 205.
click_at(205, 410)
time.sleep(1.2)
capture_screenshot('CardioCath_11_Situation_Manual_Override.png')

ws.close()
print("All Clinical Heart Situation screenshots captured successfully!")

