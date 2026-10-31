import { NetEdge, NetMap, NetMapPacket, NetNode } from './types';

const TRANSPORT_KEYS = new Set(['nodes', 'edges', 'epoch', 'full', 'base_revision', 'removed_nodes', 'removed_edges']);
const equalValue = (left: unknown, right: unknown): boolean => {
  if (left === right) { return true; }
  if (!left || !right || typeof left !== 'object' || typeof right !== 'object') { return false; }
  if (Array.isArray(left) || Array.isArray(right)) {
    return Array.isArray(left) && Array.isArray(right) && left.length === right.length
      && left.every((value, index) => equalValue(value, right[index]));
  }
  const keys = Object.keys(left);
  return keys.length === Object.keys(right).length && keys.every((key) => equalValue(left[key], right[key]));
};

const replaceEntries = <T, >(entries: T[], lookup: Map<string, T>, indexes: Map<string, number>, keyOf: (entry: T) => string) => {
  lookup.clear(); indexes.clear();
  entries.forEach((entry, index) => { lookup.set(keyOf(entry), entry); indexes.set(keyOf(entry), index); });
};

const patchEntries = <T, >(previous: T[], lookup: Map<string, T>, indexes: Map<string, number>,
  upserts: T[], removed: string[], keyOf: (entry: T) => string): T[] => {
  let entries = previous;
  const removals = new Set(removed.filter((key) => lookup.has(key)));
  if (removals.size) {
    entries = previous.filter((entry) => !removals.has(keyOf(entry)));
    removals.forEach((key) => lookup.delete(key));
    indexes.clear(); entries.forEach((entry, index) => indexes.set(keyOf(entry), index));
  }
  for (const entry of upserts) {
    const key = keyOf(entry), retained = lookup.get(key);
    if (retained && equalValue(retained, entry)) { continue; }
    if (entries === previous) { entries = previous.slice(); }
    const index = indexes.get(key);
    if (index === undefined) { indexes.set(key, entries.length); entries.push(entry); }
    else { entries[index] = entry; }
    lookup.set(key, entry);
  }
  return entries;
};

/** One local baseline per UI. Idle packets never enumerate the retained graph. */
export class NetrunMapStream {
  private snapshot: NetMap | null = null;
  private epoch: string | undefined;
  private revision: number | undefined;
  private waiting = false;
  private recoveryEpoch: string | undefined;
  private recoveryRevision: number | undefined;
  private retiredEpochs = new Set<string>();
  private observedEpoch: string | undefined;
  private wireOrder: { view: string; generation: number; session: number } | null = null;
  private nodes = new Map<string, NetNode>();
  private edges = new Map<string, NetEdge>();
  private nodeIndexes = new Map<string, number>();
  private edgeIndexes = new Map<string, number>();
  private lastPacket: NetMapPacket | null = null;
  resyncToken = 0;

  private resync(epoch?: string, revision?: number) {
    if (this.recoveryEpoch !== epoch) { this.recoveryRevision = undefined; }
    this.recoveryEpoch = epoch;
    if (revision !== undefined) { this.recoveryRevision = Math.max(this.recoveryRevision ?? revision, revision); }
    if (!this.waiting) { this.waiting = true; this.resyncToken++; }
    // A missed delta can contain a revocation even within the same epoch.
    // Clear the complete projection until a sufficiently recent baseline is
    // confirmed, including all hit-testable nodes and their metadata.
    this.snapshot = null;
    this.nodes.clear(); this.edges.clear(); this.nodeIndexes.clear(); this.edgeIndexes.clear();
    return null;
  }

  get needsResync() { return this.waiting; }
  requestResync() { this.resync(this.epoch, this.revision); }

  private acceptEpoch(epoch: string | undefined) {
    if (!epoch || epoch === this.observedEpoch) { return true; }
    const match = /^(.*):(\d+):(\d+)$/.exec(epoch);
    const order = match && { view: match[1], generation: Number(match[2]), session: Number(match[3]) };
    if (order && this.wireOrder?.view === order.view
      && (order.generation < this.wireOrder.generation || order.session < this.wireOrder.session)) { return false; }
    if (this.retiredEpochs.has(epoch)) { return false; }
    if (this.observedEpoch) {
      this.retiredEpochs.add(this.observedEpoch);
      if (this.retiredEpochs.size > 64) { this.retiredEpochs.delete(this.retiredEpochs.values().next().value); }
    }
    this.observedEpoch = epoch;
    this.wireOrder = order;
    return true;
  }

