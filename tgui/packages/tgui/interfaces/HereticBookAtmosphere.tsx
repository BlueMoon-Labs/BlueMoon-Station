import { useEffect, useId, useRef, useState } from 'react';

import { MourningLyre } from './HereticIllumination';

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
};

// Частицы закреплены за переплётом: нажатия не создают новых элементов.
const flames = [[8, 230], [975, 860], [491, 180]];
const sparks = [[13, 208], [988, 850], [497, 156], [503, 753]];
const stars = [[15, 110], [20, 362], [11, 690], [23, 912], [983, 158], [976, 474], [985, 733], [974, 893], [496, 170], [504, 396], [495, 720], [502, 911]];

const Artwork = ({ path, full, prefix }: { path: string; full: boolean; prefix: string }) => (
  <svg className="HereticBookAtmosphere__art" viewBox="0 0 1000 1000" preserveAspectRatio="none" aria-hidden="true" focusable="false">
    <defs>
      <linearGradient id={`${prefix}-tissue`} x1="0" x2="1">
        <stop stopColor="#250610" /><stop offset=".25" stopColor="#912738" /><stop offset=".52" stopColor="#e28586" /><stop offset=".7" stopColor="#ad4353" /><stop offset="1" stopColor="#340d1a" />
      </linearGradient>
      <linearGradient id={`${prefix}-fire`} x1="0" y1="1" x2="0" y2="0">
        <stop stopColor="#fff4b1" /><stop offset=".22" stopColor="#ffc056" /><stop offset=".56" stopColor="#f06623" /><stop offset="1" stopColor="#aa2b12" stopOpacity=".1" />
      </linearGradient>
      <linearGradient id={`${prefix}-ice`} x1="0" y1="0" x2="1" y2="1">
        <stop stopColor="#f9ffff" /><stop offset=".32" stopColor="#acdfed" stopOpacity=".9" /><stop offset=".6" stopColor="#6fa0c4" stopOpacity=".35" /><stop offset="1" stopColor="#f1ffff" stopOpacity=".9" />
      </linearGradient>
      <linearGradient id={`${prefix}-mercury`} x1="0" x2="1">
        <stop stopColor="#4b425e" /><stop offset=".36" stopColor="#ac9fbf" /><stop offset=".54" stopColor="#f7efff" /><stop offset=".78" stopColor="#9b8ab4" /><stop offset="1" stopColor="#403751" />
      </linearGradient>
      <linearGradient id={`${prefix}-tail`}>
        <stop stopColor="#eefff8" /><stop offset=".22" stopColor="#81fff0" stopOpacity=".8" /><stop offset="1" stopColor="#83dce9" stopOpacity="0" />
      </linearGradient>
      <linearGradient id={`${prefix}-steel`}>
        <stop stopColor="#2f3540" /><stop offset=".25" stopColor="#9397a0" /><stop offset=".46" stopColor="#fff5d9" /><stop offset=".6" stopColor="#7f8792" /><stop offset="1" stopColor="#373842" />
      </linearGradient>
      <radialGradient id={`${prefix}-patina`} cx=".3" cy=".24">
        <stop stopColor="#cab46c" /><stop offset=".25" stopColor="#989e58" /><stop offset=".49" stopColor="#54744d" /><stop offset=".69" stopColor="#9b5f30" /><stop offset="1" stopColor="#382c20" />
      </radialGradient>
    </defs>

    {path === 'Flesh' && (
      <g fill="none" className="HereticBookAtmosphere__flesh">
        <g className="HereticBookAtmosphere__tendons" stroke={`url(#${prefix}-tissue)`} strokeLinecap="round">
          <path className="HereticBookAtmosphere__mainVein" d="M499 5C482 130 513 172 495 290S517 453 500 574 483 789 501 997" strokeWidth="19" />
          <path d="M8 12C32 160-1 170 11 322S-1 479 13 600 0 830 9 990M991 12C967 160 1000 170 988 322S1001 479 988 600 1000 830 990 990" strokeWidth={full ? 15 : 8} />
          {full && <path d="M487 8C505 210 479 213 507 407S484 646 511 997M13 136l15 40-4 33M12 355l17 30-3 36M9 714l15 32-5 45M986 214l-16 41 5 39M987 525l-14 37 2 39M990 824l-19 35 4 32" strokeWidth="7" />}
        </g>
        <path className="HereticBookAtmosphere__wet" d="M496 21C490 107 499 133 495 162M505 371l1 36m-11 311-1 30M13 30l1 53m973 228 2 59M8 586l1 44" stroke="#ffd4cf" strokeWidth="2.3" strokeLinecap="round" />
        <g className="HereticBookAtmosphere__stitches" stroke="#e4b8a1" strokeWidth="2.2">
          {[100, 265, 443, 626, 809, 937].map((y) => <path key={y} d={`M487 ${y-5}q12 18 25 0m-25 2q12 18 25 0`} />)}
        </g>
      </g>
    )}

    {path === 'Ash' && (
      <>
        <path className="HereticBookAtmosphere__emberSeam" d="M9 18v966m981-966v966M499 15v970" fill="none" stroke="#f27622" strokeWidth="3" />
        {(full ? flames : flames.slice(0, 2)).map(([x, y], index) => (
          <g key={x} transform={`translate(${x} ${y})`}>
            <g className={`HereticBookAtmosphere__flame HereticBookAtmosphere__flame--${index % 3}`}>
              <path d="M10 5C-6-7-4-24 3-36 4-19 11-26 11-48 22-35 12-30 21-19 24-26 26-30 27-37 38-15 26 4 10 5Z" fill={`url(#${prefix}-fire)`} />
              <path d="M12 3C4-6 11-13 13-24 21-18 12-12 20-7 20-1 17 2 12 3Z" fill="#fff1a7" opacity=".88" />
            </g>
          </g>
        ))}
        <g className="HereticBookAtmosphere__sparks" fill="#ffe29a">
          {(full ? sparks : sparks.slice(0, 3)).map(([x, y], index) => <circle className={`HereticBookAtmosphere__spark HereticBookAtmosphere__spark--${index % 3}`} key={`${x}-${y}`} cx={x} cy={y} r={index % 2 ? 1.7 : 1.1} />)}
        </g>
      </>
    )}

    {path === 'Cosmic' && (
      <g fill="none">
        <path className="HereticBookAtmosphere__corona" d="M14 15Q1 500 14 985M986 15q13 485 0 970M500 10v980M18 13h964m-964 974h964" stroke="#62f9eb" strokeWidth="5" />
        <g className="HereticBookAtmosphere__stars" stroke="#efffd9" fill="#efffe6">
          {(full ? stars : stars.slice(0, 4)).map(([x, y], index) => <g className={`HereticBookAtmosphere__star HereticBookAtmosphere__star--${index % 3}`} key={`${x}-${y}`}><path d={`M${x-4} ${y}h8m-4-5v10`} strokeWidth=".7" /><circle cx={x} cy={y} r="1.5" /></g>)}
        </g>
        {full && <g stroke="#a6e8ed" strokeWidth=".8" opacity=".65">
          <g transform="translate(28 37)"><g className="HereticBookAtmosphere__smallOrbit"><ellipse rx="24" ry="11" /><ellipse rx="10" ry="28" /><circle cx="23" r="2" fill="#fff6b0" /></g></g>
          <g transform="translate(972 963)"><g className="HereticBookAtmosphere__smallOrbit"><ellipse rx="24" ry="11" /><ellipse rx="10" ry="28" /><circle cy="27" r="2" fill="#fff6b0" /></g></g>
                 </g>}
        <g className="HereticBookAtmosphere__comet" transform="translate(946 14)">
          <path d="M0 0Q25-8 96 0 25 8 0 0Z" fill={`url(#${prefix}-tail)`} stroke="none" /><circle r="3" fill="#fffce1" />
        </g>
      </g>
    )}

    {path === 'Rust' && (
      <g>
        <path d="M12 12v976m976-976v976M493 9v982m14-982v982" fill="none" stroke="#435441" strokeWidth="4" />
        <g className="HereticBookAtmosphere__oxidation" fill={`url(#${prefix}-patina)`}>
          {[80, 290, 650, 897].slice(0, full ? 4 : 2).map((y) => <g key={y}><path d={`M5 ${y-30} 19 ${y-20} 27 ${y-3} 19 ${y+24} 5 ${y+33}ZM995 ${y+30} 981 ${y+40} 973 ${y+57} 981 ${y+84} 995 ${y+93}Z`} /><ellipse cx="499" cy={y+20} rx="11" ry="16" /><path d={`M10 ${y-14} 19 ${y-1} 12 ${y+13}M990 ${y+46} 981 ${y+59} 988 ${y+73}`} fill="none" stroke="#c7aa68" strokeWidth="1.4" /></g>)}
        </g>
        {full && <path className="HereticBookAtmosphere__rustGrowth" d="M9 356q17 35 2 83m977-224q-15 33 1 77M497 454q13 46 0 81" fill="none" stroke="#93a65c" strokeWidth="8" strokeDasharray="8 5 2 4" />}
        <g className="HereticBookAtmosphere__rustFlakes" fill="#c1813a"><path d="m983 524 5-2 3 7-6 3Zm-6 19 4 2-2 6-4-2Zm15 17 5 2-3 7-3-3Z" /></g>
      </g>
    )}

    {path === 'Void' && (
      <g fill={`url(#${prefix}-ice)`} stroke="#e2ffff" strokeWidth=".7" className="HereticBookAtmosphere__ice">
        {(full ? [110, 355, 750] : [110]).map((y) => <g key={y}><path d={`M6 ${y+30} 10 ${y-39} 23 ${y+8} 17 ${y+37} 6 ${y+30}M10 ${y-39} 14 ${y+26} 23 ${y+8}M988 ${y+117} 975 ${y+60} 995 ${y+88} 998 ${y+128} 988 ${y+117}M975 ${y+60} 990 ${y+109} 995 ${y+88}`} /></g>)}
        {full && [200, 585, 880].map((y) => <g className="HereticBookAtmosphere__growingIce" key={y}><path d={`M491 ${y+23} 487 ${y-27} 500 ${y-6} 509 ${y-43} 513 ${y+13} 502 ${y+33}Z`} /><path d={`m487 ${y-27} 15 60 7-76m-9 37 2 39`} fill="none" stroke="#f6ffff" /></g>)}
        <path d="M499 0v1000m-9-862 9 18 9-18m-18 307 9 18 9-18m-18 360 9 18 9-18" fill="none" stroke="#dbfaff" />
      </g>
    )}

    {path === 'Blade' && (
      <g fill="none" stroke="#aeb6bb">
        <g fill={`url(#${prefix}-steel)`} stroke="#4c505e">
          <path d="M5 4h38l-9 11H17v53L5 81ZM995 4h-38l9 11h17v53l12 13ZM5 996h38l-9-11H17v-53L5 919ZM995 996h-38l9-11h17v-53l12-13Z" />
          {full && [125, 366, 641, 872].map((y) => <path key={y} d={`M487 ${y}h26v30h-26zm5 7v16m16-16v16`} />)}
        </g>
        <path d="M11 48V11h40m898 0h40v37M11 952v37h40m898 0h40v-37M494 9v982m12-982v982" strokeWidth="3" />
        <path d="M12 13h37m904 0h34M12 987h37m904 0h34" stroke="#f4ecd7" />
        <path className="HereticBookAtmosphere__bladeGleam" d="M494 280v65m12-65v65M980 305l15-3" stroke="#fffde8" strokeWidth="3" />
        <path className="HereticBookAtmosphere__steelSparks" d="m986 516-7-15m9 12 6-20m-5 23 10-6m-12 10-9 14m12-12 4 19" stroke="#fff0b1" strokeWidth="2" />
      </g>
    )}

    {path === 'Lock' && (
      <g fill="none" stroke="#c7a564">
        <path d="M12 14v973m976-973v973M493 12v976m14-976v976" strokeWidth="2" />
        {(full ? [76, 249, 484, 742, 919] : [76, 919]).map((y) => (
          <g key={y} strokeWidth="2">
            <rect x="3" y={y} width="16" height="27" rx="6" /><rect x="6" y={y+18} width="10" height="26" rx="5" />
            <rect x="981" y={y+12} width="16" height="27" rx="6" /><rect x="984" y={y+30} width="10" height="26" rx="5" />
            <path d={`M488 ${y+4}h24v25h-17v-16h10m-12 22h14`} />
          </g>
        ))}
        <g className="HereticBookAtmosphere__keyholeGlow" fill="#edd494" stroke="#ead597">
          <path d="M7 488a7 7 0 1 1 10 0l3 17H4ZM983 555a7 7 0 1 1 10 0l3 17h-16Z" />
        </g>
      </g>
    )}

    {path === 'Tide' && (
      <g fill="none" stroke="#78bfb4">
        <path className="HereticBookAtmosphere__seaweed" d="M8 994C32 871-7 853 11 726S-2 533 14 407 2 190 10 13M992 994c-24-123 15-141-3-268s13-193-3-319 12-217 4-394M500 15q-11 120 0 240t0 240 0 240 0 240" strokeWidth={full ? 4 : 2} />
        {full && <path d="M9 869q23-24 20-54M10 716q-12-18-7-40M11 513q21-31 20-48M10 294q-11-24-4-49M990 820q-24-26-21-57m23-152q12-18 7-40m-10-127q-21-31-20-48m21-184q11-24 4-49" strokeWidth="2.5" />}
        <g className="HereticBookAtmosphere__tideBubbles" strokeWidth="1.2">
          {(full ? [130, 270, 478, 693, 880] : [270, 693]).map((y, index) => <g key={y} className={`HereticBookAtmosphere__bubble HereticBookAtmosphere__bubble--${index % 3}`}><circle cx="17" cy={y} r={index % 2 ? 4 : 6} /><circle cx="983" cy={y+54} r={index % 2 ? 6 : 3} /><circle cx="500" cy={y-30} r="3" /></g>)}
        </g>
      </g>
    )}

    {path === 'Glass' && (
      <g fill="none" stroke="#d8bfdc" strokeWidth="1.5">
        <path d="M12 12v976m976-976v976M493 12v976m14-976v976" stroke="#806e8c" strokeWidth="3" />
        <g className="HereticBookAtmosphere__facets" fill="#a29aba" fillOpacity=".38">
          {(full ? [73, 241, 457, 689, 904] : [73, 904]).map((y, index) => <g key={y} className={`HereticBookAtmosphere__facet HereticBookAtmosphere__facet--${index % 3}`}><path d={`m12 ${y} 15 27-15 45-10-37Zm976 0-15 27 15 45 10-37ZM500 ${y+27}l10 23-10 45-10-31Z`} /><path className="HereticBookAtmosphere__facetEdge" d={`M12 ${y}v72m976-72v72m-488-45v68`} stroke="#f5ddb9" pathLength="100" /></g>)}
        </g>
        <path className="HereticBookAtmosphere__refraction" d="M3 130l26 31M980 702l20 24M491 409l20 25M5 739l20 25M980 146l20 24" stroke="#fff2dc" strokeWidth="3" />
        <path className="HereticBookAtmosphere__lightRoute" d="m12 80 12 28-12 48v90l-10 27 10 43v142l12 27-12 45m976-280-12 28 12 45v132l10 27-10 43" pathLength="100" stroke="#fff2dc" strokeWidth="2" />
      </g>
    )}

    {path === 'Blood' && (
      <g fill="none" stroke="#a24658">
        <path d="M11 15v970m978-970v970M495 12v976m10-976v976" stroke="#ad8957" strokeWidth="2" />
        <path className="HereticBookAtmosphere__bloodChannels" d="M11 27v900m978-834v850M500 120v715" strokeWidth="3" strokeDasharray="48 67" />
        <g className="HereticBookAtmosphere__titheDrops" fill="#ae314c" stroke="#f19aa8" strokeWidth=".7">
          {(full ? [158, 420, 738] : [420]).map((y, index) => <g key={y} className={`HereticBookAtmosphere__titheDrop HereticBookAtmosphere__titheDrop--${index}`}><path d={`M11 ${y}c-1 8-6 13-6 20a6 6 0 0 0 12 0c0-7-5-12-6-20Zm978 55c-1 8-6 13-6 20a6 6 0 0 0 12 0c0-7-5-12-6-20Z`} /></g>)}
        </g>
        {[40, 360, 665, 950].map((y) => <path key={y} d={`M488 ${y}h24m-24 5h24M3 ${y+11}h16m-16 5h16m962-16h16m-16 5h16`} stroke="#c7a777" strokeWidth="1.2" />)}
      </g>
    )}

    {path === 'Echo' && (
      <g fill="none" stroke="#d9bb73">
        <path d="M8 20v960m5-960v960m974-960v960m5-960v960M498 20v960m4-960v960" strokeWidth="1.1" />
        <g className="HereticBookAtmosphere__echoStrings" strokeWidth={full ? 1.5 : .8}>
          <path d="M11 130q8 110 0 220t0 220 0 220M989 130q-8 110 0 220t0 220 0 220M500 110q-7 105 0 210t0 210 0 210" />
        </g>
        {(full ? [70, 320, 660, 920] : [70, 920]).map((y) => <g key={y} color="#e5d7b2"><g transform={`translate(2 ${y}) scale(.45 .6)`}><MourningLyre /></g><g transform={`translate(980 ${y}) scale(.45 .6)`}><MourningLyre /></g></g>)}
        <g className="HereticBookAtmosphere__echoWaves" strokeWidth="1.1">
          <path d="M976 380q-18 60 0 120m7-137q-25 77 0 154m8-172q-32 95 0 190" />
        </g>
      </g>
    )}

    {path === 'Moon' && (
      <g fill="none">
        <path className="HereticBookAtmosphere__mercury" d="M11 15q-8 225 0 470t0 500M989 15q8 225 0 470t0 500M500 12q-5 230 0 478t0 498" stroke={`url(#${prefix}-mercury)`} strokeWidth={full ? 7 : 3} />
        <g className="HereticBookAtmosphere__mirrorWaves" stroke="#f4eaff" strokeWidth="1.2">
          <path d="M980 410q-13 55 0 110t0 110M986 375q-16 74 0 148t0 148M993 342q-19 95 0 190t0 190" />
        </g>
        {full && <g className="HereticBookAtmosphere__silverDrops" fill={`url(#${prefix}-mercury)`} stroke="#eadbf9" strokeWidth=".5"><ellipse cx="11" cy="305" rx="5" ry="12" /><ellipse cx="989" cy="745" rx="5" ry="13" /><ellipse cx="501" cy="225" rx="7" ry="19" /><ellipse cx="498" cy="843" rx="6" ry="16" /><path d="M9 34q23 5 6 42Q1 61 9 34ZM991 932q-23 5-6 42 14-15 6-42Z" /></g>}
      </g>
    )}
  </svg>
);

