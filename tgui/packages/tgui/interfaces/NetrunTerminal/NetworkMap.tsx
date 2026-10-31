import { KeyboardEvent, memo, useCallback, useEffect, useMemo, useRef, useState } from 'react';

import { Box, Button, Icon, Input } from '../../components';
import { MapProjection } from './mapLayers';
import { graphAdjacency, graphNeighborhood, GraphPoint } from './mapLayout';
import { GlyphIcon, MapLegend } from './MapLegend';
import { NetrunMapStream } from './mapStream';
import { NetworkViewport, NetworkViewportHandle } from './NetworkViewport';
import {
  ACCESS_COLORS, ACCESS_NAMES, FACTION_COLORS, NetEdge, NetEvent, NetMap, NetNode, NetrunData, NODE_ICONS,
  NODE_NAMES, PingHop, SearchResult, THEME, Waypoint,
} from './types';
import { useNetrunBackend as useBackend, useNetrunFeedback } from './useNetrunBackend';

type Placed = NetNode & GraphPoint;
type Act = (action: string, payload?: object) => void;
export type MapFocusRequest = { address: string; sequence: number };
type FocusProps = {
  onInspect?: () => void;
  focusRequest?: MapFocusRequest | null;
  consumeFocusRequest?: (request: MapFocusRequest) => boolean;
};
type MapInput = {
  map: NetMap | null;
  selectedAddress: string | null;
  selectedNetwork: string | null;
  jackAddress: string | null;
  entityHost: string | null;
  hasEntity: boolean;
  pingRoute: PingHop[];
  pingId?: number;
  pingExpiresAt?: number;
  events: NetEvent[];
  waypoint: Waypoint | null;
  search: SearchResult[];
  suspended?: boolean;
};
const EMPTY_NODES: NetNode[] = [];
const EMPTY_EDGES: NetEdge[] = [];
const EMPTY_EVENTS: NetEvent[] = [];
const EMPTY_HOPS: PingHop[] = [];
const EMPTY_SEARCH: SearchResult[] = [];
const EMPTY_ADDRESSES: string[] = [];

