import { GraphEdgeIndex } from './graphEdgeIndex';
import { GRAPH_GAP, GRAPH_TILE } from './graphLayout';
import { graphAdjacency, GraphPoint } from './mapLayout';
import { ApcZone, NetEdge, NetNode } from './types';

export type PlacedNode = NetNode & GraphPoint;
const cellKey = (x: number, y: number) => `${x},${y}`;

/** Retained render scene with a separate spatial index; it never requests hidden nodes. */
export class GraphScene {
  nodes: PlacedNode[] = [];
  edges: NetEdge[] = [];
  byAddress = new Map<string, PlacedNode>();
  adjacency = new Map<string, Set<string>>();
  /** Cached incident edges let fast camera redraw inspect only on-screen connections. */
  incidentEdges = new Map<string, NetEdge[]>();
  private cells = new Map<string, PlacedNode[]>();
  private edgeIndex = new GraphEdgeIndex();
  readonly identity: object = {};
  previousIdentity: object | null = null;
  changedNodes: PlacedNode[] | null = null;
  dynamicMembershipChanged = true;
  /** Changes only when stationary scenery needs new geometry or colors. */
  sceneryVersion: object = {};

  update(nodes: PlacedNode[], edges: NetEdge[], previous?: GraphScene) {
    const sameOrder = !!previous && nodes.length === previous.nodes.length
      && nodes.every((node, i) => node.address === previous.nodes[i].address);
    this.previousIdentity = previous?.identity || null;
    this.changedNodes = sameOrder ? nodes.filter((node, i) => node !== previous.nodes[i]) : null;
    this.dynamicMembershipChanged = !sameOrder
      || this.changedNodes.some((node) => !!node.dynamic !== !!previous.byAddress.get(node.address)?.dynamic);
    const sameGeometry = sameOrder && nodes.every((node, i) => {
      const old = previous.nodes[i];
      return node.px === old.px && node.py === old.py && node.anchorX === old.anchorX && node.anchorY === old.anchorY;
    });
    const sameScenery = sameOrder && edges === previous.edges && nodes.every((node, i) => {
      const old = previous.nodes[i];
      if (node === old) { return true; }
      if (node.dynamic && old.dynamic) { return true; }
      return node.dynamic === old.dynamic && node.type === old.type && node.network === old.network
        && node.online === old.online && node.access === old.access && node.px === old.px && node.py === old.py
        && node.anchorX === old.anchorX && node.anchorY === old.anchorY;
    });
    this.sceneryVersion = sameScenery ? previous.sceneryVersion : {};
    this.nodes = nodes;
    this.edges = edges;
    this.byAddress = new Map(nodes.map((node) => [node.address, node]));
    const nodeCell = (node: PlacedNode) => cellKey(Math.floor(node.px / GRAPH_GAP), Math.floor(node.py / GRAPH_GAP));
    if (previous) {
      this.cells = new Map(previous.cells);
      const changedCells = new Map<string, PlacedNode[]>();
      const edit = (key: string) => {
        let cell = changedCells.get(key);
        if (!cell) { cell = [...(previous.cells.get(key) || [])]; changedCells.set(key, cell); }
        return cell;
      };
      for (const old of previous.nodes) {
        if (this.byAddress.get(old.address) === old) { continue; }
        const cell = edit(nodeCell(old)), index = cell.findIndex((node) => node.address === old.address);
        if (index >= 0) { cell.splice(index, 1); }
      }
      for (const node of nodes) {
        if (previous.byAddress.get(node.address) !== node) { edit(nodeCell(node)).push(node); }
      }
      for (const [key, cell] of changedCells) {
        if (cell.length) { this.cells.set(key, cell); } else { this.cells.delete(key); }
      }
    } else {
      this.cells.clear();
      for (const node of nodes) {
        const key = nodeCell(node), cell = this.cells.get(key) || [];
        cell.push(node); this.cells.set(key, cell);
      }
    }
    // Status-only updates do not alter graph connectivity or spatial bounds.
    // Retain those expensive indexes, replacing references only in changed cells.
    if (sameGeometry && edges === previous.edges) {
      this.adjacency = previous.adjacency;
      this.incidentEdges = previous.incidentEdges;
      this.edgeIndex = previous.edgeIndex;
      return;
    }
    this.adjacency = sameOrder && edges === previous.edges ? previous.adjacency : graphAdjacency(nodes, edges);
    this.edgeIndex.update(this.byAddress, edges);
    this.incidentEdges.clear();
    for (const edge of edges) {
      for (const address of [edge.from, edge.to]) {
        const incident = this.incidentEdges.get(address) || [];
        incident.push(edge);
        this.incidentEdges.set(address, incident);
      }
    }
  }

  /** Fit includes the selected APC's actual powered area, including empty tiles. */
  fitPoints(zones: ApcZone[] = []): GraphPoint[] {
    const points: GraphPoint[] = [...this.nodes];
    for (const zone of zones) {
      for (const run of zone.runs) {
        points.push({ px: (run.x - .5) * GRAPH_TILE, py: -(run.y + .5) * GRAPH_TILE },
          { px: (run.x + run.width - .5) * GRAPH_TILE, py: -(run.y - .5) * GRAPH_TILE });
      }
    }
    return points;
  }

  visible(left: number, top: number, right: number, bottom: number) {
    // At overview zoom, iterating occupied cells avoids traversing millions of empty grid cells.
    if ((right - left) * (bottom - top) > this.nodes.length * GRAPH_GAP ** 2 * 4) {
      return this.nodes.filter((node) => node.px >= left && node.px <= right && node.py >= top && node.py <= bottom);
    }
    const result: PlacedNode[] = [];
    for (let x = Math.floor(left / GRAPH_GAP); x <= Math.floor(right / GRAPH_GAP); x++) {
      for (let y = Math.floor(top / GRAPH_GAP); y <= Math.floor(bottom / GRAPH_GAP); y++) {
        for (const node of this.cells.get(cellKey(x, y)) || []) {
          if (node.px >= left && node.px <= right && node.py >= top && node.py <= bottom) { result.push(node); }
        }
      }
    }
    return result;
  }

  hit(point: GraphPoint, zoom: number): PlacedNode | null {
    const radius = 16 / zoom;
    let best: PlacedNode | null = null, distance = radius ** 2;
    for (const node of this.visible(point.px - radius, point.py - radius, point.px + radius, point.py + radius)) {
      const next = (point.px - node.px) ** 2 + (point.py - node.py) ** 2;
      if (next < distance || (next === distance && (!best || node.address < best.address))) { best = node; distance = next; }
    }
    return best;
  }

  visibleEdges(left: number, top: number, right: number, bottom: number): NetEdge[] {
    return this.edgeIndex.visible(left, top, right, bottom);
  }
}
