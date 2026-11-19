import { sortBy } from 'common/collections';
import { flow } from 'common/fp';

import { useBackend } from '../backend';
import { Button, Section, Stack } from '../components';
import { Window } from '../layouts';

// Названия категорий приходят из DM; переводим только отображение,
// чтобы не менять ключи, по которым работает фильтрация тревог.
const alarmCategoryTitles = {
  Fire: 'Пожарные тревоги',
  Atmosphere: 'Атмосферные тревоги',
  Power: 'Тревоги энергоснабжения',
  Burglar: 'Тревоги взлома',
  Motion: 'Обнаружение движения',
  Camera: 'Камеры наблюдения',
};

const plural = (count, one, few, many) => {
  const mod10 = count % 10;
  const mod100 = count % 100;
  if (mod10 === 1 && mod100 !== 11) {
    return one;
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return few;
  }
  return many;
};

export const StationAlertConsole = (props) => {
  const { data } = useBackend();
  const {
    cameraView,
  } = data;
  return (
    <Window
      width={cameraView ? 390 : 345}
      height={587}>
      <Window.Content overflow="auto">
        <StationAlertConsoleContent />
      </Window.Content>
    </Window>
  );
};

export const StationAlertConsoleContent = (props) => {
  const { act, data } = useBackend();
  const {
    cameraView,
  } = data;

  const sortingKey = {
    "Fire": 0,
    "Atmosphere": 1,
    "Power": 2,
    "Burglar": 3,
    "Motion": 4,
    "Camera": 5,
  };

  const sortedAlarms = flow([
    sortBy((alarm) => sortingKey[alarm.name]),
  ])(data.alarms || []);

  return (
    <>
      {sortedAlarms.map(category => (
        <Section
          key={category.name}
          title={alarmCategoryTitles[category.name] || `Тревоги: ${category.name}`}>
          <ul>
            {category.alerts?.length === 0 && (
              <li className="color-good">
                Системы в норме
              </li>
            )}
            {category.alerts.map(alert => (
              <Stack
                key={alert.name}
                height="30px"
                align="baseline">
                <Stack.Item grow>
                  <li className="color-average">
                    {alert.name} {!!cameraView && alert?.sources > 1
                      ? ` (${alert.sources} ${plural(
                        alert.sources, 'источник', 'источника', 'источников'
                      )})` : ""}
                  </li>
                </Stack.Item>
                {!!cameraView && (
                  <Stack.Item>
                    <Button
                      textAlign="center"
                      width="100px"
                      icon={alert.cameras ? "video" : ""}
                      disabled={!alert.cameras}
                      content={alert.cameras === 1
                        ? alert.cameras + " камера" : alert.cameras > 1
                          ? alert.cameras + " " + plural(
                            alert.cameras, 'камера', 'камеры', 'камер'
                          ) : "Нет камеры"}
                      onClick={() => act('select_camera', {
                        alert: alert.ref,
                      })} />
                  </Stack.Item>
                )}
              </Stack>
            ))}
          </ul>
        </Section>
      ))}
    </>
  );
};
