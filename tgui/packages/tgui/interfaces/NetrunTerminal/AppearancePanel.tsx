import { useEffect, useRef, useState } from 'react';

import { Button, Icon } from '../../components';
import { EntityAvatar, PERSONA_ACCENTS } from './EntityAvatar';
import { NETRUN_THEMES, themeId } from './themes';
import { EntityState, NetrunData, Persona } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

export const AppearancePanel = ({ onClose }: { onClose: () => void }) => {
  const { act, data } = useBackend<NetrunData>(['ui_theme', 'entity']);
  const dialog = useRef<HTMLDivElement>(null);
  const close = useRef(onClose); close.current = onClose;
  useEffect(() => {
    const previous = document.activeElement as HTMLElement | null;
    dialog.current?.focus();
    const key = (event: KeyboardEvent) => {
      if (event.key === 'Escape') { event.stopPropagation(); event.preventDefault(); close.current(); }
      if (event.key !== 'Tab') { return; }
      const targets = Array.from(dialog.current?.querySelectorAll<HTMLElement>('button, input, textarea, select, [tabindex="0"]') ?? [])
        .filter((element) => !(element as HTMLInputElement).disabled && element.getAttribute('aria-disabled') !== 'true');
      const first = targets[0], last = targets[targets.length - 1];
      if (event.shiftKey && (document.activeElement === first || document.activeElement === dialog.current)) {
        event.preventDefault(); last?.focus();
      } else if (!event.shiftKey && (document.activeElement === last || document.activeElement === dialog.current)) {
        event.preventDefault(); first?.focus();
      }
    };
    document.addEventListener('keydown', key, true);
    return () => { document.removeEventListener('keydown', key, true); previous?.focus(); };
  }, []);
  return (<div className="netrun-appearance-backdrop" onMouseDown={(event) => { if (event.target === event.currentTarget) { onClose(); } }}>
    <div ref={dialog} className="netrun-appearance" role="dialog" aria-modal="true" aria-labelledby="netrun-appearance-title" tabIndex={-1}>
      <header><div><span className="netrun-eyebrow">SIGNAL / IDENTITY</span><h2 id="netrun-appearance-title">Свой почерк в сети</h2></div>
        <Button icon="xmark" aria-label="Закрыть оформление" onClick={onClose} />
      </header>
      <p className="netrun-appearance__intro">Подберите свет экрана под настроение. Стиль останется с вашим персонажем.</p>
      <h3>Тема интерфейса</h3>
      <div className="netrun-theme-grid" role="group" aria-label="Тема интерфейса">
        {Object.entries(NETRUN_THEMES).map(([id, theme]) => (<button key={id} type="button"
          className="netrun-theme-choice" aria-pressed={themeId(data.ui_theme) === id}
          onClick={() => act('set_theme', { id })}>
          <span className="netrun-theme-choice__preview" style={{ background: theme.palette.bg, borderColor: theme.palette.line }}>
            <span style={{ background: theme.palette.panel }}><i style={{ background: theme.palette.accent }} /><i style={{ background: theme.palette.muted }} /><i style={{ background: theme.palette.line }} /></span>
            <Icon name={id === 'phosphor' ? 'terminal' : id === 'amber' ? 'sun' : id === 'synthwave' ? 'satellite-dish' : id === 'noir' ? 'moon' : 'wave-square'} style={{ color: theme.palette.accent }} />
          </span><strong>{theme.name}</strong><small>{theme.mood}</small>
          {themeId(data.ui_theme) === id && <span className="netrun-theme-choice__check"><Icon name="check" /></span>}
                                                             </button>))}
      </div>
      {!!data.entity?.persona && <PersonaEditor entity={data.entity} persona={data.entity.persona} />}
    </div>
          </div>);
};

const PersonaEditor = ({ entity, persona }: { entity: EntityState; persona: Persona }) => {
  const { act } = useBackend([]);
  const [name, setName] = useState(entity.name);
  const [avatar, setAvatar] = useState(persona.avatar);
  const [accent, setAccent] = useState(persona.accent);
  const [tagline, setTagline] = useState(persona.tagline);
  useEffect(() => {
    setName(entity.name); setAvatar(persona.avatar); setAccent(persona.accent); setTagline(persona.tagline);
  }, [entity.name, persona.avatar, persona.accent, persona.tagline]);
  const dirty = name !== entity.name || avatar !== persona.avatar || accent !== persona.accent || tagline !== persona.tagline;
  return (<section className="netrun-persona-editor" aria-label="Профиль сетевой сущности">
    <h3>Сетевая личность</h3>
    <div className="netrun-persona-preview"><EntityAvatar avatar={avatar} accent={accent} size={72} />
      <div><strong>{name || entity.name}</strong><p>{tagline || 'Ваш след в ноосфере.'}</p><small>Резидентный процесс · {entity.host || 'сеть'}</small></div>
    </div>
    <label className="netrun-field">Имя процесса<input value={name} maxLength={42} onChange={(event) => setName(event.target.value)} /></label>
    <fieldset><legend>Аватар</legend><div className="netrun-avatar-choices">
      {(persona.options?.avatars ?? []).map((option) => (<button key={option.id} type="button" aria-label={option.name} aria-pressed={avatar === option.id}
        onClick={() => setAvatar(option.id)}><EntityAvatar avatar={option.id} accent={accent} /><small>{option.name}</small>
                                                         </button>))}
                                     </div>
    </fieldset>
    <fieldset><legend>Цвет подписи</legend><div className="netrun-accent-choices">
      {(persona.options?.accents ?? []).map((option) => (<button key={option.id} type="button" aria-label={option.name} title={option.name}
        aria-pressed={accent === option.id} onClick={() => setAccent(option.id)}
        style={{ background: option.color || PERSONA_ACCENTS[option.id] }}>{accent === option.id && <Icon name="check" />}
                                                         </button>))}
                                           </div>
    </fieldset>
    <label className="netrun-field">Подпись<textarea value={tagline} maxLength={160} rows={2} placeholder="Короткая строка о себе…" onChange={(event) => setTagline(Array.from(event.target.value).slice(0, 80).join(''))} />
      <small>{Array.from(tagline).length}/80</small>
    </label>
    <div className="netrun-persona-editor__save"><span>{dirty ? 'Есть несохранённые изменения' : 'Профиль сохранён'}</span>
      <Button icon="check" content="Сохранить профиль" disabled={!dirty || !name.trim()}
        onClick={() => act('appearance_update', { name: name.trim(), avatar, accent, tagline })} />
    </div>
          </section>);
};
