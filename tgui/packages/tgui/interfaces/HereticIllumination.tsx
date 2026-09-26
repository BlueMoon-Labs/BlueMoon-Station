export const SpiritLantern = ({ colored = false }: { colored?: boolean }) => (
  <g fill="none" stroke={colored ? '#d8d1b8' : 'currentColor'} strokeWidth="1.3" strokeLinecap="round" strokeLinejoin="round">
    <path d="M22 3v8m-7 7v-4a7 7 0 0 1 14 0v4M10 25l12-9 12 9 3 7H7ZM10 32v34l12 10 12-10V32M7 67l15 11 15-11M22 78v7m-5-3h10" fill={colored ? '#25273d' : 'none'} />
    <path d="M15 29v35l7 7 7-7V29M7 33h30M11 63h22m-11-47v12" />
    <g className="HereticBook__lanternSoul">
      <path d="M22 35c-6 0-8 6-5 11-6 6-7 16-1 20 0-6 5-7 5-11 4 9 8 11 7 18 8-9 4-20-3-27 5-5 2-11-3-11Z" fill={colored ? '#9be8cf' : 'currentColor'} fillOpacity={colored ? '.85' : '.18'} stroke={colored ? '#bcffe5' : 'currentColor'} />
      <path d="M20 40v2m4-2v2" stroke={colored ? '#30384c' : 'currentColor'} />
    </g>
  </g>
);

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

