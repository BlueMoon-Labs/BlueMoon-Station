import { botRole, FACTION_COLORS, factionColor, factionName } from './actorTaxonomy';

test('registry factions have distinct colours and personal factions inherit owner presentation', () => {
  expect(new Set(Object.values(FACTION_COLORS)).size).toBe(6);
  expect(factionColor('station')).toBe('#72ddea');
  expect(factionColor('redshift')).toBe('#f18f65');
  expect(factionColor('collective')).toBe('#b7a0ff');
  expect(factionColor('archivists')).toBe('#d5c77d');
  expect(factionColor('owner:42')).toBe(FACTION_COLORS.owner);
  expect(factionName('owner:42')).toBe('агент');
  expect(factionColor('owner:42', '#Aa12F0')).toBe('#Aa12F0');
  expect(factionColor('future-faction', '#123456')).toBe('#123456');
});

test('wire colour metadata accepts only concrete six-digit RGB and unknown ids are neutral', () => {
  for (const unsafe of ['red', 'var(--net-accent)', 'url(https://example.test)', '#123', '#12345678', '#12345g', '#123456;display:none']) {
    expect(factionColor('redshift', unsafe)).toBe(FACTION_COLORS.redshift);
  }
  expect(factionColor('unknown')).toBe('#8ca9b8');
  expect(factionColor('__proto__')).toBe('#8ca9b8');
  expect(botRole('__proto__').glyph).toBe('robot');
  expect(botRole('unknown').name).toBe('Автономный процесс');
});

test('all visitor types resolve their functional role and a specific readable name', () => {
  const visitors = { raider: 'blade', scavenger: 'archive', redshift_raider: 'blade',
    redshift_hacker: 'cipher', collective_guard: 'guard', archive_collector: 'archive' };
  for (const [id, glyph] of Object.entries(visitors)) {
    expect(botRole(id).glyph).toBe(glyph);
    expect(botRole(id).name).not.toBe(botRole('unknown').name);
  }
  expect(botRole('hacker').glyph).not.toBe(botRole('breacher').glyph);
  expect(botRole('collector').glyph).not.toBe(botRole('recycler').glyph);
  expect(botRole('sentinel').glyph).not.toBe(botRole('interceptor').glyph);
});
