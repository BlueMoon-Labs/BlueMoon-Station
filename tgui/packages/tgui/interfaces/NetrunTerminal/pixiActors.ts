import type { Container, Graphics, Text } from 'pixi.js';

import { factionColor } from './actorTaxonomy';
import { GRAPH_TILE } from './graphLayout';
import { boxesIntersect, GraphBox, GraphOverlay, markerColor, markerScale, physicalPoint, segmentBox } from './graphPresentation';
import type { GraphScene, PlacedNode } from './graphScene';
import type { GraphPoint } from './mapLayout';
import { drawBody, drawGlyph, GLYPH_MIN_ZOOM, glyphRadius } from './nodeGlyphs';
import { destroyDisplay, edgeAlpha, edgeColor, edgeWidth, pixiColor, PixiLibrary, segmentPath, strokeLod } from './pixiPrimitives';
import { drawBotGlyph, drawProcessGlyph, drawTintedProcessGlyph } from './processGlyphs';
import { NetEdge, NetEvent, PACKET_COLORS } from './types';

type Actor = { group: Container; body: Graphics; marks: Graphics; labels: Text[]; node: PlacedNode;
  signature: string; px: number; py: number; fromX: number; fromY: number; movedAt: number; appearedAt: number };
type Link = { graphic: Graphics; signature: string; bounds: GraphBox };
type Segment = { from: GraphPoint; to: GraphPoint; length: number; jump?: boolean; fromAddress?: string; toAddress?: string; hop?: number; hops?: number };
type Route = { graphic: Graphics; signature: string; segments: Segment[]; until: number; began: number; tint: number };
type Traffic = { born: number; point: GraphPoint; tint: number; segments: Segment[] };
type Pulse = { born: number; point: GraphPoint; tint: number };
/** One packet owns one clock and route; a terminal receipt settles its existing flight. */
type Flight = { key: string; phase: 'send' | 'done' | 'fail'; born: number; duration: number;
  travelStart: number; travelDuration: number; travelFrom: number; drawn: boolean;
  until: number; segments: Segment[]; end: GraphPoint | null; endAddress: string | null; tint: number; own: boolean };
const NO_BOX: GraphBox = { left: -Infinity, right: Infinity, top: -Infinity, bottom: Infinity };
const ARRIVAL_MS = 900;
const OUTCOME_MS = 1200;
const MAX_FLIGHTS = 48;
const RECEIPT_TRAVEL_MS = 650;
const DONE_TINT = 0x5bdab1;
const FAIL_TINT = pixiColor(PACKET_COLORS.fail, 0xff6470);
const sameOverlayData = (a: GraphOverlay | null, b: GraphOverlay) => a
  && a.gateways === b.gateways && a.entityHost === b.entityHost && a.jacked === b.jacked
  && a.selectedRoute === b.selectedRoute && a.waypointRoute === b.waypointRoute
  && a.pingRoute === b.pingRoute && a.pingId === b.pingId && a.pingExpiresAt === b.pingExpiresAt && a.events === b.events
  && a.showEndpointLinks === b.showEndpointLinks;
const sameLocalState = (a: GraphOverlay, b: GraphOverlay) => a.selected === b.selected
  && a.hovered === b.hovered && a.selectionPending === b.selectionPending;
const processSummaryKey = (node: PlacedNode) => node.processes?.slice(0, 6).map((process) =>
  `${process.kind}/${process.bot_kind}/${process.ice_kind}/${process.faction}/${process.faction_color}/${process.count}`).join('|') || '';
const needsActor = (node: PlacedNode, overlay: GraphOverlay) => node.dynamic || node.entities || node.ice || node.active || node.processes?.length
  || node.bots || node.police || node.fortress
  || node.type === 'gateway' || node.type === 'relay' || node.address === overlay.selected
  || node.address === overlay.hovered || node.address === overlay.entityHost || node.address === overlay.jacked;
const pointOn = (segments: Segment[], progress: number) => {
  let remaining = segments.reduce((sum, segment) => sum + segment.length, 0) * progress;
  for (const segment of segments) {
    if (remaining <= segment.length) {
      const t = segment.length ? remaining / segment.length : 0;
      return { px: segment.from.px + (segment.to.px - segment.from.px) * t, py: segment.from.py + (segment.to.py - segment.from.py) * t };
    }
    remaining -= segment.length;
  }
  return segments[segments.length - 1]?.to;
};
const packetTint = (event: NetEvent) => pixiColor(PACKET_COLORS[event.packet ?? ''], pixiColor(PACKET_COLORS.command, 0xffc26b));
/** Keep undisclosed route holes as holes instead of compressing them into a shortcut. */
const packetPoint = (segments: Segment[], progress: number) => {
  if (!segments.length) { return null; }
  if (segments.length === segments[0].hops) { return pointOn(segments, progress); }
  const position = progress * (segments[0].hops || segments.length);
  const segment = segments.find((part) => position >= part.hop && position <= part.hop + 1);
  if (!segment) { return null; }
  const t = position - segment.hop;
  return { px: segment.from.px + (segment.to.px - segment.from.px) * t, py: segment.from.py + (segment.to.py - segment.from.py) * t };
};

