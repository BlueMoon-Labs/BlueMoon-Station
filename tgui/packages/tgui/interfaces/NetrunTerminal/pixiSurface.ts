import type { Application, Container, Graphics } from 'pixi.js';

import { GraphBase, GraphCamera, GraphOverlay, viewBox } from './graphPresentation';
import type { GraphScene, PlacedNode } from './graphScene';
import { clamp, GraphViewport } from './graphViewport';
import type { GraphPoint } from './mapLayout';
import { PixiActors } from './pixiActors';
import { PixiLabels } from './pixiLabels';
import type { PixiLibrary } from './pixiPrimitives';
import { PixiScenery } from './pixiScenery';
import { themeId, themePalette } from './themes';
import type { NetEdge } from './types';

export type PixiCamera = GraphCamera;
export type PixiMountOptions = { signal?: AbortSignal; onStatus?: (status: 'ready' | 'lost') => void; reducedMotion?: boolean };
export type PixiSurface = {
  updateScene: (scene: GraphScene, base: GraphBase) => boolean;
  updateActors: (scene: GraphScene, overlay: GraphOverlay) => void;
  updateCamera: (camera: PixiCamera) => void;
  setInteracting: (interacting: boolean) => void;
  resize: (width: number, height: number) => boolean;
  hitTest: (point: GraphPoint, zoom: number) => PlacedNode | null;
  setSuspended: (suspended: boolean) => void;
  destroy: () => void;
};
const validSize = (width: number, height: number) => Number.isFinite(width) && Number.isFinite(height) && width > 0 && height > 0;
/** Resolution adapts framebuffer memory; topology size never disables the map or drops objects. */
export const framebufferResolution = (width: number, height: number, deviceRatio = 1) =>
  Math.min(Math.max(.1, deviceRatio), 2, Math.sqrt(3145728 / (width * height)), 8192 / Math.max(width, height));
export const webglAvailable = () => typeof window !== 'undefined' && typeof window.WebGL2RenderingContext !== 'undefined';

function disposeApplication(app: Application, canvas: HTMLCanvasElement, context: WebGL2RenderingContext) {
  try { app.stop?.(); } catch { /* An init failure can precede ticker installation. */ }
  try { app.destroy({ removeView: true }, { children: true, texture: true, textureSource: true, context: true }); }
  catch {
    // Application.destroy can throw in a plugin before stage/renderer disposal on partial init.
    try { app.stage?.destroy({ children: true, texture: true, textureSource: true, context: true }); } catch { /* Continue cleanup. */ }
    try { app.renderer?.destroy({ removeView: true }); } catch { /* Continue cleanup. */ }
  }
  try { context.getExtension('WEBGL_lose_context')?.loseContext(); } catch { /* Already lost. */ }
  canvas.remove();
}

/** Owns GPU lifecycle and the demand-driven scheduler; layers own their retained objects. */
class NetrunPixiSurface implements PixiSurface {
  private readonly scenery: PixiScenery;
  private readonly actors: PixiActors;
  private readonly labels: PixiLabels;
  private readonly grid: Graphics;
  private readonly world: Container;
  private readonly view = new GraphViewport();
  private readonly motionQuery: MediaQueryList | null;
  private frame: number | null = null;
  private wakeTimer: number | null = null;
  private restoreTimer: number | null = null;
  private disposed = false;
  private suspended = false;
  private lost = false;
  private failed = false;
  private width: number;
  private height: number;
  private camera: PixiCamera = { x: 0, y: 0, zoom: 1 };
  private scene: GraphScene | null = null;
  private base: GraphBase | null = null;
  private live: { scene: GraphScene; overlay: GraphOverlay; edges: NetEdge[]; adjacency: Map<string, Set<string>> } | null = null;
  private sceneDirty = false;
  private actorsDirty = false;
  private cameraDirty = true;
  private sizeDirty = true;
  private labelDirty = true;
  private interacting = false;
  private labelCamera: PixiCamera | null = null;
  private palette = themePalette();
  private currentTheme = '';
  private themeRoot: HTMLElement | null = null;
  private themeObserver: MutationObserver | null = null;

