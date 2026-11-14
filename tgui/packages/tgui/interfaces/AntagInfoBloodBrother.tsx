import { BooleanLike } from 'common/react';
import { AnimationEvent, CSSProperties, KeyboardEvent, ReactNode, useEffect, useRef, useState } from 'react';

import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type BrotherStateKey = 'ok' | 'hurt' | 'crit' | 'dead' | 'cuffed' | 'muted' | 'gone' | 'severed';

type StepTexts = { name: string; desc: string };

type StepProgress = { sealed: BooleanLike; sealed_by: string | null; condition: string | null };

type OathStep = StepTexts & StepProgress;

type BondAbility = {
  name: string;
  desc: string;
  how: string;
  cooldown: number;
  passive: BooleanLike;
};

/** label - блок не ступени, а клятвы: «Клятва «...» даёт». */
type BondTier = { tier: number; abilities: BondAbility[]; label?: string };

/** Тексты клятвы приходят статикой, печати шагов - в данных каждого тика. */
export type OathTexts = {
  key: string;
  name: string;
  summary?: string | null;
  story: string;
  kit?: string | null;
  vow_name: string | null;
  vow_desc: string | null;
  capstone: BondAbility | null;
  finale: string;
  steps: StepTexts[];
};

type Oath = Omit<OathTexts, 'steps'> & { steps: OathStep[] };

type OathProgress = { key: string; steps: StepProgress[] };

type Brother = { name: string; job: string; self?: BooleanLike };

type BrotherState = {
  name: string;
  state: BrotherStateKey;
  state_text?: string;
  direction: string | null;
  self?: BooleanLike;
  critical?: BooleanLike;
};

type Vow = { name: string; desc: string; broken: BooleanLike; broken_reason: string | null };

type Ability = { name: string; desc: string };

type FinaleCheck = {
  brothers: { name: string; status: string; done: BooleanLike }[];
  extra: string | null;
  extra_done: BooleanLike;
};

type Whisper = { name: string; text: string; time: string | null };

export type AntagInfoBloodBrotherData = {
  antag_name: string;
  backstory: string | null;
  backstory_owner?: BooleanLike;
  brothers: Brother[];
  bond_ladder: BondTier[];
  rules: string[];
  offer_texts: OathTexts[];
  oath_texts: OathTexts | null;
  /** next - клятва исполнена, на выбор следующие, без срока. */
  state: 'choosing' | 'sworn' | 'next';
  /** Названия исполненных прежде клятв. */
  fulfilled?: string[];
  /** Названия венцов, которые уже за командой. */
  earned_capstones?: string[];
  offered: string[];
  proposed_key: string | null;
  proposed_by: string | null;
  i_proposed: BooleanLike;
  i_signed: BooleanLike;
  unsigned?: string[];
  deadline_left: number;
  oath: OathProgress | null;
  current_step: number;
  can_seal: BooleanLike | string;
  finale_check?: FinaleCheck | null;
  tier: number;
  tier_max: number;
  cooldown_mult?: number;
  vow: Vow | null;
  brother_states: BrotherState[];
  abilities: Ability[];
  recruit?: { name: string; slot: string };
  muted: BooleanLike;
  whispers?: Whisper[];
  /** Счётчик шёпота и вестей связи: рост пускает каплю по нити. Заглушённому не приходит. */
  bond_pulse?: number | null;
};

const withProgress = (texts: OathTexts, progress?: OathProgress | null): Oath => ({
  ...texts,
  steps: texts.steps.map((step, index) => ({ sealed: 0, sealed_by: null, condition: null, ...progress?.steps?.[index], ...step })),
});

const offeredOaths = (data: AntagInfoBloodBrotherData): Oath[] =>
  (data.offered || [])
    .map((key) => (data.offer_texts || []).find((texts) => texts.key === key))
    .filter((texts): texts is OathTexts => !!texts)
    .map((texts) => withProgress(texts));

const swornOath = (data: AntagInfoBloodBrotherData): Oath | null =>
  data.oath && data.oath_texts ? withProgress(data.oath_texts, data.oath) : null;

const capstoneEarned = (data: AntagInfoBloodBrotherData, ability: BondAbility) => (data.earned_capstones || []).includes(ability.name);

/** Что ещё держит венец закрытым, или null, если он уже за командой. */
const capstoneLock = (data: AntagInfoBloodBrotherData, ability: BondAbility) => {
  if (capstoneEarned(data, ability)) {
    return null;
  }
  return data.fulfilled?.length ? 'откроет последняя печать клятвы' : `откроет печать ${data.tier_max}`;
};

type MainCommand = {
  id: string;
  label: string;
  disabled: boolean;
  reason: string | null;
  run: () => void;
};

type Tab = 'oath' | 'bond' | 'rules';

const TABS: Tab[] = ['oath', 'bond', 'rules'];
const TAB_NAMES: Record<Tab, string> = { oath: 'Клятва', bond: 'Связь', rules: 'Памятка' };

const STATE_WORDS: Record<BrotherStateKey, string> = {
  ok: 'в порядке',
  hurt: 'в крови',
  crit: 'на грани',
  dead: 'нет пульса',
  cuffed: 'в наручниках',
  muted: 'связь заглушена',
  gone: 'нить порвана',
  severed: 'клятву разорвали',
};

/** Без сознания сердце частит, только если это настоящий крит: во сне оно ровное. */
const HEARTBEAT: Record<BrotherStateKey, string> = {
  ok: 'steady',
  cuffed: 'steady',
  muted: 'steady',
  hurt: 'fast',
  crit: 'steady',
  dead: 'still',
  gone: 'still',
  severed: 'still',
};

const SAG: Record<BrotherStateKey, number> = { ok: 0, muted: 2, cuffed: 5, hurt: 8, crit: 13, dead: 11, gone: 0, severed: 0 };
const BROKEN_STATES: BrotherStateKey[] = ['dead', 'gone', 'severed'];
const PALE_STATES: BrotherStateKey[] = ['hurt', 'crit'];
const THREAD_Y = 14;
const THREAD_TOP = 22;
const THREAD_HEIGHT = 44;
const THREAD_WIDTH = 1000;
const KNOT_LOOPS = [6.5, 5, 3.8, 2.8];
const STEP_ORDINALS = ['Первая', 'Вторая', 'Третья', 'Четвёртая', 'Пятая'];
const SPLASH_BOX = 96;
const SPLASH_X = 48;
const SPLASH_Y = 52;
const REDUCED_MOTION = '(prefers-reduced-motion: reduce)';

