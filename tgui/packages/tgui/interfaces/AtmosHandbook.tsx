/**
 * Отдельное окно справочника по атмосу.
 *
 * Открывается с консоли мониторинга атмосферики и с газоанализатора. Тело
 * общее с приложением AtmoZphere на КПК - см. common/AtmosHandbookContent.
 */
import { useBackend } from '../backend';
import { Window } from '../layouts';
import type { AtmosHandbookData } from './common/AtmosHandbookContent';
import { AtmosHandbookContent } from './common/AtmosHandbookContent';

export const AtmosHandbook = () => {
  const { data } = useBackend<AtmosHandbookData>();
  return (
    <Window width={620} height={640}>
      <Window.Content scrollable>
        <AtmosHandbookContent data={data} />
      </Window.Content>
    </Window>
  );
};
