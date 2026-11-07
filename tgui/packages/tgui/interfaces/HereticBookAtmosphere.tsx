import { CSSProperties, useEffect, useRef, useState } from 'react';

import { resolveAsset } from '../assets';

export type BookPresentation = 'living' | 'muted' | 'plain';

type AtmosphereProps = {
  path: string;
  presentation: BookPresentation;
  reducedMotion: boolean;
};

const interactions: Record<string, string> = {
  Flesh: 'Разбудить глаз в переплёте',
  Ash: 'Раздуть уголь на обложке',
  Cosmic: 'Отпустить комету',
  Rust: 'Повернуть ржавую шестерню',
  Void: 'Коснуться ледяного кристалла',
  Blade: 'Провести пальцем по лезвию',
  Moon: 'Коснуться зеркальной капли',
  Lock: 'Повернуть ключ в переплёте',
  Tide: 'Раскачать затонувший колокол',
  Glass: 'Преломить свет в застёжке',
  Blood: 'Перевернуть алую ампулу',
  Echo: 'Коснуться струн погребальной лиры',
  Sand: 'Перевернуть часы в переплёте',
  Wax: 'Прикрыть огонёк ладонью',
  Spirit: 'Позвать душу к фонарю',
  Dance: 'Завести шкатулку с танцовщицей',
};

// Частицы закреплены за переплётом: нажатия не создают новых элементов.
type Mote = { x: number; y: number; size: number; delay: number; time: number };
type MoteStyle = 'rise' | 'fall' | 'drift' | 'twinkle' | 'ring';

/** Чем путь дышит у кромок книги: угли поднимаются, снег падает, звёзды мерцают. */
const moteKinds: Record<string, { style: MoteStyle; shape: 'dot' | 'flake' | 'spark' | 'drop' | 'petal' | 'ring' | 'shard' | 'wisp' }> = {
  Ash: { style: 'rise', shape: 'dot' },
  Rust: { style: 'fall', shape: 'shard' },
  Flesh: { style: 'drift', shape: 'drop' },
  Void: { style: 'fall', shape: 'flake' },
  Blade: { style: 'twinkle', shape: 'spark' },
  Moon: { style: 'drift', shape: 'dot' },
  Cosmic: { style: 'twinkle', shape: 'spark' },
  Lock: { style: 'drift', shape: 'dot' },
  Tide: { style: 'rise', shape: 'ring' },
  Glass: { style: 'twinkle', shape: 'shard' },
  Blood: { style: 'fall', shape: 'drop' },
  Echo: { style: 'ring', shape: 'ring' },
  Sand: { style: 'fall', shape: 'dot' },
  Wax: { style: 'rise', shape: 'wisp' },
  Spirit: { style: 'rise', shape: 'wisp' },
  Dance: { style: 'fall', shape: 'petal' },
};

// Кромки: внешние поля и корешок, текст страниц не перекрывается.
const lanes = [2.2, 4.4, 49.2, 50.8, 95.6, 97.8];
const motes: Mote[] = Array.from({ length: 18 }, (_, index) => ({
  x: lanes[index % lanes.length] + ((index * 7) % 5) * .25 - .5,
  y: (index * 37) % 92 + 4,
  size: 3 + (index * 5) % 4,
  delay: -((index * 1.7) % 9),
  time: 7 + (index * 3) % 6,
}));