const hashText = (text: string) => {
  let hash = 2166136261;
  for (let index = 0; index < text.length; index++) {
    hash ^= text.charCodeAt(index);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
};

const seeded = (seed: number) => {
  let state = seed;
  return () => {
    state = (state + 0x6d2b79f5) | 0;
    let value = Math.imul(state ^ (state >>> 15), 1 | state);
    value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value;
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };
};

const shapes = new Map<string, unknown>();

function memo<T>(key: string, make: () => T): T {
  if (!shapes.has(key)) {
    shapes.set(key, make());
  }
  return shapes.get(key) as T;
}

const fixed = (value: number) => Math.round(value * 10) / 10;

const pointsToPath = (points: number[][]) => points.map(([x, y], index) => `${index ? 'L' : 'M'}${fixed(x)} ${fixed(y)}`).join(' ');

const sagAt = (progress: number, apex: number) => {
  const span = progress < apex ? apex : 1 - apex;
  const distance = (progress - apex) / span;
  return 1 - distance * distance;
};

type ThreadGeometry = {
  paths: string[];
  joined: string[];
  flung: string[];
  frays: string;
  middle: number[] | null;
  breakAt: number[] | null;
};

const threadGeometry = (
  fromName: string,
  toName: string,
  fromX: number,
  toX: number,
  fromState: BrotherStateKey,
  toState: BrotherStateKey,
): ThreadGeometry => {
  const random = seeded(hashText(`${fromName}|${toName}`));
  const fromSag = SAG[fromState] ?? 0;
  const toSag = SAG[toState] ?? 0;
  const sag = Math.max(fromSag, toSag);
  const apex = toSag === fromSag ? 0.5 : toSag > fromSag ? 0.68 : 0.32;
  const kinks = 10;
  const jitter = sag ? 4 : 2.6;
  const points: number[][] = [];
  for (let index = 0; index <= kinks; index++) {
    const progress = index / kinks;
    const inner = index > 0 && index < kinks;
    const kink = inner ? (random() - 0.5) * jitter + (index % 2 ? 1 : -1) * random() * 2.2 : 0;
    const x = fromX + (toX - fromX) * progress + (inner ? (random() - 0.5) * 14 : 0);
    const y = THREAD_Y + sag * sagAt(progress, apex) + kink;
    points.push([x, y]);
  }
  const cut = Math.floor(kinks / 2);
  if (!BROKEN_STATES.includes(fromState) && !BROKEN_STATES.includes(toState)) {
    return { paths: [pointsToPath(points)], joined: [], flung: [], frays: '', middle: points[cut], breakAt: null };
  }
  const left = points.slice(0, cut + 1);
  const right = points.slice(cut);
  const joined = [pointsToPath(left), pointsToPath(right)];
  const breakAt = points[cut];
  const [leftEndX, leftEndY] = left[left.length - 1];
  left[left.length - 1] = [leftEndX - 18, leftEndY + 6 + random() * 4];
  right[0] = [right[0][0] + 18, right[0][1] + 8 + random() * 4];
  const frays = [left[left.length - 1], right[0]]
    .map(([x, y], side) => {
      const away = side ? -1 : 1;
      return `M${fixed(x)} ${fixed(y)} l${fixed(away * (6 + random() * 3))} ${fixed(2 + random() * 3)} M${fixed(x)} ${fixed(y)} l${fixed(away * (4 + random() * 3))} ${fixed(-1 - random() * 3)}`;
    })
    .join(' ');
  const flungLeft = left.map(([x, y], index) => (index === cut ? [breakAt[0] - 46, breakAt[1] - 10] : [x, y - (index === cut - 1 ? 4 : 0)]));
  const flungRight = right.map(([x, y], index) => (index ? [x, y - (index === 1 ? 3 : 0)] : [breakAt[0] + 46, breakAt[1] - 7]));
  const flung = [pointsToPath(flungLeft), pointsToPath(flungRight)];
  return { paths: [pointsToPath(left), pointsToPath(right)], joined, flung, frays, middle: null, breakAt };
};

/** Ломаная нити между двумя братьями: изломы от имён, провисание к раненому, обрыв у мёртвого и ушедшего. */
export const threadPath = (
  fromName: string,
  toName: string,
  fromX: number,
  toX: number,
  fromState: BrotherStateKey,
  toState: BrotherStateKey,
) => threadGeometry(fromName, toName, fromX, toX, fromState, toState).paths;

const threadTail = (name: string, fromX: number, direction: number) => {
  const random = seeded(hashText(`${name}|хвост`));
  const points: number[][] = [[fromX, THREAD_Y]];
  for (let index = 1; index <= 4; index++) {
    points.push([fromX + direction * index * 11, THREAD_Y + index * index * 1.1 + (random() - 0.5) * 2]);
  }
  return pointsToPath(points);
};

const raggedEdge = (seed: string, depth: number, step: number) => {
  const random = seeded(hashText(seed));
  const tear = () => fixed(random() * depth + (random() < 0.07 ? depth * 0.9 : 0));
  const points: string[] = [];
  for (let at = 0; at < 100; at += step) {
    points.push(`${fixed(at)}% ${tear()}px`);
  }
  for (let at = 0; at < 100; at += step) {
    points.push(`calc(100% - ${tear()}px) ${fixed(at)}%`);
  }
  for (let at = 100; at > 0; at -= step) {
    points.push(`${fixed(at)}% calc(100% - ${tear()}px)`);
  }
  for (let at = 100; at > 0; at -= step) {
    points.push(`${tear()}px ${fixed(at)}%`);
  }
  return `polygon(${points.join(', ')})`;
};

const CLOTH_EDGE = raggedEdge('полоса ткани', 6, 1.1);

const roughFrame = (seed: string, width: number, height: number, inset: number, wobble: number) => {
  const random = seeded(hashText(seed));
  const corners = [
    [inset, inset],
    [width - inset, inset],
    [width - inset, height - inset],
    [inset, height - inset],
  ];
  const points: number[][] = [];
  corners.forEach(([x, y], index) => {
    const [nextX, nextY] = corners[(index + 1) % 4];
    const pieces = Math.max(3, Math.round(Math.hypot(nextX - x, nextY - y) / 26));
    for (let piece = 0; piece < pieces; piece++) {
      const progress = piece / pieces;
      points.push([x + (nextX - x) * progress + (random() - 0.5) * wobble, y + (nextY - y) * progress + (random() - 0.5) * wobble]);
    }
  });
  points.push([points[0][0] + 3, points[0][1] - 1]);
  return pointsToPath(points);
};

const brushStroke = (seed: string, width: number, height: number) =>
  memo(`мазок|${seed}|${width}|${height}`, () => {
    const random = seeded(hashText(seed));
    const pieces = Math.max(6, Math.round(width / 14));
    const top: number[][] = [];
    const bottom: number[][] = [];
    for (let piece = 0; piece <= pieces; piece++) {
      const progress = piece / pieces;
      const taper = Math.min(1, Math.sin(progress * Math.PI) * 2.2);
      const half = (height / 2) * (0.35 + 0.65 * taper);
      const middle = height / 2 + (random() - 0.5) * height * 0.18;
      top.push([progress * width, middle - half * (0.8 + random() * 0.2)]);
      bottom.push([progress * width, middle + half * (0.8 + random() * 0.2)]);
    }
    return `${pointsToPath([...top, ...bottom.reverse()])} Z`;
  });

type Stroke = { body: string; hairs: string; dots: string };

const DIVIDER_LENGTH = 700;
const DIVIDER_BREADTH = 10;

/** Сухой мазок кистью: тяжёлое начало, сход на волоски, пара брызг; форма и направление - от seed. */
const dividerStroke = (seed: string, vertical: boolean) =>
  memo<Stroke>(`черта|${seed}|${vertical}`, () => {
    const random = seeded(hashText(seed));
    const place = (points: number[][]) => points.map(([along, across]) => (vertical ? [across, along] : [along, across]));
    const shape = (points: number[][], close: boolean) => `${pointsToPath(place(points))}${close ? ' Z' : ''}`;
    const reversed = random() < 0.5;
    const at = (progress: number) => DIVIDER_LENGTH * (reversed ? 1 - progress : progress);
    const tail = 0.72 + random() * 0.14;
    const weight = 0.3 + random() * 0.14;
    const waves = 1 + random() * 2;
    const phase = random() * Math.PI * 2;
    const centre = (progress: number) => DIVIDER_BREADTH / 2 + Math.sin(progress * Math.PI * waves + phase) * DIVIDER_BREADTH * 0.1;
    const pieces = 40;
    const top: number[][] = [];
    const bottom: number[][] = [];
    for (let piece = 0; piece <= pieces; piece++) {
      const progress = (piece / pieces) * tail;
      const pressure = (0.55 + 0.45 * Math.min(1, progress * 20)) * (1 - Math.pow(progress / tail, 3) * 0.8);
      const half = DIVIDER_BREADTH * weight * pressure;
      top.push([at(progress), centre(progress) - half * (0.8 + random() * 0.2)]);
      bottom.push([at(progress), centre(progress) + half * (0.8 + random() * 0.2)]);
    }
    const hairs: string[] = [];
    const hairCount = 2 + Math.floor(random() * 3);
    for (let hair = 0; hair < hairCount; hair++) {
      const from = tail - 0.1 - random() * 0.12;
      const to = Math.min(1, tail + 0.05 + random() * 0.2);
      const offset = (random() - 0.5) * DIVIDER_BREADTH * weight * 1.4;
      const line: number[][] = [];
      for (let piece = 0; piece <= 6; piece++) {
        const progress = from + ((to - from) * piece) / 6;
        line.push([at(progress), centre(progress) + offset + (random() - 0.5) * 0.7]);
      }
      hairs.push(shape(line, false));
    }
    const dots: string[] = [];
    const dotCount = 1 + Math.floor(random() * 3);
    for (let dot = 0; dot < dotCount; dot++) {
      const size = 1.4 + random() * 1.4;
      const across = random() < 0.5 ? random() : DIVIDER_BREADTH - size - random();
      const along = at(random() * 0.1) + (random() - 0.5) * 24;
      dots.push(shape([[along, across], [along + size * 2.4, across], [along + size * 2.4, across + size], [along, across + size]], true));
    }
    return { body: shape([...top, ...bottom.reverse()], true), hairs: hairs.join(' '), dots: dots.join(' ') };
  });

type Stitching = { thread: string; shadow: string; holes: string };

/** Стежки заплаты: шаг, длина, наклон и изгиб у каждого свой, тень нити смещена вниз-вправо. */
const stitching = (seed: string, width: number, height: number) =>
  memo<Stitching>(`стежки|${seed}|${width}|${height}`, () => {
    const random = seeded(hashText(seed));
    const thread: string[] = [];
    const shadow: string[] = [];
    const holes: string[] = [];
    const edge = (fromX: number, fromY: number, toX: number, toY: number) => {
      const length = Math.hypot(toX - fromX, toY - fromY);
      const dirX = (toX - fromX) / length;
      const dirY = (toY - fromY) / length;
      let along = 4 + random() * 6;
      while (along < length - 6) {
        const size = 4.5 + random() * 4;
        const angle = Math.atan2(dirY, dirX) + 0.3 + (random() - 0.5) * 0.5;
        const wobble = (random() - 0.5) * 2.2;
        const centerX = fromX + dirX * along - dirY * wobble;
        const centerY = fromY + dirY * along + dirX * wobble;
        const [cos, sin] = [Math.cos(angle) * (size / 2), Math.sin(angle) * (size / 2)];
        const bend = 0.4 + random() * 0.9;
        const curve = (dx: number, dy: number) =>
          `M${fixed(centerX - cos + dx)} ${fixed(centerY - sin + dy)} Q${fixed(centerX - Math.sin(angle) * bend + dx)} ${fixed(centerY + Math.cos(angle) * bend + dy)} ${fixed(centerX + cos + dx)} ${fixed(centerY + sin + dy)}`;
        thread.push(curve(0, 0));
        shadow.push(curve(1.1, 1.5));
        holes.push(`M${fixed(centerX - cos)} ${fixed(centerY - sin)}h0.1M${fixed(centerX + cos)} ${fixed(centerY + sin)}h0.1`);
        along += size + 4.5 + random() * 6.5;
      }
    };
    edge(6, 5, width - 6, 5);
    edge(width - 5, 6, width - 5, height - 6);
    edge(width - 6, height - 5, 6, height - 5);
    edge(5, height - 6, 5, 6);
    return { thread: thread.join(' '), shadow: shadow.join(' '), holes: holes.join(' ') };
  });

const FIBER_DEPTH = 16;
const FIBER_EDGE = 10;

/** Волокна на краю ткани: корни чуть внутри кромки, концы торчат наружу; vertical меняет оси местами. */
const fiberTile = (seed: string, length: number, count: number, reach: number, vertical: boolean) =>
  memo(`волокна|${seed}|${length}|${vertical}`, () => {
    const random = seeded(hashText(seed));
    const hairs: string[] = [];
    for (let hair = 0; hair < count; hair++) {
      const root = FIBER_EDGE + 1 + random() * 4;
      const tip = Math.max(0.5, root - reach * (0.35 + random() * 0.65));
      const along = random() * length;
      const drift = (random() - 0.5) * reach * 1.3;
      const points = [
        [along, root],
        [along + drift * (0.15 + random() * 0.5) + (random() - 0.5) * 2.5, (root + tip) / 2],
        [along + drift, tip],
      ];
      hairs.push(pointsToPath(vertical ? points.map(([x, y]) => [y, x]) : points));
    }
    return hairs.join(' ');
  });

const PATCH_STITCHES = stitching('заплата', 720, 104);
const COMMAND_OUTLINE = roughFrame('контур', 240, 52, 3, 4);
const COMMAND_ECHO = roughFrame('контур второй', 240, 52, 5, 6);
const COMMAND_FILL = roughFrame('заливка', 240, 52, 4, 5);
const COMMAND_SMEAR = brushStroke('мазок', 260, 30);

const lineShift = (text: string) => (hashText(text) % 11) - 3;

const shifted = (text: string): CSSProperties => ({ marginLeft: `${lineShift(text)}px` });

const inkLine = (line: number) => ({ '--bb-line': line }) as CSSProperties;

const PALM = [
  '......##........',
  '...##.##.##.....',
  '...##.##.##.....',
  '##.##.##.##.....',
  '##.##.##.##.....',
  '##.##.##.##...##',
  '##.##.##.##..###',
  '###########.###.',
  '##############..',
  '#############...',
  '.############...',
  '.############...',
  '..##########....',
  '..##########....',
  '...########.....',
  '....######......',
];

const CREASES = ['2,9', '3,9', '4,10', '5,10', '6,10', '7,11', '8,11', '9,10', '10,8', '11,9', '6,13', '7,13', '1,4', '6,2', '9,5'];

const HEART_REST = ['.##...##.', '####.####', '#########', '#########', '.#######.', '..#####..', '...###...', '....#....'];

const HEART_SWELL = [
  '.###...###.',
  '#####.#####',
  '###########',
  '###########',
  '###########',
  '.#########.',
  '..#######..',
  '...#####...',
  '....###....',
  '.....#.....',
];

const HEART_SQUEEZE = ['.##.##.', '#######', '#######', '.#####.', '..###..', '...#...'];

const DRIP = ['..#..', '..#..', '.###.', '.###.', '#####', '#####', '.###.'];

const cellsOf = (rows: string[], offsetX = 0, offsetY = 0) => {
  const cells: number[][] = [];
  rows.forEach((row, y) => [...row].forEach((pixel, x) => pixel === '#' && cells.push([x + offsetX, y + offsetY])));
  return cells;
};

const outlineOf = (rows: string[], offsetX = 0, offsetY = 0) => {
  const filled = (x: number, y: number) => rows[y]?.[x] === '#';
  return cellsOf(rows).filter(([x, y]) => !filled(x - 1, y) || !filled(x + 1, y) || !filled(x, y - 1) || !filled(x, y + 1)).map(([x, y]) => [x + offsetX, y + offsetY]);
};

const cellsToPath = (cells: number[][]) => cells.map(([x, y]) => `M${x} ${y}h1v1h-1z`).join('');

const PALM_FRESH = cellsToPath(cellsOf(PALM).filter(([x, y]) => !CREASES.includes(`${x},${y}`)));
const PALM_EMPTY = cellsToPath(outlineOf(PALM).filter(([x, y]) => (x + y) % 2 === 0));
const PALM_SMEAR_BASE = cellsToPath(
  cellsOf(PALM).filter(([x, y]) => !CREASES.includes(`${x},${y}`) && hashText(`${x}:${y}`) % 5 !== 0),
);
const PALM_SMEAR_DRAG = cellsToPath(
  cellsOf(PALM)
    .filter(([x, y]) => y > 7 && hashText(`${y}:${x}`) % 3 === 0)
    .map(([x, y]) => [x + 1, y + 2 + (hashText(`${x}`) % 3)])
    .filter(([, y]) => y < PALM.length),
);
const HEART_FRAMES = {
  rest: cellsToPath(cellsOf(HEART_REST, 1, 1)),
  swell: cellsToPath(cellsOf(HEART_SWELL)),
  squeeze: cellsToPath(cellsOf(HEART_SQUEEZE, 2, 2)),
};
const HEART_SHINE = { rest: cellsToPath([[2, 2]]), swell: cellsToPath([[1, 1], [2, 2]]) };
const HEART_HOLLOW = cellsToPath(outlineOf(HEART_REST, 1, 1));
const DRIP_PATH = cellsToPath(cellsOf(DRIP));

type Drop = { x: number; y: number; size: number; fresh: boolean };

/** Брызги вокруг свежей печати: влево, вверх и вниз от ладони, к тексту справа не летят. */
const splatter = (seed: string) =>
  memo<Drop[]>(`брызги|${seed}`, () => {
    const random = seeded(hashText(`${seed}|брызги`));
    const drops: Drop[] = [];
    const count = 5 + Math.floor(random() * 3);
    for (let drop = 0; drop < count; drop++) {
      const angle = ((120 + random() * 200) * Math.PI) / 180;
      const distance = 33 + random() * 12;
      const size = random() < 0.3 ? 4 : random() < 0.6 ? 3 : 2;
      drops.push({
        x: fixed(SPLASH_X + Math.cos(angle) * distance),
        y: fixed(SPLASH_Y + Math.sin(angle) * distance * 0.85),
        size,
        fresh: random() < 0.3,
      });
    }
    return drops;
  });

const blot = (seed: string) =>
  memo(`пятно|${seed}`, () => {
    const random = seeded(hashText(`${seed}|пятно`));
    const points: number[][] = [];
    const count = 20;
    for (let index = 0; index < count; index++) {
      const angle = (index / count) * Math.PI * 2;
      const reach = (27 + random() * 9) * (random() < 0.15 ? 1.22 : 1);
      points.push([SPLASH_X + Math.cos(angle) * reach, SPLASH_Y + Math.sin(angle) * reach * 0.88]);
    }
    return `${pointsToPath(points)} Z`;
  });

type SealState = 'empty' | 'fresh' | 'smeared';

const SEAL_ASSETS: Record<SealState, string> = {
  empty: 'blood_brothers_seal_empty.png',
  fresh: 'blood_brothers_seal_fresh.png',
  smeared: 'blood_brothers_seal_smeared.png',
};

/** URL ассета, если картинка реально загрузилась; до этого окно рисует свою замену. */
const useAsset = (name: string) => {
  const url = resolveAsset(name);
  const [loaded, setLoaded] = useState<string | null>(null);
  useEffect(() => {
    let alive = true;
    const probe = new Image();
    probe.onload = () => alive && setLoaded(url);
    probe.src = url;
    return () => {
      alive = false;
      probe.onload = null;
    };
  }, [url]);
  return loaded === url ? url : null;
};

const prefersCalm = () => typeof window.matchMedia === 'function' && window.matchMedia(REDUCED_MOTION).matches;

/** Системная настройка «меньше движения»: при ней окно меняет состояние без анимаций. */
const useCalm = () => {
  const [calm, setCalm] = useState(prefersCalm);
  useEffect(() => {
    if (typeof window.matchMedia !== 'function') {
      return;
    }
    const query = window.matchMedia(REDUCED_MOTION);
    const changed = () => setCalm(query.matches);
    query.addEventListener?.('change', changed);
    return () => query.removeEventListener?.('change', changed);
  }, []);
  return calm;
};

type Moment<T> = { serial: number; info: T };

/** Событие по смене данных: сравнивает значение с прошлым рендером, первый рендер событием не считается. */
const useMoment = <V extends string | number | boolean, T>(
  value: V,
  detect: (previous: V, next: V) => T | null,
  quiet: boolean,
): [Moment<T> | null, () => void] => {
  const [seen, setSeen] = useState(value);
  const [moment, setMoment] = useState<Moment<T> | null>(null);
  if (seen !== value) {
    setSeen(value);
    const info = quiet ? null : detect(seen, value);
    if (info !== null) {
      setMoment({ serial: (moment?.serial || 0) + 1, info });
    }
  }
  return [moment, () => setMoment(null)];
};

const ownEnd = (done: () => void) => (event: AnimationEvent<Element>) => {
  if (event.target === event.currentTarget) {
    done();
  }
};

const formatTime = (seconds: number) => {
  const total = Math.max(0, Math.ceil(seconds));
  const rest = total % 60;
  return `${Math.floor(total / 60)}:${rest < 10 ? '0' : ''}${rest}`;
};

const cooldownText = (ability: BondAbility, multiplier: number) => {
  const seconds = Math.round((ability.cooldown || 0) * multiplier);
  if (!seconds) {
    return ability.passive ? 'пассивно' : 'без перезарядки';
  }
  const minutes = Math.floor(seconds / 60);
  const rest = seconds % 60;
  const amount = [minutes && `${minutes} мин`, rest && `${rest} с`].filter(Boolean).join(' ');
  return `${ability.passive ? 'пассивно, ' : ''}перезарядка ${amount}`;
};

type Seals = Record<SealState, string | null>;

type SealProps = { state: SealState; asset: string | null; extra?: string };

const Seal = ({ state, asset, extra }: SealProps) => {
  const className = `AntagInfoBloodBrother__seal AntagInfoBloodBrother__seal--${state}${extra ? ` ${extra}` : ''}`;
  if (asset) {
    return <img className={className} src={asset} alt="" />;
  }
  return (
    <svg className={className} viewBox="0 0 16 16" shapeRendering="crispEdges" aria-hidden>
      {state === 'empty' && <path d={PALM_EMPTY} />}
      {state === 'fresh' && <path d={PALM_FRESH} />}
      {state === 'smeared' && (
        <>
          <path d={PALM_SMEAR_BASE} />
          <path className="AntagInfoBloodBrother__sealDrag" d={PALM_SMEAR_DRAG} />
        </>
      )}
    </svg>
  );
};

const Splatter = ({ seed }: { seed: string }) => (
  <svg className="AntagInfoBloodBrother__splatter" viewBox={`0 0 ${SPLASH_BOX} ${SPLASH_BOX}`} shapeRendering="crispEdges" aria-hidden>
    {splatter(seed).map((drop, index) => (
      <rect
        key={index}
        className={'AntagInfoBloodBrother__drop' + (drop.fresh ? ' AntagInfoBloodBrother__drop--fresh' : '')}
        x={drop.x}
        y={drop.y}
        width={drop.size}
        height={drop.size}
        style={{ '--bb-dx': `${fixed(SPLASH_X - drop.x)}px`, '--bb-dy': `${fixed(SPLASH_Y - drop.y)}px` } as CSSProperties}
      />
    ))}
  </svg>
);

const Heart = ({ state, critical }: { state: BrotherStateKey; critical: boolean }) => {
  const beat = critical && state === 'crit' ? 'racing' : HEARTBEAT[state] || 'steady';
  return (
    <svg className="AntagInfoBloodBrother__heart" data-beat={beat} viewBox="0 0 11 10" shapeRendering="crispEdges" aria-hidden>
      {beat === 'still' ? (
        <path d={HEART_HOLLOW} />
      ) : (
        <>
          <g className="AntagInfoBloodBrother__heartFrame AntagInfoBloodBrother__heartFrame--rest">
            <path d={HEART_FRAMES.rest} />
            <path className="AntagInfoBloodBrother__heartShine" d={HEART_SHINE.rest} />
          </g>
          <g className="AntagInfoBloodBrother__heartFrame AntagInfoBloodBrother__heartFrame--swell">
            <path d={HEART_FRAMES.swell} />
            <path className="AntagInfoBloodBrother__heartShine" d={HEART_SHINE.swell} />
          </g>
          <g className="AntagInfoBloodBrother__heartFrame AntagInfoBloodBrother__heartFrame--squeeze">
            <path d={HEART_FRAMES.squeeze} />
          </g>
        </>
      )}
    </svg>
  );
};

type KnotProps = { tier: number; looseFrom: number | null; onTightened: () => void };

const Knot = ({ tier, looseFrom, onTightened }: KnotProps) => {
  const level = Math.max(0, Math.min(tier, 3));
  const loop = KNOT_LOOPS[level];
  const tightening = looseFrom !== null;
  const loose = tightening ? KNOT_LOOPS[Math.max(0, Math.min(looseFrom, 3))] / loop : 1;
  return (
    <svg
      className={'AntagInfoBloodBrother__knot' + (tightening ? ' AntagInfoBloodBrother__knot--tightening' : '')}
      data-tier={tier}
      viewBox="-14 -10 28 20"
      style={{ '--bb-loose': fixed(loose) } as CSSProperties}
      aria-hidden>
      <ellipse
        className="AntagInfoBloodBrother__knotLoop"
        rx={loop * 1.3}
        ry={loop}
        onAnimationEnd={tightening ? ownEnd(onTightened) : undefined}
      />
      {tier >= 3 && <ellipse className="AntagInfoBloodBrother__knotCore" rx={loop * 1.3} ry={loop} />}
      {Array.from({ length: level }, (_, wrap) => (
        <path
          key={wrap}
          className="AntagInfoBloodBrother__knotWrap"
          pathLength={1}
          d={`M${fixed((wrap - (tier - 1) / 2) * 2.6 - 1.2)} ${fixed(-loop - 2)} l2.4 ${fixed(loop * 2 + 4)}`}
        />
      ))}
    </svg>
  );
};

type DividerProps = { seed: string; vertical?: boolean; extra?: string; ink?: number };

const Divider = ({ seed, vertical, extra, ink }: DividerProps) => {
  const stroke = dividerStroke(seed, !!vertical);
  const box = vertical ? `0 0 ${DIVIDER_BREADTH} ${DIVIDER_LENGTH}` : `0 0 ${DIVIDER_LENGTH} ${DIVIDER_BREADTH}`;
  return (
    <svg
      className={`AntagInfoBloodBrother__divider${vertical ? ' AntagInfoBloodBrother__divider--vertical' : ''}${extra ? ` ${extra}` : ''}${ink === undefined ? '' : ' AntagInfoBloodBrother__ink'}`}
      style={ink === undefined ? undefined : inkLine(ink)}
      viewBox={box}
      preserveAspectRatio="none"
      aria-hidden>
      <path className="AntagInfoBloodBrother__dividerBody" d={stroke.body} />
      <path className="AntagInfoBloodBrother__dividerHairs" d={stroke.hairs} />
      <path className="AntagInfoBloodBrother__dividerBody" d={stroke.dots} />
    </svg>
  );
};

const Soak = ({ seed }: { seed: string }) => (
  <svg className="AntagInfoBloodBrother__soak" viewBox="0 0 300 40" preserveAspectRatio="none" aria-hidden>
    <path d={brushStroke(`пятно|${seed}`, 300, 40)} />
  </svg>
);

const Title = ({ text, ink }: { text: string; ink?: number }) => (
  <div className={'AntagInfoBloodBrother__title' + (ink === undefined ? '' : ' AntagInfoBloodBrother__ink')} style={ink === undefined ? undefined : inkLine(ink)}>
    <svg className="AntagInfoBloodBrother__titleSmear" viewBox="0 0 320 16" preserveAspectRatio="none" aria-hidden>
      <path d={brushStroke(`под именем|${text}`, 320, 16)} />
    </svg>
    <span className="AntagInfoBloodBrother__titleText">{text}</span>
  </div>
);

const Quote = ({ children, ink }: { children: ReactNode; ink?: number }) => (
  <blockquote className={'AntagInfoBloodBrother__quote' + (ink === undefined ? '' : ' AntagInfoBloodBrother__ink')} style={ink === undefined ? undefined : inkLine(ink)}>
    <span className="AntagInfoBloodBrother__quoteMark" aria-hidden>
      «
    </span>
    {children}
    <span className="AntagInfoBloodBrother__quoteMark" aria-hidden>
      »
    </span>
  </blockquote>
);

const FIBER_LAYERS = [
  { name: 'short', seed: 'короткие волокна', length: 89, count: 9, reach: 6 },
  { name: 'long', seed: 'длинные волокна', length: 233, count: 3, reach: 11 },
];

const FiberStrip = ({ side }: { side: 'top' | 'bottom' | 'left' | 'right' }) => {
  const vertical = side === 'left' || side === 'right';
  return (
    <svg className={`AntagInfoBloodBrother__fibers AntagInfoBloodBrother__fibers--${side}`} shapeRendering="crispEdges" aria-hidden>
      <defs>
        {FIBER_LAYERS.map((layer) => (
          <pattern
            key={layer.name}
            id={`bb-fibers-${side}-${layer.name}`}
            patternUnits="userSpaceOnUse"
            width={vertical ? FIBER_DEPTH : layer.length}
            height={vertical ? layer.length : FIBER_DEPTH}>
            <path
              className={`AntagInfoBloodBrother__fiber AntagInfoBloodBrother__fiber--${layer.name}`}
              d={fiberTile(`${layer.seed}|${side}`, layer.length, layer.count, layer.reach, vertical)}
            />
          </pattern>
        ))}
      </defs>
      {FIBER_LAYERS.map((layer) => (
        <rect key={layer.name} width="100%" height="100%" fill={`url(#bb-fibers-${side}-${layer.name})`} />
      ))}
    </svg>
  );
};

type CommandProps = { command: MainCommand; pressed: boolean; smear: string | null; onRun: () => void };

/** Главная команда: слово в кровавом контуре, доступная набухает кровью, нажатие оставляет мазок. */
const Command = ({ command, pressed, smear, onRun }: CommandProps) => {
  const onKeyDown = (event: KeyboardEvent<HTMLSpanElement>) => {
    if ((event.code !== 'Enter' && event.code !== 'NumpadEnter' && event.code !== 'Space') || event.repeat) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    onRun();
  };
  return (
    <div className="AntagInfoBloodBrother__command">
      <span
        role="button"
        aria-disabled={command.disabled}
        tabIndex={command.disabled ? -1 : 0}
        className={'AntagInfoBloodBrother__cmd' + (command.disabled ? ' AntagInfoBloodBrother__cmd--off' : '')}
        onClick={onRun}
        onKeyDown={onKeyDown}>
        <svg className="AntagInfoBloodBrother__cmdFrame" viewBox="0 0 240 52" preserveAspectRatio="none" aria-hidden>
          <path className="AntagInfoBloodBrother__cmdFill" d={COMMAND_FILL} />
          <path className="AntagInfoBloodBrother__cmdSwell" d={COMMAND_OUTLINE} />
          <path className="AntagInfoBloodBrother__cmdEcho" d={COMMAND_ECHO} />
          <path className="AntagInfoBloodBrother__cmdLine" d={COMMAND_OUTLINE} />
        </svg>
        <svg className="AntagInfoBloodBrother__cmdDrip" viewBox="0 0 5 7" shapeRendering="crispEdges" aria-hidden>
          <path d={DRIP_PATH} />
        </svg>
        {pressed &&
          (smear ? (
            <span className="AntagInfoBloodBrother__cmdSmear" style={{ backgroundImage: `url("${smear}")` }} aria-hidden />
          ) : (
            <svg className="AntagInfoBloodBrother__cmdSmear" viewBox="0 0 260 30" preserveAspectRatio="none" aria-hidden>
              <path d={COMMAND_SMEAR} />
            </svg>
          ))}
        <span className="AntagInfoBloodBrother__cmdLabel">
          {command.label}
          <span className="AntagInfoBloodBrother__cmdLit" aria-hidden>
            {command.label}
          </span>
        </span>
      </span>
      {command.disabled && !!command.reason && <div className="AntagInfoBloodBrother__reason">{command.reason}</div>}
    </div>
  );
};

type KeyHandlers = {
  onPick: (index: number) => void;
  onMove: (delta: number) => void;
  onEnter: () => void;
  onTab: (delta: number) => void;
};

const PICK_KEYS: Record<string, number> = { Digit1: 0, Digit2: 1, Digit3: 2, Numpad1: 0, Numpad2: 1, Numpad3: 2 };
const ACTIVE_ROLES = '[role="button"], [role="link"], [role="tab"]';

/** Клавиши окна: Tab - вкладки, 1-3 и стрелки - выбор, Enter - главная команда. Поля ввода и элемент в фокусе не трогает. */
const useOathKeys = (handlers: KeyHandlers) => {
  const ref = useRef(handlers);
  ref.current = handlers;
  useEffect(() => {
    const onKeyDown = (event: globalThis.KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      if (event.ctrlKey || event.altKey || event.metaKey) return;
      if (event.repeat && (event.code === 'Enter' || event.code === 'NumpadEnter')) return;
      if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)) return;
      const onControl = typeof target?.closest === 'function' && !!target.closest(ACTIVE_ROLES);
      if (onControl && (event.code === 'Enter' || event.code === 'NumpadEnter')) return;
      if (event.code === 'Tab') {
        ref.current.onTab(event.shiftKey ? -1 : 1);
      } else if (event.code in PICK_KEYS) {
        ref.current.onPick(PICK_KEYS[event.code]);
      } else if (event.code === 'ArrowDown' || event.code === 'ArrowRight') {
        ref.current.onMove(1);
      } else if (event.code === 'ArrowUp' || event.code === 'ArrowLeft') {
        ref.current.onMove(-1);
      } else if (event.code === 'Enter' || event.code === 'NumpadEnter') {
        ref.current.onEnter();
      } else {
        return;
      }
      event.preventDefault();
    };
    window.addEventListener('keydown', onKeyDown, true);
    return () => window.removeEventListener('keydown', onKeyDown, true);
  }, []);
};