  constructor(private readonly app: Application, private readonly canvas: HTMLCanvasElement,
    private readonly context: WebGL2RenderingContext, pixi: PixiLibrary, width: number, height: number,
    private readonly onUnavailable: (() => void) | undefined, private readonly options: PixiMountOptions, host: HTMLElement) {
    this.width = width; this.height = height;
    this.scenery = new PixiScenery(pixi); this.actors = new PixiActors(pixi); this.labels = new PixiLabels(pixi);
    this.grid = new pixi.Graphics();
    // A PixiJS v8 render group applies camera transforms on the GPU without
    // reprocessing the static scenery tree for every pointer movement.
    this.world = new pixi.Container({ isRenderGroup: true });
    this.world.label = 'station-world';
    this.world.addChild(this.scenery.world, this.actors.world);
    this.app.stage.addChild(this.grid, this.world, this.labels.layer);
    this.motionQuery = typeof window.matchMedia === 'function' ? window.matchMedia('(prefers-reduced-motion: reduce)') : null;
    this.actors.setReducedMotion(options.reducedMotion ?? this.motionQuery?.matches ?? false);
    this.motionQuery?.addEventListener?.('change', this.onMotion);
    canvas.addEventListener('webglcontextlost', this.onLost);
    canvas.addEventListener('webglcontextrestored', this.onRestored);
    document.addEventListener('visibilitychange', this.onVisible);
    options.signal?.addEventListener('abort', this.destroy, { once: true });
    this.themeRoot = host.closest<HTMLElement>('[data-net-theme]');
    this.syncTheme();
    if (this.themeRoot && typeof MutationObserver !== 'undefined') {
      this.themeObserver = new MutationObserver(this.syncTheme);
      this.themeObserver.observe(this.themeRoot, { attributes: true, attributeFilter: ['data-net-theme'] });
    }
    this.requestRender();
  }

  private syncTheme = () => {
    const id = themeId(this.themeRoot?.dataset.netTheme);
    if (this.currentTheme === id || this.disposed) { return; }
    this.currentTheme = id; this.palette = themePalette(id);
    if (this.app.renderer.background) { this.app.renderer.background.color = Number.parseInt(this.palette.map.slice(1), 16); }
    this.canvas.dataset.netTheme = id;
    this.cameraDirty = true; this.requestRender();
  };