// TGUI polling replaces data objects even if their contents have not changed.
// Retain component references so logs/combat ticks do not trigger map layouts.
const useSemanticValue = <T, >(value: T, signature: string | undefined): T => {
  const previous = useRef({ value, signature });
  // The stream adapter already preserves identities for versioned wire data.
  if (signature === undefined) { previous.current = { value, signature }; return value; }
  if (previous.current.signature !== signature) { previous.current = { value, signature }; }
  return previous.current.value;
};
export const StationMap = memo((props: { suspended?: boolean; focusRequest?: MapFocusRequest | null; onInspect?: () => void } = {}) => {
  const { act, data } = useBackend<NetrunData>(['map', 'selected', 'selected_network', 'jack', 'entity', 'ping_route', 'ping', 'events', 'waypoint', 'search']);
  const [stream] = useState(() => new NetrunMapStream());
  const [, refreshRecovery] = useState(0);
  const resyncSent = useRef(0);
  const lastAcknowledged = useRef('');
  const acknowledgementGeneration = useRef(0);
  const pingClock = useRef<{ id: number; expires: number } | null>(null);
  const latest = useRef<MapInput | null>(null);
  const consumedFocusSequence = useRef<number | null>(null);
  // Keep consumption outside the projected graph, which may remount after a
  // transport resync. An old history click must never override a later selection.
  const consumeFocusRequest = useCallback((request: MapFocusRequest) => {
    if (consumedFocusSequence.current === request.sequence) { return false; }
    consumedFocusSequence.current = request.sequence;
    return true;
  }, []);
  // Timestamp receipt even while the map is hidden. Opening it later must not
  // turn an old remaining_ms snapshot into a fresh full display lifetime.
  if (data.ping && pingClock.current?.id !== data.ping.id) {
    pingClock.current = { id: data.ping.id, expires: performance.now() + Math.max(0, data.ping.remaining_ms) };
  }
  if (!props.suspended && data.map) {
    const resolved = stream.apply(data.map);
    // The server omits map and selection while another workspace is active.
    // Keep the last confirmed view on return, but discard an invalid transport epoch.
    latest.current = resolved ? {
      map: resolved, selectedAddress: data.selected?.address ?? null,
      selectedNetwork: data.selected_network?.id ?? null, jackAddress: data.jack?.address ?? null,
      entityHost: data.entity?.host ?? null, hasEntity: !!data.entity,
      pingRoute: data.ping_route ?? EMPTY_HOPS, events: data.events ?? EMPTY_EVENTS,
      pingId: data.ping?.id, pingExpiresAt: data.ping ? pingClock.current?.expires : undefined,
      waypoint: data.waypoint ?? null, search: data.search ?? EMPTY_SEARCH,
    } : null;
  }
  useEffect(() => {
    if (!props.suspended && stream.resyncToken !== resyncSent.current) {
      resyncSent.current = stream.resyncToken;
      act('map_resync');
    }
  }, [props.suspended, stream.resyncToken, act]);
  useEffect(() => {
    if (props.suspended || !stream.needsResync) { return; }
    // Lost TGUI messages may include the requested full snapshot itself.
    // Retry only while recovery is pending; ordinary map operation has no poll.
    const timer = window.setInterval(() => {
      if (stream.needsResync) { act('map_resync'); }
    }, 3500);
    return () => window.clearInterval(timer);
  }, [props.suspended, stream.needsResync, stream, act]);
  // Full snapshots can be discarded by TGUI before reaching React. Confirm
  // only a baseline that the stream has actually accepted.
  useEffect(() => {
    const packet = !props.suspended ? data.map : null;
    if (!packet || packet.full === false || packet.full === 0 || !packet.epoch
      || packet.state_revision === undefined || stream.needsResync) { return; }
    // A manual recovery may retransmit the same epoch/revision as the last
    // acknowledged snapshot. That new recovery still needs its own receipt.
    if (acknowledgementGeneration.current !== stream.resyncToken) {
      acknowledgementGeneration.current = stream.resyncToken;
      lastAcknowledged.current = '';
    }
    const key = `${packet.epoch}:${packet.state_revision}`;
    if (lastAcknowledged.current === key) { return; }
    lastAcknowledged.current = key;
    act('map_sync_ack', { epoch: packet.epoch, revision: packet.state_revision });
  }, [props.suspended, data.map, stream, act]);
  return latest.current ? <MapSnapshot input={latest.current} act={act} suspended={props.suspended}
    focusRequest={props.focusRequest} consumeFocusRequest={consumeFocusRequest} onInspect={props.onInspect} />
    : props.suspended ? null : <Box p={1} role="status" color={THEME.muted}>
      {stream.resyncToken ? 'Синхронизация карты после пропущенного обновления…' : 'Ожидание карты сети…'}
      <Button compact ml={1} icon="rotate" content="Обновить карту" onClick={() => {
        stream.requestResync();
        resyncSent.current = stream.resyncToken;
        refreshRecovery((value) => value + 1);
        act('map_resync');
      }} />
                               </Box>;
});