/** Keyed live objects: moving one endpoint never retessellates the stationary map. */
export class PixiActors {
  readonly world: Container;
  positionsChanged = false;
  private readonly linkLayer: Container;
  private readonly nodeLayer: Container;
  private readonly selectedLinks: Graphics;
  private readonly effects: Graphics;
  private readonly routes: Route[];
  private readonly nodes = new Map<string, Actor>();
  private readonly links = new Map<string, Link>();
  private scene: GraphScene | null = null;
  private overlay: GraphOverlay | null = null;
  private dynamicEdges: NetEdge[] | null = null;
  private adjacency = new Map<string, Set<string>>();
  private selectedSignature = '';
  private traffic: Traffic[] = [];
  private pulses: Pulse[] = [];
  private flights = new Map<string, Flight>();
  private drawnPackets = new Set<string>();
  private zoom = 1;
  private scale = 1;
  private lod = 1;
  private detailed = true;
  private bounds = NO_BOX;
  private reducedMotion = false;
  private moving: PlacedNode[] = [];
  private blocked = new Set<string>();
  private pingToken: number | string[] | null = null;

  constructor(private readonly pixi: PixiLibrary) {
    this.world = new pixi.Container(); this.world.label = 'netrun-live';
    this.linkLayer = new pixi.Container(); this.linkLayer.label = 'moving-cables';
    this.nodeLayer = new pixi.Container(); this.nodeLayer.label = 'processes-and-devices';
    this.selectedLinks = new pixi.Graphics();
    this.effects = new pixi.Graphics(); this.effects.label = 'traffic-and-ping';
    this.routes = [0x50e8c0, 0xe879b8, 0xffc56b].map((tint, index) => {
      const graphic = new pixi.Graphics(); graphic.label = ['selected-route', 'waypoint-route', 'ping-route'][index];
      return { graphic, signature: '', segments: [], began: 0, until: 0, tint };
    });
    this.world.addChild(this.linkLayer, this.selectedLinks, ...this.routes.map((route) => route.graphic), this.nodeLayer, this.effects);
  }

  private updateMoving(scene: GraphScene, previousScene: GraphScene) {
    const moving = new Map(this.moving.map((node) => [node.address, node]));
    for (const node of previousScene === scene ? [] : scene.changedNodes) {
      if (node.dynamic) { moving.set(node.address, node); } else { moving.delete(node.address); }
    }
    this.moving = [...moving.values()];
  }

  update(scene: GraphScene, overlay: GraphOverlay, dynamicEdges: NetEdge[], adjacency: Map<string, Set<string>>, now = performance.now()) {
    const before = this.overlay;
    const previousScene = this.scene;
    const localOnly = this.scene === scene && this.dynamicEdges === dynamicEdges && this.adjacency === adjacency && sameOverlayData(before, overlay);
    if (localOnly && sameLocalState(before, overlay)) { return false; }
    const incremental = !!before && !!this.scene && this.scene.edges === scene.edges
      && (this.scene === scene || (scene.previousIdentity === this.scene.identity && scene.changedNodes !== null));
    const affected = incremental ? [...new Set([
      ...(this.scene === scene ? [] : scene.changedNodes.map((node) => node.address)),
      before.selected, before.hovered, before.entityHost, before.jacked,
      overlay.selected, overlay.hovered, overlay.entityHost, overlay.jacked,
    ])].map((address) => scene.byAddress.get(address)).filter(Boolean) : scene.nodes;
    this.scene = scene; this.overlay = overlay; this.dynamicEdges = dynamicEdges; this.adjacency = adjacency;
    // Short, event-triggered focus animation: never leave the GPU ticker running.
    if (before?.selected !== overlay.selected && overlay.selected && !this.reducedMotion) {
      const node = scene.byAddress.get(overlay.selected);
      if (node) { this.pulses.push({ born: now, point: node, tint: 0x6fe9dc }); }
    }
    if (!localOnly) {
      if (incremental) {
        this.updateMoving(scene, previousScene);
      } else {
        this.moving = scene.nodes.filter((node) => node.dynamic);
        this.blocked = new Set([...scene.edges, ...dynamicEdges].filter((edge) => edge.online === false)
          .map((edge) => [edge.from, edge.to].sort().join('|')));
      }
    }
    const alive = new Set<string>();
    for (const node of affected) {
      if (!needsActor(node, overlay)) {
        const removed = this.nodes.get(node.address);
        if (removed && incremental) { destroyDisplay(removed.group); this.nodes.delete(node.address); }
        continue;
      }
      alive.add(node.address);
      let actor = this.nodes.get(node.address);
      if (actor && node.ice && node.ice > (actor.node.ice || 0) && !this.reducedMotion) {
        this.pulses.push({ born: now, point: node, tint: 0xf37b93 });
      }
      if (!actor) {
        const group = new this.pixi.Container(); group.label = `device:${node.address}`;
        const body = new this.pixi.Graphics(), marks = new this.pixi.Graphics(); group.addChild(body, marks);
        actor = { group, body, marks, labels: [], node, signature: '', px: node.px, py: node.py,
          fromX: node.px, fromY: node.py, movedAt: -Infinity, appearedAt: now };
        this.nodes.set(node.address, actor); this.nodeLayer.addChild(group); group.position.set(node.px, node.py);
      } else if (node.px !== actor.node.px || node.py !== actor.node.py) {
        // Real teleports snap; normal carried-device steps ease briefly.
        const smooth = !this.reducedMotion && node.dynamic && Math.hypot(node.px - actor.px, node.py - actor.py) <= GRAPH_TILE * 4;
        actor.fromX = actor.px; actor.fromY = actor.py; actor.movedAt = smooth ? now : -Infinity;
        if (!smooth) { actor.px = node.px; actor.py = node.py; actor.group.position.set(node.px, node.py); }
      }
      actor.node = node; this.paintActor(actor);
    }
    if (!incremental) {
      for (const [address, actor] of this.nodes) { if (!alive.has(address)) { destroyDisplay(actor.group); this.nodes.delete(address); } }
    }
    const linkKeys = new Set<string>();
    for (const edge of dynamicEdges) {
      if (overlay.showEndpointLinks === false && edge.kind === 'endpoint') { continue; }
      const a = scene.byAddress.get(edge.from), b = scene.byAddress.get(edge.to);
      if (!a || !b) { continue; }
      linkKeys.add(edge.id);
      let retained = this.links.get(edge.id);
      if (!retained) {
        retained = { graphic: new this.pixi.Graphics(), signature: '', bounds: NO_BOX };
        retained.graphic.label = `edge:${edge.id}`; this.links.set(edge.id, retained); this.linkLayer.addChild(retained.graphic);
      }
      this.paintLink(retained, edge, physicalPoint(a), physicalPoint(b));
    }
    for (const [id, link] of this.links) { if (!linkKeys.has(id)) { destroyDisplay(link.graphic); this.links.delete(id); } }
    this.paintPaths();
    this.paintRoute(overlay.selectedRoute, this.routes[0]); this.paintRoute(overlay.waypointRoute, this.routes[1]);
    this.paintPing(now);
    if (!localOnly) {
      this.traffic = overlay.events.filter((event) => event.kind !== 'packet' && event.age < 4).flatMap((event) => {
        const point = scene.byAddress.get(event.to) || scene.byAddress.get(event.from);
        const tint = event.kind === 'trace' ? 0xf56670 : event.kind === 'machine' ? 0x50e8c0 : event.kind === 'dns' ? 0x79adff : 0xffc26b;
        return point ? [{ born: now - Math.max(0, event.age) * 1000, point, tint,
          segments: event.route ? this.segments(event.route) : this.eventPath(event.from, event.to) }] : [];
      });
      this.syncFlights(overlay.events, now);
    }
    if (this.pulses.length > 24) { this.pulses.splice(0, this.pulses.length - 24); }
    this.setViewport(this.bounds, this.zoom); return true;
  }