  updateScene(scene: GraphScene, base: GraphBase) {
    if (this.disposed || this.failed) { return false; }
    if (scene !== this.scene || base.gateways !== this.base?.gateways || base.apcZones !== this.base?.apcZones
      || base.showEndpointLinks !== this.base?.showEndpointLinks) {
      const sceneryChanged = scene.sceneryVersion !== this.scene?.sceneryVersion
        || base.gateways !== this.base?.gateways || base.apcZones !== this.base?.apcZones || base.showEndpointLinks !== this.base?.showEndpointLinks;
      if (this.scene && (scene.changedNodes === null || scene.edges !== this.scene.edges)) {
        this.scenery.suppressUndisclosed(scene);
      }
      this.scene = scene; this.base = base;
      if (sceneryChanged) { this.sceneDirty = true; }
      this.labelDirty = true;
      this.canvas.dataset.netNodes = String(scene.nodes.length); this.canvas.dataset.netEdges = String(scene.edges.length);
      this.requestRender();
    }
    return true;
  }
  updateActors(scene: GraphScene, overlay: GraphOverlay) {
    if (this.disposed || this.failed) { return; }
    const prior = this.live;
    if (prior && prior.scene === scene) {
      const a = prior.overlay, b = overlay;
      if (a.selected === b.selected && a.hovered === b.hovered && a.selectionPending === b.selectionPending
        && a.entityHost === b.entityHost && a.jacked === b.jacked && a.gateways === b.gateways
        && a.selectedRoute === b.selectedRoute && a.waypointRoute === b.waypointRoute
        && a.pingRoute === b.pingRoute && a.pingId === b.pingId && a.pingExpiresAt === b.pingExpiresAt
          && a.events === b.events && a.showEndpointLinks === b.showEndpointLinks) { return; }
    }
    // The UI provides one complete graph. Render-layer membership stays an
    // internal cache detail, never a second transport/layout contract.
    const edges = prior && (prior.scene === scene || (scene.previousIdentity === prior.scene.identity
      && scene.edges === prior.scene.edges && !scene.dynamicMembershipChanged)) ? prior.edges
      : scene.edges.filter((edge) => scene.byAddress.get(edge.from)?.dynamic || scene.byAddress.get(edge.to)?.dynamic);
    this.live = { scene, overlay, edges, adjacency: scene.adjacency };
    this.actorsDirty = true; this.labelDirty = true; this.requestRender();
  }
  updateCamera(camera: PixiCamera) {
    if (this.disposed || !Number.isFinite(camera.x) || !Number.isFinite(camera.y) || !Number.isFinite(camera.zoom) || camera.zoom <= 0) { return; }
    if (camera.x === this.camera.x && camera.y === this.camera.y && camera.zoom === this.camera.zoom) { return; }
    this.camera = { x: camera.x, y: camera.y, zoom: camera.zoom };
    this.cameraDirty = true;
    if (!this.interacting) { this.labelDirty = true; }
    this.requestRender();
  }
  setInteracting(interacting: boolean) {
    if (this.disposed || this.interacting === interacting) { return; }
    this.interacting = interacting;
    if (!interacting) { this.labelDirty = true; }
    this.requestRender();
  }
  resize(width: number, height: number) {
    if (this.disposed || this.failed || !validSize(width, height)) { return false; }
    if (this.width !== width || this.height !== height) {
      this.width = width; this.height = height; this.sizeDirty = true; this.cameraDirty = true; this.labelDirty = true; this.requestRender();
    }
    return true;
  }
  hitTest(point: GraphPoint, zoom: number) {
    const moving = this.actors.hit(point, zoom, this.scene?.byAddress), stationary = this.scene?.hit(point, zoom);
    if (!stationary || stationary.dynamic) { return moving; }
    if (!moving) { return stationary; }
    const a = (moving.px - point.px) ** 2 + (moving.py - point.py) ** 2;
    const b = (stationary.px - point.px) ** 2 + (stationary.py - point.py) ** 2;
    return a < b || (a === b && moving.address < stationary.address) ? moving : stationary;
  }
  setSuspended(suspended: boolean) {
    if (this.disposed || this.suspended === suspended) { return; }
    this.suspended = suspended;
    if (suspended) { this.cancelFrame(); this.cancelWake(); this.interacting = false; }
    else { this.cameraDirty = true; this.labelDirty = true; this.requestRender(); }
  }
  private cancelFrame() { if (this.frame !== null) { window.cancelAnimationFrame(this.frame); this.frame = null; } }
  private cancelWake() { if (this.wakeTimer !== null) { window.clearTimeout(this.wakeTimer); this.wakeTimer = null; } }
  private requestRender = () => {
    if (this.disposed || this.suspended || this.failed || this.lost || document.hidden || this.frame !== null) { return; }
    this.frame = window.requestAnimationFrame(this.render);
    this.cancelWake();
  };
  private render = (now: number) => {
    this.frame = null;
    if (this.disposed || this.suspended || this.failed || this.lost || document.hidden) { return; }
    // Draw at the browser's native requestAnimationFrame cadence. Input
    // coalesces into one frame; the map has no idle animation loop.
    try {
      if (this.sizeDirty) {
        this.app.renderer.resize(this.width, this.height, framebufferResolution(this.width, this.height, window.devicePixelRatio || 1));
        this.sizeDirty = false;
      }
      // Local feedback first; speculative scenery only gets a small slice below.
      if (this.actorsDirty && this.live) {
        const { scene, overlay, edges, adjacency } = this.live;
        this.actors.update(scene, overlay, edges, adjacency, now); this.actorsDirty = false;
      }
      if (this.sceneDirty && this.scene && this.base) { this.scenery.queue(this.scene, this.base); this.sceneDirty = false; }
      this.world.position.set(this.camera.x, this.camera.y); this.world.scale.set(this.camera.zoom);
      this.view.x = this.camera.x; this.view.y = this.camera.y; this.view.zoom = this.camera.zoom;
      const bounds = viewBox(this.camera, this.width, this.height, 32);
      const animated = this.actors.animate(now);
      // Cull after interpolation, including the final frame of a transition.
      this.actors.setViewport(bounds, this.camera.zoom);
      // Visibility must be updated before advancing so newly revealed chunks
      // upload in this very frame, not after the last scheduled render.
      this.scenery.setViewport(bounds, this.camera.zoom);
      const building = this.scenery.advance(this.interacting ? 1 : 4);
      this.scenery.setViewport(bounds, this.camera.zoom);
      if (this.cameraDirty) { this.paintGrid(); this.cameraDirty = false; }
      // Captions are in screen coordinates. During gestures transform the
      // retained label layer with the GPU camera instead of measuring text,
      // solving label collisions and uploading glyphs at every pointer event.
      if (this.interacting && this.labelCamera) {
        const ratio = this.camera.zoom / this.labelCamera.zoom;
        this.labels.layer.scale.set(ratio);
        this.labels.layer.position.set(
          this.camera.x - this.labelCamera.x * ratio,
          this.camera.y - this.labelCamera.y * ratio);
        if (this.actors.positionsChanged) { this.labelDirty = true; }
      } else {
        if (this.live && (this.labelDirty || this.actors.positionsChanged)) {
          this.labels.layer.scale.set(1);
          this.labels.layer.position.set(0, 0);
          this.labels.update(this.live.scene, this.live.overlay, this.view,
            this.width, this.height, (node) => this.actors.pointFor(node));
          this.labelCamera = { ...this.camera };
          this.labelDirty = false;
        }
      }
      this.app.renderer.render({ container: this.app.stage });
      if (animated || building || this.sizeDirty) { this.requestRender(); }
      else if (this.actors.nextWake !== null) {
        this.wakeTimer = window.setTimeout(() => { this.wakeTimer = null; this.requestRender(); }, Math.max(1, this.actors.nextWake - now));
      }
    } catch { this.reportUnavailable(); }
  };
  private paintGrid() {
    const { x, y, zoom } = this.camera;
    const step = clamp(Math.pow(2, Math.ceil(Math.log2(80 / zoom))) * zoom, 32, 240);
    this.grid.clear();
    for (let px = ((x % step) + step) % step; px < this.width; px += step) { this.grid.moveTo(px, 0).lineTo(px, this.height); }
    for (let py = ((y % step) + step) % step; py < this.height; py += step) { this.grid.moveTo(0, py).lineTo(this.width, py); }
    this.grid.stroke({ color: Number.parseInt(this.palette.accent.slice(1), 16), alpha: .08, width: 1 });
    // Larger guide lines provide orientation at every zoom without textures,
    // custom shaders or a persistent animation loop.
    const major = step * 4;
    for (let px = ((x % major) + major) % major; px < this.width; px += major) { this.grid.moveTo(px, 0).lineTo(px, this.height); }
    for (let py = ((y % major) + major) % major; py < this.height; py += major) { this.grid.moveTo(0, py).lineTo(this.width, py); }
    this.grid.stroke({ color: Number.parseInt(this.palette.accent.slice(1), 16), alpha: .15, width: 1.15 });
  }
  private onVisible = () => { if (document.hidden) { this.cancelFrame(); this.cancelWake(); } else { this.requestRender(); } };
  private onMotion = () => {
    this.actors.setReducedMotion(this.options.reducedMotion ?? this.motionQuery?.matches ?? false); this.requestRender();
  };
  private onLost = (event: Event) => {
    event.preventDefault(); if (this.disposed) { return; }
    this.lost = true; this.cancelFrame(); this.cancelWake(); this.canvas.dataset.pixiState = 'lost'; this.options.onStatus?.('lost');
    if (this.restoreTimer !== null) { window.clearTimeout(this.restoreTimer); }
    this.restoreTimer = window.setTimeout(() => this.reportUnavailable(), 10000);
  };
  private onRestored = () => {
    if (this.disposed || this.failed) { return; }
    if (this.restoreTimer !== null) { window.clearTimeout(this.restoreTimer); this.restoreTimer = null; }
    this.lost = false; this.cameraDirty = true; this.labelDirty = true; this.sizeDirty = true;
    this.canvas.dataset.pixiState = 'ready'; this.options.onStatus?.('ready'); this.requestRender();
  };
  private reportUnavailable() {
    if (this.disposed || this.failed) { return; }
    this.failed = true; this.cancelFrame(); this.cancelWake(); this.canvas.dataset.pixiState = 'failed'; this.onUnavailable?.();
  }
  destroy = () => {
    if (this.disposed) { return; }
    this.disposed = true; this.cancelFrame(); this.cancelWake();
    this.themeObserver?.disconnect(); this.themeObserver = null; this.themeRoot = null;
    if (this.restoreTimer !== null) { window.clearTimeout(this.restoreTimer); this.restoreTimer = null; }
    this.canvas.removeEventListener('webglcontextlost', this.onLost); this.canvas.removeEventListener('webglcontextrestored', this.onRestored);
    document.removeEventListener('visibilitychange', this.onVisible); this.motionQuery?.removeEventListener?.('change', this.onMotion);
    this.options.signal?.removeEventListener('abort', this.destroy);
    for (const layer of [this.scenery, this.actors, this.labels]) { try { layer.destroy(); } catch { /* Complete every resource owner. */ } }
    this.scene = null; this.base = null; this.live = null; disposeApplication(this.app, this.canvas, this.context);
  };
}

