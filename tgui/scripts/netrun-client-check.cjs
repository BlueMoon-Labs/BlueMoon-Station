/** Local-only browser fixtures for the built TGUI bundle; no game server or IPC. */
const fs = require('fs');
const http = require('http');
const path = require('path');
const publicDir = path.resolve(__dirname, '../public');
const port = Number(process.env.NETRUN_CLIENT_CHECK_PORT || 5197);

const action = (id, name, params = []) => ({ id, name, params, access: 2, allowed: true });
const param = (id, name, type = 'text', extra = {}) => ({ id, name, type, ...extra });
const remotes = {
  AtmosPump: { data: { on: 1, pressure: 101.3, max_pressure: 4500, line_pressure: 250 },
    actions: [action('power', 'Переключить питание'), action('pressure', 'Установить давление', [param('pressure', 'Давление, кПа', 'number', { min: 0, max: 4500, value: 101.3 })])] },
  AirAlarm: { data: { atmos_alarm: 0, fire_alarm: 0, environment_data: [{ name: 'Давление', value: 101.3, unit: 'kPa' }], vents: [{ name: 'Вентиляция' }], scrubbers: [{ name: 'Скруббер' }] },
    actions: [action('mode', 'Установить режим', [param('mode', 'Режим', 'text', { options: [{ value: 'scrubbing', name: 'Фильтрация' }] })])] },
  PortableTurret: { data: { on: 1, locked: 0, check_weapons: 1, ignore_heads: 1 }, actions: [action('power', 'Переключить питание')] },
  MODsuit: { data: { active: 1, charge: 65, wearer: 'Испытатель', modules: [{ name: 'Реактивный модуль', active: 1, selected: 1 }] }, actions: [action('power', 'Переключить питание')] },
  Vending: { data: { stock: { soda: 5 }, product_records: [{ ref: 'soda', name: 'Газировка', price: 15 }], user: { name: 'Испытатель', cash: 500 } }, actions: [action('vend', 'Выдать товар', [param('ref', 'Товар')])] },
  Techweb: { data: { researchable: 1, locked: 0, web_org: 'Научный отдел', points: { Generic: 6000 },
    static_data: { id_cache: ['comptech'], node_cache: { '1': { name: 'Компьютерные консоли' } } },
    nodes: [{ id: 'comptech', tier: 1, can_unlock: 1, costs: { Generic: 2000 } }] },
    actions: [action('researchNode', 'Исследовать технологию', [param('node_id', 'Код технологии')])] },
  Fabricator: { data: { busy: 0, maxBuildButtonAmount: 5, materials_text: 'Металл: 10000', categories: [{ name: 'Детали', items: [{ id: 'micro_mani', name: 'Манипулятор' }] }] },
    actions: [action('build', 'Изготовить', [param('id', 'Чертёж'), param('amount', 'Количество', 'number', { min: 1, max: 60 })])] },
};

function fixture(scenario) {
  const common = { PC_stationtime: '12:00', PC_device_theme: 'ntos' };
  if (scenario === 'messenger') {
    return { interface: 'NtosMessenger', width: 600, height: 850, data: { ...common,
      saved_chats: {}, open_chat: 'recipient', emoji_list: [],
      messengers: { recipient: { ref: 'recipient', name: 'Получатель', job: 'Инженер' } }, delivery_status: null } };
  }
  const node = { address: 'TEST:0001', name: 'APC испытаний', type: 'apc', x: 10, y: 10, z: 1, security: 2, online: 1,
    access: 2, entities: 0, active: 0, uplink: null, network: 'engineering', legit: 2, commands: [], status: [] };
  return { interface: 'NetrunTerminal', width: 1280, height: 800, data: { ...common,
    origin: 'terminal', wireless: 0, uplink: 1, trace: 0, locked: 0, can_breach: 1, log: [], jack: null, host_actions: [],
    networks: [], view: null, selected: node, storage: { files: [], used: 0, capacity: 10 }, shard: null,
    breach: null, entity: null, combat: null, chat: { handle: 'runner', messages: [] }, web: null, window: null,
    workspace_view: 'pinned', selected_network: null, ping_route: null, cli: { verbs: [] },
    map: { gateways: [], focus: node.address, revision: 1, nodes: [node], edges: [] },
    windows: Object.entries(remotes).map(([name, remote], index) => ({ address: `TEST:${index + 1}`, title: name, type: 'terminal',
      online: 1, access: 2, fields: [], commands: [], extra: [], feed: null, watching: 0, remote: { interface: name, ...remote } })) } };
}

