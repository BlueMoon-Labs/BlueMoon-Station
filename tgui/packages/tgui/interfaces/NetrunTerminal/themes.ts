import type { CSSProperties } from 'react';

type Palette = { bg: string; panel: string; elevated: string; line: string; text: string;
  muted: string; accent: string; good: string; warn: string; bad: string; map: string };
export const NETRUN_THEMES = {
  ion: { name: 'Ion', mood: 'Холодный свет · операции', palette: {
    bg: '#080f18', panel: '#101d29', elevated: '#172b3a', line: '#294555', text: '#e5f1fa',
    muted: '#94adbd', accent: '#66d6ed', good: '#68dbb7', warn: '#f5c477', bad: '#f2969c', map: '#081420',
  } },
  phosphor: { name: 'Phosphor', mood: 'Зелёный фосфор · старый терминал', palette: {
    bg: '#080f0b', panel: '#101e14', elevated: '#1b3020', line: '#32503a', text: '#dceedd',
    muted: '#9ab49e', accent: '#96e7a3', good: '#81d9ac', warn: '#e1cb83', bad: '#eea093', map: '#09130d',
  } },
  amber: { name: 'Amber', mood: 'Тёплый янтарь · ночная смена', palette: {
    bg: '#17100b', panel: '#241b12', elevated: '#342719', line: '#58432c', text: '#f7e7cc',
    muted: '#bfaa88', accent: '#f3c070', good: '#b8d393', warn: '#f1cc75', bad: '#ef9c8d', map: '#1a120c',
  } },
  synthwave: { name: 'Afterglow', mood: 'Неоновый сумрак · свободный эфир', palette: {
    bg: '#140e20', panel: '#21182f', elevated: '#342345', line: '#584267', text: '#f3e8fb',
    muted: '#baa4ca', accent: '#eaa1e8', good: '#87dcc9', warn: '#f4c791', bad: '#f295b7', map: '#190f27',
  } },
  noir: { name: 'Noir', mood: 'Графит и серебро · без лишнего шума', palette: {
    bg: '#111214', panel: '#1c1e21', elevated: '#2a2d31', line: '#454a50', text: '#ededef',
    muted: '#adb3ba', accent: '#c9d4e0', good: '#9dd2b4', warn: '#dfc395', bad: '#dfa1a4', map: '#141619',
  } },
} satisfies Record<string, { name: string; mood: string; palette: Palette }>;
export type NetrunThemeId = keyof typeof NETRUN_THEMES;
export const themeId = (id?: string): NetrunThemeId => Object.hasOwn(NETRUN_THEMES, id ?? '') ? id as NetrunThemeId : 'ion';
export const themePalette = (id?: string): Palette => NETRUN_THEMES[themeId(id)].palette;
export const themeStyle = (id?: string): CSSProperties => Object.fromEntries(
  Object.entries(themePalette(id)).map(([name, value]) => [`--net-${name === 'line' ? 'border' : name}`, value]),
) as CSSProperties;
