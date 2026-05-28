/**
 * @file Минимальный dev-сервер для tgui hot-reload (HTTP-статика + WS).
 * Без сторонних пакетов: WS-рукопожатие и кадры на голом http/crypto.
 * @license MIT
 */

const crypto = require('crypto');
const http = require('http');
const fs = require('fs');
const path = require('path');

const WS_GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

// Порт dev-сервера. Должен совпадать с client.cjs и DM-define TGUI_DEV_SERVER_PORT.
const DEV_SERVER_PORT = 3000;

// Резолвит запрошенный URL в путь внутри root; null если выходит за пределы root.
const resolveSafePath = (root, requestUrl) => {
  let decoded;
  try {
    decoded = decodeURIComponent((requestUrl || '/').split('?')[0]);
  } catch (err) {
    return null; // невалидное percent-кодирование — считаем запрос недопустимым
  }
  const filePath = path.join(root, path.normalize(decoded));
  if (filePath !== root && !filePath.startsWith(root + path.sep)) {
    return null;
  }
  return filePath;
};

// Sec-WebSocket-Accept по RFC 6455.
const computeAcceptKey = (key) =>
  crypto.createHash('sha1').update(key + WS_GUID).digest('base64');

// Кодирует текстовый кадр сервер->клиент (без маски).
const encodeTextFrame = (text) => {
  const payload = Buffer.from(text, 'utf8');
  const len = payload.length;
  let header;
  if (len < 126) {
    header = Buffer.from([0x81, len]);
  } else if (len < 65536) {
    header = Buffer.alloc(4);
    header[0] = 0x81;
    header[1] = 126;
    header.writeUInt16BE(len, 2);
  } else {
    header = Buffer.alloc(10);
    header[0] = 0x81;
    header[1] = 127;
    header.writeUInt32BE(0, 2);
    header.writeUInt32BE(len, 6);
  }
  return Buffer.concat([header, payload]);
};

const MIME = {
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.map': 'application/json; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
};

const createDevServer = ({ port = DEV_SERVER_PORT, publicDir }) => {
  const sockets = new Set();
  const root = path.resolve(publicDir);

  const server = http.createServer((req, res) => {
    const filePath = resolveSafePath(root, req.url);
    if (!filePath) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      res.writeHead(200, {
        'Content-Type':
          MIME[path.extname(filePath)] || 'application/octet-stream',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-store',
      });
      res.end(data);
    });
  });

  server.on('upgrade', (req, socket) => {
    const key = req.headers['sec-websocket-key'];
    if (!key) {
      socket.destroy();
      return;
    }
    socket.write(
      'HTTP/1.1 101 Switching Protocols\r\n' +
        'Upgrade: websocket\r\n' +
        'Connection: Upgrade\r\n' +
        'Sec-WebSocket-Accept: ' + computeAcceptKey(key) + '\r\n' +
        '\r\n',
    );
    sockets.add(socket);
    socket.on('close', () => sockets.delete(socket));
    socket.on('error', () => sockets.delete(socket));
    socket.on('data', () => {}); // входящие кадры dev-клиента игнорируем
  });

  const broadcast = (obj) => {
    const frame = encodeTextFrame(JSON.stringify(obj));
    for (const socket of sockets) {
      if (socket.writable) {
        socket.write(frame);
      }
    }
  };

  const listen = () =>
    new Promise((resolve, reject) => {
      const onError = (err) => {
        server.removeListener('listening', onListening);
        reject(err);
      };
      const onListening = () => {
        server.removeListener('error', onError);
        resolve();
      };
      server.once('error', onError);
      server.once('listening', onListening);
      server.listen(port, '127.0.0.1');
    });

  return { server, broadcast, listen, sockets };
};

module.exports = {
  DEV_SERVER_PORT,
  computeAcceptKey,
  encodeTextFrame,
  resolveSafePath,
  createDevServer,
};
