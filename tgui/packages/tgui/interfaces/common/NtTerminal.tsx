import { classes } from 'common/react';
import { ReactNode, useState } from 'react';

/** Цвет экрана устройства: у каждой машины NT свой. */
export type NtTone = 'supply' | 'exchange' | 'contracts' | 'register' | 'medical' | 'engineering' | 'security' | 'science' | 'service' | 'civil' | 'command';

/** Тон экрана по id отдела экономики. */
export const DEPARTMENT_TONES: Record<string, NtTone> = {
  MED: 'medical',
  ENG: 'engineering',
  SEC: 'security',
  SCI: 'science',
  SRV: 'service',
  CAR: 'supply',
  CIV: 'civil',
  CMD: 'command',
};

export type NtMenuItem<T extends string> = {
  key: T;
  label: string;
  /** Сколько дел ждёт в разделе: показывается рядом с названием */
  count?: number;
};

/** Экран терминала: шапка с названием устройства и строкой состояния, под ней меню и рабочая область. */
export const NtScreen = (props: {
  tone: NtTone;
  device: string;
  status?: ReactNode;
  readout?: ReactNode;
  menu?: ReactNode;
  className?: string;
  children: ReactNode;
}) => (
  <div className={classes(['NtTerm', `NtTerm--${props.tone}`, props.className])}>
    <div className="NtTerm__head">
      <div className="NtTerm__brand">
        <span className="NtTerm__device">{props.device}</span>
        {!!props.status && <div className="NtTerm__status">{props.status}</div>}
      </div>
      {!!props.readout && <div className="NtTerm__readout">{props.readout}</div>}
    </div>
    {props.menu}
    <div className="NtTerm__body">{props.children}</div>
  </div>
);

/** Вкладки экрана; count - сколько дел ждёт в разделе. */
export const NtMenu = <T extends string>(props: { items: NtMenuItem<T>[]; selected: T; onSelect: (key: T) => void }) => (
  <div className="NtTerm__menu">
    {props.items.map((item) => (
      <span
        key={item.key}
        role="button"
        tabIndex={0}
        className={classes(['NtTerm__menuItem', item.key === props.selected && 'NtTerm__menuItem--active'])}
        onClick={() => props.onSelect(item.key)}
        onKeyDown={(event) => {
          if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            props.onSelect(item.key);
          }
        }}>
        {item.label}
        {!!item.count && <span className="NtTerm__menuCount">{item.count}</span>}
      </span>
    ))}
  </div>
);

/**
 * Рамка с заголовком в верхней линии; справа от заголовка - команды раздела. minor - карточка элемента внутри раздела.
 * help - пояснение к разделу: свёрнуто за кнопкой "?", чтобы не отодвигать рабочую часть.
 */
export const NtFrame = (props: { title?: ReactNode; buttons?: ReactNode; help?: ReactNode; className?: string; minor?: boolean; children: ReactNode }) => {
  const [helpOpen, setHelpOpen] = useState(false);
  const hasHead = !!props.title || !!props.buttons || !!props.help;
  return (
    <div className={classes(['NtTerm__frame', props.minor && 'NtTerm__frame--minor', props.className])}>
      {hasHead && (
        <div className="NtTerm__frameHead">
          {!!props.title && <span className="NtTerm__frameTitle">{props.title}</span>}
          <span className="NtTerm__frameRule" />
          {!!props.buttons && <span className="NtTerm__frameButtons">{props.buttons}</span>}
          {!!props.help && (
            <span
              role="button"
              tabIndex={0}
              title={helpOpen ? 'Скрыть пояснение' : 'Как это работает'}
              className={classes(['NtTerm__helpToggle', helpOpen && 'NtTerm__helpToggle--open'])}
              onClick={() => setHelpOpen(!helpOpen)}
              onKeyDown={(event) => {
                if (event.key === 'Enter' || event.key === ' ') {
                  event.preventDefault();
                  setHelpOpen(!helpOpen);
                }
              }}>
              ?
            </span>
          )}
        </div>
      )}
      {helpOpen && <div className="NtTerm__help">{props.help}</div>}
      <div className="NtTerm__frameBody">{props.children}</div>
    </div>
  );
};

/** Крупный показатель: подпись мелко, значение крупно. */
export const NtReadout = (props: { label: string; children: ReactNode; tone?: 'good' | 'bad' | 'warn' }) => (
  <div className={classes(['NtTerm__stat', props.tone && `NtTerm__stat--${props.tone}`])}>
    <div className="NtTerm__statLabel">{props.label}</div>
    <div className="NtTerm__statValue">{props.children}</div>
  </div>
);

/** Строка "подпись - значение": значение прижато вправо. */
export const NtLine = (props: { label: ReactNode; children: ReactNode; tone?: 'good' | 'bad' | 'warn' | 'dim' }) => (
  <div className={classes(['NtTerm__line', props.tone && `NtTerm__line--${props.tone}`])}>
    <span className="NtTerm__lineLabel">{props.label}</span>
    <span className="NtTerm__lineDots" />
    <span className="NtTerm__lineValue">{props.children}</span>
  </div>
);

/** График цены: линия с заливкой, пунктир базовой цены, крайние значения подписаны. Цвет - по тренду. */
export const NtChart = (props: { values: number[]; base?: number; height?: number; format?: (value: number) => string }) => {
  const { values, base, height = 90, format = (value) => value.toFixed(2) } = props;
  if (values.length < 2) {
    return <div className="NtTerm__chart NtTerm__chart--empty" style={{ height: `${height}px` }}>история появится через минуту</div>;
  }
  const all = base !== undefined ? [...values, base] : values;
  const min = Math.min(...all);
  const max = Math.max(...all);
  const span = max - min || 1;
  const w = 100;
  const h = 40;
  const y = (value: number) => h - 2 - ((value - min) / span) * (h - 4);
  const x = (index: number) => (index / (values.length - 1)) * w;
  const line = values.map((value, index) => `${x(index).toFixed(2)},${y(value).toFixed(2)}`).join(' ');
  const rising = values[values.length - 1] >= values[0];
  return (
    <div className={classes(['NtTerm__chart', rising ? 'NtTerm__chart--up' : 'NtTerm__chart--down'])} style={{ height: `${height}px` }}>
      <svg viewBox={`0 0 ${w} ${h}`} preserveAspectRatio="none" width="100%" height="100%" aria-hidden="true">
        <polygon points={`0,${h} ${line} ${w},${h}`} className="NtTerm__chartFill" />
        {base !== undefined && <line x1={0} x2={w} y1={y(base)} y2={y(base)} className="NtTerm__chartBase" vectorEffect="non-scaling-stroke" />}
        <polyline points={line} className="NtTerm__chartLine" vectorEffect="non-scaling-stroke" />
      </svg>
      <span className="NtTerm__chartMax">{format(Math.max(...values))}</span>
      <span className="NtTerm__chartMin">{format(Math.min(...values))}</span>
      {base !== undefined && (
        <span className="NtTerm__chartBaseLabel" style={{ top: `${(y(base) / h) * 100}%` }}>
          база {format(base)}
        </span>
      )}
    </div>
  );
};

/** Пустой экран раздела: одна строка по делу. */
export const NtEmpty = (props: { children: ReactNode }) => <div className="NtTerm__empty">{props.children}</div>;
