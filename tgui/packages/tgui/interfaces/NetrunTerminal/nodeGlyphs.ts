import type { Graphics } from 'pixi.js';

/** Unit-space drawing primitive: a body fits the unit circle and is scaled by its device radius. */
export type GlyphPrimitive =
  | { kind: 'line'; x1: number; y1: number; x2: number; y2: number }
  | { kind: 'polyline'; points: number[]; closed?: boolean }
  | { kind: 'circle'; x: number; y: number; r: number }
  | { kind: 'rect'; x: number; y: number; w: number; h: number }
  | { kind: 'roundRect'; x: number; y: number; w: number; h: number; r: number };

export type GlyphFamily = 'infrastructure' | 'security' | 'compute' | 'service' | 'silicon' | 'device';

/** One device silhouette and pictogram, shared by Pixi and the React legend icons. */
export type NodeGlyph = {
  family: GlyphFamily;
  /** Body radius in world units; more important devices are larger. */
  radius: number;
  /** Silhouette: filled with the access colour, outlined with the LAN colour. */
  body: GlyphPrimitive[];
  /** Pictogram strokes in dark ink. */
  strokes: GlyphPrimitive[];
  /** Pictogram fills in dark ink. */
  fills: GlyphPrimitive[];
};

type GlyphPath = Pick<Graphics, 'moveTo' | 'lineTo' | 'closePath' | 'circle' | 'rect' | 'roundRect'>;
type GlyphGraphics = GlyphPath & Pick<Graphics, 'fill' | 'stroke'>;

/** Pictograms appear only when they are large enough to read. */
export const GLYPH_MIN_ZOOM = .32;
export const MAX_GLYPH_RADIUS = 18;
export const GLYPH_INK = 0x0b1822;
export const GLYPH_INK_CSS = '#0b1822';
export const GLYPH_STROKE = 1.9;
export const BODY_STROKE = 1.8;
export const BODY_ALPHA = .94;
export const OFFLINE_ALPHA = .55;
export const OFFLINE_SLASH = 2.2;

const line = (x1: number, y1: number, x2: number, y2: number): GlyphPrimitive => ({ kind: 'line', x1, y1, x2, y2 });
const path = (closed: boolean, ...points: number[]): GlyphPrimitive => ({ kind: 'polyline', points, closed });
const circle = (x: number, y: number, r: number): GlyphPrimitive => ({ kind: 'circle', x, y, r });
const rect = (x: number, y: number, w: number, h: number): GlyphPrimitive => ({ kind: 'rect', x, y, w, h });
const round = (x: number, y: number, w: number, h: number, r: number): GlyphPrimitive => ({ kind: 'roundRect', x, y, w, h, r });
const regular = (sides: number, rotation = 0) => path(true, ...Array.from({ length: sides }, (_, i) => {
  const angle = rotation + i * 2 * Math.PI / sides;
  return [Math.cos(angle), Math.sin(angle)];
}).flat());
const rotate = (points: number[], angle: number) => points.map((_, i) => i % 2
  ? points[i - 1] * Math.sin(angle) + points[i] * Math.cos(angle)
  : points[i] * Math.cos(angle) - points[i + 1] * Math.sin(angle));
/** A chip outline with three pins on every side, as one closed silhouette. */
const chip = (half: number, depth: number, width: number) => {
  const points: number[] = [];
  // Each side runs clockwise from its corner; pins stick out along the outward normal.
  const sides = [[-1, -1, 1, 0, 0, -1], [1, -1, 0, 1, 1, 0], [1, 1, -1, 0, 0, 1], [-1, 1, 0, -1, -1, 0]];
  for (const [cx, cy, dx, dy, nx, ny] of sides) {
    points.push(cx * half, cy * half);
    for (const offset of [-.42, 0, .42]) {
      const along = half + offset * half;
      for (const [step, out] of [[-width / 2, 0], [-width / 2, depth], [width / 2, depth], [width / 2, 0]]) {
        points.push(cx * half + dx * (along + step) + nx * out, cy * half + dy * (along + step) + ny * out);
      }
    }
  }
  return path(true, ...points);
};
const lens = (height: number, steps = 10) => path(true, ...Array.from({ length: steps * 2 }, (_, i) => {
  const t = i < steps ? i / steps : 1 - (i - steps) / steps, top = i < steps ? -1 : 1;
  return [-1 + 2 * t, top * height * Math.sin(Math.PI * t)];
}).flat());

