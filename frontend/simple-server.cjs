const http = require('http');
const fs = require('fs');
const path = require('path');

const FRONTEND_DIR = '/home/ubuntu/M-2.0/frontend';
const BACKEND_URL = 'http://127.0.0.1:8622';
const PORT = 8623;

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
  '.map': 'application/json',
};

function serveStatic(req, res) {
  let filePath = path.join(FRONTEND_DIR, req.url === '/' ? 'index.html' : req.url);
  
  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        fs.readFile(path.join(FRONTEND_DIR, 'index.html'), (err2, content2) => {
          if (err2) {
            res.writeHead(404);
            res.end('Not found');
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(content2);
          }
        });
      } else {
        res.writeHead(500);
        res.end('Server error');
      }
    } else {
      const ext = path.extname(filePath);
      res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
      res.end(content);
    }
  });
}

function proxyToBackend(req, res) {
  const url = new URL(req.url, BACKEND_URL);
  const options = {
    hostname: '127.0.0.1',
    port: 8622,
    path: url.pathname + url.search,
    method: req.method,
    headers: {
      ...req.headers,
      host: '127.0.0.1:8622',
    },
  };

  const proxyReq = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res, { end: true });
  });

  proxyReq.on('error', (err) => {
    console.error('Proxy error:', err.message);
    res.writeHead(502);
    res.end('Bad gateway');
  });

  req.pipe(proxyReq, { end: true });
}

const server = http.createServer((req, res) => {
  if (req.url.startsWith('/api/') || req.url.startsWith('/health') || req.url.startsWith('/ws') || req.url.startsWith('/sse')) {
    return proxyToBackend(req, res);
  }
  serveStatic(req, res);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Maya frontend server running on http://0.0.0.0:${PORT}`);
  console.log(`Proxying API requests to ${BACKEND_URL}`);
});