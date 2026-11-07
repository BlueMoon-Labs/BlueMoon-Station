import { classes } from 'common/react';
import { ReactNode, useEffect, useRef } from 'react';

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

/** Цифры 1-9 переключают пункты меню; не мешает вводу текста и сочетаниям с Ctrl/Alt. */
export const useMenuKeys = <T extends string>(items: NtMenuItem<T>[], onSelect: (key: T) => void) => {
  const ref = useRef({ items, onSelect });
  ref.current = { items, onSelect };
  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      if (event.ctrlKey || event.altKey || event.metaKey) return;
      if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)) return;
      const match = /^(?:Digit|Numpad)([1-9])$/.exec(event.code);
      if (!match) return;
      const item = ref.current.items[Number(match[1]) - 1];
      if (!item) return;
      ref.current.onSelect(item.key);
      event.preventDefault();
    };
    window.addEventListener('keydown', onKeyDown, true);
    return () => window.removeEventListener('keydown', onKeyDown, true);
  }, []);
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
        <span className="NtTerm__mark">NT</span>
        <span className="NtTerm__device">{props.device}</span>
        {!!props.status && <div className="NtTerm__status">{props.status}</div>}
      </div>
      {!!props.readout && <div className="NtTerm__readout">{props.readout}</div>}
    </div>
    {props.menu}
    <div className="NtTerm__body">{props.children}</div>
  </div>
);

/** Текстовое меню экрана: [1] Каталог [2] Корзина 3 ... */
export const NtMenu = <T extends string>(props: { items: NtMenuItem<T>[]; selected: T; onSelect: (key: T) => void }) => {
  useMenuKeys(props.items, props.onSelect);
  return (
    <div className="NtTerm__menu">
      {props.items.map((item, index) => (
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
          <span className="NtTerm__menuKey">{index + 1}</span>
          {item.label}
          {!!item.count && <span className="NtTerm__menuCount">{item.count}</span>}
        </span>
      ))}
    </div>
  );
};

/** Рамка с заголовком в верхней линии; справа от заголовка - команды раздела. */
export const NtFrame = (props: { title?: ReactNode; buttons?: ReactNode; className?: string; children: ReactNode }) => (
  <div className={classes(['NtTerm__frame', props.className])}>
    {(!!props.title || !!props.buttons) && (
      <div className="NtTerm__frameHead">
        {!!props.title && <span className="NtTerm__frameTitle">{props.title}</span>}
        <span className="NtTerm__frameRule" />
        {!!props.buttons && <span className="NtTerm__frameButtons">{props.buttons}</span>}
      </div>
    )}
    <div className="NtTerm__frameBody">{props.children}</div>
  </div>
);

/** Крупный показатель: подпись мелко, значение крупно. */
export const NtReadout = (props: { label: string; children: ReactNode; tone?: 'good' | 'bad' | 'warn' }) => (
  <div className={classes(['NtTerm__stat', props.tone && `NtTerm__stat--${props.tone}`])}>
    <div className="NtTerm__statLabel">{props.label}</div>
    <div className="NtTerm__statValue">{props.children}</div>
  </div>
);

/** Строка «подпись ....... значение» с точечным заполнителем. */
export const NtLine = (props: { label: ReactNode; children: ReactNode; tone?: 'good' | 'bad' | 'warn' | 'dim' }) => (
  <div className={classes(['NtTerm__line', props.tone && `NtTerm__line--${props.tone}`])}>
    <span className="NtTerm__lineLabel">{props.label}</span>
    <span className="NtTerm__lineDots" />
    <span className="NtTerm__lineValue">{props.children}</span>
  </div>
);

/** Пустой экран раздела: одна строка по делу. */
export const NtEmpty = (props: { children: ReactNode }) => <div className="NtTerm__empty">{props.children}</div>;
