import { createContext, CSSProperties, ReactNode, useContext, useLayoutEffect, useRef } from 'react';

import { resolveAsset } from '../assets';
import { isWorkshopBook } from './HereticBookAtmosphere';

/** Путь раскрытой книги: от него зависят концовки-сцены. */
export const BookPathContext = createContext('Unbound');

/** Перо обводит рисунок при появлении: длина штриха задаётся каждой линии отдельно. */
const DrawnSvg = ({ className, viewBox, strokeWidth = '1.3', children }: { className: string; viewBox: string; strokeWidth?: string; children: ReactNode }) => {
  const ref = useRef<SVGSVGElement>(null);
  useLayoutEffect(() => {
    const strokes = ref.current?.querySelectorAll<SVGGeometryElement>('path, circle, ellipse, rect');
    strokes?.forEach((stroke, index) => {
      if (typeof stroke.getTotalLength !== 'function' || stroke.getAttribute('stroke-dasharray') || stroke.getAttribute('pathLength')) return;
      // Линии со своей анимацией пути (пламя, лучи) не перебиваем.
      if (getComputedStyle(stroke).animationName !== 'none') return;
      const length = Math.ceil(stroke.getTotalLength());
      stroke.style.setProperty('--ink-length', `${length}`);
      stroke.style.setProperty('--ink-delay', `${Math.min(index * 45, 1100)}ms`);
      stroke.style.setProperty('--ink-time', `${Math.min(1400, Math.max(450, length * 2.2))}ms`);
      stroke.setAttribute('data-ink', '');
    });
  }, []);
  return (
    <svg ref={ref} className={className} viewBox={viewBox} fill="none" stroke="currentColor" strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" focusable="false">
      <defs>
        <pattern id="heretic-hatch" width="3.4" height="3.4" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
          <path d="M0 0v3.4" stroke="currentColor" strokeWidth=".55" strokeOpacity=".75" />
        </pattern>
        <pattern id="heretic-crosshatch" width="4" height="4" patternUnits="userSpaceOnUse" patternTransform="rotate(30)">
          <path d="M0 0v4M0 0h4" stroke="currentColor" strokeWidth=".45" strokeOpacity=".6" />
        </pattern>
        <pattern id="heretic-stipple" width="5" height="5" patternUnits="userSpaceOnUse">
          <circle cx="1.2" cy="1.2" r=".5" fill="currentColor" stroke="none" />
          <circle cx="3.7" cy="3.6" r=".38" fill="currentColor" stroke="none" />
        </pattern>
        <radialGradient id="heretic-halo-fade">
          <stop offset="0" stopColor="#fff" stopOpacity=".9" />
          <stop offset=".7" stopColor="#fff" stopOpacity=".25" />
          <stop offset="1" stopColor="#fff" stopOpacity="0" />
        </radialGradient>
        <mask id="heretic-halo-mask"><rect width="100%" height="100%" fill="url(#heretic-halo-fade)" /></mask>
      </defs>
      <rect className="HereticBook__stipple" width="100%" height="100%" fill="url(#heretic-stipple)" stroke="none" mask="url(#heretic-halo-mask)" />
      {children}
    </svg>
  );
};

/** Гравюра пути: чёрно-белый оттиск служит маской и красится в чернила книги. */
export const HereticIllumination = ({ path }: { path: string }) => (
  <div
    className={`HereticBook__illumination HereticBook__illumination--${path}`}
    style={{ '--engraving': `url("${resolveAsset(`heretic-plate-${path.toLowerCase()}.webp`)}")` } as CSSProperties}
    aria-hidden="true" />
);

/** Сумрак: на полях опалённого пергамента редкие события руки и огня - клякса, тление кромки, набросок, глаз-подпалина, потёк туши. */
const duskSheets = ['blot', 'drip', 'ember', 'eye', 'line', 'wing'] as const;
const duskSheetStyle = () => Object.fromEntries(duskSheets.map((sheet) => [`--dusk-anim-${sheet}`, `url("${resolveAsset(`heretic-dusk-anim-${sheet}.webp`)}")`])) as CSSProperties;
const DuskPageLife = () => (
  <div className="HereticBook__duskLife" style={duskSheetStyle()} aria-hidden="true">
    <i className="HereticBook__duskEye" />
    <div className="HereticBook__duskMargin">
      <i className="HereticBook__duskEmber" />
      <i className="HereticBook__duskDrip" />
      <i className="HereticBook__duskSketch" />
      <i className="HereticBook__duskBlot" />
    </div>
  </div>
);

/** Вид сверху: руна 3×3, компоненты на клетках, рука касается центра. */
export const RitualDiagram = () => (
  <DrawnSvg className="HereticBook__ritualDrawing" viewBox="0 0 300 170" strokeWidth="1.1">
    <path d="M84 22h132v132H84z" className="HereticBook__bold" />
    <path d="M128 22v132m44-132v132M84 66h132M84 110h132" className="HereticBook__fine" />
    <circle cx="150" cy="88" r="60" />
    <circle cx="150" cy="88" r="52" strokeDasharray="1 5" className="HereticBook__fine" />
    <path d="m150 40 41 72H109Zm0 96-41-72h82Z" className="HereticBook__fine" />
    <circle cx="150" cy="88" r="11" className="HereticBook__bold" />
    <path d="M94 34l18 18m-4-6 4 6-6-2" />
    <path d="M190 36l16 14m-3-3 5-1m-4 5 1 4" />
    <path d="M196 128h12m-6-6v12M92 128c6-6 12-6 18 0-6 6-12 6-18 0Z" />
    <path className="HereticBook__ritualHand" d="M262 88h-62m10-8-10 8 10 8m52-18c6 0 10 4 10 10s-4 10-10 10" />
    <path d="M84 12h132m-132-4v8m132-8v8M72 22v132m-4-132h8m-8 132h8" className="HereticBook__fine" />
    <text x="140" y="9">3×3</text>
    <text x="226" y="122">пустой</text>
    <text x="226" y="134">рукой</text>
    <text x="8" y="56">компоненты</text>
    <text x="8" y="68">на клетках</text>
    <path d="M60 74h28" strokeDasharray="2 3" className="HereticBook__fine" />
  </DrawnSvg>
);