const moteShapes = {
  dot: <circle cx="8" cy="8" r="3.2" />,
  flake: <path d="M8 1.5v13M2.4 4.8l11.2 6.4M2.4 11.2l11.2-6.4M8 1.5 6.6 3M8 1.5 9.4 3M8 14.5 6.6 13M8 14.5l1.4-1.5" fill="none" strokeWidth="1.1" />,
  spark: <path d="M8 1 9.2 6.8 15 8 9.2 9.2 8 15 6.8 9.2 1 8 6.8 6.8Z" />,
  drop: <path d="M8 2c1.2 3.6 4 5.6 4 8.4a4 4 0 0 1-8 0C4 7.6 6.8 5.6 8 2Z" />,
  petal: <path d="M8 2c4 2 5 7 0 12C3 9 4 4 8 2Z" />,
  ring: <circle cx="8" cy="8" r="5" fill="none" strokeWidth="1.1" />,
  shard: <path d="m8 1.5 4.5 6-2.5 7-5-3.5Z" />,
  wisp: <path d="M8 15c-3-3-1-6 0-8s1-4-1-6c4 1 5 5 3 8-1 2-1 4-2 6Z" />,
};

const Motes = ({ path, full }: { path: string; full: boolean }) => {
  const kind = moteKinds[path];
  if (!kind) return null;
  return (
    <div className={`HereticBookAtmosphere__motes HereticBookAtmosphere__motes--${kind.style}`}>
      {(full ? motes : motes.slice(0, 4)).map((mote, index) => (
        <svg
          key={index}
          className="HereticBookAtmosphere__mote"
          viewBox="0 0 16 16"
          style={{ left: `${mote.x}%`, top: `${mote.y}%`, width: mote.size * 2.4, height: mote.size * 2.4, animationDelay: `${mote.delay}s`, animationDuration: `${mote.time}s` } as CSSProperties}
          aria-hidden="true"
          focusable="false"
        >
          {moteShapes[kind.shape]}
        </svg>
      ))}
    </div>
  );
};

/** Каптал: шёлковая лента у головки и хвостика корешка. */
const Headband = ({ position }: { position: 'top' | 'bottom' }) => <i className={`HereticBookAtmosphere__headband HereticBookAtmosphere__headband--${position}`} aria-hidden="true" />;

const MaterialAtmosphere = ({ path, presentation, reducedMotion }: AtmosphereProps) => {
  const [reacting, setReacting] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => () => {
    if (timer.current !== null) clearTimeout(timer.current);
  }, []);
  const interact = () => {
    if (timer.current !== null) return;
    setReacting(true);
    timer.current = setTimeout(() => {
      timer.current = null;
      setReacting(false);
    }, reducedMotion ? 900 : presentation === 'muted' ? 1200 : 2800);
  };
  const full = presentation === 'living';
  const art = (kind: 'corner' | 'clasp') => ({ backgroundImage: `url("${resolveAsset(`heretic-${kind}-${path.toLowerCase()}.webp`)}")` });
  return (
    <div className={`HereticBookAtmosphere HereticBookAtmosphere--${path} HereticBookAtmosphere--${presentation}${reducedMotion ? ' HereticBookAtmosphere--still' : ''}${reacting ? ' HereticBookAtmosphere--reacting' : ''}`} data-reacting={reacting}>
      <Motes path={path} full={full} />
      <Headband position="top" />
      <Headband position="bottom" />
      {(['tl', 'tr', 'bl', 'br'] as const).map((position) => <i key={position} className={`HereticBookAtmosphere__corner HereticBookAtmosphere__corner--${position}`} style={art('corner')} aria-hidden="true" />)}
      <button type="button" className="HereticBookAtmosphere__toy" style={art('clasp')} aria-label={interactions[path]} title={interactions[path]} aria-pressed={reacting} onClick={interact} />
      <div className="HereticBookAtmosphere__burst" aria-hidden="true">
        {Array.from({ length: 10 }, (_, index) => <i key={index} style={{ '--angle': `${index * 36 + 8}deg`, '--reach': `${26 + (index % 3) * 12}px`, animationDelay: `${(index % 4) * 40}ms` } as CSSProperties} />)}
      </div>
    </div>
  );
};

export const HereticBookAtmosphere = (props: AtmosphereProps) => {
  if (props.presentation === 'plain' || !interactions[props.path]) return null;
  return <MaterialAtmosphere key={`${props.path}-${props.presentation}-${props.reducedMotion}`} {...props} />;
};
