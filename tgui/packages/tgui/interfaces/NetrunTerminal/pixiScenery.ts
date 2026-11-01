import type { Container, Graphics } from 'pixi.js';

import { GRAPH_TILE } from './graphLayout';
import { boxesIntersect, GraphBase, GraphBox, markerColor, physicalPoint, segmentBox } from './graphPresentation';
import type { GraphScene, PlacedNode } from './graphScene';
import {
  BODY_ALPHA, BODY_STROKE, GLYPH_INK, GLYPH_MIN_ZOOM, GLYPH_STROKE, glyphRadius,
  traceBody, traceGlyphFills, traceGlyphStrokes, traceOfflineSlash,
} from './nodeGlyphs';
import { destroyDisplay, edgeAlpha, edgeColor, edgeWidth, pixiColor, PixiLibrary, segmentPath, strokeLod } from './pixiPrimitives';
import type { NetEdge } from './types';

type Stroke = { from: { px: number; py: number }; to: { px: number; py: number }; offline?: boolean };
type ZoneRect = { x: number; y: number; width: number };
type Device = { node: PlacedNode; border: number };
type Batch = { key: string; nodes: Device[]; glyphs: PlacedNode[]; strokes: Stroke[]; zones: ZoneRect[];
  color: number; alpha: number; width: number; bounds: GraphBox; signature: string[] };
type Part = { bucket: string; key: string; color: number; alpha: number; width: number;
  bounds: GraphBox; signature: string; device?: Device; glyph?: PlacedNode; stroke?: Stroke; zone?: ZoneRect };
type NodeInput = { node: PlacedNode; fill: number; border: number; parts: Part[] };
type EdgeInput = { edge: NetEdge; fromX: number; fromY: number; toX: number; toY: number; part: Part };
type RetainedBatch = { graphic: Graphics; signature: string; bounds: GraphBox };
const CELL = GRAPH_TILE * 8;
/** Cables and tethers keep a readable on-screen width through quantized zoom levels. */
const LINE_LAYERS = new Set([1, 2]);
const GLYPH_LAYER = 4;
const bucketAt = (kind: string, x: number, y: number) => `${kind}:${Math.floor(x / CELL)},${Math.floor(y / CELL)}`;
const EMPTY_BOUNDS = (): GraphBox => ({ left: Infinity, top: Infinity, right: -Infinity, bottom: -Infinity });
const include = (box: GraphBox, next: GraphBox) => {
  box.left = Math.min(box.left, next.left); box.right = Math.max(box.right, next.right);
  box.top = Math.min(box.top, next.top); box.bottom = Math.max(box.bottom, next.bottom);
};

/** World-coordinate Graphics batches survive camera movement and unrelated live updates. */
export class PixiScenery {
  readonly world: Container;
  private readonly layers: Container[];
  private readonly records = new Map<string, RetainedBatch>();
  private scene: GraphScene | null = null;
  private base: GraphBase | null = null;
  private readonly prepared = new Map<string, { batch: Batch; signature: string }>();
  private readonly waiting = new Set<string>();
  private readonly buckets = new Map<string, Map<string, Part>>();
  private readonly bucketKeys = new Map<string, string[]>();
  private readonly suppressed = new Set<string>();
  private nodeInputs = new Map<string, NodeInput>();
  private edgeInputs = new Map<string, EdgeInput>();
  private zoneParts: Part[] = [];
  private builtZones: GraphBase['apcZones'];
  private viewport: GraphBox | null = null;
  private lod = 1;
  private pending: Generator<void, void, unknown> | null = null;
  constructor(private readonly pixi: PixiLibrary) {
    this.world = new pixi.Container();
    this.world.label = 'netrun-scenery';
    this.layers = ['zones', 'cables', 'anchors', 'devices', 'glyphs'].map((name) => {
      const layer = new pixi.Container(); layer.label = name; this.world.addChild(layer); return layer;
    });
  }

  queue(scene: GraphScene, base: GraphBase, force = false) {
    if (!force && this.scene === scene && this.base?.gateways === base.gateways
      && this.base?.apcZones === base.apcZones && this.base?.showEndpointLinks === base.showEndpointLinks) { return false; }
    this.scene = scene; this.base = base;
    this.pending = this.build(scene, base);
    return true;
  }