export const HereticPageOrnament = ({ path }: { path: string }) => (
  <>
    {!isWorkshopBook(path) && <PageOrnamentLines path={path} />}
    {path === 'Dusk' && <DuskPageLife />}
  </>
);

const PageOrnamentLines = ({ path }: { path: string }) => (
  <svg className="HereticBook__pageOrnament" viewBox="0 0 320 600" preserveAspectRatio="none" fill="none" stroke="currentColor" strokeWidth=".8" aria-hidden="true" focusable="false">
    {path === 'Dusk' ? (
      <>
        <path d="M160 22a38 12 0 1 0 .1 0M160 578a38 12 0 1 0 .1 0" />
        <path d="M14 70c20-30 46-48 86-52M306 70c-20-30-46-48-86-52M14 530c20 30 46 48 86 52M306 530c-20 30-46 48-86 52" />
        {[120, 220, 380, 480].map((y) => <path key={y} d={`M12 ${y}c6 8 6 20 0 28m296-28c-6 8-6 20 0 28`} />)}
        <path d="M150 22l4 6-3 5M168 578l-4-6 3-5" strokeDasharray="2 2" />
      </>
    ) : null}
  </svg>
);

/** Заставка над записью: завиток к центральному ромбу. */
export const Headpiece = () => (
  <svg className="HereticBook__headpiece" viewBox="0 0 240 22" fill="none" stroke="currentColor" strokeWidth="1" strokeLinecap="round" aria-hidden="true" focusable="false">
    <path d="M120 3.5 126.5 11 120 18.5 113.5 11Z" fill="currentColor" fillOpacity=".25" />
    <path d="M120 7.5 123 11l-3 3.5-3-3.5Z" fill="currentColor" stroke="none" />
    <path d="M108 11c-10 0-12-7-20-7-6 0-8 5-4 7 3 1.5 6-.5 5-2.5M132 11c10 0 12-7 20-7 6 0 8 5 4 7-3 1.5-6-.5-5-2.5" />
    <path d="M108 11c-8 0-10 6-17 6-4 0-6-2-5-4M132 11c8 0 10 6 17 6 4 0 6-2 5-4" strokeOpacity=".7" />
    <path d="M84 11H22m134 0h62" strokeWidth=".7" />
    <circle cx="18" cy="11" r="1.6" fill="currentColor" stroke="none" />
    <circle cx="222" cy="11" r="1.6" fill="currentColor" stroke="none" />
  </svg>
);

export type TailScene = 'path' | 'knowledge' | 'ritual';
/** Книги, у которых концовка главы - гравюра-сцена пути, а не завиток. */
const tailScenes: Record<string, Record<TailScene, string>> = {
  Dusk: { path: 'shadow', knowledge: 'sun', ritual: 'halo' },
};

/** Концовка: виньетка в конце записи. */
export const Tailpiece = ({ scene }: { scene?: TailScene }) => {
  const path = useContext(BookPathContext);
  const art = scene && tailScenes[path]?.[scene];
  if (art) {
    const engraving = { '--engraving': `url("${resolveAsset(`heretic-scene-${path.toLowerCase()}-${art}.webp`)}")` } as CSSProperties;
    return <div className={`HereticBook__scene HereticBook__scene--${art}`} style={engraving} aria-hidden="true" />;
  }
  return (
    <svg className="HereticBook__tailpiece" viewBox="0 0 120 26" fill="none" stroke="currentColor" strokeWidth="1" strokeLinecap="round" aria-hidden="true" focusable="false">
      <path d="M60 4c5 4 7 9 7 14-3-3-5-4-7-4s-4 1-7 4c0-5 2-10 7-14Z" fill="currentColor" fillOpacity=".3" />
      <path d="M60 14v8M53 18c-8 2-14 0-20-4-4-3-9-3-11 0M67 18c8 2 14 0 20-4 4-3 9-3 11 0" />
      <path d="M22 14c-3 2-2 6 1 6m75-6c3 2 2 6-1 6" strokeOpacity=".7" />
      <circle cx="60" cy="24" r="1.3" fill="currentColor" stroke="none" />
    </svg>
  );
};

/** Указующая рука на полях у главной команды страницы: стоит слева от кнопки и указывает пальцем вправо, на неё. */
export const Manicule = () => (
  <svg className="HereticBook__manicule" viewBox="0 0 48 24" fill="none" stroke="currentColor" strokeWidth="1.1" strokeLinejoin="round" strokeLinecap="round" aria-hidden="true" focusable="false">
    <g transform="matrix(-1 0 0 1 48 0)">
      <path d="M47 7h-7v11h7" />
      <path d="M40 8c-4-2-8-2-11-1H11c-2 0-3 1-3 2s1 2 3 2h13c-1 1-1 2 0 3h-1c-1 0-2 1-2 2s1 2 2 2h1c-1 1 0 3 1 3h2c0 1 1 2 2 2h8l3-3Z" fill="currentColor" fillOpacity=".12" />
      <path d="M24 11h4m-5 3h4m-3 3h3M43 9v7" strokeOpacity=".7" />
    </g>
  </svg>
);