  private metadata(packet: NetMapPacket, nodes: NetNode[], edges: NetEdge[], fresh = false): NetMap {
    const previous = this.snapshot;
    const result = fresh ? { nodes, edges } as NetMap : { ...previous, nodes, edges };
    let changed = fresh || !previous || previous.nodes !== nodes || previous.edges !== edges;
    for (const key of Object.keys(packet)) {
      if (TRANSPORT_KEYS.has(key)) { continue; }
      const value = packet[key];
      // Native area runs can be large. Their server generation already covers their contents.
      const retained = key === 'apc_zones' && !fresh && previous && packet.static_revision !== undefined
        && packet.static_revision === previous.static_revision ? previous.apc_zones
        : previous && equalValue(previous[key], value) ? previous[key] : value;
      result[key] = retained;
      if (!previous || previous[key] !== retained) { changed = true; }
    }
    result.epoch = packet.epoch;
    if (packet.epoch !== previous?.epoch) { changed = true; }
    this.snapshot = changed ? result : previous;
    return this.snapshot;
  }

  apply(packet: NetMapPacket | null): NetMap | null {
    if (!packet) { return this.snapshot; }
    if (packet === this.lastPacket) { return this.snapshot; }
    this.lastPacket = packet;
    // Late packets from an already replaced epoch cannot restore revoked data.
    if (!this.acceptEpoch(packet.epoch)) { return this.snapshot; }
    if (packet.full === false || packet.full === 0) {
      if (!this.snapshot || this.waiting || packet.epoch !== this.epoch) { return this.resync(packet.epoch, packet.state_revision); }
      if (packet.state_revision < this.revision) { return this.snapshot; }
      if (packet.state_revision === this.revision) {
        // Route, selection and relay readiness may change without graph mutations.
        return this.metadata(packet, this.snapshot.nodes, this.snapshot.edges);
      }
      // The server composes final upserts/removals over this entire interval.
      // A delayed full-snapshot receipt may rewind its cursor while this client
      // already has an intermediate revision. Applying that overlap is idempotent;
      // only a baseline ahead of ours means an update is actually missing.
      if (packet.base_revision > this.revision) { return this.resync(packet.epoch, packet.state_revision); }
      const nodes = patchEntries(this.snapshot.nodes, this.nodes, this.nodeIndexes,
        packet.nodes || [], packet.removed_nodes || [], (node) => node.address);
      const removedEdges = packet.removed_edges || [];
      // A malformed/lost update must not manufacture links to undisclosed endpoints.
      if (packet.edges?.some((edge) => !this.nodes.has(edge.from) || !this.nodes.has(edge.to))) { return this.resync(packet.epoch, packet.state_revision); }
      const orphaned = packet.removed_nodes?.length
        ? this.snapshot.edges.filter((edge) => !this.nodes.has(edge.from) || !this.nodes.has(edge.to)).map((edge) => edge.id) : [];
      const edges = patchEntries(this.snapshot.edges, this.edges, this.edgeIndexes,
        packet.edges || [], [...removedEdges, ...orphaned], (edge) => edge.id);
      this.revision = packet.state_revision;
      return this.metadata(packet, nodes, edges);
    }
    if (this.waiting && packet.epoch === this.recoveryEpoch && this.recoveryRevision !== undefined
      && packet.state_revision < this.recoveryRevision) { return null; }
    const sameStream = packet.epoch !== undefined && packet.epoch === this.epoch;
    if (!this.waiting && sameStream && this.snapshot && packet.state_revision <= this.revision) {
      return packet.state_revision < this.revision ? this.snapshot : this.metadata(packet, this.snapshot.nodes, this.snapshot.edges);
    }
    // A new authorization epoch must replace the disclosed set, but it does
    // not require replacing identical objects that are still disclosed. This
    // also avoids rebuilding an entire Pixi scene when the server sends a
    // full snapshot after changing the player's network or permissions.
    const retainFull = <T, >(incoming: T[], previous: T[] | undefined, lookup: Map<string, T>, keyOf: (entry: T) => string) => {
      const entries = incoming.map((entry) => {
        const retained = lookup.get(keyOf(entry));
        return retained && equalValue(retained, entry) ? retained : entry;
      });
      return previous && entries.length === previous.length && entries.every((entry, index) => entry === previous[index])
        ? previous : entries;
    };
    const nodes = retainFull(packet.nodes, this.snapshot?.nodes, this.nodes, (node) => node.address);
    const edges = retainFull(packet.edges, this.snapshot?.edges, this.edges, (edge) => edge.id);
    replaceEntries(nodes, this.nodes, this.nodeIndexes, (node) => node.address);
    replaceEntries(edges, this.edges, this.edgeIndexes, (edge) => edge.id);
    this.epoch = packet.epoch; this.revision = packet.state_revision; this.waiting = false;
    this.recoveryEpoch = undefined; this.recoveryRevision = undefined;
    return this.metadata(packet, nodes, edges, true);
  }
}