  private paintLink(link: Link, edge: NetEdge, from: GraphPoint, to: GraphPoint) {
    const signature = `${from.px},${from.py}:${to.px},${to.py}:${edge.kind}:${edge.online}:${this.lod}`;
    link.bounds = segmentBox(from, to);
    if (link.signature === signature) { return; }
    link.signature = signature;
    link.graphic.clear();
    segmentPath(link.graphic, from, to, edge.online === false ? 8 * this.lod : 0);
    link.graphic.stroke({ color: edgeColor(edge.kind, edge.online !== false), width: edgeWidth(edge.kind) * this.lod,
      alpha: edgeAlpha(edge.kind, edge.online !== false) });
  }

  /** Bots, police and fortresses decorate the live node; bodies of static nodes stay in scenery. */
  private paintActor(actor: Actor) {
    const node = actor.node, overlay = this.overlay!;
    const selected = node.address === overlay.selected, hosted = node.address === overlay.entityHost;
    const jacked = node.address === overlay.jacked, hovered = node.address === overlay.hovered;
    const fill = pixiColor(markerColor(node), 0x678698), border = pixiColor(overlay.gateways.get(node.network)?.color, 0x82a9ba);
    const fortress = node.fortress;
    const fortressKey = fortress ? `${fortress.tier}/${fortress.walls}/${fortress.faction}/${fortress.faction_color}/${fortress.damaged}/${fortress.online}` : '';
    const signature = `${node.type}:${!!node.dynamic}:${node.online}:${fill}:${border}:${node.entities}:${node.ice}:${node.bots || 0}:${!!node.police}:${processSummaryKey(node)}:${fortressKey}:${node.active}:${selected}:${overlay.selectionPending}:${hosted}:${jacked}:${hovered}:${this.scale}:${this.detailed}`;
    if (actor.signature === signature) { return; }
    actor.signature = signature; actor.body.clear(); actor.marks.clear();
    // No LOD enlargement of ordinary device bodies. This scale is reserved
    // for LAN/ICE/entity contours (never the underlying node).
    if (node.dynamic) {
      drawBody(actor.body, node.type, 0, 0, fill, border, node.online);
      if (this.zoom >= GLYPH_MIN_ZOOM) { drawGlyph(actor.body, node.type, 0, 0); }
    }
    const radius = glyphRadius(node.type), marks = actor.marks;
    const scale = node.ice || node.entities || node.bots || node.police || node.processes?.length || fortress
      || node.type === 'gateway' || node.type === 'relay' ? this.scale : 1;
    if (fortress) { this.paintFortress(marks, fortress, (radius + 9) * scale, scale); }
    if (node.type === 'gateway' || node.type === 'relay') {
      marks.circle(0, 0, (radius + 5) * scale)
        .stroke({ color: border, width: Math.min(3, scale * 1.3), alpha: .64 });
    }
    if (selected || hosted || jacked || hovered) {
      marks.circle(0, 0, radius + (hovered && !selected ? 5 : 8)).stroke({ color: selected ? overlay.selectionPending ? 0xffd18a : 0xeafff5 : hosted ? 0xf8a3e6 : jacked ? 0x65b4d5 : 0x8ed1ea, width: selected ? 2.4 : 1.6, alpha: .95 });
      if (selected) { marks.circle(0, 0, radius + 12).stroke({ color: 0x70e6cd, width: 1.2, alpha: .3 }); }
    }
    if (node.ice) {
      marks.circle(0, 0, (radius + 10) * scale).stroke({ color: 0x101721, width: 4.4 * scale, alpha: .9 });
      marks.circle(0, 0, (radius + 10) * scale).stroke({ color: 0xff8996, width: 2 * scale, alpha: .95 });
    } else if (node.active && (this.detailed || selected || hovered)) {
      marks.circle(0, 0, (radius + 5) * scale).stroke({ color: 0xffc26b, width: 1.6 * scale, alpha: .65 });
    }
    this.paintProcessMarkers(actor, radius, scale);
  }

