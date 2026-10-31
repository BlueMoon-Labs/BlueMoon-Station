import type { MachineWindow } from './types';

type Remote = NonNullable<MachineWindow['remote']>;
type Action = Remote['actions'][number];
type RecordData = Record<string, unknown>;
type Option = { value: string; name: string };
export type MachinePresentation = { title: string; readings: { label: string; value: string }[]; actions: Action[] };
const record = (value: unknown): RecordData => value && typeof value === 'object' && !Array.isArray(value) ? value as RecordData : {};
const rows = (value: unknown): RecordData[] => Array.isArray(value) ? value.map(record) : [];
const text = (value: unknown) => typeof value === 'string' || typeof value === 'number' ? String(value) : '—';
const yes = (value: unknown) => value ? 'Включено' : 'Выключено';
const unit = (value: unknown, suffix: string) => typeof value === 'number' && Number.isFinite(value) ? `${Math.round(value * 100) / 100} ${suffix}` : '—';
const cost = (value: unknown) => Object.entries(record(value)).map(([id, amount]) => `${text(amount)} ${id}`).join(', ');

/** Only native data already published by this endpoint can populate request choices.
 * Choices improve usability; the DM schema, access and native machine remain authoritative. */
export function machinePresentation(remote: Remote): MachinePresentation | null {
  const data = record(remote.data);
  const readings: MachinePresentation['readings'] = [];
  let title: string;
  let choiceAction = '', choiceParam = '';
  let choices: Option[] | undefined;
  let unavailable: string | undefined;
  let amountMax: number | undefined;
  const add = (label: string, value: string) => readings.push({ label, value });
  switch (remote.interface) {
    case 'AtmosPump':
      title = 'Управление насосом';
      add('Питание', yes(data.on));
      if (typeof data.max_rate === 'number') { add('Расход', unit(data.rate, 'л/с')); }
      else { add('Уставка давления', unit(data.pressure, 'кПа')); }
      if (typeof data.line_pressure === 'number') { add('Давление линии', unit(data.line_pressure, 'кПа')); }
      for (const port of rows(data.ports)) { add(text(port.name), unit(port.pressure, 'кПа')); }
      break;
    case 'AirAlarm':
      title = 'Атмосфера отсека';
      add('Атмосферная тревога', data.atmos_alarm ? 'Тревога' : 'Норма');
      add('Пожарная тревога', data.fire_alarm ? 'Тревога' : 'Норма');
      for (const reading of rows(data.environment_data)) { add(text(reading.name), unit(reading.value, reading.unit === 'kPa' ? 'кПа' : text(reading.unit))); }
      add('Вентиляции / скрубберы', `${rows(data.vents).length} / ${rows(data.scrubbers).length}`);
      break;
    case 'PortableTurret':
      title = 'Контроллер турели';
      add('Питание', yes(data.on)); add('Панель', data.locked ? 'Заблокирована' : 'Разблокирована');
      for (const [key, label] of [['check_weapons', 'Проверка оружия'], ['neutralize_criminals', 'Розыск'], ['neutralize_all', 'Огонь по всем'],
        ['neutralize_unidentified', 'Неопознанные'], ['neutralize_nonmindshielded', 'Без защиты разума'], ['neutralize_cyborgs', 'Киборги'], ['ignore_heads', 'Исключение глав']]) {
        add(label, yes(data[key]));
      }
      break;
    case 'MODsuit':
      title = 'Системы MOD';
      add('Системы', yes(data.active)); add('Батарея', unit(data.charge, '%')); add('Носитель', text(data.wearer));
      add('Сервисная панель', data.open ? 'Открыта' : 'Закрыта');
      for (const module of rows(data.modules)) { add(text(module.name), `${yes(module.active)}${module.selected ? ' · выбран' : ''}`); }
      break;
    case 'Vending': {
      title = 'Торговый автомат'; choiceAction = 'vend'; choiceParam = 'ref';
      const stock = record(data.stock);
      const products = [...rows(data.product_records), ...rows(data.coin_records), ...(data.extended_inventory ? rows(data.hidden_records) : [])];
      choices = products.filter(product => typeof product.ref === 'string' && Number(stock[product.ref]) > 0)
        .map(product => ({ value: String(product.ref), name: `${text(product.name)} · ${text(product.price)} кр. · ${text(stock[String(product.ref)])} шт.` }));
      const user = record(data.user);
      add('Покупатель', text(user.name)); if (typeof user.cash === 'number') { add('Баланс', unit(user.cash, 'кр.')); }
      add('Доступно товаров', String(choices.length));
      if (!choices.length) { unavailable = 'Нет доступных товаров. Дождитесь обновления ассортимента.'; }
      break;
    }
    case 'Techweb': {
      title = 'Исследования сервера'; choiceAction = 'researchNode'; choiceParam = 'node_id';
      const catalog = record(data.static_data), names = new Map<string, string>();
      const ids = Array.isArray(catalog.id_cache) ? catalog.id_cache : [];
      for (const [key, value] of Object.entries(record(catalog.node_cache))) {
        const id = ids[Number(key) - 1];
        if (typeof id === 'string') { names.set(id, text(record(value).name)); }
      }
      choices = rows(data.nodes).filter(node => typeof node.id === 'string' && node.tier === 1 && node.can_unlock)
        .map(node => ({ value: String(node.id), name: `${names.get(String(node.id)) || (typeof node.name === 'string' ? node.name : String(node.id))}${cost(node.costs) ? ` · ${cost(node.costs)}` : ''}` }));
      add('Организация', text(data.web_org)); add('Очки', cost(data.points) || '0');
      add('Доступно исследований', String(choices.length));
      if (data.locked) { unavailable = 'Научная консоль заблокирована.'; }
      else if (data.researchable === false || data.researchable === 0 || !choices.length) { unavailable = 'Нет доступных исследований. Проверьте связь с сервером, зависимости и очки.'; }
      break;
    }
    case 'Fabricator':
      title = 'Производство'; choiceAction = 'build'; choiceParam = 'id';
      choices = rows(data.categories).flatMap(category => rows(category.items))
        .filter(item => typeof item.id === 'string').map(item => ({ value: String(item.id), name: text(item.name) }));
      add('Состояние', data.busy ? 'Изготовление' : 'Готово'); add('Материалы', text(data.materials_text));
      add('Доступно чертежей', String(choices.length));
      if (typeof data.maxBuildButtonAmount === 'number' && data.maxBuildButtonAmount >= 1) { amountMax = data.maxBuildButtonAmount; }
      if (data.busy || data.onHold) { unavailable = 'Производство занято или приостановлено.'; }
      else if (!choices.length) { unavailable = 'Нет доставленных чертежей. Проверьте исследовательский сервер.'; }
      break;
    default: return null;
  }
  const actions = remote.actions.map(action => {
    if (action.id !== choiceAction) { return action; }
    return { ...action, allowed: action.allowed && !unavailable, reason: action.reason || unavailable,
      params: action.params?.map(param => param.id === choiceParam ? { ...param, options: choices } :
        (param.id === 'amount' && amountMax !== undefined ? { ...param, value: param.value ?? 1, max: Math.min(param.max ?? amountMax, amountMax) } : param)) };
  });
  return { title, readings, actions };
}