const newlyTorn = (previous: string, next: string) => {
  const before = previous.split('\n');
  const fresh = next.split('\n').filter((key) => key && !before.includes(key));
  return fresh.length ? fresh : null;
};

/** Предыстория команды: третьему брату она чужая, поэтому подписана и взята в кавычки. */
const Backstory = ({ data }: { data: AntagInfoBloodBrotherData }) =>
  data.backstory_owner ? (
    data.backstory
  ) : (
    <>
      <span className="AntagInfoBloodBrother__backstoryOwner">Их общая история:</span> «{data.backstory}»
    </>
  );

const Thread = ({ calm }: { calm: boolean }) => {
  const { data } = useBackend<AntagInfoBloodBrotherData>();
  const states = data.brother_states?.length
    ? data.brother_states
    : (data.brothers || []).map((brother): BrotherState => ({ name: brother.name, state: 'ok', direction: null, self: brother.self }));
  const jobs: Record<string, string> = {};
  for (const brother of data.brothers || []) {
    jobs[brother.name] = brother.job;
  }
  const count = states.length;
  const margin = 150;
  const spots = states.map((_, index) =>
    count > 1 ? margin + ((THREAD_WIDTH - margin * 2) * index) / (count - 1) : THREAD_WIDTH / 2,
  );
  const segments = states.slice(1).map((brother, index) => {
    const previous = states[index];
    const geometry = threadGeometry(previous.name, brother.name, spots[index], spots[index + 1], previous.state, brother.state);
    const torn = geometry.paths.length > 1;
    let mood = '';
    if (torn) {
      mood = ' AntagInfoBloodBrother__strand--torn';
    } else if (previous.state === 'muted' || brother.state === 'muted') {
      mood = ' AntagInfoBloodBrother__strand--muted';
    } else if (PALE_STATES.includes(previous.state) || PALE_STATES.includes(brother.state)) {
      mood = ' AntagInfoBloodBrother__strand--pale';
    }
    return { key: `${previous.name}|${brother.name}`, geometry, torn, mood };
  });
  const whole = segments.filter((segment) => !segment.torn);
  const [snap, clearSnap] = useMoment(
    segments
      .filter((segment) => segment.torn)
      .map((segment) => segment.key)
      .join('\n'),
    newlyTorn,
    calm,
  );
  const [tighten, clearTighten] = useMoment(data.tier || 0, (previous, next) => (next > previous ? previous : null), calm);
  const [pulse, clearPulse] = useMoment(
    data.bond_pulse ?? -1,
    (previous, next) => (previous >= 0 && next > previous && whole.length ? true : null),
    calm,
  );
  return (
    <div className="AntagInfoBloodBrother__header" data-muted={data.muted ? 'true' : undefined}>
      <div className="AntagInfoBloodBrother__ties">
        <svg
          className="AntagInfoBloodBrother__thread"
          viewBox={`0 0 ${THREAD_WIDTH} ${THREAD_HEIGHT}`}
          preserveAspectRatio="none"
          aria-hidden>
          {count > 0 && <path className="AntagInfoBloodBrother__strand" d={threadTail(states[0].name, spots[0], -1)} />}
          {count > 1 && (
            <path className="AntagInfoBloodBrother__strand" d={threadTail(states[count - 1].name, spots[count - 1], 1)} />
          )}
          {segments.map((segment) => {
            const snapping = !!snap?.info.includes(segment.key);
            return (
              <g key={segment.key}>
                {segment.geometry.paths.map((path, part) => (
                  <path
                    key={`${segment.torn ? 'torn' : 'whole'}-${part}`}
                    className={'AntagInfoBloodBrother__strand' + segment.mood + (snapping ? ' AntagInfoBloodBrother__strand--snapping' : '')}
                    d={path}
                    style={
                      snapping
                        ? ({
                          '--bb-from': `path("${segment.geometry.joined[part]}")`,
                          '--bb-flung': `path("${segment.geometry.flung[part]}")`,
                        } as CSSProperties)
                        : undefined
                    }
                    onAnimationEnd={snapping && !part ? ownEnd(clearSnap) : undefined}
                  />
                ))}
                {segment.torn && (
                  <path className={'AntagInfoBloodBrother__fray' + (snapping ? ' AntagInfoBloodBrother__fray--fresh' : '')} d={segment.geometry.frays} />
                )}
                {snapping && !!segment.geometry.breakAt && (
                  <g className="AntagInfoBloodBrother__spill">
                    <rect x={segment.geometry.breakAt[0] - 6} y={segment.geometry.breakAt[1]} width={5} height={4} />
                    <rect x={segment.geometry.breakAt[0] + 3} y={segment.geometry.breakAt[1] + 1} width={4} height={3} />
                  </g>
                )}
              </g>
            );
          })}
          {!!pulse &&
            whole.map((segment, order) => (
              <path
                key={`${segment.key}-${pulse.serial}`}
                className="AntagInfoBloodBrother__bead"
                pathLength={1}
                d={segment.geometry.paths[0]}
                style={{ '--bb-order': order } as CSSProperties}
                onAnimationEnd={order === whole.length - 1 ? ownEnd(clearPulse) : undefined}
              />
            ))}
        </svg>
        {segments.map(
          (segment) =>
            !!segment.geometry.middle && (
              <div
                key={segment.key}
                className="AntagInfoBloodBrother__knotTrack"
                style={{ transform: `translate(${fixed(segment.geometry.middle[0] / 10)}%, ${fixed(THREAD_TOP + segment.geometry.middle[1])}px)` }}>
                <Knot tier={data.tier} looseFrom={tighten ? tighten.info : null} onTightened={clearTighten} />
              </div>
            ),
        )}
        {states.map((brother, index) => (
          <div
            key={brother.name}
            className={'AntagInfoBloodBrother__brother' + (BROKEN_STATES.includes(brother.state) ? ' AntagInfoBloodBrother__brother--dim' : '')}
            data-state={brother.state}
            style={{ left: `${spots[index] / 10}%` }}>
            <div className="AntagInfoBloodBrother__brotherName">
              <Heart state={brother.state} critical={!!brother.critical} />
              {brother.name}
            </div>
            <span className="AntagInfoBloodBrother__pin" aria-hidden />
            <div className="AntagInfoBloodBrother__brotherJob">{jobs[brother.name]}</div>
            <div className="AntagInfoBloodBrother__brotherState">
              {brother.state_text || STATE_WORDS[brother.state] || brother.state}
              {brother.self ? ', это вы' : brother.direction ? `, ${brother.direction}` : ''}
            </div>
          </div>
        ))}
      </div>
      {!!data.backstory && !data.oath && (
        <div className="AntagInfoBloodBrother__backstory">
          <Backstory data={data} />
        </div>
      )}
    </div>
  );
};

