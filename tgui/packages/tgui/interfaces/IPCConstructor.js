import { useBackend, useSharedState } from '../backend';
import {
  Box,
  Button,
  ColorBox,
  Dropdown,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  PixelArtImage,
  ProgressBar,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

const SlotListItem = (props, context) => {
  const { act } = useBackend(context);
  const { slot, busy, limbStyles } = props;
  const styleOptions = slot.styles || limbStyles;

  return (
    <LabeledList.Item
      label={slot.label}
      buttons={(
        <Button
          icon="eject"
          content="Извлечь"
          disabled={!slot.occupied || busy}
          onClick={() => act('eject', { slot: slot.id })} />
      )}>
      <Stack vertical>
        <Stack.Item>
          <Box color={slot.occupied ? 'good' : 'bad'}>
            {slot.name}
          </Box>
        </Stack.Item>
        {!!slot.occupied && !!slot.style_changeable && (
          <Stack.Item mt={0.5}>
            <Dropdown
              width="100%"
              options={styleOptions}
              selected={slot.style}
              disabled={busy}
              onSelected={value => act('set_limb_style', { slot: slot.id, style: value })} />
          </Stack.Item>
        )}
      </Stack>
    </LabeledList.Item>
  );
};

const ImplantListItem = (props, context) => {
  const { act } = useBackend(context);
  const { implant, busy } = props;

  return (
    <LabeledList.Item
      label="Имплант"
      buttons={(
        <Button
          icon="eject"
          content="Извлечь"
          disabled={busy}
          onClick={() => act('eject_implant', { implant: implant.id })} />
      )}>
      <Box color="good">
        {implant.name}
      </Box>
    </LabeledList.Item>
  );
};

const GenitalOptionItem = (props, context) => {
  const { act } = useBackend(context);
  const { option, busy } = props;

  return (
    <LabeledList.Item label={option.label}>
      <Button.Checkbox
        fluid
        checked={option.enabled}
        disabled={busy || option.disabled}
        onClick={() => act('set_genital_option', {
          option: option.id,
          enabled: option.enabled ? 0 : 1,
        })}>
        {option.enabled ? 'Установить' : 'Не устанавливать'}
      </Button.Checkbox>
    </LabeledList.Item>
  );
};

const GenitalSizeItem = (props, context) => {
  const { act } = useBackend(context);
  const { option, busy } = props;

  return (
    <LabeledList.Item label={option.label}>
      {option.type === 'list' ? (
        <Dropdown
          width="100%"
          options={option.options || []}
          selected={option.value}
          disabled={busy || !option.enabled}
          onSelected={value => act('set_genital_size', {
            size_id: option.id,
            value,
          })} />
      ) : (
        <NumberInput
          fluid
          step={1}
          stepPixelSize={4}
          minValue={option.min}
          maxValue={option.max}
          value={option.value}
          disabled={busy || !option.enabled}
          onDrag={(e, value) => act('set_genital_size', {
            size_id: option.id,
            value,
          })}
          onChange={(e, value) => act('set_genital_size', {
            size_id: option.id,
            value,
          })} />
      )}
    </LabeledList.Item>
  );
};

const GenitalColorItem = (props, context) => {
  const { act } = useBackend(context);
  const { option, busy } = props;

  return (
    <LabeledList.Item label={option.label}>
      <Stack align="center">
        <Stack.Item grow>
          <Button
            icon="palette"
            fluid
            content="Выбрать цвет"
            disabled={busy || !option.enabled}
            onClick={() => act('set_genital_color', {
              color_id: option.id,
            })} />
        </Stack.Item>
        <Stack.Item ml={1}>
          <ColorBox
            color={`#${option.value || 'FFFFFF'}`}
            width="2.5rem"
            height="2.1rem" />
        </Stack.Item>
      </Stack>
    </LabeledList.Item>
  );
};

const ConstructorTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    busy,
    suggested_name,
    screens = [],
    limb_styles = [],
    selected_screen,
    size_min,
    size_max,
    bodyparts = [],
    organs = [],
    issues = [],
    can_assemble,
    selected_size,
    stored_metal,
    stored_glass,
    stored_plastic,
    material_capacity,
    required_metal,
    required_glass,
    required_plastic,
    estimated_time_seconds,
    assembly_progress,
    assembly_remaining_seconds,
    assembly_status_text,
    assembly_part_tier,
    preinstalled_software,
    preview_icon,
    implants = [],
  } = data;

  const [designation, setDesignation] = useSharedState(context, 'designation', '');

  return (
    <>
      <Section title="Профиль сборки">
        <Stack align="stretch">
          <Stack.Item basis="42%">
            <Section title="Предпросмотр синтетика" fill>
              <Box
                backgroundColor="#11181d"
                p={1}
                style={{ border: '1px solid #31424d', borderRadius: '4px' }}>
                {preview_icon ? (
                  <PixelArtImage
                    src={`data:image/png;base64,${preview_icon}`}
                    fit="contain"
                    maxHeight={300}
                    containerStyle={{ minHeight: '300px' }} />
                ) : (
                  <Box
                    textAlign="center"
                    color="average"
                    height="300px"
                    lineHeight="300px">
                    Предпросмотр недоступен
                  </Box>
                )}
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item grow ml={1}>
            <Section title="Управление конструктором" fill>
              <Stack vertical>
                <Stack.Item>
                  {!!issues.length && (
                    <NoticeBox danger>
                      {issues.map(issue => (
                        <Box key={issue}>{issue}</Box>
                      ))}
                    </NoticeBox>
                  )}
                  {!issues.length && (
                    <NoticeBox success>
                      Все необходимые детали загружены. Шасси готово к финальной сборке.
                    </NoticeBox>
                  )}
                </Stack.Item>

                <Stack.Item>
                  <Box mb={0.5}>Имя синтетика</Box>
                  <Input
                    fluid
                    maxLength={26}
                    placeholder={suggested_name}
                    value={designation}
                    onChange={(e, value) => setDesignation(value)} />
                  <Box mt={0.5} color="label">
                    Оставьте пустым, чтобы отдать выбор синтетику.
                  </Box>
                </Stack.Item>

                <Stack.Item mt={1}>
                  <Box mb={0.5}>Экран</Box>
                  <Dropdown
                    width="100%"
                    options={screens}
                    selected={selected_screen}
                    disabled={busy}
                    onSelected={value => act('set_screen', { screen: value })} />
                </Stack.Item>

                <Stack.Item mt={1}>
                  <Box mb={0.5}>
                    Размер шасси: {Math.round((selected_size || 1) * 100)}%
                  </Box>
                  <NumberInput
                    fluid
                    step={1}
                    stepPixelSize={4}
                    minValue={(size_min || 1) * 100}
                    maxValue={(size_max || 1) * 100}
                    value={(selected_size || 1) * 100}
                    format={value => `${Math.round(value)}%`}
                    onDrag={(e, value) => act('set_size', { size: value / 100 })}
                    onChange={(e, value) => act('set_size', { size: value / 100 })} />
                </Stack.Item>

                <Stack.Item mt={1}>
                  <Box color="label">
                    Все загруженные детали и ресурсы хранятся внутри конструктора до запуска сборки.
                  </Box>
                </Stack.Item>

                <Stack.Item mt={1}>
                  <LabeledList>
                    <LabeledList.Item label="Уровень деталей">
                      T{Math.min(5, Math.round(assembly_part_tier || 1))}
                    </LabeledList.Item>
                    <LabeledList.Item label="Предустановленное программное обеспечение">
                      {preinstalled_software}
                    </LabeledList.Item>
                  </LabeledList>
                </Stack.Item>

                <Stack.Item mt={1}>
                  <Stack align="center">
                    <Stack.Item grow>
                      <Box bold>
                        {busy
                          ? `Сборка идет: осталось ${assembly_remaining_seconds} сек.`
                          : `Время сборки: ${estimated_time_seconds} сек.`}
                      </Box>
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="cogs"
                        content="Собрать IPC"
                        disabled={busy || !can_assemble}
                        onClick={() => act('assemble', { designation })} />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>

                {busy && (
                  <Stack.Item mt={1}>
                    <Box mb={0.5} color="label">
                      {assembly_status_text}
                    </Box>
                    <Box mb={0.5}>Прогресс сборки</Box>
                    <ProgressBar
                      value={assembly_progress || 0}
                      minValue={0}
                      maxValue={1}
                      ranges={{
                        good: [1, Infinity],
                        average: [0.35, 1],
                        bad: [0, 0.35],
                      }}>
                      {Math.round((assembly_progress || 0) * 100)}%
                    </ProgressBar>
                  </Stack.Item>
                )}
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Section>

      <Section title="Установленные детали">
        <Stack align="stretch">
          <Stack.Item grow>
            <Section title="Шасси">
              <LabeledList>
                {bodyparts.map(slot => (
                  <SlotListItem key={slot.id} slot={slot} busy={busy} limbStyles={limb_styles} />
                ))}
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item grow ml={1}>
            <Section title="Внутренние модули">
              <LabeledList>
                {organs.map(slot => (
                  <SlotListItem key={slot.id} slot={slot} busy={busy} limbStyles={limb_styles} />
                ))}
              </LabeledList>
            </Section>
          </Stack.Item>
        </Stack>
      </Section>

      <Section title="Импланты">
        <LabeledList>
          {!implants.length && (
            <LabeledList.Item label="Статус">
              <Box color="average">
                Импланты не загружены.
              </Box>
            </LabeledList.Item>
          )}
          {!!implants.length && implants.map(implant => (
            <ImplantListItem key={implant.id} implant={implant} busy={busy} />
          ))}
        </LabeledList>
      </Section>

      <Section title="Загруженные ресурсы">
        <Box bold mb={0.5}>Сталь</Box>
        <ProgressBar
          value={stored_metal}
          minValue={0}
          maxValue={Math.max(required_metal, 1)}
          ranges={{
            good: [required_metal, Infinity],
            average: [Math.max(required_metal * 0.5, 1), required_metal],
            bad: [0, Math.max(required_metal * 0.5, 1)],
          }}>
          {stored_metal} / {required_metal} листов
        </ProgressBar>
        <Box mt={0.5} mb={1} color="label">
          Хранилище: {stored_metal} / {material_capacity} листов
        </Box>

        <Box bold mb={0.5}>Стекло</Box>
        <ProgressBar
          value={stored_glass}
          minValue={0}
          maxValue={Math.max(required_glass, 1)}
          ranges={{
            good: [required_glass, Infinity],
            average: [Math.max(required_glass * 0.5, 1), required_glass],
            bad: [0, Math.max(required_glass * 0.5, 1)],
          }}>
          {stored_glass} / {required_glass} листов
        </ProgressBar>
        <Box mt={0.5} color="label">
          Хранилище: {stored_glass} / {material_capacity} листов
        </Box>

        {!!required_plastic && (
          <>
            <Box bold mt={1} mb={0.5}>Пластик</Box>
            <ProgressBar
              value={stored_plastic}
              minValue={0}
              maxValue={Math.max(required_plastic, 1)}
              ranges={{
                good: [required_plastic, Infinity],
                average: [Math.max(required_plastic * 0.5, 1), required_plastic],
                bad: [0, Math.max(required_plastic * 0.5, 1)],
              }}>
              {stored_plastic} / {required_plastic} листов
            </ProgressBar>
            <Box mt={0.5} color="label">
              Хранилище: {stored_plastic} / {material_capacity} листов
            </Box>
          </>
        )}

        <Box mt={1}>
          Ресурсы хранятся в конструкторе отдельно от установленных деталей.
        </Box>
      </Section>
    </>
  );
};

const GenitalsTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    busy,
    genital_options = [],
    genital_size_options = [],
    genital_color_options = [],
    genitals_enabled,
  } = data;

  return (
    <Section title="Половые системы">
      <Stack vertical>
        <Stack.Item>
          <Button.Checkbox
            fluid
            checked={genitals_enabled}
            disabled={busy}
            onClick={() => act('toggle_genitals', {
              enabled: genitals_enabled ? 0 : 1,
            })}>
            Добавить половые системы
          </Button.Checkbox>
        </Stack.Item>

        {!genitals_enabled && (
          <Stack.Item>
            <NoticeBox info>
              Включите модуль, чтобы открыть настройку половых систем. После включения сборщик начнет требовать пластик.
            </NoticeBox>
          </Stack.Item>
        )}

        {!!genitals_enabled && (
          <>
            <Stack.Item>
              <NoticeBox info>
                Выберите, какие половые системы будут установлены в синтетика на финальном этапе сборки.
              </NoticeBox>
            </Stack.Item>
            <Stack.Item>
              <LabeledList>
                {genital_options.map(option => (
                  <GenitalOptionItem key={option.id} option={option} busy={busy} />
                ))}
              </LabeledList>
            </Stack.Item>
            <Stack.Item>
              <Section title="Типы и размеры">
                <LabeledList>
                  {genital_size_options.map(option => (
                    <GenitalSizeItem key={option.id} option={option} busy={busy} />
                  ))}
                </LabeledList>
              </Section>
            </Stack.Item>
            <Stack.Item>
              <Section title="Цвета">
                <LabeledList>
                  {genital_color_options.map(option => (
                    <GenitalColorItem key={option.id} option={option} busy={busy} />
                  ))}
                </LabeledList>
              </Section>
            </Stack.Item>
            <Stack.Item>
              <Box color="label">
                Зависимые опции открываются автоматически. Например, для матки требуется вагина, а для ануса требуются ягодицы.
              </Box>
            </Stack.Item>
          </>
        )}
      </Stack>
    </Section>
  );
};

export const IPCConstructor = (props, context) => {
  const [activeTab, setActiveTab] = useSharedState(context, 'activeTab', 'constructor');

  const shownTab = activeTab === 'genitals'
    ? 'genitals'
    : 'constructor';

  return (
    <Window
      title="Сборщик синтетиков"
      width={880}
      height={820}
      resizable>
      <Window.Content scrollable>
        <Tabs fluid textAlign="center" mb={1}>
          <Tabs.Tab
            selected={shownTab === 'constructor'}
            onClick={() => setActiveTab('constructor')}>
            Конструктор
          </Tabs.Tab>
          <Tabs.Tab
            selected={shownTab === 'genitals'}
            onClick={() => setActiveTab('genitals')}>
            Половые системы
          </Tabs.Tab>
        </Tabs>

        {shownTab === 'constructor' && (
          <ConstructorTab />
        )}

        {shownTab === 'genitals' && (
          <GenitalsTab />
        )}
      </Window.Content>
    </Window>
  );
};
