import { Button } from '../../components';
import { GLYPH_INK_CSS, glyphSvgPaths } from './nodeGlyphs';
import { edgeColor, edgeWidth } from './pixiPrimitives';
import { PROCESS_GLYPHS, processSvgPaths } from './processGlyphs';
import { ACCESS_COLORS, ACCESS_NAMES, FACTION_COLORS, NODE_NAMES, PACKET_COLORS, PACKET_NAMES } from './types';

const hex = (value: number) => `#${value.toString(16).padStart(6, '0')}`;

/** The map's own device silhouette and pictogram, for legends, filters and cards. */
export const GlyphIcon = (props: { type: string; size?: number; fill?: string; border?: string; offline?: boolean }) => {
  const { type, size = 16, fill = '#8fb3c4', border = '#4f86a3', offline = false } = props;
  const paths = glyphSvgPaths(type);
  return (
    <svg className="netrun-glyph-icon" width={size} height={size} viewBox="-1.2 -1.2 2.4 2.4" aria-hidden="true" focusable="false">
      <path d={paths.body} fill={fill} stroke={border} strokeWidth={0.12} strokeLinejoin="round" />
      {!!paths.strokes && <path d={paths.strokes} fill="none" stroke={GLYPH_INK_CSS} strokeWidth={0.13} strokeLinecap="round" strokeLinejoin="round" />}
      {!!paths.fills && <path d={paths.fills} fill={GLYPH_INK_CSS} />}
      {offline && <path d={paths.slash} stroke={GLYPH_INK_CSS} strokeWidth={0.16} strokeLinecap="round" />}
    </svg>
  );
};

const LinkSample = (props: { kind: string; online?: boolean }) => (
  <svg width="34" height="10" aria-hidden="true">
    <line x1="2" y1="5" x2="32" y2="5" stroke={hex(edgeColor(props.kind, props.online !== false))}
      strokeWidth={Math.max(1, edgeWidth(props.kind) * .9)} strokeOpacity={props.online === false ? .5 : .9}
      strokeDasharray={props.online === false ? '3 3' : undefined} strokeLinecap="round" />
  </svg>
);

const Dot = (props: { color: string; ring?: boolean }) => (
  <svg width="12" height="12" aria-hidden="true">
    {props.ring ? <circle cx="6" cy="6" r="4.5" fill="none" stroke={props.color} strokeWidth="2" />
      : <circle cx="6" cy="6" r="4" fill={props.color} />}
  </svg>
);

const Badge = (props: { shape: 'bots' | 'police' | 'entity' | 'ice' | 'fortress' }) => props.shape !== 'fortress' ? (
  <svg width="18" height="18" viewBox="-1.4 -1.4 2.8 2.8" aria-hidden="true">
    <path d={processSvgPaths(props.shape).body} fill={hex(PROCESS_GLYPHS[props.shape].color)} stroke="#07151f" strokeWidth=".25" />
    <path d={processSvgPaths(props.shape).ink} fill="none" stroke="#10212b" strokeWidth=".16" strokeLinecap="round" strokeLinejoin="round" />
  </svg>
) : (
  <svg width="16" height="16" viewBox="0 0 16 16" aria-hidden="true">
    {props.shape === 'fortress' && <>
      <circle cx="8" cy="8" r="5.5" fill="none" stroke={FACTION_COLORS.station} strokeWidth="2" />
      <rect x="6.5" y="0.5" width="3" height="3" fill={FACTION_COLORS.station} />
      <rect x="6.5" y="12.5" width="3" height="3" fill={FACTION_COLORS.station} />
      <rect x="0.5" y="6.5" width="3" height="3" fill={FACTION_COLORS.station} />
      <rect x="12.5" y="6.5" width="3" height="3" fill={FACTION_COLORS.station} />
                                   </>}
  </svg>
);

/** Toggleable map legend: every symbol the map draws, nothing permanently on screen. */
export const MapLegend = (props: { types: string[]; entity: boolean; onClose: () => void }) => (
  <div className="netrun-map-legend" data-net-overlay role="dialog" aria-label="Легенда карты">
    <div className="netrun-map-legend__head">
      <strong>Легенда</strong>
      <Button compact icon="xmark" tooltip="Скрыть легенду" onClick={props.onClose} />
    </div>
    {!!props.types.length && (
      <section>
        <h4>Устройства на этаже</h4>
        <div className="netrun-map-legend__grid">
          {props.types.map((type) => (
            <span key={type}><GlyphIcon type={type} size={18} /> {NODE_NAMES[type] || type}</span>
          ))}
        </div>
      </section>
    )}
    <section>
      <h4>Заливка — ваш доступ</h4>
      <div className="netrun-map-legend__grid">
        {ACCESS_NAMES.map((name, i) => <span key={name}><Dot color={ACCESS_COLORS[i]} /> {name}</span>)}
        <span><GlyphIcon type="camera" size={18} fill="#85434a" offline /> не отвечает</span>
      </div>
    </section>
    <section>
      <h4>Связи</h4>
      <div className="netrun-map-legend__grid">
        <span><LinkSample kind="apc" /> APC ↔ APC</span>
        <span><LinkSample kind="relay" /> реле NTnet</span>
        <span><LinkSample kind="endpoint" /> устройство ↔ APC</span>
        <span><LinkSample kind="apc" online={false} /> связь нарушена</span>
      </div>
      <p className="netrun-map-legend__hint">Тонкие кабели устройств видны по умолчанию; их можно скрыть в фильтрах. Яркий след показывает реальный путь отправленного пакета.</p>
    </section>
    <section>
      <h4>Пакеты в полёте</h4>
      <div className="netrun-map-legend__grid">
        {Object.entries(PACKET_NAMES).map(([kind, name]) => <span key={kind}><Dot color={PACKET_COLORS[kind]} ring={kind === 'fail'} /> {name}</span>)}
      </div>
    </section>
    <section>
      <h4>Процессы и укрепления</h4>
      <div className="netrun-map-legend__grid">
        <span><Badge shape="ice" /> ICE</span>
        <span><Badge shape="entity" /> сущности</span>
        <span><Badge shape="bots" /> боты</span>
        <span><Badge shape="police" /> сетевая полиция</span>
        <span><Badge shape="fortress" /> крепость (зубцы — стены)</span>
      </div>
    </section>
    <p className="netrun-map-legend__hint">
      ЛКМ — выбрать · потянуть — двигать · колесо — масштаб · WASD — выбор соседа{props.entity ? ' · Shift+WASD — переход' : ''}
    </p>
  </div>
);
