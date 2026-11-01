import { Button } from '../../components';
import { SelectedNode } from './types';

type Props = {
  selected: SelectedNode;
  host?: string | null;
  pending: boolean;
  act: (action: string, params: { address: string }) => void;
};

export const NodeMovement = ({ selected, host, pending, act }: Props) => {
  if (!host || host === selected.address) { return null; }
  const movement = selected.movement;
  const allowed = movement?.allowed ?? selected.can_hop ?? (selected.access >= 2 && selected.online);
  const routed = movement?.action === 'travel';
  const tooltip = movement?.reason || (routed
    ? 'Пройти по открытым узлам до выбранного. Доступ и врата проверяются на каждом переходе.'
    : 'Войти в соседний узел: нужен доступ пользователя или право прохода по ЛВС.');
  return (
    <>
      <Button
        mt={1}
        icon={routed ? 'route' : 'person-walking-arrow-right'}
        color="good"
        content="Перейти в узел"
        disabled={pending || !allowed}
        tooltip={tooltip}
        onClick={() => act(movement ? 'move' : 'hop', { address: selected.address })}
      />
      {!movement && (
        <Button
          mt={1}
          ml={1}
          icon="route"
          content="Пройти к узлу"
          disabled={pending}
          tooltip="Автопроход по уже открытым узлам до выбранного."
          onClick={() => act('travel', { address: selected.address })}
        />
      )}
    </>
  );
};
