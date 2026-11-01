import { BOT_ROLES } from './actorTaxonomy';
import { BOT_GLYPHS, botSvgPaths, drawBotGlyph } from './processGlyphs';
import { MockGraphics } from './testSupport/pixiLibraryMock';

test('bot role SVG and Pixi share bounded, distinct pictogram geometry', () => {
  const shapes = new Set<string>();
  for (const glyph of Object.values(BOT_GLYPHS)) {
    const primitives = [glyph.body, ...glyph.ink];
    for (const primitive of primitives) {
      const coordinates = Object.values(primitive).flat().filter((value) => typeof value === 'number') as number[];
      expect(coordinates.every((value) => Number.isFinite(value) && Math.abs(value) <= 2)).toBe(true);
    }
    shapes.add(JSON.stringify(primitives));
  }
  expect(shapes.size).toBe(Object.keys(BOT_GLYPHS).length);
  for (const kind of Object.keys(BOT_ROLES)) {
    expect(botSvgPaths(kind).body).not.toMatch(/NaN|undefined/);
    expect(botSvgPaths(kind).ink.length).toBeGreaterThan(0);
  }
  expect(botSvgPaths('redshift_hacker')).toEqual(botSvgPaths('hacker'));
  expect(botSvgPaths('unknown')).toEqual(botSvgPaths());
});

test('map role glyph honours faction tint and preserves dark high-contrast ink', () => {
  const graphic = new MockGraphics();
  drawBotGlyph(graphic as never, 'recycler', 50, 25, 10, 0xf18f65);
  expect(graphic.calls.find((call) => call.op === 'fill').args[0]).toEqual({ color: 0xf18f65 });
  expect(graphic.calls.at(-1)).toEqual({ op: 'stroke', args: [{ color: 0x10212b, width: 1.6, cap: 'round', join: 'round' }] });
  expect(graphic.calls.filter((call) => call.op === 'lineTo').length).toBeGreaterThan(5);
});