/** One actual canvas/context; aborted async init never appends or leaks an orphan renderer. */
export async function mountNetrunPixi(host: HTMLElement, width: number, height: number,
  onUnavailable?: () => void, options: PixiMountOptions = {}): Promise<PixiSurface | null> {
  if (!validSize(width, height) || !webglAvailable() || options.signal?.aborted || typeof window.requestAnimationFrame !== 'function') { return null; }
  let library: PixiLibrary;
  try { library = await import('pixi.js'); } catch { return null; }
  if (options.signal?.aborted) { return null; }
  const canvas = document.createElement('canvas');
  const context = canvas.getContext('webgl2', { alpha: false, antialias: true, powerPreference: 'low-power' });
  if (!context) { return null; }
  const app = new library.Application();
  try {
    await app.init({ canvas, context, width, height, preference: 'webgl', preferWebGLVersion: 2,
      powerPreference: 'low-power', autoStart: false, sharedTicker: false, antialias: true, autoDensity: false,
      resolution: framebufferResolution(width, height, window.devicePixelRatio || 1), background: 0x081420,
      eventFeatures: { move: false, globalMove: false, click: false, wheel: false } });
    app.stop();
    if (options.signal?.aborted) { disposeApplication(app, canvas, context); return null; }
    canvas.setAttribute('data-net-pixi', 'webgl2'); canvas.setAttribute('data-pixi-state', 'ready'); canvas.setAttribute('aria-hidden', 'true');
    Object.assign(canvas.style, { position: 'absolute', inset: '0', width: '100%', height: '100%', display: 'block', pointerEvents: 'none' });
    const surface = new NetrunPixiSurface(app, canvas, context, library, width, height, onUnavailable, options, host);
    host.appendChild(canvas); options.onStatus?.('ready'); return surface;
  } catch (error) {
    console.error('NetRun Pixi initialization failed', error);
    disposeApplication(app, canvas, context); return null;
  }
}