  /** All occupant geometry belongs to the retained live layer, including compatibility with count-only payloads. */
  private paintProcessMarkers(actor: Actor, radius: number, scale: number) {
    const node = actor.node, marks = actor.marks, processes = node.processes?.slice(0, 6);
    if (!processes?.length && node.ice) {
      drawProcessGlyph(marks, 'ice', -(radius + 8) * scale, -(radius + 7) * scale, (this.detailed ? 10 : 8) * scale);
    }
    if (!processes?.length && node.entities) {
      drawProcessGlyph(marks, 'entity', (radius + 9) * scale, -(radius + 7) * scale, (this.detailed ? 10 : 8) * scale);
    }
    if (!processes?.length && node.bots && !(node.police && node.bots === 1)) {
      drawProcessGlyph(marks, 'bots', (radius + 9) * scale, (radius + 9) * scale, (this.detailed ? 10 : 8) * scale);
    }
    if (!processes?.length && node.police) {
      drawProcessGlyph(marks, 'police', -(radius + 9) * scale, (radius + 9) * scale, (this.detailed ? 10 : 8) * scale);
    }
    const processBadges: { value: string; x: number; y: number }[] = [];
    for (let i = 0; i < (processes?.length || 0); i++) {
      const process = processes[i];
      const angle = -Math.PI / 4 + i * 2 * Math.PI / Math.max(4, processes.length);
      const orbit = (radius + 15) * scale, x = Math.cos(angle) * orbit, y = Math.sin(angle) * orbit;
      const tint = process.kind === 'ice' ? process.ice_kind === 'black' ? 0xdba0ff : 0xff8996
        : pixiColor(factionColor(process.faction, process.faction_color), 0x8ca9b8);
      const markerRadius = (this.detailed ? 10 : 8) * scale;
      if (process.kind === 'bot') { drawBotGlyph(marks, process.bot_kind, x, y, markerRadius, tint); }
      else { drawTintedProcessGlyph(marks, process.kind === 'ice' ? 'ice' : 'entity', x, y, markerRadius, tint); }
      if (process.count > 1) { processBadges.push({ value: String(process.count), x: x + markerRadius * .8, y: y + markerRadius }); }
    }
    const represented = processes?.reduce((count, process) => count + process.count, 0) || 0;
    const overflow = (node.entities || 0) + (node.bots || 0) + (node.ice || 0) - represented;
    if (processes?.length && overflow > 0) { processBadges.push({ value: `+${overflow}`, x: 0, y: (radius + 31) * scale }); }
    const badges = this.detailed ? processes?.length ? processBadges : [node.ice > 1 ? { value: String(node.ice), x: -(radius + 16) * scale, y: -(radius + 17) * scale } : null,
      node.entities > 1 ? { value: String(node.entities), x: (radius + 17) * scale, y: -(radius + 17) * scale } : null,
      node.bots > 1 ? { value: String(node.bots), x: (radius + 17) * scale, y: (radius + 19) * scale } : null].filter(Boolean) : [];
    for (let i = 0; i < badges.length; i++) {
      const badge = badges[i]; let label = actor.labels[i];
      if (!label) {
        label = new this.pixi.Text({ text: '', style: { fontFamily: 'monospace', fontSize: 10, fontWeight: 'bold', fill: 0xf3f8ff,
          stroke: { color: 0x07151f, width: 3 } } });
        label.anchor.set(.5); actor.group.addChild(label); actor.labels.push(label);
      }
      label.text = badge.value; label.position.set(badge.x, badge.y); label.scale.set(1 / this.zoom); label.visible = true;
    }
    for (let i = badges.length; i < actor.labels.length; i++) { actor.labels[i].visible = false; }
  }

