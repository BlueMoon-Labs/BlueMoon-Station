import type { Graphics } from 'pixi.js';

import { BotGlyphId, botRole } from './actorTaxonomy';
import { GlyphPrimitive, primitivePath, tracePrimitive } from './nodeGlyphs';

export type ProcessKind = 'entity' | 'bots' | 'ice' | 'police';
const poly = (...points: number[]): GlyphPrimitive => ({ kind: 'polyline', points, closed: true });
const line = (x1: number, y1: number, x2: number, y2: number): GlyphPrimitive => ({ kind: 'line', x1, y1, x2, y2 });
const shield = poly(-.9, -.9, .9, -.9, .9, .15, 0, 1, -.9, .15);
type ProcessGlyph = { color: number; body: GlyphPrimitive; ink: GlyphPrimitive[] };
/** Shared silhouettes and pictograms remain recognisable in the legend and at map overview LOD. */
export const PROCESS_GLYPHS: Record<ProcessKind, ProcessGlyph> = {
  entity: { color: 0xf5a9e2, body: poly(0, -1, 1, 0, 0, 1, -1, 0), ink: [
    { kind: 'circle', x: 0, y: -.28, r: .2 }, poly(-.48, .45, -.33, .12, .33, .12, .48, .45),
  ] },
  bots: { color: 0xd8ef83, body: { kind: 'roundRect', x: -1, y: -.8, w: 2, h: 1.7, r: .25 }, ink: [
    line(0, -.8, 0, -1.2), line(-.55, -.15, -.25, -.15), line(.25, -.15, .55, -.15), line(-.4, .4, .4, .4),
  ] },
  ice: { color: 0xff8996, body: shield, ink: [
    line(0, -.6, 0, .5), line(-.48, -.35, .48, .25), line(-.48, .25, .48, -.35),
  ] },
  police: { color: 0x8dcaff, body: shield, ink: [
    poly(0, -.64, .17, -.21, .62, -.19, .28, .11, .38, .56, 0, .31, -.38, .56, -.28, .11, -.62, -.19, -.17, -.21),
  ] },
};
const circle = (x: number, y: number, r: number): GlyphPrimitive => ({ kind: 'circle', x, y, r });
const round: GlyphPrimitive = { kind: 'roundRect', x: -1, y: -1, w: 2, h: 2, r: .25 };
const hexagon = poly(-.5, -1, .5, -1, 1, 0, .5, 1, -.5, 1, -1, 0);
const gear = poly(...Array.from({ length: 32 }, (_, index) => {
  const angle = index * Math.PI / 16, radius = index % 4 === 0 || index % 4 === 3 ? 1 : .76;
  return [Math.cos(angle) * radius, Math.sin(angle) * radius];
}).flat());
/** Faction fills the silhouette; a bold role pictogram stays readable without a letter or label. */
export const BOT_GLYPHS: Record<BotGlyphId, ProcessGlyph> = {
  robot: PROCESS_GLYPHS.bots,
  guard: { color: 0x77d9ad, body: shield, ink: [line(0, -.62, 0, .55), line(-.5, -.14, .5, -.14)] },
  interceptor: { color: 0x77d9ad, body: shield, ink: [poly(-.45, -.6, .4, -.1, -.45, .5), line(.5, -.6, .5, .5)] },
  tool: { color: 0x77d9ad, body: round, ink: [
    poly(-.64, .6, .05, -.1, -.05, -.5, .22, -.76, .22, -.38, .53, -.38, .66, -.65, .72, -.26, .43, .02, .14, -.02, -.5, .74),
  ] },
  radar: { color: 0x77d9ad, body: circle(0, 0, 1), ink: [circle(0, 0, .62), circle(0, 0, .25), line(0, 0, .66, -.66)] },
  box: { color: 0x77d9ad, body: hexagon, ink: [poly(-.65, -.35, 0, -.68, .65, -.35, .65, .4, 0, .72, -.65, .4),
    line(-.65, -.35, 0, -.02), line(.65, -.35, 0, -.02), line(0, -.02, 0, .72)] },
  recycle: { color: 0x77d9ad, body: circle(0, 0, 1), ink: [
    line(-.55, .25, -.1, -.58), poly(-.36, -.49, -.1, -.58, -.06, -.3),
    line(.04, -.58, .59, .28), poly(.34, .18, .59, .28, .62, -.02),
    line(.5, .5, -.5, .5), poly(-.28, .29, -.5, .5, -.27, .7),
  ] },
  cipher: { color: 0x77d9ad, body: round, ink: [poly(-.4, -.42, -.76, 0, -.4, .42),
    poly(.4, -.42, .76, 0, .4, .42), line(.18, -.65, -.18, .65)] },
  breacher: { color: 0x77d9ad, body: hexagon, ink: [poly(-.65, -.54, -.07, 0, -.65, .54),
    poly(-.08, -.54, .5, 0, -.08, .54), line(.65, -.6, .65, .6)] },
  blade: { color: 0xed7687, body: poly(0, -1.1, 1, 0, 0, 1.1, -1, 0), ink: [
    poly(-.43, .55, .13, -.44, .55, -.69, .46, -.21, -.16, .7), line(-.48, .22, .2, .65),
  ] },
  archive: { color: 0xd5c77d, body: round, ink: [poly(-.68, -.45, .68, -.45, .68, .6, -.68, .6),
    line(-.73, -.63, .73, -.63), line(-.25, -.08, .25, -.08), line(-.25, .2, .25, .2)] },
  badge: PROCESS_GLYPHS.police,
  gear: { color: 0x72ddea, body: gear, ink: [circle(0, 0, .35), line(-.57, -.57, -.3, -.3), line(.3, .3, .57, .57)] },
};
const glyphPaths = (glyph: ProcessGlyph) => ({ body: primitivePath(glyph.body), ink: glyph.ink.map(primitivePath).join(' ') });
export const botSvgPaths = (kind?: string | null) => glyphPaths(BOT_GLYPHS[botRole(kind).glyph]);
export const processSvgPaths = (kind: ProcessKind) => {
  return glyphPaths(PROCESS_GLYPHS[kind]);
};
export function drawProcessGlyph(graphics: Graphics, kind: ProcessKind, x: number, y: number, radius: number) {
  drawGlyph(graphics, PROCESS_GLYPHS[kind], x, y, radius);
}
export function drawBotGlyph(graphics: Graphics, kind: string | null | undefined, x: number, y: number, radius: number, color: number) {
  drawGlyph(graphics, BOT_GLYPHS[botRole(kind).glyph], x, y, radius, color);
}
export function drawTintedProcessGlyph(graphics: Graphics, kind: ProcessKind, x: number, y: number, radius: number, color: number) {
  drawGlyph(graphics, PROCESS_GLYPHS[kind], x, y, radius, color);
}
function drawGlyph(graphics: Graphics, glyph: ProcessGlyph, x: number, y: number, radius: number, color = glyph.color) {
  tracePrimitive(graphics, glyph.body, x, y, radius);
  graphics.fill({ color }).stroke({ color: 0x07151f, width: radius * .32, alpha: .98 });
  tracePrimitive(graphics, glyph.body, x, y, radius);
  graphics.stroke({ color: 0xffffff, width: radius * .08, alpha: .7 });
  for (const primitive of glyph.ink) { tracePrimitive(graphics, primitive, x, y, radius); }
  graphics.stroke({ color: 0x10212b, width: radius * .16, cap: 'round', join: 'round' });
}