const relay: Omit<NodeGlyph, 'radius'> = { family: 'infrastructure', body: [regular(6)],
  strokes: [path(false, -.3, .62, 0, -.16, .3, .62), line(-.17, .3, .17, .3),
    path(false, -.36, -.62, -.54, -.32, -.36, -.02), path(false, .36, -.62, .54, -.32, .36, -.02)],
  fills: [circle(0, -.3, .13)] };
const blade = [.07, -.08, .34, -.56, -.04, -.68, -.13, -.12];

const GLYPHS: Record<string, NodeGlyph> = {
  apc: { family: 'infrastructure', radius: 15, body: [round(-.84, -.84, 1.68, 1.68, .2)], strokes: [],
    fills: [path(true, .16, -.66, -.34, .1, -.02, .1, -.16, .66, .34, -.12, .02, -.12)] },
  relay: { ...relay, radius: 16 },
  gateway: { family: 'infrastructure', radius: 16, body: [regular(4, Math.PI / 4)],
    strokes: [path(false, -.62, -.2, .62, -.2, .36, -.44), path(false, .62, .2, -.62, .2, -.36, .44)], fills: [] },
  camera: { family: 'security', radius: 12,
    body: [path(true, -.94, -.44, .46, -.44, .94, -.66, .94, .42, .46, .2, -.94, .2), rect(-.54, .2, .24, .46), rect(-.78, .62, .72, .2)],
    strokes: [circle(.66, -.12, .16)], fills: [circle(-.6, -.12, .1)] },
  turret: { family: 'security', radius: 14, body: [regular(8, Math.PI / 8)],
    strokes: [circle(0, 0, .44), line(0, -.74, 0, -.2), line(0, .2, 0, .74), line(-.74, 0, -.2, 0), line(.2, 0, .74, 0)],
    fills: [circle(0, 0, .09)] },
  airlock: { family: 'security', radius: 13, body: [round(-.66, -.96, 1.32, 1.92, .14)],
    strokes: [line(0, -.56, 0, .8), line(-.42, -.72, .42, -.72), line(-.3, -.06, -.3, .3), line(.3, -.06, .3, .3)], fills: [] },
  server: { family: 'compute', radius: 15, body: [round(-.72, -.96, 1.44, 1.92, .12)],
    strokes: [line(-.46, -.5, .18, -.5), line(-.46, 0, .18, 0), line(-.46, .5, .18, .5)],
    fills: [circle(.42, -.5, .09), circle(.42, 0, .09), circle(.42, .5, .09)] },
  terminal: { family: 'compute', radius: 13,
    body: [round(-.96, -.82, 1.92, 1.32, .14), rect(-.12, .48, .24, .22), round(-.46, .68, .92, .2, .08)],
    strokes: [path(false, -.62, -.44, -.32, -.18, -.62, .08), line(-.14, .1, .38, .1)], fills: [] },
  circuit: { family: 'compute', radius: 12, body: [chip(.64, .24, .16)],
    strokes: [rect(-.32, -.32, .64, .64)], fills: [circle(-.16, -.16, .08)] },
  deck: { family: 'compute', radius: 13,
    body: [path(true, -.96, .64, .96, .64, .8, -.18, -.8, -.18), round(-.62, -.76, 1.24, .58, .08)],
    strokes: [line(-.42, -.47, .12, -.47), line(-.6, .14, .6, .14), line(-.68, .4, .68, .4)], fills: [] },
  vendor: { family: 'service', radius: 13,
    body: [path(true, -.82, .94, .82, .94, .82, -.38, .98, -.38, .74, -.92, -.74, -.92, -.98, -.38, -.82, -.38)],
    strokes: [line(-.82, -.38, .82, -.38), line(-.26, -.86, -.32, -.38), line(.26, -.86, .32, -.38),
      rect(-.52, -.16, 1.04, .6), line(-.3, .72, .3, .72)], fills: [] },
  atmos: { family: 'service', radius: 12, body: [round(-.86, -.86, 1.72, 1.72, .46)], strokes: [],
    fills: [0, 2, 4].map((step) => path(true, ...rotate(blade, step * Math.PI / 3))).concat(circle(0, 0, .14)) },
  intercom: { family: 'service', radius: 12, body: [round(-.74, -.92, 1.48, 1.84, .32)],
    strokes: [circle(0, -.22, .36)], fills: [circle(0, -.22, .12), round(-.24, .42, .48, .2, .08)] },
  ai: { family: 'silicon', radius: 18, body: [lens(.68)], strokes: [circle(0, 0, .42)], fills: [circle(0, 0, .19)] },
  borg: { family: 'silicon', radius: 14,
    body: [round(-.78, -.72, 1.56, 1.44, .3), rect(-.98, -.22, .22, .44), rect(.76, -.22, .22, .44)],
    strokes: [line(-.32, .34, .32, .34)], fills: [circle(-.32, -.12, .14), circle(.32, -.12, .14)] },
  pai: { family: 'silicon', radius: 12, body: [round(-.88, -.74, 1.76, 1.48, .58)],
    strokes: [path(false, -.34, .2, -.12, .38, .12, .38, .34, .2)], fills: [circle(-.3, -.12, .11), circle(.3, -.12, .11)] },
  implant: { family: 'silicon', radius: 11, body: [round(-1, -.46, 2, .92, .46)],
    strokes: [line(0, -.36, 0, .36), line(.28, 0, .62, 0)], fills: [circle(-.5, 0, .11)] },
  neural: { family: 'silicon', radius: 12,
    body: [path(true, -.95, .1, -.9, -.35, -.6, -.75, -.15, -.86, 0, -.7, .15, -.86, .6, -.75, .9, -.35, .95, .1,
      .75, .5, .35, .7, .1, .65, 0, .85, -.1, .65, -.35, .7, -.75, .5)],
    strokes: [line(0, -.56, 0, .52), path(false, -.64, -.2, -.36, -.06, -.52, .22), path(false, .64, -.2, .36, -.06, .52, .22)],
    fills: [] },
  modsuit: { family: 'silicon', radius: 13,
    body: [path(true, -.84, .2, -.84, -.2, -.72, -.6, -.4, -.88, 0, -.96, .4, -.88, .72, -.6, .84, -.2, .84, .2,
      .62, .62, .3, .9, -.3, .9, -.62, .62)],
    strokes: [line(-.22, .56, .22, .56)], fills: [round(-.6, -.32, 1.2, .4, .18)] },
  optic: { family: 'silicon', radius: 11,
    body: [round(-.98, -.42, .86, .74, .3), round(.12, -.42, .86, .74, .3), rect(-.14, -.24, .28, .14)],
    strokes: [line(-.78, -.02, -.32, -.02), line(.32, -.02, .78, -.02)], fills: [] },
};
const DEFAULT_GLYPH: NodeGlyph = { family: 'device', radius: 11, body: [circle(0, 0, 1)], strokes: [], fills: [circle(0, 0, .3)] };