const MapSnapshot = memo(({ input, act, suspended, focusRequest, consumeFocusRequest, onInspect }: { input: MapInput; act: Act; suspended?: boolean } & FocusProps) => {
  const rawNodes = input.map?.nodes ?? EMPTY_NODES;
  const rawEdges = input.map?.edges ?? EMPTY_EDGES;
  const streamed = input.map?.epoch !== undefined;
  // Structural hash excludes mutable activity/access/route/trace fields.
  // The server's topology revision alone is not sufficient: a graph slice can
  // change with search/focus/reveal even when its global revision stays fixed.
  const topologyKey = input.map?.structure_revision === undefined ? JSON.stringify([
    input.map?.revision, rawNodes.map((node) => [node.address, node.type, node.uplink]),
    rawEdges.map((edge) => [edge.id, edge.from, edge.to, edge.kind]),
  ]) : `${input.map.epoch || ''}:${input.map.structure_revision}`;
  const stateKey = input.map?.state_revision;
  const nodes = useSemanticValue(rawNodes, streamed ? undefined : stateKey === undefined ? JSON.stringify(rawNodes.map((node) => [
    node.address, node.type, node.uplink, node.name, node.network, node.sector, node.apc, node.x, node.y, node.z,
    node.online, node.access, node.security, node.entities, node.ice, node.bots, node.police, node.fortress, node.active, node.can_hop, node.dynamic,
  ])) : `${topologyKey}:${stateKey}`);
  const edges = useSemanticValue(rawEdges, streamed ? undefined : stateKey === undefined ? JSON.stringify(rawEdges) : `${topologyKey}:${stateKey}`);
  const gateways = useSemanticValue(input.map?.gateways ?? [], streamed ? undefined : JSON.stringify(input.map?.gateways ?? []));
  const storedRoute = useSemanticValue(input.map?.route ?? null, streamed ? undefined : JSON.stringify(input.map?.route ?? null));
  const geographyValue = useMemo(() => ({ source_sector: input.map?.source_sector, source_z: input.map?.source_z,
    active_sector: input.map?.active_sector, active_z: input.map?.active_z, sectors: input.map?.sectors,
    apc_zones: input.map?.apc_zones, relay_destinations: input.map?.relay_destinations }),
  [input.map?.source_sector, input.map?.source_z, input.map?.active_sector, input.map?.active_z,
    input.map?.sectors, input.map?.apc_zones, input.map?.relay_destinations]);
  const geography = useSemanticValue(geographyValue, streamed ? undefined : JSON.stringify(geographyValue));
  const apcZones = useSemanticValue(input.map?.apc_zones, streamed ? undefined : JSON.stringify(input.map?.apc_zones));
  const map = useMemo(() => input.map ? { ...input.map, ...geography, apc_zones: apcZones, nodes, edges, gateways, route: storedRoute } : null,
    [!!input.map, input.map?.focus, input.map?.revision, input.map?.structure_revision, input.map?.static_revision, stateKey, geography, apcZones, nodes, edges, gateways, storedRoute]);
  const pingRoute = useSemanticValue(input.pingRoute, JSON.stringify(input.pingRoute));
  const events = useSemanticValue(input.events, JSON.stringify(input.events));
  const waypoint = useSemanticValue(input.waypoint, JSON.stringify(input.waypoint));
  const search = useSemanticValue(input.search, JSON.stringify(input.search));
  return (<GraphMap {...input} map={map} topologyKey={topologyKey} suspended={suspended}
    focusRequest={focusRequest} consumeFocusRequest={consumeFocusRequest} onInspect={onInspect}
    pingRoute={pingRoute} events={events} waypoint={waypoint} search={search} act={act} />);
});

