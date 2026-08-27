import { createServer } from 'http';
import { readFile } from 'fs/promises';
import { join, extname } from 'path';
import { createProxyMiddleware } from 'http-proxy-middleware';

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

async function serveStatic(req, res) {
  let filePath = join(FRONTEND_DIR, req.url === '/' ? 'index.html' : req.url);
  
  try {
    const content = await readFile(filePath);
    const ext = extname(filePath);
    res.writeHead(200, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
    res.end(content);
  } catch (err) {
    if (err.code === 'ENOENT') {
      try {
        const content = await readFile(join(FRONTEND_DIR, 'index.html'));
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(content);
      } catch {
        res.writeHead(404);
        res.end('Not found');
      }
    } else {
      res.writeHead(500);
      res.end('Server error');
    }
  }
}

const proxy = createProxyMiddleware({
  target: BACKEND_URL,
  changeOrigin: true,
  ws: true,
  logLevel: 'silent',
  onError: (err, req, res) => {
    console.error('Proxy error:', err.message);
    res.writeHead(502);
    res.end('Bad gateway');
  },
});

const server = createServer(async (req, res) => {
  if (req.url.startsWith('/api/') || req.url.startsWith('/health') || req.url.startsWith('/ws') || req.url.startsWith('/sse')) {
    return proxy(req, res, () => {});
  }
  await serveStatic(req, res);
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Maya frontend server running on http://0.0.0.0:${PORT}`);
  console.log(`Proxying API requests to ${BACKEND_URL}`);
});