type Act = (action: string, payload?: object) => void;

const choosingCommand = (data: AntagInfoBloodBrotherData, selected: Oath | undefined, act: Act): MainCommand | null => {
  if (!selected) {
    return null;
  }
  const muted = data.muted ? 'связь заглушена' : null;
  if (data.proposed_key === selected.key) {
    if (data.i_proposed) {
      return { id: `wait:${selected.key}`, label: 'Предложено', disabled: true, reason: null, run: () => undefined };
    }
    if (data.i_signed) {
      return { id: `signed:${selected.key}`, label: 'Подписано', disabled: true, reason: null, run: () => undefined };
    }
    return { id: `sign:${selected.key}`, label: 'Подписать кровью', disabled: !!muted, reason: muted, run: () => act('sign') };
  }
  return {
    id: `propose:${selected.key}`,
    label: 'Предложить',
    disabled: !!muted,
    reason: muted,
    run: () => act('propose', { key: selected.key }),
  };
};

const sealCommand = (data: AntagInfoBloodBrotherData, act: Act): MainCommand | null => {
  if (!data.oath || !data.current_step) {
    return null;
  }
  const ready = data.can_seal === 1 || data.can_seal === true;
  let reason: string | null = null;
  if (data.muted) {
    reason = 'связь заглушена';
  } else if (!ready) {
    reason = typeof data.can_seal === 'string' ? data.can_seal : 'печать сейчас не встанет';
  }
  return { id: `seal:${data.current_step}`, label: 'Скрепить кровью', disabled: !!reason, reason, run: () => act('seal') };
};

