import { useBackend } from '../backend';
import {
  Box,
  Button,
  Knob,
  LabeledList,
  NoticeBox,
  Section,
} from '../components';
import { Window } from '../layouts';

export const PersonalMusicBox = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    playing,
    has_track,
    track_name,
    volume,
    upload_ready,
    play_ready,
    upload_cooldown,
    play_cooldown,
    file_change_cooldown,
    in_hand,
  } = data;

  return (
    <Window title="Personal Music Box" width={420} height={320}>
      <Window.Content scrollable>
        {!in_hand && (
          <NoticeBox mb={1}>
            Возьмите шкатулку в руку, чтобы загрузить трек.
          </NoticeBox>
        )}
        <Section
          title="Воспроизведение"
          buttons={(
            <Button
              icon={playing ? 'stop' : 'play'}
              content={playing ? 'Стоп' : 'Играть'}
              color={playing ? 'bad' : 'good'}
              disabled={playing ? false : (!has_track || !play_ready)}
              onClick={() => act('toggle')}
            />
          )}>
          <LabeledList>
            <LabeledList.Item label="Трек">
              {has_track ? track_name : 'Не загружен'}
            </LabeledList.Item>
            <LabeledList.Item label="Статус">
              {playing ? 'Играет' : (has_track ? 'Готов' : 'Ожидает .ogg')}
            </LabeledList.Item>
            <LabeledList.Item label="Громкость">
              <Knob
                size={1.25}
                value={volume}
                unit="%"
                minValue={0}
                maxValue={100}
                step={5}
                stepPixelSize={1}
                disabled={!has_track}
                onDrag={(e, value) => act('set_volume', { volume: value })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Загрузка">
          <Box mb={1}>
            Выберите файл <b>.ogg</b> с компьютера (до 6 МБ, Ogg Vorbis).
          </Box>
          <Button
            fluid
            icon="upload"
            content="Загрузить трек"
            disabled={!in_hand || playing || !upload_ready}
            onClick={() => act('upload')}
          />
          {!upload_ready && upload_cooldown && (
            <NoticeBox mt={1}>
              Повторная загрузка через: {upload_cooldown}
            </NoticeBox>
          )}
          {!upload_ready && file_change_cooldown && (
            <NoticeBox mt={1}>
              Смена трека через: {file_change_cooldown}
            </NoticeBox>
          )}
          {!play_ready && play_cooldown && (
            <NoticeBox mt={1}>
              Повторный запуск через: {play_cooldown}
            </NoticeBox>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
