const http = require('http');
const fs = require('fs');

async function main() {
  const tabs = await new Promise((resolve, reject) => {
    http.get('http://127.0.0.1:9222/json', (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });

  const page = tabs.find(t => t.type === 'page' && t.url.includes('quantom-forge.web.app'));
  if (!page) {
    console.error('Page not found');
    process.exit(1);
  }

  const ws = new WebSocket(page.webSocketDebuggerUrl);

  ws.addEventListener('open', () => {
    let id = 1;
    function send(method, params = {}) {
      return new Promise(resolve => {
        const reqId = id++;
        const handler = (e) => {
          const msg = JSON.parse(e.data);
          if (msg.id === reqId) {
            ws.removeEventListener('message', handler);
            resolve(msg.result);
          }
        };
        ws.addEventListener('message', handler);
        ws.send(JSON.stringify({ id: reqId, method, params }));
      });
    }

    (async () => {
      await send('Runtime.enable');
      await send('Console.enable');
      await send('Page.enable');

      await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 900, deviceScaleFactor: 1, mobile: false });

      console.log('Waiting 3s for dashboard...');
      await new Promise(r => setTimeout(r, 3000));

      console.log('Clicking CardioCath 3D Lab card at (986, 471)...');
      await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: 986, y: 471 });
      await new Promise(r => setTimeout(r, 200));
      await send('Input.dispatchMouseEvent', { type: 'mousePressed', x: 986, y: 471, button: 'left', clickCount: 1 });
      await new Promise(r => setTimeout(r, 100));
      await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x: 986, y: 471, button: 'left', clickCount: 1 });

      console.log('Waiting 8 seconds for CardioCath viewports to initialize...');
      await new Promise(r => setTimeout(r, 8000));

      const hubState = await send('Runtime.evaluate', {
        expression: `({
          heartViewers: window.CardioCathThree ? Array.from(window.CardioCathThree.heartViewers.keys()) : [],
          fluoroViewers: window.CardioCathThree ? Array.from(window.CardioCathThree.fluoroViewers.keys()) : [],
          containers: Array.from(document.querySelectorAll('[id^="cardiocath"]')).map(el => ({
            id: el.id,
            w: el.clientWidth,
            h: el.clientHeight,
            children: el.children.length,
            hasCanvas: !!el.querySelector('canvas')
          }))
        })`,
        returnByValue: true
      });
      console.log('Hub & Containers State:', JSON.stringify(hubState.result.value, null, 2));

      console.log('Capturing screenshot...');
      const res = await send('Page.captureScreenshot', { format: 'png' });
      fs.writeFileSync('/Users/aliasghar08/.gemini/antigravity/brain/8a422a93-6b4d-4bd8-b38e-901bc40d7135/live_heart_translucent_verified.png', Buffer.from(res.data, 'base64'));
      console.log('Saved to live_heart_translucent_verified.png!');

      ws.close();
      process.exit(0);
    })().catch(e => {
      console.error(e);
      process.exit(1);
    });
  });
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
