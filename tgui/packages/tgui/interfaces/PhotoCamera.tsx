import { useBackend } from '../backend';
import { Button, LabeledList, NumberInput, Section, Stack } from '../components';
import { Window } from '../layouts';

const editorModes = [
  ['ask', 'Спрашивать'],
  ['open', 'Открывать'],
  ['skip', 'Не открывать'],
] as const;

type PhotoCameraData = {
  width: number;
  minWidth: number;
  maxWidth: number;
  height: number;
  minHeight: number;
  maxHeight: number;
  canFlash: boolean;
  flashEnabled: boolean;
  editorMode: (typeof editorModes)[number][0] | null;
  hasDisk: boolean;
};

export const PhotoCamera = () => {
  const { act, data } = useBackend<PhotoCameraData>();
  const { canFlash, flashEnabled, editorMode, hasDisk } = data;
  const windowHeight = 86 + (canFlash ? 26 : 0) + (editorMode ? 72 : 0) + (hasDisk ? 24 : 0);

  return (
    <Window title="Настройки камеры" width={390} height={windowHeight}>
      <Window.Content>
        <Section>
          <LabeledList>
            <LabeledList.Item label="Ширина, м">
              <Stack align="center">
                <Stack.Item>
                  <NumberInput
                    width={5}
                    value={data.width}
                    minValue={data.minWidth}
                    maxValue={data.maxWidth}
                    step={2}
                    onChange={(_, size) => act('set_width', { size })} />
                </Stack.Item>
                <Stack.Item ml={2}>Высота, м</Stack.Item>
                <Stack.Item>
                  <NumberInput
                    width={5}
                    value={data.height}
                    minValue={data.minHeight}
                    maxValue={data.maxHeight}
                    step={2}
                    onChange={(_, size) => act('set_height', { size })} />
                </Stack.Item>
              </Stack>
            </LabeledList.Item>
            {!!canFlash && (
              <LabeledList.Item label="Вспышка">
                <Button
                  icon="lightbulb"
                  selected={!!flashEnabled}
                  onClick={() => act('toggle_flash')}>
                  {flashEnabled ? 'Включена' : 'Выключена'}
                </Button>
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
        {!!editorMode && (
          <Section title="Редактор после съёмки">
            {editorModes.map(([mode, label]) => (
              <Button
                key={mode}
                selected={editorMode === mode}
                onClick={() => act('set_editor_mode', { mode })}>
                {label}
              </Button>
            ))}
          </Section>
        )}
        {!!hasDisk && (
          <Button icon="eject" onClick={() => act('eject_disk')}>
            Извлечь голодиск
          </Button>
        )}
      </Window.Content>
    </Window>
  );
};