  /** Never display a retained chunk containing a node or link no longer disclosed. */
  suppressUndisclosed(scene: GraphScene) {
    const edges = new Set(scene.edges.map((edge) => edge.id));
    const suppress = (bucket: string) => {
      this.suppressed.add(bucket);
      for (const key of this.bucketKeys.get(bucket) || []) {
        const retained = this.records.get(key);
        if (retained) { retained.graphic.visible = false; }
        this.waiting.delete(key);
      }
    };
    for (const [address, input] of this.nodeInputs) {
      if (!scene.byAddress.has(address)) { for (const part of input.parts) { suppress(part.bucket); } }
    }
    for (const [id, input] of this.edgeInputs) { if (!edges.has(id)) { suppress(input.part.bucket); } }
  }

  /** Build descriptors in bounded slices, then upload only newly visible GPU chunks. */
  advance(budgetMs = 4) {
    const began = performance.now(); let work = 0;
    while (this.pending && (work === 0 || performance.now() - began < budgetMs) && work < 24) {
      if (this.pending.next().done) { this.pending = null; }
      work++;
    }
    while (!this.pending && this.waiting.size && (work === 0 || performance.now() - began < budgetMs) && work < 24) {
      const key = this.waiting.values().next().value as string;
      this.waiting.delete(key);
      const prepared = this.prepared.get(key);
      if (prepared && (!this.viewport || boxesIntersect(prepared.batch.bounds, this.viewport))) {
        this.paint(prepared.batch, this.effectiveSignature(prepared.batch.key, prepared.signature));
      }
      work++;
    }
    return !!this.pending || this.waiting.size > 0;
  }

  private nodeInput(node: PlacedNode, base: GraphBase): NodeInput {
    const previous = this.nodeInputs.get(node.address);
    const fill = pixiColor(markerColor(node), 0x678698);
    const border = pixiColor(base.gateways.get(node.network)?.color, 0x527287);
    const old = previous?.node;
    if (previous && previous.fill === fill && previous.border === border && old.type === node.type
      && old.px === node.px && old.py === node.py && old.anchorX === node.anchorX && old.anchorY === node.anchorY) { return previous; }
    const anchor = physicalPoint(node), parts: Part[] = [];
    if (anchor.px !== node.px || anchor.py !== node.py) {
      parts.push({ bucket: bucketAt('2-anchor', node.px, node.py), key: node.address,
        color: 0x75a3b4, alpha: .24, width: 1, stroke: { from: anchor, to: node },
        signature: `${anchor.px},${anchor.py},${node.px},${node.py}`, bounds: segmentBox(anchor, node) });
    }
    const reach = glyphRadius(node.type) + 2;
    const bounds = { left: node.px - reach, right: node.px + reach, top: node.py - reach, bottom: node.py + reach };
    parts.push({ bucket: bucketAt('3-node', node.px, node.py), key: node.address,
      color: fill, alpha: BODY_ALPHA, width: BODY_STROKE, device: { node, border },
      signature: `${node.address}:${node.px},${node.py}:${node.type}:${border}`, bounds });
    // Pictograms live in their own layer: an overview hides them without retessellation.
    parts.push({ bucket: bucketAt('4-glyph', node.px, node.py), key: node.address,
      color: GLYPH_INK, alpha: .9, width: GLYPH_STROKE, glyph: node,
      signature: `${node.address}:${node.px},${node.py}:${node.type}:${node.online}`, bounds });
    return { node, fill, border, parts };
  }

  private edgeInput(edge: NetEdge, scene: GraphScene, base: GraphBase): EdgeInput | null {
    if (base.showEndpointLinks === false && edge.kind === 'endpoint') { return null; }
    const a = scene.byAddress.get(edge.from), b = scene.byAddress.get(edge.to);
    if (!a || !b || a.dynamic || b.dynamic) { return null; }
    const from = physicalPoint(a), to = physicalPoint(b), previous = this.edgeInputs.get(edge.id);
    if (previous && previous.edge.kind === edge.kind && previous.edge.online === edge.online
      && previous.fromX === from.px && previous.fromY === from.py && previous.toX === to.px && previous.toY === to.py) { return previous; }
    const part: Part = { bucket: bucketAt('1-edge', from.px, from.py), key: edge.id,
      color: edgeColor(edge.kind, edge.online !== false), alpha: edgeAlpha(edge.kind, edge.online !== false),
      width: edgeWidth(edge.kind), stroke: { from, to, offline: edge.online === false },
      signature: `${edge.id}:${from.px},${from.py},${to.px},${to.py}`, bounds: segmentBox(from, to) };
    return { edge, fromX: from.px, fromY: from.py, toX: to.px, toY: to.py, part };
  }