/** Рисунки путей выполнены чернилами, как и остальные записи в книге. */
export const HereticIllumination = ({ path }: { path: string }) => (
  <svg
    className={`HereticBook__illumination HereticBook__illumination--${path}`}
    viewBox="0 0 320 220"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.3"
    aria-hidden="true"
    focusable="false"
  >
    {path === 'Ash' ? (
      <>
        <path d="M36 194h248M56 202h208M105 194l13-74h84l13 74M115 137h90M124 156h72M146 188h28v-24h-28z" />
        <path className="HereticBook__fire" d="M160 121c-50-17-51-46-24-77-3 25 8 29 16 33-4-36 18-52 17-67 29 41 5 51 23 69l13-22c20 44-5 60-45 64Z" />
        <path d="M150 119c-15-18-9-27 6-41-2 18 20 16 12 41M104 68l-9-13m-9 42-16-3m149-11 14-7M213 40l8-12" />
        <g className="HereticBook__embers"><path d="m119 33 3-8m69 5 3-8m49 112 3-8m-152 21 3-8m89-89 3-8" /></g>
        <circle cx="160" cy="98" r="86" strokeDasharray="2 11" />
      </>
    ) : path === 'Rust' ? (
      <>
        <path d="M35 23h250v174H35zM46 34h228v152H46zM80 34v152m160-152v152M46 70h228m-228 80h228" />
        <g className="HereticBook__gear">
          <path d="m150 44 20 0 3 16 14 6 13-10 14 14-10 13 6 14 16 3v20l-16 3-6 14 10 13-14 14-13-10-14 6-3 16h-20l-3-16-14-6-13 10-14-14 10-13-6-14-16-3v-20l16-3 6-14-10-13 14-14 13 10 14-6Z" />
          <circle cx="160" cy="110" r="35" /><circle cx="160" cy="110" r="12" />
          <path d="M160 75v23m0 24v23m-35-35h23m24 0h23" />
        </g>
        <path d="m60 49 5 5m0-5-5 5m195-5 5 5m0-5-5 5M60 169l5 5m0-5-5 5m195-5 5 5m0-5-5 5M88 161l8-6 4 13 10-3m116-113-10 5 4 12-11 4" />
      </>
    ) : path === 'Flesh' ? (
      <>
        <g className="HereticBook__pulse">
          <path d="M154 68c-17-33-58-24-58 12-23 34 7 83 66 112 48-24 76-55 62-91-7-32-42-50-61-23M154 68l-5-35 19-7 14 33m-43 0-17-29-18 10 13 23M184 80l15-34 18 7-12 40" />
          <path d="M158 86c-18 11-16 33-3 53l7 53m-7-53-30-15-8-25m38 40 29-8 22-29m-51 38-24 19m33-42 24-13 2-17" />
        </g>
        <path className="HereticBook__veins" d="M96 94 66 76 44 39m25 40-28 11m68 48-42 9-30 29m37-30-23-22m169-20 27-22 30 4m-31-5 11-31m-43 96 35 13 27 30m-31-31 25-8" />
        <path d="M20 19q15 70 0 182M300 19q-15 70 0 182" strokeDasharray="3 9" />
      </>
    ) : path === 'Void' ? (
      <>
        <g className="HereticBook__winter">
          {[0, 60, 120, 180, 240, 300].map((angle) => <path key={angle} transform={`rotate(${angle} 160 110)`} d="M160 22l13 43-13 45-13-45Z" />)}
        </g>
        <path className="HereticBook__winter" d="M160 23v174M85 66l150 88M85 154l150-88M148 36l12 14 12-14m-24 148 12-14 12 14M91 84l18-4-3-18m107 96-3-18 18-4M91 136l18 4-3 18m107-96-3 18 18 4" />
        <circle cx="160" cy="110" r="44" strokeDasharray="1 8" />
        <path d="M50 25h38M50 25v38m220-38h-38m38 0v38M50 195h38m-38 0v-38m220 38h-38m38 0v-38" opacity=".5" />
        <circle cx="160" cy="110" r="18" />
      </>
    ) : path === 'Blade' ? (
      <>
        <path d="M40 190h240M160 24v176M44 108h232" strokeDasharray="3 5" />
        <g className="HereticBook__guard">
          <path d="m87 176 41-80 6-59 10-18 4 21-18 61-31 82m17-24-35-17m-27 20 38 15m23-74-12-32M235 176l-41-80-6-59-10-18-4 21 18 61 31 82m-17-24 35-17m27 20-38 15m-23-74 12-32" />
          <path d="M112 127q48-74 96 0M121 115l-9 12 15-1m73-11 8 12-15-1" />
        </g>
        <circle cx="160" cy="108" r="74" /><circle cx="160" cy="108" r="78" strokeDasharray="1 8" />
        <text x="34" y="106">I</text><text x="276" y="106">II</text><text x="153" y="213">III</text>
      </>
    ) : path === 'Moon' ? (
      <>
        <ellipse cx="160" cy="108" rx="74" ry="92" /><ellipse cx="160" cy="108" rx="65" ry="83" />
        <path d="M160 7v14m0 174v18M78 108h16m132 0h16M100 38l9 10m102 129 9 10M100 179l9-10m102-129 9-10" />
        <g className="HereticBook__reflection">
          <path d="M176 47a40 40 0 1 0 0 78 44 44 0 0 1 0-78Z" />
          <path d="M118 159q42-21 84 0M121 169q39-16 78 0m-66 9q27-9 54 0" />
        </g>
        <path d="m43 73 5 11 11 5-11 5-5 11-5-11-11-5 11-5Zm230 46 5 11 11 5-11 5-5 11-5-11-11-5 11-5Z" />
      </>
    ) : path === 'Lock' ? (
      <>
        <path d="M65 196V79a95 68 0 0 1 190 0v117M78 196V81a82 56 0 0 1 164 0v115M92 196V84a68 45 0 0 1 136 0v112" />
        <path d="M42 204h236M99 84h25v-9h25v16h-11v18h-23v23h16v24h-23v33m91-105h-23v-9h-16v19h15v25h26v21h-12v21h20v27" strokeDasharray="2 2" />
        <g className="HereticBook__key">
          <circle cx="160" cy="108" r="18" /><circle cx="160" cy="108" r="10" />
          <path d="M156 126v58h9v-11h13v-9h-13v-12h12v-8h-12v-18" />
        </g>
        <path d="M46 75h18m192 0h18M45 148h20m190 0h20M153 22h14m-7-7v14" />
      </>
    ) : path === 'Tide' ? (
      <>
        <ellipse cx="160" cy="119" rx="103" ry="86" strokeDasharray="1 7" />
        <path d="M149 47V28q11-16 22 0v19M113 158V91a47 47 0 0 1 94 0v67l13 17H100ZM113 149h94M110 175v10h100v-10" />
        <circle cx="160" cy="104" r="25" /><circle cx="160" cy="104" r="20" />
        <path d="M140 104h40m-20-20v40m-14-34 28 28m0-28-28 28" />
        <g className="HereticBook__tide">
          <path d="M42 179q19-15 38 0t38 0 38 0 38 0 38 0 38 0M54 192q18-11 36 0t36 0 36 0 36 0 36 0 36 0" />
          <circle cx="86" cy="130" r="5" /><circle cx="230" cy="104" r="4" /><circle cx="97" cy="67" r="3" /><circle cx="216" cy="49" r="2" />
        </g>
        <path d="M35 117h15m220 0h15M160 9v9" />
      </>
    ) : path === 'Glass' ? (
      <>
        <path d="M62 199V89a98 76 0 0 1 196 0v110M72 195V91a88 66 0 0 1 176 0v104M47 205h226" />
        <g className="HereticBook__facets">
          <path d="m160 27 35 52-14 51-21 65-35-75 12-42Zm0 0-1 69-34 24m34-24 36-17m-36 17 22 34m-22-34 1 99" />
          <path d="m87 74 38 46-37 27Zm145 2-37 3 27 39Zm-17 64-34-10 11 49ZM95 158l21 21-13 18Z" />
        </g>
        <path d="M23 95h56m-17-6 17 6-17 6m122-1 33-18m-30 24 40 1m-42 5 35 25M119 43l-16-14m95 0 16-14" />
        <path className="HereticBook__opticalRay" d="M23 95h64l72 1 36-17 57-23m-93 40 22 34 69 18" pathLength="100" />
        <circle cx="160" cy="98" r="8" />
      </>
    ) : path === 'Blood' ? (
      <>
        <circle cx="160" cy="106" r="87" /><circle cx="160" cy="106" r="78" strokeDasharray="2 7" />
        <path d="M116 105h88c0 33-17 49-44 49s-44-16-44-49Zm44 49v38m-31 0h62m-75-79h88M137 192l-8 8h62l-8-8M127 123q5 18 21 22" />
        <path className="HereticBook__bloodThread" d="M66 43c-18 43 15 68 50 66m138-66c18 43-15 68-50 66" pathLength="100" />
        <path className="HereticBook__titheDrop" d="M160 36c-4 17-17 29-17 42a17 17 0 0 0 34 0c0-13-13-25-17-42Zm-9 38q-4 12 5 15" />
        <path d="m55 33 13 6 41 100-6 4L57 48Zm199 0-13 6-41 100 6 4 46-95ZM90 115l22-8m96 0 22 8M40 169l34-13m172 0 34 13" />
        <path d="M42 26v40m-6-28h12M278 26v40m-6-28h12M69 184l-9 14m191-14 9 14" />
      </>
    ) : path === 'Echo' ? (
      <>
        <circle cx="160" cy="108" r="88" /><circle cx="160" cy="108" r="80" strokeDasharray="2 7" />
        <g transform="translate(109 7) scale(2.3)"><MourningLyre /></g>
        <g className="HereticBook__echoWaves">
          <path d="M112 67q-13 29 0 58m-12-70q-21 41 0 82M213 71q13 27 0 54m12-67q21 40 0 80" />
        </g>
        <path d="M52 150h43m130 0h43M48 158h56m112 0h56M58 166h54m96 0h54M79 175h36m90 0h36" />
        <path d="m160 13 4 9-4 9-4-9ZM57 68l8 4-8 4-8-4Zm206 0 8 4-8 4-8-4Z" />
      </>
    ) : path === 'Sand' ? (
      <>
        <path d="M102 29h116v12H102zM102 180h116v12H102zM114 42v137m92-137v137M126 42q0 44 34 64-34 29-34 73m68-137q0 44-34 64 34 29 34 73" />
        <path d="m132 59 28 34 28-34Zm0 112 28-35 28 35Z" fill="currentColor" opacity=".25" />
        <path className="HereticBook__sandStream" d="M160 101v36" strokeDasharray="1 4" />
        <path d="M83 48q-55 60 0 120m-7-11 7 11-14-2M237 168q55-60 0-120m7 11-7-11 14 2M44 111h39m154 0h39" />
        <path d="M54 178q24-21 46-12m123-110q21 12 44-4M60 187q21-13 42-8" opacity=".5" />
        <text x="151" y="23">XII</text><text x="153" y="211">I</text>
      </>
    ) : path === 'Wax' ? (
      <>
        <path d="M75 188h170M116 177h88l9 11H107ZM160 176v-35m-57-17q0 28 57 17 57 11 57-17M94 119h18m96 0h18M145 134h30" />
        <path d="M146 65h28v67h-28zM95 79h16v38H95zM209 79h16v38h-16zM146 76q5-9 10 0v23q4 7 8 0V85q4-6 10-1M95 87q7-8 9 1v12m105-12q7-8 9 1v12" />
        <g className="HereticBook__waxFlames"><path d="M160 21c2 18 15 22 11 34-4 12-23 9-23-3 0-10 12-14 12-31ZM103 42c0 13 10 17 9 25-2 9-18 9-18-1 0-7 9-12 9-24Zm114 0c0 13 10 17 9 25-2 9-18 9-18-1 0-7 9-12 9-24Z" /></g>
        <path d="M65 31v113l25 38m165-151v113l-25 38M54 47v101l22 35m190-136v101l-22 35" opacity=".5" />
        <path d="M124 208h72M134 201h52" />
      </>
    ) : path === 'Spirit' ? (
      <>
        <path d="M77 191V79q0-56 65-56t65 56v112M85 188V81q0-50 57-50t57 50v107M62 197h160M87 205h109" opacity=".55" />
        <g className="HereticBook__departingSoul">
          <path d="M143 44c-23 0-35 23-30 44-5 12-19 23-20 47 9-7 16-8 24-20-4 30-8 41-23 61 23-3 32-12 43-31 1 15 10 22 4 39 25-16 34-44 29-66 9 16 17 20 25 25-5-29-20-43-21-56 6-25-8-43-31-43Z" />
          <path d="M121 87c-1-20 7-33 21-35 17 1 26 18 24 37M126 98q-11 26-13 40m48-40q16 32 8 52m-27-30q-2 26-17 42" />
          <path d="m129 68 7-7h13l8 7-2 15-9 10h-7l-9-10Z" fill="currentColor" fillOpacity=".08" />
          <path d="M132 71h7v4h-7Zm15 0h7v4h-7Zm-4 5-2 5h4ZM136 85h13m-10-2v6m6-6v6" />
        </g>
        <g transform="translate(228 85) scale(1.1)"><SpiritLantern /></g>
        <path className="HereticBook__soulThread" d="M156 117c67-39 22 61 96 27" strokeDasharray="3 4" />
        <path d="M247 81V45h-23m16 8 7-8 7 8M43 74v39m-7-30h14M43 124v15m-7-7h14M69 61l7 7m137-7-7 7" />
        <circle cx="142" cy="101" r="90" strokeDasharray="1 9" opacity=".45" />
      </>
    ) : path === 'Cosmic' ? (
      <>
        <g className="HereticBook__orbit">
          <circle cx="160" cy="110" r="88" /><circle cx="160" cy="110" r="79" strokeDasharray="1 6" />
          <ellipse cx="160" cy="110" rx="112" ry="36" transform="rotate(-30 160 110)" />
          <ellipse cx="160" cy="110" rx="36" ry="105" transform="rotate(-30 160 110)" />
          <circle cx="202" cy="34" r="5" fill="currentColor" /><circle cx="61" cy="151" r="4" fill="currentColor" />
        </g>
        <path d="m94 111 39-45 72 24 16 59-70 24-57-62Zm39-45 18 107 54-83m-111 21 127 38" />
        {[[94, 111], [133, 66], [205, 90], [221, 149], [151, 173]].map(([x, y]) => <path key={x} d={`M${x-5} ${y}h10m-5-5v10`} />)}
        <circle cx="160" cy="110" r="12" /><path d="M154 110h12m-6-6v12" />
      </>
    ) : (
      <>
        <circle cx="160" cy="110" r="78" /><circle cx="160" cy="110" r="69" strokeDasharray="2 7" />
        <path d="M116 167V82q0-44 44-44t44 44v85M135 167V86q0-27 25-27t25 27v81M110 167h100M153 112h14v39h-14z" />
        <path d="M160 21V9m69 55 12-7m-12 99 12 7m-81 36v12M91 156l-12 7m12-99-12-7" />
      </>
    )}
  </svg>
);

