import { CSSProperties, ReactNode, useLayoutEffect, useRef } from 'react';

import { resolveAsset } from '../assets';

export const MourningLyre = ({ colored = false }: { colored?: boolean }) => (
  <g className="HereticLyre" fill="none" stroke={colored ? '#d9bb73' : 'currentColor'} strokeWidth="1.1" strokeLinecap="round" strokeLinejoin="round">
    <g className="HereticLyre__frame">
      <path d="M13 13C6 24 5 39 7 49q1 11 10 16l3-5q-8-4-8-14-2-15 5-30Z" fill={colored ? '#b9a67b' : 'none'} />
      <path d="M30 17q10-4 11 7 1 17-6 32l-7 9-3-4q11-11 11-32 0-5-7-5Z" fill={colored ? '#7b6139' : 'none'} />
      <path d="m12 13 22 5 5 7-26-6Z" fill={colored ? '#b58c4b' : 'none'} />
      <path d="m11 11 1-5 6-2 3 4-5 3 1 5m13 3 1-7 5 1 2 6M9 27l5 1m-7 6 5 1m-5 6 5 1m24-10 4 1m-5 10 4 1" stroke={colored ? '#eee0b9' : 'currentColor'} />
    </g>
    <g className="HereticLyre__strings" stroke={colored ? '#f1dfad' : 'currentColor'}>
      {[[15, 19, 1.1], [22, 21, 1.05], [29, 23, 1]].map(([x, y, scale], index) => (
        <g key={x} transform={`translate(${x} ${y}) scale(1 ${scale})`}>
          <path className={`HereticLyre__string HereticLyre__string--${index}`} d="M0 0Q0 20 0 40" />
        </g>
      ))}
    </g>
    <path className="HereticLyre__soundboard" d="M10 61h25l-4 8-9 5-9-6Zm5 5h16m-12 4h9" fill={colored ? '#593637' : 'none'} />
    <path d="M11 61h24m-21 3h18" stroke={colored ? '#eee0b9' : 'currentColor'} strokeWidth="1.8" />
    <g className="HereticLyre__pendant">
      <path d="M23 74v5m0 0 3 4-3 4-3-4Z" fill={colored ? '#d9bb73' : 'none'} />
    </g>
  </g>
);

