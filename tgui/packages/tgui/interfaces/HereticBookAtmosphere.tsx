import { CSSProperties, useEffect, useRef, useState } from 'react';

import { resolveAsset } from '../assets';

export type BookPresentation = 'living' | 'muted' | 'plain';

type AtmosphereProps = {
  path: string;
  presentation: BookPresentation;
  reducedMotion: boolean;
};

/** Книги мастерской Мансуса: общий переплёт, бумага и поле владельца (HereticBookWorkshop.scss). Значение - листы редких событий assets/heretic-<путь>-anim-<лист>.webp. */
export const bookWorkshopSheets: Record<string, readonly string[]> = {
  Lock: ['key'],
  Void: ['frost'],
  Lead: ['smoke'],
  Hammer: ['glow', 'sparks'],
  Ash: ['flame', 'ember'],
  Rust: ['gear', 'drop'],
  Flesh: ['flap', 'veins'],
  Blade: ['glint'],
  Moon: ['smile'],
  Cosmic: ['pricks'],
  Tide: ['flood'],
  Glass: [],
  Blood: ['drop'],
  Echo: ['staff', 'answer'],
  Sand: ['trickle', 'gust'],
  Wax: ['drip', 'face'],
  Spirit: ['name', 'damp'],
  Dance: ['steps', 'notes'],
};
export const isWorkshopBook = (path: string) => Object.hasOwn(bookWorkshopSheets, path);

const interactions: Record<string, string> = {
  Flesh: 'Качнуть коренной зуб на жильной нити',
  Ash: 'Качнуть уголёк в проволочной оплётке',
  Cosmic: 'Качнуть латунный отвес на нитке',
  Rust: 'Качнуть ржавую гайку на проволоке',
  Void: 'Качнуть осколок стекла на нитке',
  Blade: 'Качнуть темляк с синей кистью',
  Moon: 'Качнуть пустой медальон на цепочке',
  Lock: 'Качнуть ключ на нитке',
  Tide: 'Качнуть свинцовый лот на лине',
  Glass: 'Качнуть стеклорез на крючке',
  Blood: 'Качнуть ланцет с каплей на острие',
  Echo: 'Качнуть камертон на вощёной нитке',
  Sand: 'Качнуть песочные часики на ремешке',
  Wax: 'Качнуть пару свечей на общем фитиле',
  Spirit: 'Качнуть немой колокольчик на крепе',
  Dance: 'Качнуть камертон на алой ленте',
  Dusk: 'Повернуть треснувший нимб на застёжке',
  Lead: 'Качнуть стреляную гильзу на цепочке',
  Hammer: 'Качнуть кованый молоточек на цепи',
};

// Частицы закреплены за переплётом: нажатия не создают новых элементов.
type Mote = { x: number; y: number; size: number; delay: number; time: number };
type MoteStyle = 'rise' | 'fall' | 'drift' | 'twinkle' | 'ring';

/** Чем путь дышит у кромок книги: угли поднимаются, снег падает, звёзды мерцают. */
const moteKinds: Record<string, { style: MoteStyle; shape: 'dot' | 'flake' | 'spark' | 'drop' | 'petal' | 'ring' | 'shard' | 'wisp' | 'feather' }> = {
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
  Dusk: { style: 'fall', shape: 'feather' },
  Lead: { style: 'fall', shape: 'spark' },
  Hammer: { style: 'rise', shape: 'spark' },
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
  feather: <path d="M10.6 1.2c1.6 3.4.8 7.6-2.2 10.8L6.6 14l-.5 1.6-.6-.3.6-1.6.2-2.6C5.2 7.8 7 3.6 10.6 1.2Zm-4.2 12 3-8.4" strokeWidth=".6" />,
};

/** Сбой Сумрака: у заголовка под курсором тень на миг отстаёт и двоится. */
const duskHeadings = 'h1, h2, h3, .HereticBook__bookTitle, .HereticBook__chapterTitle, .HereticBook__groupTitle';
const duskSlip = (heading: HTMLElement) => {
  if (typeof heading.animate !== 'function' || heading.getAnimations?.().some((animation) => animation.id === 'dusk-slip')) return;
  if (Math.random() < 0.25) return;
  const dx = (Math.random() < 0.5 ? -1 : 1) * (3 + Math.random() * 2);
  const slip = heading.animate([
    { textShadow: '0 0 0 transparent, 0 0 0 transparent', transform: 'translateX(0)' },
    { textShadow: `${dx}px 0 0 #dcdbc085, ${-dx * 0.5}px 1px 0 #05030c`, transform: `translateX(${dx * -0.2}px)`, offset: 0.18 },
    { textShadow: `${dx * 1.7}px 1px 1px #dcdbc04d, 0 0 0 transparent`, transform: 'translateX(0)', offset: 0.5 },
    { textShadow: '0 0 0 transparent, 0 0 0 transparent', transform: 'translateX(0)' },
  ], { duration: 700, easing: 'ease-out' });
  slip.id = 'dusk-slip';
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
  const root = useRef<HTMLDivElement>(null);
  useEffect(() => () => {
    if (timer.current !== null) clearTimeout(timer.current);
  }, []);
  useEffect(() => {
    const book = root.current?.closest('.HereticBook');
    if (path !== 'Dusk' || presentation !== 'living' || reducedMotion || !book) return;
    const glitch = (event: Event) => {
      const heading = (event.target as Element | null)?.closest?.(duskHeadings);
      if (heading instanceof HTMLElement && book.contains(heading)) duskSlip(heading);
    };
    book.addEventListener('pointerover', glitch);
    return () => book.removeEventListener('pointerover', glitch);
  }, [path, presentation, reducedMotion]);
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
    <div ref={root} className={`HereticBookAtmosphere HereticBookAtmosphere--${path} HereticBookAtmosphere--${presentation}${isWorkshopBook(path) ? ' HereticBookAtmosphere--workshop' : ''}${reducedMotion ? ' HereticBookAtmosphere--still' : ''}${reacting ? ' HereticBookAtmosphere--reacting' : ''}`} data-reacting={reacting}>
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