const Toy = ({ path, prefix }: { path: string; prefix: string }) => (
  <svg viewBox="0 0 44 88" className="HereticBookAtmosphere__toyArt" aria-hidden="true" focusable="false">
    <defs>
      <radialGradient id={`${prefix}-eye`}><stop stopColor="#ffd2b1" /><stop offset=".45" stopColor="#c27572" /><stop offset=".8" stopColor="#7c293a" /><stop offset="1" stopColor="#3b1327" /></radialGradient>
      <radialGradient id={`${prefix}-coal`}><stop stopColor="#ffd88e" /><stop offset=".26" stopColor="#f78129" /><stop offset=".6" stopColor="#762e14" /><stop offset="1" stopColor="#27180f" /></radialGradient>
      <radialGradient id={`${prefix}-sphere`} cx=".35" cy=".3"><stop stopColor="#e9fff9" /><stop offset=".18" stopColor="#8ffdeb" /><stop offset=".5" stopColor="#3d8dbe" /><stop offset=".85" stopColor="#21395b" /><stop offset="1" stopColor="#0b142f" /></radialGradient>
      <linearGradient id={`${prefix}-metal`}><stop stopColor="#424b5d" /><stop offset=".48" stopColor="#eff0df" /><stop offset=".65" stopColor="#999da9" /><stop offset="1" stopColor="#4a4559" /></linearGradient>
    </defs>
    {path === 'Flesh' ? (
      <>
        <path d="M17 2C0 9 11 26 3 41S4 73 18 85c19 9 21-17 21-37S35 2 17 2Z" fill={`url(#${prefix}-eye)`} stroke="#512136" strokeWidth="1.5" />
        <path d="M7 23q15-13 28 2M7 65q15 12 26-2" fill="none" stroke="#efb2a3" strokeWidth="1.3" />
        <g className="HereticBookAtmosphere__eyeOpen"><path d="M5 44q16-28 34 0Q21 68 5 44Z" fill="#eac3ad" stroke="#512138" strokeWidth="2" /><ellipse cx="22" cy="44" rx="8" ry="12" fill="#794224" /><ellipse cx="22" cy="44" rx="2.6" ry="9" fill="#190f16" /><circle cx="25" cy="39" r="2.3" fill="#fff3dc" /></g>
        <path className="HereticBookAtmosphere__eyelid" d="M5 44q15 6 34 0" fill="none" stroke="#391325" strokeWidth="3" />
      </>
    ) : path === 'Ash' ? (
      <><path d="m12 22 16-6 12 21-4 28-13 11L5 61 3 37Z" fill={`url(#${prefix}-coal)`} stroke="#582d1b" strokeWidth="2" /><path className="HereticBookAtmosphere__coalCracks" d="m13 23 5 19-8 17m8-17 15-6m-15 6 7 13-1 18m1-18 10 8" fill="none" stroke="#ffb94e" strokeWidth="1.7" /></>
    ) : path === 'Cosmic' ? (
      <><ellipse cx="22" cy="45" rx="18" ry="27" fill="none" stroke="#cab86e" /><circle cx="22" cy="45" r="17" fill={`url(#${prefix}-sphere)`} /><ellipse cx="22" cy="45" rx="20" ry="8" fill="none" stroke="#b9fae6" transform="rotate(-35 22 45)" /><circle cx="38" cy="33" r="2.5" fill="#fffbd9" /></>
    ) : path === 'Rust' ? (
      <g className="HereticBookAtmosphere__gearToy"><path d="m16 18 12 0 2 7 8 4-2 9 5 6-5 6 2 9-8 4-2 7H16l-2-7-8-4 2-9-5-6 5-6-2-9 8-4Z" fill="#666846" stroke="#b58b56" strokeWidth="2" /><circle cx="22" cy="44" r="11" fill="#373c2c" stroke="#9b642f" strokeWidth="4" /><path d="M19 36h6v16h-6z" fill="#ad8b58" /></g>
    ) : path === 'Void' ? (
      <><path d="m22 6 16 34-8 36-17-7L5 39Z" fill="#b5e1ec" fillOpacity=".75" stroke="#f1ffff" /><path d="m22 6-4 34 12 36M5 39l13 1 20 0m-20 0-5 29" fill="none" stroke="#eaffff" /><path d="m23 20 6 18-7 15" fill="none" stroke="#fff" strokeWidth="2" /></>
    ) : path === 'Lock' ? (
      <g className="HereticBookAtmosphere__keyToy" fill="#b29255" stroke="#e1c88e" strokeWidth="1.2">
        <circle cx="22" cy="23" r="15" /><circle cx="22" cy="23" r="8" fill="#332820" />
        <path d="M18 38v43h8V70h12v-9H26v-9h9v-8h-9v-6Z" />
        <path d="M21 42v33" stroke="#f7e5b1" />
      </g>
    ) : path === 'Tide' ? (
      <g className="HereticBookAtmosphere__bellToy" stroke="#c0b383" strokeWidth="1.2">
        <path d="M18 17v-7q4-7 8 0v7" fill="none" />
        <path d="M9 62V33a13 17 0 0 1 26 0v29l6 8H3Z" fill="#396561" />
        <path d="M5 70h34v5H5Z" fill="#a59359" /><circle cx="22" cy="43" r="10" fill="#102e37" />
        <path d="M13 43h18m-9-9v18m-6-15 12 12m0-12-12 12" />
        <path d="M20 75v5h4v-5" fill="#cbbb80" /><path d="M12 59h20" fill="none" />
      </g>
    ) : path === 'Glass' ? (
      <g className="HereticBookAtmosphere__prismToy" stroke="#e1cfe8" strokeWidth="1.1">
        <path d="m22 7 17 31-9 40H13L5 38Z" fill="#746580" /><path d="m22 7-6 31 14 40 9-40Z" fill="#b2a1c2" /><path d="m22 7 3 34-12 37-8-40Z" fill="#ccc1c5" />
        <path d="m5 38 20 3 14-3M22 7l3 34 5 37" fill="none" /><path d="M9 79h26m-25 3h24" stroke="#ba9864" strokeWidth="3" />
        <path className="HereticBookAtmosphere__refraction" d="m8 33 29 16m-28-9 25 16" stroke="#fff0c1" strokeWidth="2" />
      </g>
    ) : path === 'Blood' ? (
      <g className="HereticBookAtmosphere__ampouleToy" stroke="#c7a173" strokeWidth="1.2">
        <path d="M16 9h12v12l9 12v36q-15 19-30 0V33l9-12Z" fill="#382330" /><path className="HereticBookAtmosphere__ampoulePool" d="M13 44h18v24q-9 10-18 0Z" fill="#a92846" />
        <path d="M17 26 11 35v30M16 10h12m-14 5h16m-14 5h12" fill="none" stroke="#e4c2ab" /><path className="HereticBookAtmosphere__ampouleDrop" d="M22 33c-1 5-4 7-4 11a4 4 0 0 0 8 0c0-4-3-6-4-11Z" fill="#f27d92" stroke="none" />
        <path d="M15 80h14m-13 4h12" strokeWidth="3" />
      </g>
    ) : path === 'Echo' ? (
      <g stroke="#d9bb73" strokeWidth="1.5">
        <g className="HereticBookAtmosphere__lyreToy"><MourningLyre colored /></g>
        <g className="HereticBookAtmosphere__echoWaves" fill="none"><path d="M2 24q-5 14 0 28m40-28q5 14 0 28" /><path d="M-3 19q-8 19 0 38m50-38q8 19 0 38" /></g>
      </g>
    ) : path === 'Blade' ? (
      <><path d="m22 3 9 19-5 40h-8l-5-40Z" fill={`url(#${prefix}-metal)`} stroke="#8c929f" /><path d="M8 63h28m-14 0v18m-5 0h10" stroke="#d2c5a3" strokeWidth="4" /><path d="M22 5v52" stroke="#f5f2de" /><g className="HereticBookAtmosphere__counterBlade"><path d="m2 63 32-45 8-3-2 10L8 68Z" fill={`url(#${prefix}-metal)`} stroke="#e8e5d2" /><path d="m3 58 12 12" stroke="#d9b975" strokeWidth="3" /></g><path className="HereticBookAtmosphere__steelSparks" d="m22 42-7-7m9 5 7-9m-5 13 9 2m-15 1-4 8" stroke="#fff4b4" strokeWidth="2" /></>
    ) : (
      <><ellipse cx="22" cy="44" rx="18" ry="29" fill={`url(#${prefix}-metal)`} stroke="#e2d7ee" strokeWidth="2" /><path d="M25 24a21 21 0 0 0 0 41 24 24 0 0 1 0-41Z" fill="#cbbdde" /><path d="M11 50q11 7 22 0m-20 8q9 4 18 0" fill="none" stroke="#f9f0ff" /></>
    )}
  </svg>
);

const MaterialAtmosphere = ({ path, presentation, reducedMotion }: AtmosphereProps) => {
  const [reacting, setReacting] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const prefix = `heretic-atmosphere-${useId().replace(/:/g, '')}`;
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
  return (
    <div className={`HereticBookAtmosphere HereticBookAtmosphere--${path} HereticBookAtmosphere--${presentation}${reducedMotion ? ' HereticBookAtmosphere--still' : ''}${reacting ? ' HereticBookAtmosphere--reacting' : ''}`} data-reacting={reacting}>
      <Artwork path={path} full={presentation === 'living'} prefix={prefix} />
      <button type="button" className="HereticBookAtmosphere__toy" aria-label={interactions[path]} title={interactions[path]} aria-pressed={reacting} onClick={interact}>
        <Toy path={path} prefix={prefix} />
      </button>
    </div>
  );
};

export const HereticBookAtmosphere = (props: AtmosphereProps) => {
  if (props.presentation === 'plain' || !interactions[props.path]) return null;
  return <MaterialAtmosphere key={`${props.path}-${props.presentation}-${props.reducedMotion}`} {...props} />;
};