export const nodeGlyph = (type: string): NodeGlyph => GLYPHS[type] ?? DEFAULT_GLYPH;
export const glyphRadius = (type: string) => nodeGlyph(type).radius;
export const GLYPH_TYPES = Object.keys(GLYPHS);

export function tracePrimitive(graphic: GlyphPath, primitive: GlyphPrimitive, x: number, y: number, radius: number) {
  switch (primitive.kind) {
    case 'line':
      graphic.moveTo(x + primitive.x1 * radius, y + primitive.y1 * radius).lineTo(x + primitive.x2 * radius, y + primitive.y2 * radius);
      break;
    case 'polyline': {
      const points = primitive.points;
      graphic.moveTo(x + points[0] * radius, y + points[1] * radius);
      for (let i = 2; i < points.length; i += 2) { graphic.lineTo(x + points[i] * radius, y + points[i + 1] * radius); }
      if (primitive.closed) { graphic.closePath(); }
      break;
    }
    case 'circle': graphic.circle(x + primitive.x * radius, y + primitive.y * radius, primitive.r * radius); break;
    case 'rect': graphic.rect(x + primitive.x * radius, y + primitive.y * radius, primitive.w * radius, primitive.h * radius); break;
    case 'roundRect':
      graphic.roundRect(x + primitive.x * radius, y + primitive.y * radius, primitive.w * radius, primitive.h * radius, primitive.r * radius);
      break;
  }
}