const proposalLine = (data: AntagInfoBloodBrotherData, offered: Oath[], selected: Oath | undefined) => {
  if (!data.proposed_key) {
    if (data.muted) {
      return 'Связь заглушена: пока стоит майндшилд, клятву не предложить.';
    }
    return data.state === 'next'
      ? 'Можно дать ещё одну клятву: её венец добавится к прежним. Не хотите - просто уйдите вместе к концу смены.'
      : 'Выберите клятву и предложите её братьям. Не решите вовремя - клятвой станет первая.';
  }
  const proposed = offered.find((offer) => offer.key === data.proposed_key);
  const who = data.i_proposed ? 'Вы предлагаете' : `${data.proposed_by || 'Брат'} предлагает`;
  const self = (data.brothers || []).find((brother) => brother.self)?.name;
  const others = (data.unsigned || []).filter((name) => name !== self);
  const waiting = others.length ? ` Ждём подписи: ${others.join(', ')}.` : '';
  if (selected?.key !== data.proposed_key) {
    return `${who} «${proposed?.name || data.proposed_key}».${waiting} Можно предложить эту взамен.`;
  }
  if (data.i_proposed) {
    return `${who} эту клятву.${waiting}`;
  }
  if (data.i_signed) {
    return `Ваша подпись есть.${waiting}`;
  }
  if (data.muted) {
    return `${who} эту клятву, но связь заглушена: подписать нельзя.${waiting}`;
  }
  return `${who} эту клятву. Подпишите кровью - и она дана.${waiting}`;
};

