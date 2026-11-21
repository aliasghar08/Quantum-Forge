const http = require('http');

async function main() {
  const tabs = await new Promise((resolve, reject) => {
    http.get('http://127.0.0.1:9222/json', (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });

  const page = tabs.find(t => t.type === 'page' && t.url.includes('quantom-forge.web.app'));
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
      const evalRes = await send('Runtime.evaluate', {
        expression: `
          (() => {
            function findInShadow(root, selector) {
              const res = [];
              if (!root) return res;
              if (root.querySelectorAll) res.push(...root.querySelectorAll(selector));
              const walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT);
              while (walker.nextNode()) {
                if (walker.currentNode.shadowRoot) res.push(...findInShadow(walker.currentNode.shadowRoot, selector));
              }
              return res;
            }

            const el = findInShadow(document.body, '#cardiocath-heart-container-8')[0];
            try {
              const v = window.CardioCathThree.initHeartViewer(el, {});
              return { success: true, id: v.id, canvasCount: el.querySelectorAll('canvas').length };
            } catch(e) {
              return { error: e.message, stack: e.stack };
            }
          })()
        `,
        returnByValue: true
      });
      console.log('Result:', JSON.stringify(evalRes.result.value, null, 2));

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