  /** Crenellated ring in the faction colour: merlons for standing walls, a broken ring when damaged. */
  private paintFortress(marks: Graphics, fortress: NonNullable<PlacedNode['fortress']>, ring: number, scale: number) {
    const color = fortress.online ? pixiColor(factionColor(fortress.faction, fortress.faction_color), 0x72ddea) : 0x5d6b75;
    const steps = 24;
    for (let i = 0; i < steps; i++) {
      if (fortress.damaged && i % 3 === 2) { continue; }
      const a = i * 2 * Math.PI / steps, b = (i + 1) * 2 * Math.PI / steps;
      marks.moveTo(Math.cos(a) * ring, Math.sin(a) * ring).lineTo(Math.cos(b) * ring, Math.sin(b) * ring);
    }
    marks.stroke({ color, width: 2.4 * scale, alpha: fortress.online ? .9 : .5 });
    if (fortress.tier >= 3) {
      marks.circle(0, 0, ring + 4 * scale).stroke({ color, width: 1.2 * scale, alpha: .45 });
    }
    const merlons = Math.min(24, Math.max(0, fortress.walls) * 2), size = 4 * scale;
    for (let i = 0; i < merlons; i++) {
      const angle = -Math.PI / 2 + i * 2 * Math.PI / merlons;
      const x = Math.cos(angle) * ring, y = Math.sin(angle) * ring;
      marks.rect(x - size / 2, y - size / 2, size, size);
    }
    marks.fill({ color, alpha: fortress.walls ? .95 : .4 });
  }

  /** Map edges carry the hop between adjacent nodes; relay jumps between visible relays are drawn straight. */
  private segments(addresses: string[], allowJumps = false): Segment[] {
    const result: Segment[] = [];
    for (let i = 1; i < addresses.length; i++) {
      const a = this.scene!.byAddress.get(addresses[i - 1]), b = this.scene!.byAddress.get(addresses[i]);
      if (!a || !b || !a.online || !b.online || this.blocked.has([a.address, b.address].sort().join('|'))) { continue; }
      const adjacent = !!this.adjacency.get(a.address)?.has(b.address);
      if (!adjacent && !allowJumps) { continue; }
      const from = physicalPoint(a), to = physicalPoint(b);
      result.push({ from, to, length: Math.hypot(to.px - from.px, to.py - from.py), jump: !adjacent,
        fromAddress: a.address, toAddress: b.address, hop: i - 1, hops: addresses.length - 1 });
    }
    return result;
  }

  /** Dispatches are processed before outcomes, even when both arrive in one UI push. */
  private syncFlights(events: NetEvent[], now: number) {
    for (const event of [...events.filter((entry) => entry.phase !== 'done' && entry.phase !== 'fail'),
      ...events.filter((entry) => entry.phase === 'done' || entry.phase === 'fail')]) {
      if (event.kind !== 'packet' || !event.id) { continue; }
      const phase = event.phase === 'done' || event.phase === 'fail' ? event.phase : 'send';
      const key = event.id, previous = this.flights.get(key);
      if (previous && (previous.phase === phase || phase === 'send')) { continue; }
      if (!previous && phase === 'send' && this.drawnPackets.has(key)) { continue; }
      const born = now - Math.max(0, event.age) * 1000;
      const end = this.scene!.byAddress.get(event.to) || null;
      // An explicit route is authoritative, including redacted/missing hops.
      // Without route data only an actual direct edge is known; never invent a BFS route.
      const segments = event.route ? this.segments(event.route, true)
        : previous?.segments || this.segments([event.from, event.to]);
      if (!segments.length && !end) { continue; }
      const duration = phase === 'send' ? Math.max(1, (event.duration || 0) * 1000) : OUTCOME_MS;
      const remaining = phase === 'send' ? (event.remaining_ms ?? Math.max(0, duration - (now - born))) + ARRIVAL_MS
        : Math.max(0, OUTCOME_MS - (now - born));
      const until = now + Math.min(remaining, event.lifetime_ms ?? remaining);
      if (until <= now) { continue; }
      // A receipt can arrive before the browser rendered its dispatch. Give it
      // one bounded traversal of the disclosed path, within the server expiry.
      // An already drawn dispatch continues from its current position instead.
      const travelFrom = previous?.drawn && previous.phase === 'send'
        ? Math.min(1, Math.max(0, (now - previous.born) / previous.duration)) : this.drawnPackets.has(key) ? 1 : 0;
      const travelDuration = phase === 'send' ? duration : segments.length && travelFrom < 1
        ? Math.min(RECEIPT_TRAVEL_MS * (1 - travelFrom), Math.max(0, until - now - 250)) : 0;
      this.flights.set(key, { key, phase, born, duration, until, segments,
        travelStart: phase === 'send' ? born : now, travelDuration, travelFrom: phase === 'send' ? 0 : travelFrom, drawn: false,
        end: end ? physicalPoint(end) : null, endAddress: event.to,
        tint: phase === 'send' ? packetTint(event) : phase === 'done' ? DONE_TINT : FAIL_TINT, own: !!event.own });
    }
    // Revalidate retained coordinates against the currently disclosed map. ACL
    // revocation or local filtering must immediately remove old route fragments.
    for (const [key, flight] of this.flights) {
      flight.segments = flight.segments.flatMap((segment) => {
        const a = this.scene!.byAddress.get(segment.fromAddress), b = this.scene!.byAddress.get(segment.toAddress);
        return a && b ? [{ ...segment, from: physicalPoint(a), to: physicalPoint(b) }] : [];
      });
      const endpoint = this.scene!.byAddress.get(flight.endAddress);
      flight.end = endpoint ? physicalPoint(endpoint) : null;
      if (now >= flight.until || (!flight.segments.length && !flight.end)) { this.flights.delete(key); }
    }
    if (this.flights.size > MAX_FLIGHTS) {
      const excess = [...this.flights.values()].sort((a, b) => a.born - b.born).slice(0, this.flights.size - MAX_FLIGHTS);
      for (const flight of excess) { this.flights.delete(flight.key); }
    }
  }