export const RitualDiagram = () => (
  <svg className="HereticBook__ritualDrawing" viewBox="0 0 300 150" fill="none" stroke="currentColor" aria-hidden="true" focusable="false">
    <path d="M70 14h160v122H70zM123 14v122m54-122v122M70 55h160M70 96h160" strokeDasharray="3 5" />
    <ellipse cx="150" cy="75" rx="68" ry="52" /><ellipse cx="150" cy="75" rx="58" ry="43" />
    <path d="m150 27 54 73H96Zm0 96-54-73h108ZM37 75h37m151 0h37M61 68l13 7-13 7m177-14-13 7 13 7" />
    <circle cx="150" cy="75" r="12" />
  </svg>
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
    ) : path === 'Cosmic' ? (
      <>
        <path d="m9 86 15-39 35-29 37 7m-72 22 5-32 30 3M311 514l-15 39-35 29-37-7m72-22-5 32-30-3M10 565l26 17 29-2m190-560 29-2 26 17" />
        {[[24, 47], [59, 18], [29, 15], [296, 553], [261, 582], [291, 585], [36, 582], [284, 18]].map(([x, y]) => <path key={`${x}-${y}`} d={`M${x-3} ${y}h6m-3-3v6`} />)}
      </>
    ) : null}
  </svg>
);