type PatchProps = { kicker: ReactNode; title: string; sub: ReactNode; command: ReactNode; turned: boolean };

const Patch = ({ kicker, title, sub, command, turned }: PatchProps) => (
  <div className="AntagInfoBloodBrother__patch">
    <svg className="AntagInfoBloodBrother__stitches" viewBox="0 0 720 104" preserveAspectRatio="none" aria-hidden>
      <path className="AntagInfoBloodBrother__stitchShadow" d={PATCH_STITCHES.shadow} />
      <path className="AntagInfoBloodBrother__stitchThread" d={PATCH_STITCHES.thread} />
      <path className="AntagInfoBloodBrother__stitchHoles" d={PATCH_STITCHES.holes} />
    </svg>
    <div className={'AntagInfoBloodBrother__patchText' + (turned ? ' AntagInfoBloodBrother__patchText--turned' : '')}>
      <div className="AntagInfoBloodBrother__kicker">{kicker}</div>
      <div className="AntagInfoBloodBrother__patchTitle">{title}</div>
      <div className="AntagInfoBloodBrother__patchSub">{sub}</div>
    </div>
    {command}
  </div>
);

type ListProps = { selected: number; onSelect: (index: number) => void };

const Finale = ({ text }: { text: string | null | undefined }) =>
  text ? (
    <div className="AntagInfoBloodBrother__fact">
      <b>К концу смены:</b> {text}
    </div>
  ) : null;

const OathChoice = ({ selected, onSelect }: ListProps) => {
  const { data } = useBackend<AntagInfoBloodBrotherData>();
  const offered = offeredOaths(data);
  const chosen = offered[selected];
  return (
    <div className="AntagInfoBloodBrother__columns">
      <div className="AntagInfoBloodBrother__list" role="listbox" aria-label="Клятвы">
        {offered.map((offer, index) => (
          <div
            key={offer.key}
            role="option"
            aria-selected={index === selected}
            className={'AntagInfoBloodBrother__row' + (index === selected ? ' AntagInfoBloodBrother__row--selected' : '')}
            style={shifted(offer.key)}
            onClick={() => onSelect(index)}>
            {index === selected && <Soak seed={offer.key} />}
            <span className="AntagInfoBloodBrother__rowNumber">{index + 1}</span>
            <span className="AntagInfoBloodBrother__rowText">
              <span className="AntagInfoBloodBrother__rowName">{offer.name}</span>
              {!!offer.summary && <span className="AntagInfoBloodBrother__rowNote">{offer.summary}</span>}
              <span className="AntagInfoBloodBrother__rowNote">
                {[offer.vow_name && `обет: ${offer.vow_name}`, offer.capstone && `даст: ${offer.capstone.name}`]
                  .filter(Boolean)
                  .join(' · ')}
              </span>
              {data.proposed_key === offer.key && (
                <span className="AntagInfoBloodBrother__rowMark">
                  {data.i_proposed ? 'предлагаете вы' : `предлагает ${data.proposed_by || 'брат'}`}
                </span>
              )}
            </span>
          </div>
        ))}
        {!offered.length && <div className="AntagInfoBloodBrother__quiet">Клятв пока нет. Кровь ещё не решила.</div>}
        {data.state === 'next' && !!data.finale_check && <FinaleChecklist check={data.finale_check} />}
      </div>
      <Divider seed="колонки выбора" vertical />
      <div className="AntagInfoBloodBrother__detail">
        {!!chosen && (
          <>
            <Title text={chosen.name} />
            <Quote>{chosen.story}</Quote>
            {!!chosen.capstone && (
              <div className="AntagInfoBloodBrother__fact">
                <b>Даст: {chosen.capstone.name}</b> - {chosen.capstone.desc}
              </div>
            )}
            {!!chosen.kit && (
              <div className="AntagInfoBloodBrother__fact">
                <b>Узелок каждому:</b> {chosen.kit}
              </div>
            )}
            {!!chosen.vow_name && (
              <div className="AntagInfoBloodBrother__fact">
                <b>Обет «{chosen.vow_name}»</b>
                {chosen.vow_desc ? `: ${chosen.vow_desc}` : ''}
              </div>
            )}
            <Finale text={chosen.finale} />
            <Divider seed={chosen.key} />
            <ol className="AntagInfoBloodBrother__steps">
              {chosen.steps.map((step, index) => (
                <li key={index} style={shifted(step.name)}>
                  <span className="AntagInfoBloodBrother__stepName">{step.name}</span>
                  {!!step.desc && <span className="AntagInfoBloodBrother__stepDesc">{step.desc}</span>}
                </li>
              ))}
            </ol>
          </>
        )}
      </div>
    </div>
  );
};

/** Финал после третьей печати: кто из живых уже на ЦК, кто скован, мёртвые не мешают. */
const FinaleChecklist = ({ check }: { check: FinaleCheck }) => (
  <div className="AntagInfoBloodBrother__finale" aria-label="Финал">
    <b>Уйти вместе</b>
    {check.brothers.map((row) => (
      <div key={row.name} className={'AntagInfoBloodBrother__finaleRow' + (row.done ? ' AntagInfoBloodBrother__finaleRow--done' : '')}>
        {row.name} - {row.status}
      </div>
    ))}
    {!!check.extra && (
      <div className={'AntagInfoBloodBrother__finaleRow' + (check.extra_done ? ' AntagInfoBloodBrother__finaleRow--done' : '')}>
        {check.extra}: {check.extra_done ? 'да' : 'нет'}
      </div>
    )}
  </div>
);

const stepSeal = (data: AntagInfoBloodBrotherData, step: OathStep): SealState => {
  if (!step.sealed) {
    return 'empty';
  }
  const present = data.brother_states.some((brother) => brother.name === step.sealed_by && !['gone', 'severed'].includes(brother.state));
  return present || !step.sealed_by ? 'fresh' : 'smeared';
};

type SwornProps = ListProps & {
  seals: Seals;
  stamping: number | null;
  written: boolean;
  onStamped: () => void;
  onWritten: () => void;
};

