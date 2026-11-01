/* eslint-disable react/no-unused-prop-types -- the controller reads its immutable presentation snapshot. */
import { forwardRef, memo, useId, useImperativeHandle, useLayoutEffect, useMemo, useRef, useState } from 'react';

import { Button, Icon } from '../../components';
import type { GraphOverlay } from './graphPresentation';
import { GraphScene, PlacedNode } from './graphScene';
import { clamp } from './graphViewport';
import { NetEdge, NODE_NAMES } from './types';
import { NetworkViewportController, SelectionFeedback, ViewportHover, ViewportHUD, ViewportSnapshot, ViewportStatus } from './viewportController';

export type NetworkViewportHandle = { center: (address: string) => void; fit: () => void;
  previewSelection: (address: string) => void; rejectSelection: (message: string) => void };
export type NetworkViewportProps = GraphOverlay & {
  nodes: PlacedNode[];
  edges: NetEdge[];
  adjacency: Map<string, Set<string>>;
  suspended?: boolean;
  onSelect: (address: string) => void;
};

/** Pixi draws the map; the small React HUD retains native focus and readable status. */
export const NetworkViewport = memo(forwardRef<NetworkViewportHandle, NetworkViewportProps>((props, externalRef) => {
  const host = useRef<HTMLDivElement>(null);
  const latest = useRef(props); latest.current = props;
  const hintId = useId();
  const priorScene = useRef<GraphScene | null>(null);
  const scene = useMemo(() => {
    const graph = new GraphScene(); graph.update(props.nodes, props.edges, priorScene.current); priorScene.current = graph; return graph;
  }, [props.nodes, props.edges]);
  const snapshot = useMemo<ViewportSnapshot>(() => ({ scene, overlay: props, suspended: !!props.suspended }), [scene, props]);
  const [status, setStatus] = useState<ViewportStatus>({ phase: props.suspended ? 'paused' : 'loading' });
  const [hud, setHUD] = useState<ViewportHUD>({ nodes: scene.nodes.length, zoom: 85 });
  const [hover, setHover] = useState<ViewportHover>(null);
  const [selectionFeedback, setSelectionFeedback] = useState<SelectionFeedback>(null);
  const [controller] = useState(() => new NetworkViewportController(snapshot, {
    onStatus: setStatus, onHUD: setHUD, onHover: setHover,
    onSelectionFeedback: setSelectionFeedback,
    onSelect: (address) => latest.current.onSelect(address),
  }));
  useImperativeHandle(externalRef, () => ({ center: controller.center, fit: controller.fit,
    previewSelection: controller.previewSelection, rejectSelection: controller.rejectSelection }), [controller]);
  useLayoutEffect(() => {
    if (!host.current) { return; }
    controller.attach(host.current);
    return () => controller.detach();
  }, [controller]);
  useLayoutEffect(() => { controller.update(snapshot); }, [controller, snapshot]);

  const hoveredNode = hover ? scene.byAddress.get(hover.address) : null;
  const width = host.current?.clientWidth || 720, height = host.current?.clientHeight || 480;
  return (
    <div ref={host} className="netrun-viewport" data-net-viewport data-net-renderer="pixi"
      data-net-runtime={status.phase} role="application" aria-label="Карта сети"
      aria-describedby={hintId} aria-busy={status.phase === 'loading'} tabIndex={0}>
      <span id={hintId} className="netrun-viewport__sr-only">
        WASD — выбор узла. Shift и WASD — переход сущности. Перетаскивание — движение карты, колесо — масштаб.
      </span>
      {status.phase === 'loading' && <div data-net-overlay className="netrun-viewport__state" role="status">
        <Icon name="circle-notch" spin /><strong>{status.message || 'Запускаем карту сети…'}</strong>
                                     </div>}
      {status.phase === 'error' && <div data-net-overlay className="netrun-viewport__state" role="alert">
        <Icon name="display" /><strong>Карта временно недоступна</strong>
        <p>{status.message}</p>
        <Button icon="rotate" content="Повторить запуск карты" onClick={() => controller.retry()} />
                                   </div>}
      {status.phase === 'empty' && <div data-net-overlay className="netrun-viewport__state" role="status">
        <Icon name="diagram-project" /><strong>Нет узлов для отображения</strong>
        <p>Выберите другой этаж или измените фильтры карты.</p>
                                   </div>}
      {status.phase === 'ready' && selectionFeedback && <div data-net-selection-feedback
        className={`netrun-viewport__selection netrun-viewport__selection--${selectionFeedback.phase}`}
        role="status" aria-live="polite">{selectionFeedback.message}
                                                        </div>}
      {status.phase === 'ready' && hover && hoveredNode && <div role="tooltip" className="netrun-viewport__tooltip"
        style={{ left: clamp(hover.x + 14, 8, Math.max(8, width - 226)), top: clamp(hover.y + 12, 8, Math.max(8, height - 118)) }}>
        <strong>{hoveredNode.name}</strong>
        <code>{hoveredNode.address}</code>
        <span className={hoveredNode.online ? 'netrun-viewport__online' : 'netrun-viewport__offline'}>
          {NODE_NAMES[hoveredNode.type] || hoveredNode.type} · {hoveredNode.online ? 'В сети' : 'Не отвечает'}
        </span>
        <span>{hoveredNode.sector || ''}{hoveredNode.ice ? ` · ICE: ${hoveredNode.ice}` : ''}{hoveredNode.entities ? ` · процессы: ${hoveredNode.entities}` : ''}</span>
        <span>X {hoveredNode.x} · Y {hoveredNode.y} · Z {hoveredNode.z ?? '—'}</span>
                                                           </div>}
    </div>
  );
}));