  private paintPaths() {
    const selected = this.overlay!.selected && this.scene!.byAddress.get(this.overlay!.selected);
    const edges = selected ? [...(this.adjacency.get(selected.address) || [])].flatMap((address) => {
      const target = this.scene!.byAddress.get(address);
      const infrastructure = selected.type === 'apc' || selected.type === 'relay' || selected.type === 'gateway';
      const quiet = this.overlay!.showEndpointLinks === false && infrastructure
        && target && target.type !== 'apc' && target.type !== 'relay' && target.type !== 'gateway';
      return target && !quiet ? [{ from: physicalPoint(selected), to: physicalPoint(target) }] : [];
    }) : [];
    const anchors = this.moving.flatMap((node) => {
      const point = physicalPoint(node); return point.px === node.px && point.py === node.py ? [] : [{ from: point, to: node }];
    });
    const signature = `${this.detailed}:${this.lod}:${edges.length}:` + [...edges, ...anchors].map(({ from, to }) => `${from.px},${from.py}:${to.px},${to.py}`).join('|');
    if (signature === this.selectedSignature) { return; }
    this.selectedSignature = signature; this.selectedLinks.clear();
    if (this.detailed) {
      for (const { from, to } of edges) { segmentPath(this.selectedLinks, from, to); }
      this.selectedLinks.stroke({ color: 0x9ad0e0, width: (edges.length > 24 ? 1.2 : 2.8) * this.lod, alpha: edges.length > 24 ? .2 : .75 });
    }
    for (const { from, to } of anchors) { segmentPath(this.selectedLinks, from, to); }
    if (anchors.length) { this.selectedLinks.stroke({ color: 0x75a3b4, width: 1.4 * this.lod, alpha: .5 }); }
  }

  private paintRoute(addresses: string[], route: Route, ping = false) {
    const segments = this.segments(addresses), path = segments.map(({ from, to }) => `${from.px},${from.py}:${to.px},${to.py}`).join('|');
    const signature = `${this.lod}|${path}`;
    if (route.signature === signature) { return; }
    route.signature = signature; route.segments = segments; route.graphic.clear();
    // Muted continuous path beneath bright dashes improves route legibility
    // at fractional zoom without shaders or multiple display objects.
    for (const segment of segments) { segmentPath(route.graphic, segment.from, segment.to); }
    if (segments.length) { route.graphic.stroke({ color: route.tint, width: 6 * this.lod, alpha: .2 }); }
    for (const segment of segments) { segmentPath(route.graphic, segment.from, segment.to, (ping ? 6 : 12) * this.lod, 7 * this.lod); }
    if (segments.length) { route.graphic.stroke({ color: route.tint, width: 3.2 * this.lod, alpha: .9 }); }
  }

  private clearPing() {
    const route = this.routes[2];
    if (route.signature || route.segments.length) { route.graphic.clear(); }
    route.signature = ''; route.segments = [];
  }

  private paintPing(now: number) {
    const overlay = this.overlay!, route = this.routes[2];
    const token = overlay.pingId ?? overlay.pingRoute;
    if (this.pingToken !== token) {
      this.pingToken = token; route.began = now;
      route.until = overlay.pingExpiresAt ?? now + 1800;
    }
    if (!overlay.pingRoute.length || now >= route.until) { this.clearPing(); return; }
    this.paintRoute(overlay.pingRoute, route, true);
  }

  private eventPath(from: string, to: string): Segment[] {
    if (!from || !to || from === to || !this.scene!.byAddress.has(from) || !this.scene!.byAddress.has(to)) { return []; }
    const previous = new Map<string, string | null>([[from, null]]), queue = [from];
    for (let i = 0; i < queue.length && !previous.has(to); i++) {
      for (const neighbor of this.adjacency.get(queue[i]) || []) {
        if (!previous.has(neighbor) && this.scene!.byAddress.get(neighbor)?.online
          && !this.blocked.has([queue[i], neighbor].sort().join('|'))) { previous.set(neighbor, queue[i]); queue.push(neighbor); }
      }
    }
    if (!previous.has(to)) { return []; }
    const path = [to]; for (let cursor = previous.get(to); cursor; cursor = previous.get(cursor)) { path.push(cursor); }
    return this.segments(path.reverse());
  }

