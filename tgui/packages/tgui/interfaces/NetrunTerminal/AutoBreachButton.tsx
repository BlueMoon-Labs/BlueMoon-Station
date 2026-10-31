import { Button } from '../../components';
import { NetrunData } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

export const AutoBreachButton = (props: { kind: 'node' | 'network'; id: string; disabled?: boolean }) => {
  const { act, data } = useBackend<NetrunData>(['can_autobreach', 'breach', 'locked']);
  if (!data.can_autobreach) { return null; }
  return (
    <Button icon="robot" content="Автовзлом" disabled={props.disabled || !!data.breach || data.locked > 0}
      tooltip="autobreach.exe: гарантированный USER узла или ГОСТЬ ЛВС после ожидания. Связь и программа должны сохраняться; ICE и трассировка продолжают действовать."
      onClick={() => act('breach', { kind: props.kind, id: props.id, automatic: true })} />
  );
};