  private* build(scene: GraphScene, base: GraphBase): Generator<void, void, unknown> {
    let work = 0;
    // Stage changes separately: a newer snapshot can cancel this generator
    // without partially mutating the last committed map.
    const changed = new Map<string, Map<string, Part>>();
    const edit = (part: Part, remove = false) => {
      let bucket = changed.get(part.bucket);
      if (!bucket) { bucket = new Map(this.buckets.get(part.bucket)); changed.set(part.bucket, bucket); }
      if (remove) { bucket.delete(part.key); } else { bucket.set(part.key, part); }
    };
    let zones = this.zoneParts;
    if (base.apcZones !== this.builtZones) {
      for (const part of zones) { edit(part, true); }
      zones = [];
      for (const zone of base.apcZones || []) {
        for (const [index, run] of zone.runs.entries()) {
          const x = (run.x - .5) * GRAPH_TILE, y = -(run.y + .5) * GRAPH_TILE, width = run.width * GRAPH_TILE;
          const part: Part = { bucket: bucketAt('0-zone', x, y), key: `${zone.address}:${index}`,
            color: 0x4095bc, alpha: .16, width: 1, zone: { x, y, width }, signature: `${x},${y},${width}`,
            bounds: { left: x, right: x + width, top: y, bottom: y + GRAPH_TILE } };
          zones.push(part); edit(part);
          if (++work % 128 === 0) { yield; }
        }
      }
    }
    const nodes = new Map<string, NodeInput>();
    for (const node of scene.nodes) {
      if (node.dynamic) { continue; }
      const previous = this.nodeInputs.get(node.address), input = this.nodeInput(node, base);
      if (input !== previous) {
        for (const part of previous?.parts || []) { edit(part, true); }
        for (const part of input.parts) { edit(part); }
      }
      nodes.set(node.address, input);
      if (++work % 128 === 0) { yield; }
    }
    for (const [address, input] of this.nodeInputs) {
      if (!nodes.has(address)) { for (const part of input.parts) { edit(part, true); } }
    }
    const edges = new Map<string, EdgeInput>();
    for (const edge of scene.edges) {
      const previous = this.edgeInputs.get(edge.id), input = this.edgeInput(edge, scene, base);
      if (!input) { continue; }
      if (input !== previous) {
        if (previous) { edit(previous.part, true); }
        edit(input.part);
      }
      edges.set(edge.id, input);
      if (++work % 128 === 0) { yield; }
    }
    for (const [id, input] of this.edgeInputs) { if (!edges.has(id)) { edit(input.part, true); } }
    // Only changed spatial buckets need descriptors/signatures. Unrelated
    // devices, area runs and cables retain both CPU data and GPU geometry.
    const prepared = new Map<string, Map<string, Batch>>();
    for (const [bucket, parts] of changed) {
      const batches = new Map<string, Batch>(), tails = new Map<string, Batch>();
      for (const part of parts.values()) {
        const prefix = `${bucket}:${part.color}:${part.alpha}:${part.width}`;
        let item = tails.get(prefix);
        if (!item || item.nodes.length + item.strokes.length + item.zones.length >= 128) {
          const key = `${prefix}:${item ? Number(item.key.slice(item.key.lastIndexOf(':') + 1)) + 1 : 0}`;
          item = { key, nodes: [], glyphs: [], strokes: [], zones: [], color: part.color, alpha: part.alpha,
            width: part.width, bounds: EMPTY_BOUNDS(), signature: [] };
          batches.set(key, item); tails.set(prefix, item);
        }
        if (part.device) { item.nodes.push(part.device); }
        if (part.glyph) { item.glyphs.push(part.glyph); }
        if (part.stroke) { item.strokes.push(part.stroke); }
        if (part.zone) { item.zones.push(part.zone); }
        item.signature.push(part.signature); include(item.bounds, part.bounds);
        if (++work % 128 === 0) { yield; }
      }
      prepared.set(bucket, batches);
    }
    // Commit atomically, including removals and moves across spatial buckets.
    this.nodeInputs = nodes; this.edgeInputs = edges; this.zoneParts = zones; this.builtZones = base.apcZones;
    for (const [bucket, batches] of prepared) {
      this.suppressed.delete(bucket);
      for (const key of this.bucketKeys.get(bucket) || []) {
        this.prepared.delete(key); this.waiting.delete(key);
        if (!batches.has(key)) {
          const retained = this.records.get(key);
          if (retained) { destroyDisplay(retained.graphic); this.records.delete(key); }
        }
      }
      this.bucketKeys.set(bucket, [...batches.keys()]);
      const parts = changed.get(bucket);
      if (parts.size) { this.buckets.set(bucket, parts); }
      else { this.buckets.delete(bucket); this.bucketKeys.delete(bucket); }
      for (const [key, data] of batches) {
        this.prepared.set(key, { batch: data, signature: `${data.width}:${data.signature.join('|')}` });
      }
    }
    this.enqueueVisible();
  }