  setViewport(bounds: GraphBox, zoom: number) {
    const nextScale = markerScale(zoom), detailed = zoom >= .6, lod = strokeLod(zoom);
    const glyphsChanged = (this.zoom >= GLYPH_MIN_ZOOM) !== (zoom >= GLYPH_MIN_ZOOM);
    const geometryChanged = this.scale !== nextScale || this.detailed !== detailed || this.lod !== lod || glyphsChanged;
    const zoomChanged = this.zoom !== zoom;
    this.bounds = bounds; this.zoom = zoom; this.scale = nextScale; this.detailed = detailed; this.lod = lod;
    for (const actor of this.nodes.values()) {
      if (geometryChanged && this.overlay) { actor.signature = ''; this.paintActor(actor); }
      actor.group.visible = actor.px >= bounds.left - 48 * nextScale && actor.px <= bounds.right + 48 * nextScale && actor.py >= bounds.top - 48 * nextScale && actor.py <= bounds.bottom + 48 * nextScale;
      if (zoomChanged) { for (const label of actor.labels) { label.scale.set(1 / zoom); } }
    }
    if (geometryChanged && this.scene && this.dynamicEdges) {
      for (const edge of this.dynamicEdges) {
        const a = this.scene.byAddress.get(edge.from), b = this.scene.byAddress.get(edge.to), retained = this.links.get(edge.id);
        if (a && b && retained) { this.paintLink(retained, edge, physicalPoint(this.pointFor(a)), physicalPoint(this.pointFor(b))); }
      }
    }
    for (const link of this.links.values()) { link.graphic.visible = boxesIntersect(link.bounds, bounds); }
    if (geometryChanged && this.overlay) {
      this.paintPaths(); this.paintRoute(this.overlay.selectedRoute, this.routes[0]);
      this.paintRoute(this.overlay.waypointRoute, this.routes[1]); this.paintPing(performance.now());
    }
  }

  setReducedMotion(reduced: boolean) { this.reducedMotion = reduced; }

  /** Static pings and reduced-motion flights still need one closing frame, without a RAF loop. */
  get nextWake() {
    let wake: number | null = this.routes[2].segments.length ? this.routes[2].until : null;
    for (const flight of this.flights.values()) {
      const end = flight.until;
      wake = wake === null ? end : Math.min(wake, end);
    }
    return wake;
  }

  private drawFlight(flight: Flight, now: number) {
    if (now >= flight.until) { return false; }
    flight.drawn = true;
    this.drawnPackets.add(flight.key);
    if (this.drawnPackets.size > MAX_FLIGHTS * 3) { this.drawnPackets.delete(this.drawnPackets.values().next().value); }
    const travelling = now < flight.travelStart + flight.travelDuration;
    const elapsed = flight.phase === 'send' ? now - flight.born
      : now - (flight.travelDuration ? flight.travelStart + flight.travelDuration : flight.born);
    // The whole actual dispatch route is visible before delivery. A very fast
    // packet first observed with its outcome still leaves this completed path.
    const fade = flight.phase === 'send' || travelling ? 1 : Math.max(0, 1 - elapsed / flight.duration);
    for (const segment of flight.segments) { segmentPath(this.effects, segment.from, segment.to, segment.jump ? 8 * this.lod : 0); }
    if (flight.segments.length) { this.effects.stroke({ color: flight.tint, width: (flight.own ? 3.2 : 1.8) * this.lod,
      alpha: (flight.own ? .62 : .25) * fade }); }
    if (flight.phase !== 'send' && (!travelling || this.reducedMotion)) {
      if (elapsed >= flight.duration) { return false; }
      if (!flight.end) { return flight.segments.length > 0; }
      const progress = Math.max(0, elapsed / flight.duration);
      this.effects.circle(flight.end.px, flight.end.py, 16 + progress * 18)
        .stroke({ color: flight.tint, width: 2.6 - progress, alpha: .9 * (1 - progress) });
      if (flight.phase === 'fail') {
        const r = 8;
        this.effects.moveTo(flight.end.px - r, flight.end.py - r).lineTo(flight.end.px + r, flight.end.py + r)
          .moveTo(flight.end.px + r, flight.end.py - r).lineTo(flight.end.px - r, flight.end.py + r)
          .stroke({ color: flight.tint, width: 2.4, alpha: .9 * (1 - progress) });
      }
      return true;
    }
    const width = (flight.own ? 3.2 : 2.2) * this.lod, radius = (flight.own ? 6 : 4.5) * Math.max(1, this.lod * .75);
    if (this.reducedMotion) {
      for (const segment of flight.segments) { segmentPath(this.effects, segment.from, segment.to); }
      if (flight.segments.length) { this.effects.stroke({ color: flight.tint, width, alpha: .55 }); }
      if (flight.end) { this.effects.circle(flight.end.px, flight.end.py, 22).stroke({ color: flight.tint, width: 1.5, alpha: .65 }); }
      return true;
    }
    if (travelling && flight.segments.length) {
      const progress = flight.travelFrom + (1 - flight.travelFrom) * Math.max(0, (now - flight.travelStart) / flight.travelDuration);
      const tail = Math.max(flight.travelFrom, progress - .16);
      // Comet tail: the travelled stretch fades behind the packet.
      const head = packetPoint(flight.segments, progress), back = packetPoint(flight.segments, tail);
      if (head && back) {
        for (let i = 1; i <= 4; i++) {
          const point = packetPoint(flight.segments, tail + (progress - tail) * i / 4);
          if (point) { this.effects.circle(point.px, point.py, radius * (.35 + i * .12)).fill({ color: flight.tint, alpha: .15 + i * .12 }); }
        }
        this.effects.circle(head.px, head.py, radius).fill({ color: flight.tint, alpha: .95 });
        for (const segment of flight.segments) {
          if (segment.jump) { segmentPath(this.effects, segment.from, segment.to, 8 * this.lod, 8 * this.lod); }
        }
        this.effects.stroke({ color: flight.tint, width: 1.2 * this.lod, alpha: .35 });
      }
    } else if (flight.end) {
      const progress = Math.min(1, Math.max(0, (elapsed - flight.duration) / ARRIVAL_MS));
      this.effects.circle(flight.end.px, flight.end.py, 14 + progress * 18)
        .stroke({ color: flight.tint, width: 2.4 - progress * 1.4, alpha: .85 * (1 - progress) });
    }
    return true;
  }