export const CarnivalMask = ({ colored = false, strokeWidth = 1.1 }: { colored?: boolean; strokeWidth?: number }) => (
  <g className="HereticMask" fill={colored ? '#e8dccb' : 'none'} stroke={colored ? '#8f1d21' : 'currentColor'} strokeWidth={strokeWidth} strokeLinejoin="round">
    <path d="M24 14C28 11 35 10 40 9 43 8 45 6.5 47 5 46.5 10 45 14 42.5 17.5 40 22 33 25 28.5 23.5L26.2 20.7 24.6 19 24 19.6 23.4 19 21.8 20.7 19.5 23.5C15 25 8 22 5.5 17.5 3 14 1.5 10 1 5 3 6.5 5 8 8 9 13 10 20 11 24 14Z" />
    <path d="M28 17.6Q32 13 37.5 14.4 34 19.5 28 17.6ZM20 17.6Q16 13 10.5 14.4 14 19.5 20 17.6Z" fill={colored ? '#1b1012' : 'none'} />
    <path d="M9 9q7 3 11 2m8 0q4 1 11-2" fill="none" stroke={colored ? '#c8553d' : 'currentColor'} strokeWidth={strokeWidth * 0.7} />
  </g>
);

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
    aria-hidden="true"
  />
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
  <svg className="HereticBook__pageOrnament" viewBox="0 0 320 600" preserveAspectRatio="none" fill="none" stroke="currentColor" strokeWidth=".8" aria-hidden="true" focusable="false">
    {path === 'Ash' ? (
      <path d="M3 55 9 39 5 23 19 18 23 9 48 5M274 5l10 10 17-4 6 20 8 16M4 548l6 9-4 18 16 4 8 13 22 2m220 0 19-4 7-14 13-6-4-21" />
    ) : path === 'Rust' ? (
      <>
        <path d="M10 11h300v578H10zM17 18h286v564H17zM10 41h20m260 0h20M10 559h20m260 0h20" />
        {[[10, 11], [310, 11], [10, 300], [310, 300], [10, 589], [310, 589]].map(([x, y]) => <g key={`${x}-${y}`}><circle cx={x} cy={y} r="4" /><path d={`m${x-2} ${y-2} 4 4m0-4-4 4`} /></g>)}
      </>
    ) : path === 'Flesh' ? (
      <g className="HereticBook__veins">
        <path d="M4 0q21 58 9 105T15 222T8 354T17 472T6 600M316 0q-21 58-9 105t-2 117 7 132-9 118 11 128" strokeWidth="1.6" />
        <path d="M17 46q14 6 16 28m-18 9-9 17m7 49q19 10 15 39m-15 3-10 18m10 43q22 10 21 38m-24 34 16 15 5 27m-14 74 14 19m-17 20q21 25 13 45m-16 25 14 16M303 46q-14 6-16 28m18 9 9 17m-7 49q-19 10-15 39m15 3 10 18m-10 43q-22 10-21 38m24 34-16 15-5 27m14 74-14 19m17 20q-21 25-13 45m16 25-14 16" />
      </g>
    ) : path === 'Void' ? (
      <>
        <path d="M9 72V9h68M9 9l48 48M25 9l18 17m-34 0 16 17m-16 5 23 13m16-52 13 23M311 528v63h-68m68 0-48-48m32 48-18-17m34 0-16-17m16-5-23-13m-16 52-13-23" />
        <path d="M12 15 28 48M16 12 48 28m260 557-16-33m12 36-32-16" strokeDasharray="1 5" />
      </>
    ) : path === 'Blade' ? (
      <>
        <path d="M13 20h294v560H13zM18 25h284v550H18zM146 20l14-9 14 9-14 9Zm0 560 14-9 14 9-14 9Z" />
        {Array.from({ length: 11 }, (_, i) => <path key={i} d={`M13 ${50+i*50}h7m280 0h7`} />)}
      </>
    ) : path === 'Moon' ? (
      <>
        <path d="M12 555V78Q12 13 160 13T308 78v477q-148 60-296 0ZM18 550V82q0-61 142-61t142 61v468q-142 54-284 0Z" />
        <path d="m160 3 4 12-4 12-4-12Zm0 570 4 12-4 12-4-12Z" />
      </>
    ) : path === 'Lock' ? (
      <>
        <path d="M10 84V10h84m132 0h84v74M10 516v74h84m132 0h84v-74M18 67V18h49m186 0h49v49M18 533v49h49m186 0h49v-49" />
        <path d="M26 52V26h26v18H35v17M268 26h26v26h-18V35h-17M26 548v26h26v-18H35v-17M268 574h26v-26h-18v17h-17" />
        <path d="M10 115v370m300-370v370" strokeDasharray="2 8" />
      </>
    ) : path === 'Tide' ? (
      <>
        <path d="M12 15q12 24 0 48t0 48 0 48 0 48 0 48 0 48 0 48 0 48 0 48 0 48 0 48 0 48M308 15q-12 24 0 48t0 48 0 48 0 48 0 48 0 48 0 48 0 48 0 48 0 48 0 48 0 48" />
        <path d="M35 14h250M35 586h250" strokeDasharray="1 7" />
        {[71, 189, 337, 487].map((y) => <g key={y}><circle cx="20" cy={y} r="3" /><circle cx="300" cy={y + 29} r="4" /></g>)}
      </>
    ) : path === 'Glass' ? (
      <>
        <path d="m12 14 37 8-23 35-14 33Zm296 0-37 8 23 35 14 33ZM12 510l14 33 23 35-37 8Zm296 0-14 33-23 35 37 8Z" />
        <path d="M12 110v370m296-370v370M65 14h190M65 586h190" strokeDasharray="10 4 2 4" />
        {[151, 273, 397].map((y) => <path key={y} d={`m12 ${y} 8 16-8 16-8-16Zm296 0-8 16 8 16 8-16Z`} />)}
      </>
    ) : path === 'Blood' ? (
      <>
        <path d="M13 38V13h294v25M13 562v25h294v-25M20 53v494m280-494v494" />
        <path d="M31 13v24h24V13m210 0v24h24V13M31 587v-24h24v24m210 0v-24h24v24" />
        {[92, 217, 342, 467].map((y) => <g key={y}><path d={`M13 ${y}c-2 7-6 11-6 16a6 6 0 0 0 12 0c0-5-4-9-6-16Zm294 0c-2 7-6 11-6 16a6 6 0 0 0 12 0c0-5-4-9-6-16Z`} /><path d={`M13 ${y+35}v61m294-61v61`} strokeDasharray="1 5" /></g>)}
      </>
    ) : path === 'Echo' ? (
      <>
        <path d="M12 92V14h78m140 0h78v78M12 508v78h78m140 0h78v-78M12 114v372m296-372v372" />
        <path d="M19 104v392m282-392v392M38 15q0 23-23 23m36-23q0 36-36 36m49-36q0 49-49 49M282 585q0-23 23-23m-36 23q0-36 36-36m-49 36q0-49 49-49" />
        <path d="M148 14h24m-24 4h24M148 586h24m-24-4h24" />
        {[143, 281, 419].map((y) => <g key={y}><g transform={`translate(5 ${y}) scale(.36 .48)`}><MourningLyre /></g><g transform={`translate(298 ${y}) scale(.36 .48)`}><MourningLyre /></g></g>)}
      </>
    ) : path === 'Sand' ? (
      <>
        <path d="M15 38V15h290v23M15 562v23h290v-23M21 71v458m278-458v458" strokeDasharray="9 3 1 3" />
        {[90, 240, 390].map((y) => <path key={y} d={`M9 ${y}h15l-15 30h15Zm287 0h15l-15 30h15Z`} />)}
        <path d="m151 15 9-9 9 9-9 9Zm0 570 9-9 9 9-9 9Z" />
      </>
    ) : path === 'Wax' ? (
      <>
        <path d="M15 65V15h290v50M15 535v50h290v-50M22 87v426m276-426v426" />
        <path d="M16 16v31q6 15 12 0V31q6-9 12 0v33q7 14 14 0V18M266 18v26q7 14 14 0V30q6-9 12 0v52q6 14 12 0V16" />
        {[160, 320, 480].map((y) => <path key={y} d={`M15 ${y}c-9 14-9 20 0 20s9-6 0-20Zm290 0c-9 14-9 20 0 20s9-6 0-20Z`} />)}
      </>
    ) : path === 'Spirit' ? (
      <>
        <path d="M14 72V14h292v58M14 528v58h292v-58M20 89v422m280-422v422" />
        <path d="M17 20q24 16 43 0m200 0q20 16 43 0M17 580q24-16 43 0m200 0q20-16 43 0M144 14l16-9 16 9-16 12Zm0 572 16-9 16 9-16 12Z" />
        {[129, 271, 413].map((y) => <g key={y}><path d={`M12 ${y}q-9 0-6 10l6 17 6-17q3-10-6-10Zm296 0q-9 0-6 10l6 17 6-17q3-10-6-10Z`} /><path d={`M12 ${y+33}v56m296-56v56`} strokeDasharray="1 5" /></g>)}
      </>
    ) : path === 'Dance' ? (
      <>
        <path d="M14 70V14h292v56M14 530v56h292v-56M20 90v420m280-420v420" />
        <path d="M10 90q8 21 0 42t0 42 0 42 0 42 0 42 0 42 0 42 0 42 0 42 0 42M310 90q-8 21 0 42t0 42 0 42 0 42 0 42 0 42 0 42 0 42 0 42 0 42" strokeDasharray="7 3" />
        <g transform="translate(22 20) scale(.62)"><CarnivalMask /></g>
        <g transform="translate(268 20) scale(.62)"><CarnivalMask /></g>
        <path d="M24 580l1-8q4-4 8-1l5 5 9 2q2 1 1 3H24Zm1 0v5M296 580l-1-8q-4-4-8-1l-5 5-9 2q-2 1-1 3h20Zm-1 0v5" />
        {[78, 118, 158, 198, 238].map((x, index) => <path key={x} d={`M${x} ${index % 2 ? 588 : 582}c6-3 10-1 10 1s-4 4-10 1Zm-3 0a2 2 0 1 0 0 .1Z`} />)}
        <path d="m151 14 9-8 9 8-9 8Z" />
      </>
    ) : path === 'Cosmic' ? (
      <>
        <path d="m9 86 15-39 35-29 37 7m-72 22 5-32 30 3M311 514l-15 39-35 29-37-7m72-22-5 32-30-3M10 565l26 17 29-2m190-560 29-2 26 17" />
        {[[24, 47], [59, 18], [29, 15], [296, 553], [261, 582], [291, 585], [36, 582], [284, 18]].map(([x, y]) => <path key={`${x}-${y}`} d={`M${x-3} ${y}h6m-3-3v6`} />)}
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

/** Концовка: виньетка в конце записи. */
export const Tailpiece = () => (
  <svg className="HereticBook__tailpiece" viewBox="0 0 120 26" fill="none" stroke="currentColor" strokeWidth="1" strokeLinecap="round" aria-hidden="true" focusable="false">
    <path d="M60 4c5 4 7 9 7 14-3-3-5-4-7-4s-4 1-7 4c0-5 2-10 7-14Z" fill="currentColor" fillOpacity=".3" />
    <path d="M60 14v8M53 18c-8 2-14 0-20-4-4-3-9-3-11 0M67 18c8 2 14 0 20-4 4-3 9-3 11 0" />
    <path d="M22 14c-3 2-2 6 1 6m75-6c3 2 2 6-1 6" strokeOpacity=".7" />
    <circle cx="60" cy="24" r="1.3" fill="currentColor" stroke="none" />
  </svg>
);

/** Указующая рука на полях у главной команды страницы. */
export const Manicule = () => (
  <svg className="HereticBook__manicule" viewBox="0 0 48 24" fill="none" stroke="currentColor" strokeWidth="1.1" strokeLinejoin="round" strokeLinecap="round" aria-hidden="true" focusable="false">
    <path d="M47 7h-7v11h7" />
    <path d="M40 8c-4-2-8-2-11-1H11c-2 0-3 1-3 2s1 2 3 2h13c-1 1-1 2 0 3h-1c-1 0-2 1-2 2s1 2 2 2h1c-1 1 0 3 1 3h2c0 1 1 2 2 2h8l3-3Z" fill="currentColor" fillOpacity=".12" />
    <path d="M24 11h4m-5 3h4m-3 3h3M43 9v7" strokeOpacity=".7" />
  </svg>
);
