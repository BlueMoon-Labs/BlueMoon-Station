/** Presentation metadata only: unknown server profiles keep a neutral, usable identity. */
export type BotGlyphId = 'robot' | 'guard' | 'interceptor' | 'tool' | 'radar' | 'box' | 'recycle'
  | 'cipher' | 'breacher' | 'blade' | 'archive' | 'badge' | 'gear';
type BotRole = { name: string; icon: string; glyph: BotGlyphId };
export const BOT_ROLES: Record<string, BotRole> = {
  custom: { name: 'Собственный агент', icon: 'robot', glyph: 'robot' },
  sentinel: { name: 'Агент-страж', icon: 'shield-halved', glyph: 'guard' },
  interceptor: { name: 'Агент-перехватчик', icon: 'crosshairs', glyph: 'interceptor' },
  mender: { name: 'Агент-ремонтник', icon: 'screwdriver-wrench', glyph: 'tool' },
  surveyor: { name: 'Агент-разведчик', icon: 'satellite-dish', glyph: 'radar' },
  collector: { name: 'Агент-сборщик', icon: 'box', glyph: 'box' },
  recycler: { name: 'Агент-утилизатор', icon: 'recycle', glyph: 'recycle' },
  hacker: { name: 'Агент-взломщик', icon: 'code', glyph: 'cipher' },
  breacher: { name: 'Агент-пробойник', icon: 'burst', glyph: 'breacher' },
  raider: { name: 'Рейдер', icon: 'khanda', glyph: 'blade' },
  scavenger: { name: 'Мусорщик сети', icon: 'box-archive', glyph: 'archive' },
  police: { name: 'Сетевая полиция', icon: 'shield-halved', glyph: 'badge' },
  custodian: { name: 'Санитар сети', icon: 'gears', glyph: 'gear' },
};
/** Visitors share their functional role, but retain their own name and faction. */
const VISITOR_ROLES: Record<string, { role: string; name: string }> = {
  redshift_raider: { role: 'raider', name: 'Налётчик Красного смещения' },
  redshift_hacker: { role: 'hacker', name: 'Диверсант Красного смещения' },
  collective_guard: { role: 'sentinel', name: 'Страж Осколочного коллектива' },
  archive_collector: { role: 'scavenger', name: 'Собиратель Вольного архива' },
};
for (const [id, visitor] of Object.entries(VISITOR_ROLES)) {
  BOT_ROLES[id] = { ...BOT_ROLES[visitor.role], name: visitor.name };
}
const UNKNOWN_ROLE: BotRole = { name: 'Автономный процесс', icon: 'robot', glyph: 'robot' };
function ownValue<T>(table: Record<string, T>, id: string) {
  return Object.prototype.hasOwnProperty.call(table, id) ? table[id] : undefined;
}
export const botRole = (kind?: string | null): BotRole => ownValue(BOT_ROLES, kind ?? '') || UNKNOWN_ROLE;
export const BOT_NAMES: Record<string, string> = Object.fromEntries(Object.entries(BOT_ROLES).map(([id, role]) => [id, role.name]));
export const BOT_ICONS: Record<string, string> = Object.fromEntries(Object.entries(BOT_ROLES).map(([id, role]) => [id, role.icon]));

export const FACTION_COLORS: Record<string, string> = {
  station: '#72ddea', owner: '#77d9ad', rogue: '#ed7687',
  redshift: '#f18f65', collective: '#b7a0ff', archivists: '#d5c77d',
};
const FACTION_LABELS: Record<string, string> = {
  station: 'станция', owner: 'агент', rogue: 'дикий',
  redshift: 'Красное смещение', collective: 'Осколочный коллектив', archivists: 'Вольный архив',
};
export const factionFamily = (faction?: string | null) => faction?.startsWith('owner:') ? 'owner' : faction ?? '';
/** Accept only a concrete RGB value, never CSS expressions from wire metadata. */
export const factionColor = (faction?: string | null, provided?: string | null) =>
  provided && /^#[\da-f]{6}$/i.test(provided) ? provided : ownValue(FACTION_COLORS, factionFamily(faction)) || '#8ca9b8';
export const factionName = (faction?: string | null) => ownValue(FACTION_LABELS, factionFamily(faction)) || null;