  /** Only a finite effect/transition can request the next frame. Quiet maps do not tick. */
  animate(now: number) {
    let animating = false;
    this.positionsChanged = false;
    for (const actor of this.nodes.values()) {
      const t = this.reducedMotion ? 1 : Math.min(1, Math.max(0, (now - actor.movedAt) / 180)), eased = 1 - (1 - t) ** 3;
      const px = actor.fromX + (actor.node.px - actor.fromX) * eased, py = actor.fromY + (actor.node.py - actor.fromY) * eased;
      if (px !== actor.px || py !== actor.py) { this.positionsChanged = true; }
      actor.px = px; actor.py = py;
      actor.group.position.set(actor.px, actor.py);
      const opacity = this.reducedMotion ? 1 : Math.min(1, (now - actor.appearedAt) / 150);
      actor.group.alpha = Math.max(0, opacity); if (t < 1 || opacity < 1) { animating = true; }
    }
    if (this.positionsChanged) {
      for (const edge of this.dynamicEdges || []) {
        const a = this.scene!.byAddress.get(edge.from), b = this.scene!.byAddress.get(edge.to), retained = this.links.get(edge.id);
        if (!a || !b || !retained) { continue; }
        this.paintLink(retained, edge, physicalPoint(this.pointFor(a)), physicalPoint(this.pointFor(b)));
      }
    }
    this.effects.clear();
    this.pulses = this.pulses.filter((pulse) => now - pulse.born < 700);
    for (const pulse of this.pulses) {
      const progress = Math.max(0, (now - pulse.born) / 700);
      this.effects.circle(pulse.point.px, pulse.point.py, 19 + progress * 21)
        .stroke({ color: pulse.tint, width: 2.5 - 1.5 * progress, alpha: .8 * (1 - progress) });
      animating = true;
    }
    for (const event of this.traffic) {
      const age = Math.max(0, (now - event.born) / 1000); if (age >= 4) { continue; }
      const tint = event.tint;
      if (this.reducedMotion) { this.effects.circle(event.point.px, event.point.py, 24).stroke({ color: tint, width: 1.5, alpha: .65 }); continue; }
      const phase = (age % 1.2) / 1.2;
      this.effects.circle(event.point.px, event.point.py, (20 + phase * 15)).stroke({ color: tint, width: 1.5, alpha: (1 - phase) * (1 - age / 4) });
      const packet = pointOn(event.segments, age % 1); if (packet) { this.effects.circle(packet.px, packet.py, 3).fill({ color: tint, alpha: .9 }); }
      animating = true;
    }
    for (const flight of [...this.flights.values()]) {
      if (!this.drawFlight(flight, now)) { this.flights.delete(flight.key); continue; }
      if (!this.reducedMotion) { animating = true; }
    }
    const ping = this.routes[2];
    if (ping.segments.length) {
      if (now >= ping.until) { this.clearPing(); }
      else {
        if (!this.reducedMotion && now - ping.began < 1800) {
          const point = pointOn(ping.segments, ((now - ping.began) % 900) / 900);
          if (point) { this.effects.circle(point.px, point.py, 5).fill({ color: ping.tint, alpha: .95 }); }
          animating = true;
        }
      }
    }
    return animating;
  }

  pointFor(node: PlacedNode): PlacedNode {
    const actor = this.nodes.get(node.address);
    return actor && (actor.px !== node.px || actor.py !== node.py) ? { ...node, px: actor.px, py: actor.py,
      anchorX: (node.anchorX ?? node.px) + actor.px - node.px, anchorY: (node.anchorY ?? node.py) + actor.py - node.py } : node;
  }
  hit(point: GraphPoint, zoom: number, disclosed?: Map<string, PlacedNode>): PlacedNode | null {
    let best: PlacedNode | null = null, distance = (16 / zoom) ** 2;
    for (const actor of this.nodes.values()) {
      const current = disclosed ? disclosed.get(actor.node.address) : actor.node;
      if (!current) { continue; }
      const next = (actor.px - point.px) ** 2 + (actor.py - point.py) ** 2;
      if (next < distance || (next === distance && (!best || current.address < best.address))) {
        distance = next; best = this.pointFor(current);
      }
    }
    return best;
  }
  destroy() { this.nodes.clear(); this.links.clear(); this.traffic = []; this.pulses = []; this.flights.clear(); this.drawnPackets.clear(); this.scene = null; this.overlay = null; destroyDisplay(this.world); }
}
