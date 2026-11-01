import { graphBounds, GraphPoint } from './mapLayout';

export const clamp = (n: number, min: number, max: number) => Math.max(min, Math.min(max, n));

/** Camera state is independent of data revisions and survives incremental reconciliation. */
export class GraphViewport {
  x = 0;
  y = 0;
  zoom = 0.85;
  fitting = true;

  fit(points: Iterable<GraphPoint>, width: number, height: number) {
    const bounds = graphBounds(points, 80);
    this.zoom = Math.min(2.5, Math.max(1, width) / bounds.width, Math.max(1, height) / bounds.height);
    this.x = width / 2 - (bounds.minX + bounds.width / 2) * this.zoom;
    this.y = height / 2 - (bounds.minY + bounds.height / 2) * this.zoom;
    this.fitting = true;
  }

  center(point: GraphPoint, width: number, height: number) {
    this.x = width / 2 - point.px * this.zoom;
    this.y = height / 2 - point.py * this.zoom;
    this.fitting = false;
  }

  /** Zoom to a world-space box (used to expand a collapsed LAN into view). */
  fitBox(minX: number, minY: number, maxX: number, maxY: number, width: number, height: number) {
    const boxWidth = Math.max(1, maxX - minX), boxHeight = Math.max(1, maxY - minY), padding = 80;
    this.zoom = clamp(Math.min(width / (boxWidth + padding * 2), height / (boxHeight + padding * 2)), 0.08, 2.5);
    this.x = width / 2 - (minX + boxWidth / 2) * this.zoom;
    this.y = height / 2 - (minY + boxHeight / 2) * this.zoom;
    this.fitting = false;
  }

  pan(x: number, y: number) { this.x = x; this.y = y; this.fitting = false; }

  zoomAt(x: number, y: number, delta: number, fitZoom: number) {
    const next = clamp(this.zoom * Math.exp(-delta * .0013), Math.min(.08, fitZoom), 2.5);
    this.x = x - (x - this.x) * next / this.zoom;
    this.y = y - (y - this.y) * next / this.zoom;
    this.zoom = next;
    this.fitting = false;
  }

  project(point: GraphPoint): GraphPoint { return { px: point.px * this.zoom + this.x, py: point.py * this.zoom + this.y }; }
  unproject(x: number, y: number): GraphPoint { return { px: (x - this.x) / this.zoom, py: (y - this.y) / this.zoom }; }
}
