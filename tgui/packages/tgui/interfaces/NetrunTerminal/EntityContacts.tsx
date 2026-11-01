import { useState } from 'react';

import { Box, Button, Icon } from '../../components';
import { botRole, factionColor, factionFamily, factionName } from './actorTaxonomy';
import { EntityAvatar } from './EntityAvatar';
import { FileOffer } from './FileExchange';
import { botSvgPaths } from './processGlyphs';
import { EntityContact, IceKind, THEME } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

/** Allegiance wording differs for processes and structures. */
export const factionLabel = (context: 'bot' | 'fortress', faction?: string | null) => {
  const family = factionFamily(faction);
  const structure: Record<string, string> = { owner: 'частная', rogue: 'подпольная' };
  return (context === 'fortress' && structure[family]) || factionName(faction);
};

export const botKindLabel = (kind?: string | null) => botRole(kind).name;

export const BLACK_ICE_COLOR = '#dba0ff';
export const iceKindLabel = (kind?: IceKind) => kind === 'black' ? 'BLACK ICE · нелегальный'
  : `ICE${kind === 'hunter' ? ' · охотник' : kind === 'sentry' ? ' · сторож' : ''}`;
export const IceAvatar = ({ kind, size = 28 }: { kind?: IceKind; size?: number }) => (
  <span className="netrun-avatar" role="img" aria-label={iceKindLabel(kind)}
    style={{ color: kind === 'black' ? BLACK_ICE_COLOR : THEME.bad, width: size, height: size, fontSize: `${Math.round(size / 2)}px`,
      background: kind === 'black' ? '#271332' : undefined }}>
    <Icon name={kind === 'black' ? 'skull-crossbones' : 'shield-halved'} style={{ margin: 0 }} />
  </span>
);
export const BlackIceWarning = () => (
  <Box mt={0.5} color={BLACK_ICE_COLOR} fontSize="11px">
    <Icon name="triangle-exclamation" mr={0.5} />
    Нелегальный BLACK ICE: нейрообратная связь может повредить телу при нейроподключении.
  </Box>
);

/** Archetype pictogram framed in the faction colour (contacts, combat, agents). */
export const BotAvatar = (props: { kind?: string | null; faction?: string | null; factionColor?: string | null; size?: number }) => {
  const { kind, faction, size = 28 } = props;
  const glyph = botSvgPaths(kind);
  return (
    <span className="netrun-avatar" role="img" aria-label={`Бот: ${botKindLabel(kind)}`}
      data-bot-glyph={botRole(kind).glyph}
      style={{ color: factionColor(faction, props.factionColor), width: size, height: size }}>
      <svg viewBox="-1.4 -1.4 2.8 2.8" aria-hidden="true" width={size} height={size}>
        <path d={glyph.body} fill="currentColor" stroke="#07151f" strokeWidth=".16" />
        <path d={glyph.ink} fill="none" stroke="#10212b" strokeWidth=".17" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    </span>
  );
};

const contactKind = (contact: EntityContact) => {
  if (contact.kind === 'ice') {
    return iceKindLabel(contact.ice_kind);
  }
  if (contact.kind === 'bot') {
    return [botKindLabel(contact.bot_kind), factionLabel('bot', contact.faction)].filter(Boolean).join(' · ');
  }
  return 'Сущность';
};

export const EntityContacts = (props: {
  address: string;
  contacts?: EntityContact[];
  pending: boolean;
  localEntity: boolean;
}) => {
  const { act } = useBackend([]);
  if (!props.contacts?.length) { return null; }
  return (
    <Box mt={2}>
      <Box bold mb={0.5}>Процессы на узле</Box>
      {props.contacts.map((contact) => (
        <ContactCard key={`${props.address}:${contact.ref}`} address={props.address} contact={contact} pending={props.pending} />
      ))}
      {props.localEntity && props.contacts.some((contact) => !contact.self) && (
        <Button icon="crosshairs" content="Открыть бой" disabled={props.pending}
          onClick={() => act('workspace_view', { page: 'combat' })} />
      )}
    </Box>
  );
};

const ContactCard = (props: { address: string; contact: EntityContact; pending: boolean }) => {
  const { act } = useBackend([]);
  const { contact, pending } = props;
  const [message, setMessage] = useState('');
  const canMessage = !pending && contact.can_message;
  const bot = contact.kind === 'bot';
  const blackIce = contact.kind === 'ice' && contact.ice_kind === 'black';
  const accent = blackIce ? BLACK_ICE_COLOR : bot ? factionColor(contact.faction, contact.faction_color) : undefined;
  const send = () => {
    const text = message.trim();
    if (!canMessage || !text) { return; }
    act('entity_message', { ref: contact.ref, text });
    setMessage('');
  };
  return (
    <Box p={1} mb={0.5} data-net-contact={contact.kind}
      style={{ background: THEME.bg, border: `1px solid ${accent || THEME.line}` }}>
      <Box bold color={accent}>
        {contact.kind === 'entity' ? <EntityAvatar avatar={contact.persona?.avatar} accent={contact.persona?.accent} size={28} />
          : bot ? <BotAvatar kind={contact.bot_kind} faction={contact.faction} factionColor={contact.faction_color} /> : <IceAvatar kind={contact.ice_kind} />}
        {contact.name}{contact.self ? ' · вы' : ''}
        {!!contact.faction_name && <Box inline ml={0.5} fontSize="10px" color={factionColor(contact.faction, contact.faction_color)}>
          <Icon name="flag" mr={0.5} />{contact.faction_name}
                                   </Box>}
      </Box>
      {!!contact.persona?.tagline && <Box className="netrun-contact-tagline">{contact.persona.tagline}</Box>}
      <Box color={THEME.muted} fontSize="11px">
        {contactKind(contact)} · {contact.state}
        {' · '}{contact.integrity}/{contact.max_integrity}
      </Box>
      {bot && !!contact.goal && <Box fontSize="11px">Задача: {contact.goal}</Box>}
      {blackIce && <BlackIceWarning />}
      {!!contact.threat && <Box mt={0.5} color={THEME.warn} fontSize="11px">{contact.threat}</Box>}
      {!contact.self && (contact.can_signal || contact.can_message) && (
        <Box mt={0.5}>
          <Button compact icon="satellite-dish" content="Послать сигнал"
            disabled={pending || !contact.can_signal}
            onClick={() => act('entity_signal', { ref: contact.ref })} />
          <form onSubmit={(event) => { event.preventDefault(); send(); }}
            style={{ display: 'flex', gap: '4px', marginTop: '5px', minWidth: 0 }}>
            <input aria-label={`Сообщение для ${contact.name}`} placeholder="Личное сообщение…"
              value={message} maxLength={240} disabled={!canMessage}
              onChange={(event) => setMessage(event.target.value.slice(0, 240))}
              style={{ flex: '1 1 0', minWidth: 0, background: THEME.bg, color: THEME.text,
                border: `1px solid ${THEME.line}`, padding: '4px', fontFamily: 'monospace' }} />
            <Button compact icon="paper-plane" tooltip={`Отправить сообщение ${contact.name}`}
              disabled={!canMessage || !message.trim()} onClick={send} />
          </form>
        </Box>
      )}
      {!contact.self && contact.can_offer !== undefined && <FileOffer address={props.address} contact={contact} pending={pending} />}
    </Box>
  );
};