const GraphMap = memo((props: MapInput & { topologyKey: string; act: Act } & FocusProps) => {
  const { act, selectedAddress, selectedNetwork, jackAddress, entityHost, hasEntity,
    map, topologyKey, pingRoute, pingId, pingExpiresAt, events, waypoint, search, suspended, focusRequest, consumeFocusRequest, onInspect } = props;
  const viewport = useRef<NetworkViewportHandle>(null);
  const feedback = useNetrunFeedback();
  const latestFeedback = useRef(feedback); latestFeedback.current = feedback;
  const selectionIntent = useRef<{ address: string; action: string; previousNonce?: string; nonce?: string } | null>(null);
  const gatewaysMenu = useRef<HTMLDetailsElement>(null);
  const [projection] = useState(() => new MapProjection());
  const [query, setQuery] = useState('');
  const [focusNearby, setFocusNearby] = useState(false);
  const [disabledTypes, setDisabledTypes] = useState<Record<string, boolean>>({});
  const [legendOpen, setLegendOpen] = useState(false);
  const [showEndpointLinks, setShowEndpointLinks] = useState(true);
  const [pendingCenter, setPendingCenter] = useState<string | null>(null);
  const [searchReset, setSearchReset] = useState(0);
  const nodes = map?.nodes ?? EMPTY_NODES;
  const edges = map?.edges ?? EMPTY_EDGES;
  const placed = projection.update(nodes, edges).nodes;
  const adjacency = useMemo(() => graphAdjacency(nodes, edges), [topologyKey]);
  const liveAdjacency = useMemo(() => graphAdjacency(nodes, edges.filter((edge) => edge.online !== false)), [topologyKey, edges]);
  const byAddress = useMemo(() => new Map(placed.map((node) => [node.address, node])), [placed]);
  const gateways = useMemo(() => new Map((map?.gateways ?? []).map((gateway) => [gateway.id, gateway])), [map?.gateways]);
  const gatewaySectors = useMemo(() => {
    const sectors = new Map<string, string>();
    for (const node of nodes) {
      if (node.network && node.sector) { sectors.set(node.network, node.sector.replace('sector:', 'S')); }
    }
    return sectors;
  }, [nodes]);
  const types = useMemo(() => [...new Set(nodes.map((node) => node.type))].sort(), [nodes]);
  const nearby = useMemo(() => focusNearby && selectedAddress ? graphNeighborhood(adjacency, selectedAddress, 2) : null,
    [focusNearby, selectedAddress, adjacency]);
  const q = query.trim().toLowerCase();
  const visibleNodes = useMemo(() => placed.filter((node) => !disabledTypes[node.type]
    && (!nearby || nearby.has(node.address))
    && (!q || [node.name, node.address, NODE_NAMES[node.type] || node.type, node.sector || '']
      .some((text) => text.toLowerCase().includes(q)))), [placed, disabledTypes, nearby, q]);
  const visibleIds = useMemo(() => new Set(visibleNodes.map((n) => n.address)), [visibleNodes]);
  const visibleEdges = useMemo(() => edges.filter((edge) => visibleIds.has(edge.from) && visibleIds.has(edge.to)), [edges, visibleIds]);
  // End-to-end routes are never geometrically shortened through omitted nodes:
  // the Pixi route layer additionally verifies every adjacent pair against real edges.
  const selectedRoute = map?.route?.reachable ? map.route.route : EMPTY_ADDRESSES;
  const pingAddresses = useMemo(() => pingRoute.filter((hop) => hop.kind === 'node').map((hop) => hop.ref), [pingRoute]);
  const previewSelection = useCallback((address: string, action = 'select') => {
    viewport.current?.previewSelection(address);
    selectionIntent.current = { address, action, previousNonce: latestFeedback.current?.nonce };
  }, []);
  const onSelect = useCallback((address: string) => {
    setPendingCenter(null); previewSelection(address); act('select', { address });
    if (selectedAddress === address) { onInspect?.(); }
  }, [act, previewSelection, onInspect, selectedAddress]);
  const locate = useCallback((address: string, own = false) => {
    setQuery(''); setSearchReset((value) => value + 1); setFocusNearby(false); setDisabledTypes({}); setPendingCenter(address);
    previewSelection(address, own ? 'focus_host' : 'select');
    if (own) { act('focus_host'); } else { act('select', { address }); }
    if (selectedAddress === address) { onInspect?.(); }
  }, [act, previewSelection, onInspect, selectedAddress]);
  useEffect(() => {
    if (suspended || !focusRequest || !consumeFocusRequest?.(focusRequest)) { return; }
    locate(focusRequest.address);
  }, [suspended, focusRequest, consumeFocusRequest, locate]);
  useEffect(() => {
    const intent = selectionIntent.current;
    if (!intent) { return; }
    if (selectedAddress === intent.address) {
      selectionIntent.current = null;
      if (!suspended) { onInspect?.(); }
      return;
    }
    if (!feedback || feedback.action !== intent.action
      || (feedback.action === 'select' && feedback.payload.address !== intent.address)) { return; }
    if (!intent.nonce && feedback.nonce !== intent.previousNonce) { intent.nonce = feedback.nonce; }
    // A correlated receipt confirms immediate selection processing, not the
    // success of delayed movement or machine commands. Those keep their own state.
    if (feedback.phase === 'received' && feedback.nonce === intent.nonce
      && (feedback.action === 'select' || feedback.action === 'focus_host')) {
      viewport.current?.rejectSelection('Узел не выбран. Проверьте доступ и связь.');
      selectionIntent.current = null;
    }
  }, [feedback, selectedAddress, suspended, onInspect]);
  useEffect(() => {
    // A cross-floor selection arrives after the click. Wait for its committed viewport scene.
    if (pendingCenter && selectedAddress === pendingCenter && visibleIds.has(pendingCenter) && viewport.current) {
      viewport.current.center(pendingCenter); setPendingCenter(null);
    }
  }, [pendingCenter, selectedAddress, visibleIds]);

  const onKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.ctrlKey || event.altKey || event.metaKey || !(event.target instanceof Element)
      || !event.target.closest('[data-net-viewport]')
      || event.target.closest('input, textarea, button, select, [contenteditable="true"]')) { return; }
    const key = event.code?.startsWith('Key') ? event.code.slice(3).toLowerCase() : event.key.toLowerCase();
    const directions: Record<string, [number, number]> = { w: [0, -1], s: [0, 1], a: [-1, 0], d: [1, 0] };
    if (!directions[key]) { return; }
    event.preventDefault(); event.stopPropagation();
    const hopping = event.shiftKey && hasEntity;
    const current = byAddress.get(hopping ? entityHost : selectedAddress ?? map?.focus ?? nodes[0]?.address);
    if (!current) { return; }
    const [dx, dy] = directions[key];
    const neighbors = liveAdjacency.get(current.address);
    let best: Placed | null = null;
    let bestScore = Infinity;
    for (const node of visibleNodes) {
      if (node.address === current.address) { continue; }
      const allowed = node.can_hop ?? (node.online && node.access >= 2);
      if (hopping && (!neighbors?.has(node.address) || !allowed)) { continue; }
      const vx = node.px - current.px, vy = node.py - current.py;
      const projection = vx * dx + vy * dy;
      if (projection <= 0 && !hopping) { continue; }
      // A player should still be able to take their only legal link even if
      // the layout put it in another quadrant after a topology change.
      const score = Math.abs(vx * dy - vy * dx) * 2 + Math.hypot(vx, vy)
        + (projection <= 0 ? 100000 : 0);
      if (score < bestScore) { best = node; bestScore = score; }
    }
    if (best) {
      if (hopping) { previewSelection(best.address, 'hop'); act('hop', { address: best.address }); }
      else { onSelect(best.address); }
    }
  };

  if (!map) { return null; }
  const sector = map.sectors?.find((entry) => entry.id === map.active_sector);
  const selectedNode = selectedAddress ? byAddress.get(selectedAddress) : null;
  const relayDestinations = (map.relay_destinations || []).filter((destination) => destination.from === (selectedAddress || entityHost));
  const hiddenTypes = types.filter((type) => disabledTypes[type]).length;
  const docked = !!waypoint || relayDestinations.length > 0 || search?.length > 0;
  return (
    <Box data-net-layout="map" onKeyDown={onKeyDown} style={{
      background: '#08131c', border: `1px solid ${THEME.line}`, borderRadius: '7px',
      display: 'flex', flexDirection: 'column', flex: '1 1 auto', height: '100%',
      minHeight: 0, minWidth: 0, boxSizing: 'border-box', overflow: 'hidden',
    }}>
      <div className="netrun-map-tools">
        {!!map.sectors?.length && (
          <details className="netrun-map-popover netrun-map-sectors">
            <summary title="Сектор и этаж карты">
              <Icon name="layer-group" /> {sector?.name || 'Сектор'}{map.active_z ? ` · Z${map.active_z}` : ''}
            </summary>
            <div className="netrun-map-popover__body">
              {map.sectors.map((entry) => (<Button key={entry.id} compact selected={entry.id === map.active_sector}
                content={entry.name} aria-label={`Сектор: ${entry.name}`} onClick={() => { setPendingCenter(null); act('map_sector', { id: entry.id }); }} />))}
              {!!sector?.levels.length && <span className="netrun-map-popover__break" />}
              {sector?.levels.map((z) => (<Button key={z} compact selected={z === map.active_z}
                content={`Z${z}`} aria-label={`Этаж Z${z}`} onClick={() => { setPendingCenter(null); act('map_sector', { id: sector.id, z }); }} />))}
            </div>
          </details>
        )}
        {!!map.source_sector && (map.source_sector !== map.active_sector || map.source_z !== map.active_z) && <Button compact
          icon="location-crosshairs" tooltip="Вернуться к этажу точки подключения" onClick={() => act('map_sector', { id: map.source_sector, z: map.source_z })}>
          <span className="netrun-sr-only">Точка подключения</span>
                                                                                                              </Button>}
        <Input key={searchReset} width="160px" placeholder="Имя или адрес устройства…" aria-label="Поиск устройств на карте" value={query}
          onInput={(_event, value) => { setPendingCenter(null); setQuery(value); }}
          onEnter={(_event, value) => act('search', { text: value })} />
        <Button compact icon="magnifying-glass" tooltip="Поиск узлов по всей сети" onClick={() => act('search', { text: query })} />
        <span className="netrun-map-tools__sep" />
        {!!hasEntity && !!entityHost && <Button compact icon="street-view" tooltip="Мой узел"
          onClick={() => locate(entityHost, true)}><span className="netrun-sr-only">Мой узел</span>
                                        </Button>}
        <Button compact icon="bullseye" selected={focusNearby} disabled={!selectedAddress}
          tooltip="Рядом: окружение выбранного узла в 2 переходах" onClick={() => { setPendingCenter(null); setFocusNearby(!focusNearby); }}>
          <span className="netrun-sr-only">Рядом</span>
        </Button>
        <Button compact icon="crosshairs" tooltip="К выбранному: центрировать устройство" disabled={!selectedAddress}
          onClick={() => selectedAddress && viewport.current?.center(selectedAddress)}>
          <span className="netrun-sr-only">К выбранному</span>
        </Button>
        <Button compact icon="expand" tooltip="Обзор: все устройства этажа" onClick={() => viewport.current?.fit()}>
          <span className="netrun-sr-only">Обзор</span>
        </Button>
        <span className="netrun-map-tools__sep" />
        <details className="netrun-map-popover netrun-map-filterbar">
          <summary title="Типы устройств на карте">
            <Icon name="filter" /> Фильтры{hiddenTypes ? ` · скрыто ${hiddenTypes}` : ''}
          </summary>
          <div className="netrun-map-popover__body netrun-map-filters">
            <Button compact icon="diagram-project" selected={showEndpointLinks}
              content="Кабели устройств" tooltip="Показать все подключения к APC. Маршруты пакетов и выбранного устройства видны всегда."
              onClick={() => setShowEndpointLinks((shown) => !shown)} />
            <span className="netrun-map-popover__break" />
            {types.map((type) => (<Button key={type} compact selected={!disabledTypes[type]}
              aria-label={`Фильтр: ${NODE_NAMES[type] || type}`} tooltip={NODE_NAMES[type] || type}
              onClick={() => { setPendingCenter(null); setDisabledTypes((old) => ({ ...old, [type]: !old[type] })); }}>
              <GlyphIcon type={type} size={14} /> <span className="netrun-map-type-label">{NODE_NAMES[type] || type}</span>
                                  </Button>))}
            {hiddenTypes > 0 && <Button compact icon="eye" content="Показать все" onClick={() => setDisabledTypes({})} />}
          </div>
        </details>
        <details className="netrun-map-gateways netrun-map-popover" ref={gatewaysMenu} onKeyDown={(event) => {
          if (event.key === 'Escape') { event.currentTarget.open = false; }
        }}>
          <summary>Сети ({(map.gateways ?? []).length}){selectedNetwork ? ` · ${(map.gateways ?? []).find((net) => net.id === selectedNetwork)?.code || ''}` : ''}</summary>
          <div className="netrun-map-gateways__list">
        {(map.gateways ?? []).map((gateway) => (<Button key={gateway.id} compact content={[gateway.code, gatewaySectors.get(gateway.id)].filter(Boolean).join(' · ')}
          icon={gateway.has_key ? 'key' : gateway.access ? 'network-wired' : 'lock'}
          selected={selectedNetwork === gateway.id}
          tooltip={`${gateway.name} · ${ACCESS_NAMES[gateway.access]} · защита ${gateway.security}`}
          style={{ color: gateway.color, flexShrink: 0 }} onClick={() => {
            if (gatewaysMenu.current) { gatewaysMenu.current.open = false; }
            act('select_network', { id: gateway.id });
          }} />))}
          </div>
        </details>
        <Button compact icon="circle-info" selected={legendOpen} tooltip="Легенда карты" onClick={() => setLegendOpen(!legendOpen)} />
        <span style={{ flex: '1 1 auto', minWidth: 0 }} />
        <Box color={THEME.muted} fontSize="10px" style={{ whiteSpace: 'nowrap' }}>
          {visibleNodes.length}/{nodes.length} · текущий этаж
        </Box>
        <Box style={{ flex: '0 0 auto', textAlign: 'right' }}>
          {map.route ? <StoredRouteStatus route={map.route} />
            : <Box color={THEME.muted} fontSize="10px">Путь: —</Box>}
        </Box>
      </div>
      <div className="netrun-map-stage">
        <NetworkViewport ref={viewport} adjacency={adjacency} nodes={visibleNodes} edges={visibleEdges} suspended={suspended}
          gateways={gateways} selected={selectedAddress} jacked={jackAddress}
          apcZones={map.apc_zones}
          entityHost={entityHost} selectedRoute={selectedRoute} waypointRoute={waypoint?.route || EMPTY_ADDRESSES}
          pingRoute={pingAddresses} pingId={pingId} pingExpiresAt={pingExpiresAt} events={events}
          showEndpointLinks={showEndpointLinks} onSelect={onSelect} />
        <SelectionCard node={selectedNode} />
        {docked && <div className="netrun-map-dock" data-net-overlay>
          {!!waypoint && <div className="netrun-map-dock__panel">
            <WaypointRoute wp={waypoint} onClear={() => act('clear_waypoint')} onNext={(address) => act('select', { address })} />
                         </div>}
          {relayDestinations.length > 0 && <div data-net-relay-destinations className="netrun-map-dock__panel">
            <Box color={THEME.muted} fontSize="10px">Реле NTnet · направления перехода</Box>
            {relayDestinations.map((destination) => (<Box key={`${destination.from}:${destination.to}`} mt={0.5} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Icon name="tower-broadcast" color={destination.online ? THEME.good : THEME.bad} />
              <Box style={{ flex: '1 1 auto', minWidth: 0 }}>{destination.name} · {map.sectors?.find((entry) => entry.id === destination.sector)?.name || destination.sector} · Z{destination.z}</Box>
              <Button compact content="Показать" aria-label={`Показать реле ${destination.name}`}
                onClick={() => locate(destination.to)} />
              <Button compact icon="arrow-right" content="Перейти" disabled={!destination.can_hop}
                tooltip={destination.unavailable_reason || 'Перейти через реле'} aria-label={`Перейти к реле ${destination.name}`}
                onClick={() => act('relay_hop', { address: destination.to })} />
                                                     </Box>))}
                                           </div>}
          {search?.length > 0 && <div className="netrun-map-dock__panel" style={{ fontFamily: 'monospace' }}>
            <Box color={THEME.muted} fontSize="10px" mb={0.5}>Найдено в сети: {search.length}
              <Button compact icon="xmark" ml={1} tooltip="Очистить поиск" onClick={() => act('search', { text: '' })} />
            </Box>
            {search.map((result) => (<Box key={result.address} mb={0.5} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Icon name={NODE_ICONS[result.type] || 'circle'} color={result.online ? THEME.accent : THEME.bad} />
              <Box style={{ flex: '1 1 auto', minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {result.name} <Box inline color={THEME.muted} fontSize="9px">{result.address}</Box>
              </Box>
              <Button compact icon="location-arrow" selected={waypoint?.address === result.address}
                tooltip="Проложить маршрут" onClick={() => act('set_waypoint', { address: result.address })} />
              {result.visible && <Button compact icon="diagram-project" tooltip="Выбрать на карте"
                aria-label={`Выбрать узел ${result.name} на карте`} onClick={() => locate(result.address)} />}
                                     </Box>))}
                                 </div>}
                   </div>}
        {!nodes.length ? <div className="netrun-map-notice" data-net-overlay>На этом этаже нет доступных узлов.</div>
          : !visibleNodes.length && <div className="netrun-map-notice" data-net-overlay>
            Все узлы скрыты фильтрами.
            <Button compact ml={1} icon="filter-circle-xmark" content="Сбросить фильтры" onClick={() => {
              setQuery(''); setSearchReset((value) => value + 1); setDisabledTypes({}); setFocusNearby(false);
            }} />
                                    </div>}
        {legendOpen && <MapLegend types={types} entity={hasEntity} onClose={() => setLegendOpen(false)} />}
      </div>
    </Box>
  );
});

