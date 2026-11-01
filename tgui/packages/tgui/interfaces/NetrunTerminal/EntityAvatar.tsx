export const PERSONA_ACCENTS: Record<string, string> = {
  cyan: '#72ddea', mint: '#77d9ad', amber: '#f5c477', rose: '#eb9ac4', violet: '#b7a0ff', silver: '#c9d4e0',
};
const avatars: Record<string, { name: string; art: ReactNode }> = {
  cipher: { name: 'Шифр', art: <><path d="m18 13-9 11 9 11m12-22 9 11-9 11m-4-25-4 28" /><circle cx="24" cy="24" r="21" strokeDasharray="2 6" opacity=".3" /></> },
  ghost: { name: 'Призрак', art: <><path d="M12 39V21a12 12 0 0 1 24 0v18l-6-4-6 4-6-4z" /><path d="M18 22v3m12-3v3m-10 5h8" /><path d="M9 18H5m38 12h-4" opacity=".4" /></> },
  moth: { name: 'Мотылёк', art: <path d="m24 23-9-13-9 3 5 15 13 7 13-7 5-15-9-3-9 13v17m0-16-5-8m5 8 5-8M13 16l5 9-8-3m25-6-5 9 8-3M14 31l-2 7 10-4m12-3 2 7-10-4" /> },
  fox: { name: 'Лис', art: <><path d="m9 9 15 10L39 9l-3 22-12 10-12-10z" /><path d="m12 13 5 14-5 4m24-18-5 14 5 4m-19-4 4 1m6 0 4-1m-10 7 3 3 3-3m-3 3v4" /></> },
  eye: { name: 'Наблюдатель', art: <><path d="M3 24s9-13 21-13 21 13 21 13-9 13-21 13S3 24 3 24Z" /><circle cx="24" cy="24" r="8" /><circle cx="24" cy="24" r="2" fill="currentColor" /><path d="M24 3v4m0 34v4M9 7l3 4m24 26 3 4" opacity=".4" /></> },
  orb: { name: 'Орбита', art: <><circle cx="24" cy="24" r="13" /><ellipse cx="24" cy="24" rx="23" ry="8" transform="rotate(-35 24 24)" /><path d="M24 11c-8 9-8 17 0 26m0-26c8 9 8 17 0 26" opacity=".45" /><circle cx="39" cy="12" r="3" fill="currentColor" stroke="none" /></> },
};
export const PERSONA_AVATAR_OPTIONS = Object.entries(avatars).map(([id, glyph]) => ({ id, name: glyph.name }));

/** Curated vector identities remain sharp at HUD, contact-card and profile sizes. */
export const EntityAvatar = ({ avatar = 'cipher', accent = 'cyan', size = 48 }: { avatar?: string; accent?: string; size?: number }) => {
  const glyph = avatars[avatar] || avatars.cipher;
  return (<span className="netrun-avatar" style={{ color: PERSONA_ACCENTS[accent] || PERSONA_ACCENTS.cyan, width: size, height: size }}>
    <svg viewBox="0 0 48 48" role="img" aria-label={`Аватар: ${glyph.name}`} fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">{glyph.art}</svg>
          </span>);
};
import type { ReactNode } from 'react';