const SwornOath = ({ selected, onSelect, seals, stamping, written, onStamped, onWritten }: SwornProps) => {
  const { data } = useBackend<AntagInfoBloodBrotherData>();
  const oath = swornOath(data);
  if (!oath) {
    return null;
  }
  const step = oath.steps[selected];
  const stepNumber = selected + 1;
  const lastLine = oath.steps.length + 3;
  let statusLabel = 'Ждёт';
  let status = `сначала печать шага ${data.current_step || stepNumber - 1}`;
  if (step?.sealed) {
    statusLabel = 'Скреплено';
    status = step.sealed_by ? `печать: ${step.sealed_by}` : 'печать стоит';
  } else if (stepNumber === data.current_step) {
    statusLabel = 'Сейчас';
    status = step.condition || 'этот шаг следующий';
  }
  const vow = data.vow;
  return (
    <div className={'AntagInfoBloodBrother__sworn' + (written ? ' AntagInfoBloodBrother__sworn--written' : '')}>
      <div className="AntagInfoBloodBrother__oathHead">
        <Title text={oath.name} ink={0} />
        <Quote ink={1}>{oath.story}</Quote>
      </div>
      <div className="AntagInfoBloodBrother__prints" role="listbox" aria-label="Печати клятвы">
        {oath.steps.map((entry, index) => {
          const seal = stepSeal(data, entry);
          const current = index + 1 === data.current_step;
          const pressing = stamping === index;
          let note = 'ждёт своей очереди';
          if (entry.sealed) {
            note = entry.sealed_by ? `печать: ${entry.sealed_by}` : 'скреплено';
          } else if (current) {
            note = 'сейчас';
          }
          return (
            <div
              key={index}
              role="option"
              aria-selected={index === selected}
              className={
                'AntagInfoBloodBrother__print AntagInfoBloodBrother__ink' +
                (index === selected ? ' AntagInfoBloodBrother__print--selected' : '') +
                (entry.sealed ? ' AntagInfoBloodBrother__print--sealed' : '') +
                (current ? ' AntagInfoBloodBrother__print--current' : '') +
                (pressing ? ' AntagInfoBloodBrother__print--stamping' : '')
              }
              style={{ ...inkLine(index + 2), marginTop: `${(hashText(entry.name) % 7) - 1}px` }}
              onClick={() => onSelect(index)}>
              {index === selected && <Soak seed={entry.name} />}
              <span className="AntagInfoBloodBrother__printMark">
                {!!entry.sealed && (
                  <svg className="AntagInfoBloodBrother__blot" viewBox={`0 0 ${SPLASH_BOX} ${SPLASH_BOX}`} aria-hidden>
                    <path d={blot(entry.name)} />
                  </svg>
                )}
                {!!entry.sealed && (
                  <svg className="AntagInfoBloodBrother__printSmear" viewBox="0 0 90 14" preserveAspectRatio="none" aria-hidden>
                    <path d={brushStroke(`след ладони|${entry.name}`, 90, 14)} />
                  </svg>
                )}
                {pressing && (
                  <span className="AntagInfoBloodBrother__sealBefore">
                    <Seal state="empty" asset={seals.empty} />
                  </span>
                )}
                <Seal state={seal} asset={seals[seal]} extra="AntagInfoBloodBrother__printSeal" />
                {seal === 'fresh' && <Splatter seed={entry.name} />}
                {pressing && <Seal state="fresh" asset={seals.fresh} extra="AntagInfoBloodBrother__sealGhost" />}
              </span>
              <span className="AntagInfoBloodBrother__printText">
                <span className="AntagInfoBloodBrother__printName">
                  {index + 1}. {entry.name}
                </span>
                <span className="AntagInfoBloodBrother__printNote" onAnimationEnd={pressing ? ownEnd(onStamped) : undefined}>
                  {note}
                </span>
              </span>
            </div>
          );
        })}
      </div>
      <div className="AntagInfoBloodBrother__columns">
        <div className="AntagInfoBloodBrother__stepInfo AntagInfoBloodBrother__ink" style={inkLine(lastLine - 1)}>
          {!!step && (
            <>
              <div className="AntagInfoBloodBrother__kicker">
                Шаг {stepNumber} из {oath.steps.length}: {step.name}
              </div>
              <div className="AntagInfoBloodBrother__text">{step.desc}</div>
              <div className="AntagInfoBloodBrother__status">
                <span className="AntagInfoBloodBrother__statusLabel">{statusLabel}:</span> {status}
              </div>
            </>
          )}
        </div>
        <Divider seed={`колонки|${oath.key}`} vertical ink={lastLine - 1} />
        <div
          className="AntagInfoBloodBrother__detail AntagInfoBloodBrother__ink"
          style={inkLine(lastLine)}
          onAnimationEnd={written ? ownEnd(onWritten) : undefined}>
          {!!vow && (
            <div className={'AntagInfoBloodBrother__fact' + (vow.broken ? ' AntagInfoBloodBrother__fact--broken' : '')}>
              {vow.broken ? (
                <>
                  <b>Обет «{vow.name}» нарушен</b>
                  {vow.broken_reason ? `: ${vow.broken_reason}.` : '.'}
                </>
              ) : (
                <>
                  <b>Обет «{vow.name}» держится.</b> {vow.desc}
                </>
              )}
            </div>
          )}
          {!!oath.capstone && (
            <div className="AntagInfoBloodBrother__fact">
              <b>Венец: {oath.capstone.name}</b>, {capstoneLock(data, oath.capstone) || 'открыт'}
            </div>
          )}
          {!!oath.kit && (
            <div className="AntagInfoBloodBrother__fact">
              <b>Узелок клятвы:</b> {oath.kit}
            </div>
          )}
          {!data.finale_check && <Finale text={oath.finale} />}
        </div>
      </div>
    </div>
  );
};

type LadderEntry = { tier: number; ability: BondAbility; capstone: boolean; source?: string };

const ladderEntries = (data: AntagInfoBloodBrotherData, capstoneOath: Oath | undefined): LadderEntry[] => {
  const entries: LadderEntry[] = [];
  for (const step of data.bond_ladder || []) {
    for (const ability of step.abilities) {
      entries.push({ tier: step.tier, ability, capstone: false, source: step.label });
    }
  }
  const capstone = capstoneOath?.capstone;
  if (capstone && !entries.some((entry) => entry.ability.name === capstone.name)) {
    entries.push({ tier: data.tier_max, ability: capstone, capstone: true });
  }
  return entries;
};

const abilityState = (data: AntagInfoBloodBrotherData, entry: LadderEntry) => {
  if (entry.tier > data.tier) {
    return { open: false, text: `откроет печать ${entry.tier}` };
  }
  const lock = entry.capstone ? capstoneLock(data, entry.ability) : null;
  if (lock) {
    return { open: false, text: lock };
  }
  return data.muted ? { open: false, text: 'заглушено' } : { open: true, text: 'открыто' };
};

/** Последние шёпоты крови: кто, когда и что сказал; заглушённому не приходят. */
const Whispers = ({ whispers }: { whispers: Whisper[] }) => (
  <div className="AntagInfoBloodBrother__rung AntagInfoBloodBrother__whispers" data-reached="true" aria-label="Шёпоты крови">
    <div className="AntagInfoBloodBrother__rungHead">
      <span>Шёпоты крови</span>
    </div>
    {whispers.map((whisper, index) => (
      <div key={index} className="AntagInfoBloodBrother__whisper" style={shifted(`${whisper.name}|${index}`)}>
        {!!whisper.time && <span className="AntagInfoBloodBrother__whisperTime">{whisper.time}</span>}
        <b>{whisper.name}:</b> {whisper.text}
      </div>
    ))}
  </div>
);

type LadderProps = { focus: string | null; capstoneOath: Oath | undefined; seals: Seals };