const trace = (graphic: GlyphPath, primitives: GlyphPrimitive[], x: number, y: number, radius: number) => {
  for (const primitive of primitives) { tracePrimitive(graphic, primitive, x, y, radius); }
  return primitives.length > 0;
};
export const traceBody = (graphic: GlyphPath, type: string, x: number, y: number) => {
  const glyph = nodeGlyph(type); return trace(graphic, glyph.body, x, y, glyph.radius);
};
export const traceGlyphStrokes = (graphic: GlyphPath, type: string, x: number, y: number) => {
  const glyph = nodeGlyph(type); return trace(graphic, glyph.strokes, x, y, glyph.radius);
};
export const traceGlyphFills = (graphic: GlyphPath, type: string, x: number, y: number) => {
  const glyph = nodeGlyph(type); return trace(graphic, glyph.fills, x, y, glyph.radius);
};
/** Unreachable devices are crossed out corner to corner, inside their silhouette. */
export const traceOfflineSlash = (graphic: GlyphPath, type: string, x: number, y: number) => {
  const reach = glyphRadius(type) * .62;
  graphic.moveTo(x - reach, y + reach).lineTo(x + reach, y - reach);
};

/** One self-contained device marker; batched scenery traces the same paths itself. */
export function drawBody(graphic: GlyphGraphics, type: string, x: number, y: number, fill: number, border: number, online = true) {
  traceBody(graphic, type, x, y);
  graphic.fill({ color: fill, alpha: online ? BODY_ALPHA : OFFLINE_ALPHA }).stroke({ color: border, width: BODY_STROKE, alpha: online ? 1 : .6 });
  if (!online) {
    traceOfflineSlash(graphic, type, x, y);
    graphic.stroke({ color: GLYPH_INK, width: OFFLINE_SLASH, alpha: .85 });
  }
  return graphic;
}

export function drawGlyph(graphic: GlyphGraphics, type: string, x: number, y: number, alpha = .9) {
  if (traceGlyphStrokes(graphic, type, x, y)) { graphic.stroke({ color: GLYPH_INK, width: GLYPH_STROKE, alpha }); }
  if (traceGlyphFills(graphic, type, x, y)) { graphic.fill({ color: GLYPH_INK, alpha }); }
  return graphic;
}

const fixed = (value: number) => Number(value.toFixed(3));
/** SVG path data in unit space, for the same primitives the map draws. */
export const primitivePath = (primitive: GlyphPrimitive): string => {
  switch (primitive.kind) {
    case 'line': return `M${fixed(primitive.x1)} ${fixed(primitive.y1)}L${fixed(primitive.x2)} ${fixed(primitive.y2)}`;
    case 'polyline': {
      const points = primitive.points, parts = [`M${fixed(points[0])} ${fixed(points[1])}`];
      for (let i = 2; i < points.length; i += 2) { parts.push(`L${fixed(points[i])} ${fixed(points[i + 1])}`); }
      return parts.join('') + (primitive.closed ? 'Z' : '');
    }
    case 'circle': {
      const { x, y, r } = primitive;
      return `M${fixed(x - r)} ${fixed(y)}a${fixed(r)} ${fixed(r)} 0 1 0 ${fixed(r * 2)} 0a${fixed(r)} ${fixed(r)} 0 1 0 ${fixed(-r * 2)} 0Z`;
    }
    case 'rect': {
      const { x, y, w, h } = primitive;
      return `M${fixed(x)} ${fixed(y)}h${fixed(w)}v${fixed(h)}h${fixed(-w)}Z`;
    }
    case 'roundRect': {
      const { x, y, w, h } = primitive, r = Math.min(primitive.r, w / 2, h / 2), a = `A${fixed(r)} ${fixed(r)} 0 0 1`;
      return `M${fixed(x + r)} ${fixed(y)}H${fixed(x + w - r)}${a} ${fixed(x + w)} ${fixed(y + r)}V${fixed(y + h - r)}`
        + `${a} ${fixed(x + w - r)} ${fixed(y + h)}H${fixed(x + r)}${a} ${fixed(x)} ${fixed(y + h - r)}V${fixed(y + r)}${a} ${fixed(x + r)} ${fixed(y)}Z`;
    }
  }
};

export type GlyphSvgPaths = { body: string; strokes: string; fills: string; slash: string };
const svgCache = new Map<string, GlyphSvgPaths>();
export const glyphSvgPaths = (type: string): GlyphSvgPaths => {
  const glyph = nodeGlyph(type), key = GLYPHS[type] ? type : '';
  let paths = svgCache.get(key);
  if (!paths) {
    paths = { body: glyph.body.map(primitivePath).join(''), strokes: glyph.strokes.map(primitivePath).join(''),
      fills: glyph.fills.map(primitivePath).join(''), slash: 'M-.62 .62L.62 -.62' };
    svgCache.set(key, paths);
  }
  return paths;
};