  /** Line batches also depend on the quantized zoom level; everything else on its geometry only. */
  private effectiveSignature(key: string, signature: string) {
    return LINE_LAYERS.has(Number(key[0])) ? `${signature}@${this.lod}` : signature;
  }

  private enqueueVisible() {
    for (const [key, { batch, signature }] of this.prepared) {
      const visible = !this.suppressed.has(batch.key.slice(0, batch.key.indexOf(':', batch.key.indexOf(':') + 1)))
        && (!this.viewport || boxesIntersect(batch.bounds, this.viewport));
      const retained = this.records.get(key), effective = this.effectiveSignature(key, signature);
      // A cable waiting for its new width keeps showing the old one rather than blinking out.
      const current = retained && (retained.signature === effective
        || (LINE_LAYERS.has(Number(key[0])) && retained.signature.startsWith(`${signature}@`)));
      if (retained) { retained.graphic.visible = visible && !!current; }
      if (visible && (!retained || retained.signature !== effective)) { this.waiting.add(key); }
      else { this.waiting.delete(key); }
    }
  }

  private paint(data: Batch, signature: string) {
    let retained = this.records.get(data.key);
    if (!retained) {
      const graphic = new this.pixi.Graphics(); graphic.label = data.key;
      this.layers[Number(data.key[0])].addChild(graphic);
      retained = { graphic, signature: '', bounds: data.bounds };
      this.records.set(data.key, retained);
    }
    retained.bounds = data.bounds;
    retained.graphic.visible = true;
    if (retained.signature === signature) { return; }
    retained.signature = signature;
    const graphic = retained.graphic;
    graphic.clear();
    for (const rect of data.zones) { graphic.rect(rect.x, rect.y, rect.width, GRAPH_TILE); }
    if (data.zones.length) { graphic.fill({ color: data.color, alpha: data.alpha }); }
    const scale = LINE_LAYERS.has(Number(data.key[0])) ? this.lod : 1;
    for (const stroke of data.strokes) { segmentPath(graphic, stroke.from, stroke.to, stroke.offline ? 8 * scale : 0); }
    if (data.strokes.length) { graphic.stroke({ color: data.color, width: data.width * scale, alpha: data.alpha }); }
    // Device silhouettes: filled with the access colour, outlined with the LAN colour.
    for (const { node, border } of data.nodes) {
      traceBody(graphic, node.type, node.px, node.py);
      graphic.fill({ color: data.color, alpha: data.alpha }).stroke({ color: border, width: data.width });
    }
    if (!data.glyphs.length) { return; }
    let stroked = false, filled = false;
    for (const node of data.glyphs) {
      stroked = traceGlyphStrokes(graphic, node.type, node.px, node.py) || stroked;
      if (!node.online) { traceOfflineSlash(graphic, node.type, node.px, node.py); stroked = true; }
    }
    if (stroked) { graphic.stroke({ color: data.color, width: data.width, alpha: data.alpha }); }
    for (const node of data.glyphs) { filled = traceGlyphFills(graphic, node.type, node.px, node.py) || filled; }
    if (filled) { graphic.fill({ color: data.color, alpha: data.alpha }); }
  }

  /** Panning changes visibility; zoom toggles pictograms and, across a level, cable widths. */
  setViewport(bounds: GraphBox, zoom: number) {
    const lod = strokeLod(zoom), lodChanged = lod !== this.lod;
    this.lod = lod;
    this.layers[GLYPH_LAYER].visible = zoom >= GLYPH_MIN_ZOOM;
    if (!lodChanged && this.viewport && this.viewport.left === bounds.left && this.viewport.right === bounds.right
      && this.viewport.top === bounds.top && this.viewport.bottom === bounds.bottom) { return; }
    this.viewport = bounds;
    this.enqueueVisible();
  }

  destroy() {
    this.pending = null; this.waiting.clear(); this.prepared.clear(); this.records.clear(); this.buckets.clear(); this.bucketKeys.clear(); this.suppressed.clear();
    this.nodeInputs.clear(); this.edgeInputs.clear(); this.zoneParts = []; this.builtZones = undefined;
    this.scene = null; this.base = null; destroyDisplay(this.world);
  }
}