const BondLadder = ({ focus, capstoneOath, seals }: LadderProps) => {
  const { data } = useBackend<AntagInfoBloodBrotherData>();
  const ladder = useRef<HTMLDivElement | null>(null);
  const rows = useRef<Record<string, HTMLDivElement | null>>({});
  useEffect(() => {
    const row = focus ? rows.current[focus] : null;
    if (row && ladder.current) {
      ladder.current.scrollTop = Math.max(0, row.offsetTop - 44);
    }
  }, [focus]);
  const entries = ladderEntries(data, capstoneOath);
  const tiers = Array.from({ length: (data.tier_max || 0) + 1 }, (_, tier) => tier);
  return (
    <div className="AntagInfoBloodBrother__ladder" ref={ladder}>
      {!data.muted && !!data.whispers?.length && <Whispers whispers={data.whispers} />}
      {tiers.map((tier) => {
        const own = entries.filter((entry) => entry.tier === tier);
        const reached = tier <= data.tier;
        let label = tier ? `Печать ${tier}` : 'С клятвы';
        if (tier === data.tier_max) {
          label += capstoneOath ? ` · венец клятвы «${capstoneOath.name}»` : ' · венец клятвы';
        }
        return (
          <div key={tier} className="AntagInfoBloodBrother__rung" data-reached={reached ? 'true' : undefined}>
            <div className="AntagInfoBloodBrother__rungHead">
              {tier ? <Seal state={reached ? 'fresh' : 'empty'} asset={seals[reached ? 'fresh' : 'empty']} /> : null}
              <span>{label}</span>
            </div>
            {!own.length && (
              <div className="AntagInfoBloodBrother__quiet">
                {tier === data.tier_max ? 'Венец зависит от клятвы: выберите её, и он появится здесь.' : 'Ничего нового.'}
              </div>
            )}
            {own.map((entry) => {
              const { ability, source } = entry;
              const state = abilityState(data, entry);
              return (
                <div
                  key={ability.name}
                  ref={(node) => {
                    rows.current[ability.name] = node;
                  }}
                  role="listitem"
                  aria-label={ability.name}
                  aria-current={focus === ability.name ? 'true' : undefined}
                  className={
                    'AntagInfoBloodBrother__ability' +
                    (state.open ? '' : ' AntagInfoBloodBrother__ability--closed') +
                    (focus === ability.name ? ' AntagInfoBloodBrother__ability--focus' : '')
                  }>
                  {focus === ability.name && <Soak seed={ability.name} />}
                  {!!source && <div className="AntagInfoBloodBrother__abilitySource">{source}</div>}
                  <div className="AntagInfoBloodBrother__abilityHead">
                    <span className="AntagInfoBloodBrother__abilityName">{ability.name}</span>
                    <span className="AntagInfoBloodBrother__abilityState">{state.text}</span>
                  </div>
                  <div className="AntagInfoBloodBrother__text">{ability.desc}</div>
                  <div className="AntagInfoBloodBrother__abilityHow">
                    <b>Как:</b> {ability.how}{' '}
                    <span className="AntagInfoBloodBrother__abilityCooldown">{cooldownText(ability, data.cooldown_mult ?? 1)}</span>
                  </div>
                  {ability.name === data.recruit?.name && (
                    <div className="AntagInfoBloodBrother__abilityHow">
                      <b>Место в братстве:</b> {data.recruit.slot}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        );
      })}
    </div>
  );
};

const Rules = () => {
  const { data } = useBackend<AntagInfoBloodBrotherData>();
  return (
    <div className="AntagInfoBloodBrother__rules">
      {!!data.backstory && (
        <div className="AntagInfoBloodBrother__rulesStory">
          <Backstory data={data} />
        </div>
      )}
      <ol className="AntagInfoBloodBrother__rulesList">
        {(data.rules || []).map((rule, index) => (
          <li key={index} style={shifted(rule)}>
            {rule}
          </li>
        ))}
      </ol>
    </div>
  );
};

type FooterProps = { capstoneOath: Oath | undefined; onAbility: (name: string) => void };

const Footer = ({ capstoneOath, onAbility }: FooterProps) => {
  const { data } = useBackend<AntagInfoBloodBrotherData>();
  const ladder = ladderEntries(data, capstoneOath).filter((entry) => entry.tier <= data.tier && (!entry.capstone || capstoneEarned(data, entry.ability)));
  const names = ladder.length ? ladder.map((entry) => entry.ability.name) : (data.abilities || []).map((ability) => ability.name);
  const onKeyDown = (event: KeyboardEvent<HTMLSpanElement>, name: string) => {
    if ((event.code === 'Enter' || event.code === 'NumpadEnter' || event.code === 'Space') && !event.repeat) {
      event.preventDefault();
      onAbility(name);
    }
  };
  return (
    <nav className="AntagInfoBloodBrother__footer" aria-label="Открытые способности">
      <Divider seed="подвал" extra="AntagInfoBloodBrother__rule AntagInfoBloodBrother__rule--top" />
      <span className="AntagInfoBloodBrother__footerLinks">
        <span className="AntagInfoBloodBrother__footerLabel">{data.muted ? 'Связь заглушена:' : 'Открыто:'}</span>{' '}
        {names.map((name, index) => (
          <span key={name}>
            {index ? ' · ' : ''}
            <span
              role="link"
              tabIndex={0}
              className="AntagInfoBloodBrother__footerLink"
              onClick={() => onAbility(name)}
              onKeyDown={(event) => onKeyDown(event, name)}>
              {name}
            </span>
          </span>
        ))}
      </span>
      <span className="AntagInfoBloodBrother__footerHint">подробнее - во вкладке «Связь»</span>
    </nav>
  );
};

const useListSelection = (count: number, anchor: number, resetKey: string | number) => {
  const [picked, setPicked] = useState<number | null>(null);
  useEffect(() => setPicked(null), [resetKey]);
  const clamp = (index: number) => Math.max(0, Math.min(index, count - 1));
  const index = count ? clamp(picked ?? anchor) : 0;
  const select = (next: number) => {
    if (count) {
      setPicked(clamp(next));
    }
  };
  return { index, select };
};

const newlySealed = (previous: string, next: string) => {
  const [previousKey, previousMask = ''] = previous.split('|');
  const [nextKey, nextMask = ''] = next.split('|');
  if (!previousKey || previousKey !== nextKey) {
    return null;
  }
  for (let index = nextMask.length - 1; index >= 0; index--) {
    if (nextMask[index] === '1' && previousMask[index] !== '1') {
      return index;
    }
  }
  return null;
};

export const AntagInfoBloodBrother = () => {
  const { act, data } = useBackend<AntagInfoBloodBrotherData>();
  const calm = useCalm();
  const oath = swornOath(data);
  const sworn = data.state === 'sworn' && !!oath;
  const offered = offeredOaths(data);
  const proposedIndex = offered.findIndex((offer) => offer.key === data.proposed_key);
  const steps = oath?.steps || [];
  const stepAnchor = data.current_step ? data.current_step - 1 : Math.max(0, steps.length - 1);
  const oaths = useListSelection(offered.length, Math.max(0, proposedIndex), data.proposed_key || '');
  const stepList = useListSelection(steps.length, stepAnchor, data.current_step);
  const list = sworn ? stepList : oaths;
  const [tab, setTab] = useState<Tab>('oath');
  const [focusAbility, setFocusAbility] = useState<string | null>(null);
  const quietOath = calm || tab !== 'oath';
  const sealedMask = oath ? `${oath.key}|${steps.map((step) => (step.sealed ? 1 : 0)).join('')}` : '';
  const [stamp, clearStamp] = useMoment(sealedMask, newlySealed, quietOath);
  const [written, clearWritten] = useMoment(sworn, (previous, next) => (!previous && next ? true : null), quietOath);
  const [shift, clearShift] = useMoment(tab, (previous, next) => (TABS.indexOf(next) > TABS.indexOf(previous) ? 'right' : 'left'), calm);
  const cloth = useAsset('blood_brothers_cloth.png');
  const smear = useAsset('blood_brothers_smear.png');
  const seals: Seals = {
    empty: useAsset(SEAL_ASSETS.empty),
    fresh: useAsset(SEAL_ASSETS.fresh),
    smeared: useAsset(SEAL_ASSETS.smeared),
  };
  const [pressed, setPressed] = useState<string | null>(null);
  const selectedOath = offered[oaths.index];
  const capstoneOath = sworn ? oath || undefined : selectedOath;
  const command = sworn ? sealCommand(data, act) : choosingCommand(data, selectedOath, act);
  const run = () => {
    if (!command || command.disabled) {
      return;
    }
    setPressed(command.id);
    command.run();
  };
  const openTab = (next: Tab) => {
    setTab(next);
    clearStamp();
    clearWritten();
    if (next !== 'bond') {
      setFocusAbility(null);
    }
  };
  useOathKeys({
    onPick: (index) => tab === 'oath' && list.select(index),
    onMove: (delta) => tab === 'oath' && list.select(list.index + delta),
    onEnter: run,
    onTab: (delta) => openTab(TABS[(TABS.indexOf(tab) + delta + TABS.length) % TABS.length]),
  });
  const clothStyle: CSSProperties = cloth
    ? ({ '--bb-cloth': `url("${cloth}")` } as CSSProperties)
    : { clipPath: CLOTH_EDGE };
  const currentStep = oath?.steps[data.current_step - 1];
  const commandNode = command && <Command command={command} pressed={pressed === command.id} smear={smear} onRun={run} />;
  const turned = !!stamp || !!written;
  let patch: ReactNode;
  if (sworn && currentStep) {
    patch = (
      <Patch
        kicker={`${STEP_ORDINALS[data.current_step - 1] || data.current_step} печать из ${steps.length}`}
        title={currentStep.name}
        sub={currentStep.condition || currentStep.desc}
        command={commandNode}
        turned={turned}
      />
    );
  } else if (sworn) {
    patch = (
      <Patch
        kicker={`Все печати стоят: ${steps.length} из ${steps.length}`}
        title="Клятва скреплена"
        sub={`К концу смены: ${oath?.finale || 'всем живым братьям - до ЦК, без наручников'}.`}
        command={data.finale_check ? <FinaleChecklist check={data.finale_check} /> : null}
        turned={turned}
      />
    );
  } else {
    patch = (
      <Patch
        kicker={
          data.state === 'next' ? (
            `Клятва «${oath?.name || ''}» исполнена · следующая - по желанию`
          ) : (
            <>
              Выбираем клятву, осталось <span className="AntagInfoBloodBrother__timer">{formatTime(data.deadline_left)}</span>
            </>
          )
        }
        title={selectedOath?.name || 'Клятв нет'}
        sub={proposalLine(data, offered, selectedOath)}
        command={commandNode}
        turned={false}
      />
    );
  }
  let body: ReactNode;
  if (tab === 'bond') {
    body = <BondLadder focus={focusAbility} capstoneOath={capstoneOath} seals={seals} />;
  } else if (tab === 'rules') {
    body = <Rules />;
  } else if (sworn) {
    body = (
      <SwornOath
        selected={stepList.index}
        onSelect={(index) => stepList.select(index)}
        seals={seals}
        stamping={stamp ? stamp.info : null}
        written={!!written}
        onStamped={clearStamp}
        onWritten={clearWritten}
      />
    );
  } else {
    body = <OathChoice selected={oaths.index} onSelect={(index) => oaths.select(index)} />;
  }
  const enterHint = command && !command.disabled ? command.label.toLowerCase() : null;
  return (
    <Window width={760} height={600} title="Кровная клятва">
      <Window.Content fitted>
        <div className="AntagInfoBloodBrother" data-state={sworn ? 'sworn' : 'choosing'}>
          <div className="AntagInfoBloodBrother__sheet">
            <div
              className="AntagInfoBloodBrother__cloth"
              data-cloth={cloth ? 'asset' : undefined}
              data-muted={data.muted ? 'true' : undefined}
              style={clothStyle}>
              <Thread calm={calm} />
              {patch}
              <div className={'AntagInfoBloodBrother__tabs' + (shift ? ' AntagInfoBloodBrother__tabs--moved' : '')} role="tablist">
                {TABS.map((name) => (
                  <span
                    key={name}
                    role="tab"
                    aria-selected={tab === name}
                    tabIndex={-1}
                    className={'AntagInfoBloodBrother__tab' + (tab === name ? ' AntagInfoBloodBrother__tab--active' : '')}
                    onClick={() => openTab(name)}>
                    {tab === name && (
                      <svg className="AntagInfoBloodBrother__tabSmear" viewBox="0 0 120 8" preserveAspectRatio="none" aria-hidden>
                        <path d={brushStroke(`вкладка|${name}`, 120, 8)} />
                      </svg>
                    )}
                    {TAB_NAMES[name]}
                  </span>
                ))}
                <Divider seed="вкладки" extra="AntagInfoBloodBrother__rule AntagInfoBloodBrother__rule--bottom" />
              </div>
              <div
                key={tab}
                className={'AntagInfoBloodBrother__page' + (shift ? ` AntagInfoBloodBrother__page--from-${shift.info}` : '')}
                role="tabpanel"
                aria-label={TAB_NAMES[tab]}
                onAnimationEnd={shift ? ownEnd(clearShift) : undefined}>
                {body}
              </div>
              <Footer
                capstoneOath={capstoneOath}
                onAbility={(name) => {
                  setFocusAbility(name);
                  openTab('bond');
                }}
              />
            </div>
            <FiberStrip side="top" />
            <FiberStrip side="bottom" />
            <FiberStrip side="left" />
            <FiberStrip side="right" />
          </div>
          <div className="AntagInfoBloodBrother__keys">
            Tab - вкладки · 1 2 3 и стрелки - {sworn ? 'печать' : 'клятва'}
            {enterHint ? ` · Enter - ${enterHint}` : ''}
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
