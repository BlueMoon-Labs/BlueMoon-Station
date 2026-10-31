import type { PlacedNode } from './graphScene';
import type { GraphPoint } from './mapLayout';
import { ACCESS_COLORS, ApcZone, Gateway, NetEvent } from './types';

/** Renderer-independent map state shared by the viewport, input and Pixi layers. */
export type GraphOverlay = {
  selected: string | null; jacked: string | null; entityHost: string | null;
  hovered?: string | null;
  selectionPending?: boolean;
  gateways: Map<string, Gateway>; selectedRoute: string[]; waypointRoute: string[]; pingRoute: string[];
  pingId?: number; pingExpiresAt?: number;
  events: NetEvent[]; apcZones?: ApcZone[];
  /** Quiet overview hides endpoint cables; focus and actual packet routes remain visible. */
  showEndpointLinks?: boolean;
};
export type GraphBase = Pick<GraphOverlay, 'gateways' | 'apcZones' | 'showEndpointLinks'>;
export type GraphCamera = { x: number; y: number; zoom: number };
export type GraphBox = { left: number; top: number; right: number; bottom: number };
export const markerColor = (node: PlacedNode) => !node.online ? '#85434a' : ACCESS_COLORS[node.access] || '#678698';
export const physicalPoint = (node: GraphPoint): GraphPoint => ({ px: node.anchorX ?? node.px, py: node.anchorY ?? node.py });
export const boxesIntersect = (a: GraphBox, b: GraphBox) => a.left <= b.right && b.left <= a.right && a.top <= b.bottom && b.top <= a.bottom;
export const segmentBox = (a: GraphPoint, b: GraphPoint): GraphBox => ({ left: Math.min(a.px, b.px), right: Math.max(a.px, b.px), top: Math.min(a.py, b.py), bottom: Math.max(a.py, b.py) });
export const viewBox = (camera: GraphCamera, width: number, height: number, padding = 0): GraphBox => ({
  left: (-camera.x - padding) / camera.zoom, right: (width - camera.x + padding) / camera.zoom,
  top: (-camera.y - padding) / camera.zoom, bottom: (height - camera.y + padding) / camera.zoom,
});
/** Quantized LOD keeps overview markers readable without rebuilding geometry on every zoom pixel. */
export const markerScale = (zoom: number) => Math.max(1, 2 ** Math.ceil(Math.log2(.5 / Math.max(zoom, 1e-6))));