/** Floating card of the selected device: identity, status and its live markers. */
const SelectionCard = memo(({ node }: { node: Placed | null | undefined }) => (
  <div className="netrun-map-selectionbar" role="status" data-net-overlay>
    {node ? <GlyphIcon type={node.type} size={18} fill={node.online ? ACCESS_COLORS[node.access] : '#85434a'} offline={!node.online} />
      : <Icon name="hand-pointer" />}
    <strong>{node?.name || 'Выберите устройство на карте'}</strong>
    {node ? <SelectionDetails node={node} /> : <span>Наведите курсор для подсказки · нажмите для просмотра действий</span>}
  </div>
));
const SelectionDetails = ({ node }: { node: Placed }) => (
  <>
    <span>{node.address}</span>
    <span style={{ color: node.online ? THEME.good : THEME.bad }}>{node.online ? 'В сети' : 'Не отвечает'}</span>
    <span>{ACCESS_NAMES[node.access]}</span>
    {!!node.fortress && <span style={{ color: FACTION_COLORS[node.fortress.faction] }}><Icon name="chess-rook" /> крепость</span>}
    {!!node.police && <span style={{ color: FACTION_COLORS.station }}><Icon name="shield-halved" /> полиция</span>}
    {!!node.bots && <span><Icon name="robot" /> ботов: {node.bots}</span>}
  </>
);
const StoredRouteStatus = memo(({ route }: { route: NonNullable<NetMap['route']> }) => (<Box
  color={route.reachable ? THEME.accent : THEME.bad} fontSize="10px" title={`Сохранённый маршрут #${route.revision}`}>
  {route.reachable ? `Путь: ${route.hops} пер. · ${Math.round(route.latency)} мс` : 'Путь: нет связи'}
                                                                                        </Box>));
const WaypointRoute = ({ wp, onClear, onNext }: { wp: Waypoint; onClear: () => void; onNext: (address: string) => void }) => (<Box inline
  color={wp.lost || !wp.reachable ? THEME.bad : THEME.accent} fontSize="10px">
  <Icon name="route" mr={1} />{wp.name} · {wp.lost ? 'цель потеряна' : wp.reachable ? `${wp.hops} переходов` : 'нет маршрута'}
  {!!wp.next && <Button compact ml={1} icon="arrow-right" content="Следующий узел" onClick={() => onNext(wp.next)} />}
  <Button compact icon="xmark" ml={1} onClick={onClear} />
                                                                                                                              </Box>);
