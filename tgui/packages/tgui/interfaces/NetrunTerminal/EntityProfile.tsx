import { Box } from '../../components';
import { EntityAvatar } from './EntityAvatar';
import { NetrunData, THEME } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

export const EntityPanel = () => {
  const { data } = useBackend<NetrunData>(['entity']);
  const entity = data.entity;
  if (!entity) { return null; }
  const ratio = entity.max_integrity ? Math.max(0, Math.min(1, entity.integrity / entity.max_integrity)) : 0;
  return (<div className="netrun-entity-profile">
    <EntityAvatar avatar={entity.persona?.avatar} accent={entity.persona?.accent} size={58} />
    <div className="netrun-entity-profile__body">
      <div><strong>{entity.name}</strong><small>{entity.diving ? 'ПОГРУЖЕНИЕ' : 'РЕЗИДЕНТ'}</small></div>
      {!!entity.persona?.tagline && <p>{entity.persona.tagline}</p>}
      <Box fontSize="11px" color={THEME.muted}>Носитель: {entity.host_name || '—'} {entity.host || ''}</Box>
      <div className="netrun-entity-profile__integrity"><span style={{ width: `${ratio * 100}%`, background: ratio > 0.5 ? THEME.good : ratio > 0.25 ? THEME.warn : THEME.bad }} /></div>
      <Box fontSize="11px" color={THEME.muted}>Целостность {entity.integrity}/{entity.max_integrity}</Box>
    </div>
          </div>);
};