http.createServer((req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${port}`);
  if (url.pathname === '/' || url.pathname === '/tgui.html') {
    const sample = fixture(url.searchParams.get('scenario') || 'messenger');
    const bootstrap = `
      <script>
      document.addEventListener('DOMContentLoaded', () => {
        const sample = ${JSON.stringify(sample)};
        if (sample.data.windows) { sample.data.window = sample.data.windows[0]; }
        Byond.winset = () => {}; Byond.winget = () => Promise.resolve({ x: 0, y: 0 });
        Byond.topic = message => {
          const output = document.getElementById('fixture-actions');
          output.textContent = JSON.stringify(message);
          const payload = message.payload ? JSON.parse(message.payload) : {};
          if (message.type === 'act/window_focus') {
            window.update(JSON.stringify({ type: 'update', payload: { data: {
              window: sample.data.windows.find(entry => entry.address === payload.address) } } }));
          }
          if (message.type === 'act/workspace_view') {
            window.update(JSON.stringify({ type: 'update', payload: { data: { workspace_view: payload.page } } }));
          }
          if (message.type === 'act/PDA_sendMessage') {
            window.update(JSON.stringify({ type: 'update', payload: { data: { delivery_status: 'Запрос отправлен. Ожидается подтверждение доставки.', delivery_pending: 1 } } }));
          }
        };
        window.update(JSON.stringify({ type: 'update', payload: {
          config: { interface: sample.interface, title: 'Локальная проверка ' + sample.interface,
            status: 2, window: { key: 'client-check-' + sample.interface, fancy: false, scale: 1 } }, data: sample.data } }));
        const controls = document.getElementById('fixture-controls');
        for (const [label, status, pending, error] of sample.interface === 'NtosMessenger' ? [
          ['Ожидание', 'Запрос отправлен. Ожидается подтверждение доставки.', 1, 0],
          ['Доставлено', 'Сообщение доставлено.', 0, 0],
          ['Ошибка', 'Доставка отклонена: получатель отключён от сети.', 0, 1],
        ] : []) {
          const button = document.createElement('button'); button.textContent = label;
          button.onclick = () => window.update(JSON.stringify({ type: 'update', payload: { data: {
            delivery_status: status, delivery_pending: pending, delivery_error: error } } }));
          controls.append(button);
        }
      });
      </script>`;
    const html = fs.readFileSync(path.join(publicDir, 'tgui.html'), 'utf8')
      .replace('<!-- tgui:assets -->', '<link rel="stylesheet" href="/tgui.bundle.css"><script src="/tgui.bundle.js"></script>')
      .replace('</body>', '<div id="fixture-controls" style="position:fixed;right:3px;top:3px;z-index:99999"></div><output id="fixture-actions" style="display:none"></output>' + bootstrap + '</body>');
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }); res.end(html); return;
  }
  const files = { '/tgui.bundle.js': 'application/javascript', '/tgui.bundle.css': 'text/css' };
  if (!files[url.pathname]) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': files[url.pathname] });
  fs.createReadStream(path.join(publicDir, url.pathname.slice(1))).pipe(res);
}).listen(port, '127.0.0.1', () => console.log(`Local client fixtures: http://127.0.0.1:${port}/tgui.html?external&scenario=messenger`));
