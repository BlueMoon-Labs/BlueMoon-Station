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

const shellStyle = {
  background: `
    radial-gradient(circle at top left, rgba(101, 171, 199, 0.12), transparent 26%),
    radial-gradient(circle at top right, rgba(83, 112, 173, 0.08), transparent 24%),
    linear-gradient(180deg, #11161c 0%, #0c1016 100%)
  `,
};

const panelStyle = {
  background: 'linear-gradient(180deg, rgba(23, 30, 38, 0.98) 0%, rgba(17, 22, 28, 0.98) 100%)',
  border: '1px solid rgba(100, 142, 169, 0.18)',
  borderRadius: '8px',
  boxShadow: '0 14px 24px rgba(0, 0, 0, 0.22), inset 0 1px 0 rgba(214, 238, 255, 0.035)',
};

const insetPanelStyle = {
  background: 'linear-gradient(180deg, rgba(15, 21, 28, 0.99) 0%, rgba(11, 16, 22, 0.99) 100%)',
  border: '1px solid rgba(93, 126, 151, 0.16)',
  borderRadius: '6px',
  boxShadow: 'inset 0 0 18px rgba(0, 0, 0, 0.16)',
};

const previewFrameStyle = {
  ...insetPanelStyle,
  minHeight: '300px',
  background: `
    radial-gradient(circle at 50% 18%, rgba(105, 185, 218, 0.1), transparent 30%),
    linear-gradient(180deg, rgba(16, 22, 30, 0.98) 0%, rgba(9, 14, 20, 0.98) 100%)
  `,
  boxShadow: '0 0 0 1px rgba(98, 142, 173, 0.12), inset 0 0 26px rgba(0, 0, 0, 0.26)',
  position: 'relative',
  overflow: 'hidden',
};

const badgeStyle = {
  background: 'linear-gradient(180deg, rgba(29, 36, 44, 0.96), rgba(18, 24, 30, 0.98))',
  border: '1px solid rgba(100, 142, 169, 0.18)',
  borderRadius: '7px',
  boxShadow: 'inset 0 1px 0 rgba(220, 242, 255, 0.028)',
  padding: '8px 10px',
  position: 'relative',
  overflow: 'hidden',
};

const tabStyle = isSelected => ({
  background: isSelected
    ? 'linear-gradient(180deg, rgba(59, 102, 129, 0.96), rgba(33, 61, 79, 0.98))'
    : 'linear-gradient(180deg, rgba(30, 38, 47, 0.95), rgba(19, 25, 31, 0.98))',
  border: `1px solid ${isSelected ? 'rgba(128, 191, 225, 0.28)' : 'rgba(88, 113, 133, 0.14)'}`,
  borderRadius: '999px',
  boxShadow: isSelected
    ? '0 0 0 1px rgba(116, 186, 223, 0.08), inset 0 1px 0 rgba(228, 247, 255, 0.06)'
    : 'inset 0 1px 0 rgba(255,255,255,0.02)',
  color: isSelected ? '#ecf8ff' : '#b1c5d3',
  paddingLeft: '6px',
  paddingRight: '6px',
});

const sectionTitle = text => (
  <Box
    className="ipc-section-title"
    bold
    style={{
      color: '#d5e8f2',
      letterSpacing: '0.07em',
      textTransform: 'uppercase',
    }}>
    {text}
  </Box>
);

const StatusCard = ({ label, value, accent = '#7fdcff' }) => (
  <Box className="ipc-status-card" style={badgeStyle}>
    <Box
      color="label"
      style={{
        fontSize: '11px',
        letterSpacing: '0.05em',
        textTransform: 'uppercase',
        opacity: 0.8,
      }}>
      {label}
    </Box>
    <Box
      bold
      mt={0.5}
      style={{
        color: accent,
        fontSize: '16px',
        textShadow: `0 0 10px ${accent}22`,
      }}>
      {value}
    </Box>
  </Box>
);

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
          <Box
            color={slot.occupied ? 'good' : 'bad'}
            style={{
              ...insetPanelStyle,
              padding: '8px 10px',
            }}>
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
      <Box
        color="good"
        style={{
          ...insetPanelStyle,
          padding: '8px 10px',
        }}>
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
  const optionalPartLabels = {
    l_arm: 'левая рука',
    r_arm: 'правая рука',
    l_leg: 'левая нога',
    r_leg: 'правая нога',
  };
  const missing_optional_parts = bodyparts
    .filter(slot => optionalPartLabels[slot.id] && !slot.occupied)
    .map(slot => optionalPartLabels[slot.id]);
  const assembledName = designation || 'этого синтетика';
  const assembleConfirmText = missing_optional_parts.length
    ? `Создать ${assembledName}? Отсутствуют части: ${missing_optional_parts.join(', ')}`
    : 'Подтвердить сборку?';

  return (
    <>
      <Section title="Профиль сборки">
        <Stack align="stretch">
          <Stack.Item basis="42%">
            <Section title={sectionTitle('Предпросмотр синтетика')} fill style={panelStyle}>
              <Box className="ipc-preview-frame" p={1} style={previewFrameStyle}>
                <Box className="ipc-preview-grid" />
                <Box className="ipc-preview-scan" />
                {preview_icon ? (
                  <PixelArtImage
                    src={`data:image/png;base64,${preview_icon}`}
                    fit="contain"
                    maxHeight={300}
                    containerStyle={{
                      minHeight: '300px',
                      position: 'relative',
                      zIndex: 2,
                    }} />
                ) : (
                  <Box
                    textAlign="center"
                    color="average"
                    height="300px"
                    lineHeight="300px"
                    style={{ position: 'relative', zIndex: 2 }}>
                    Предпросмотр недоступен
                  </Box>
                )}
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item grow ml={1}>
            <Section title={sectionTitle('Управление конструктором')} fill style={panelStyle}>
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
                  <Stack>
                    <Stack.Item grow>
                      <StatusCard
                        label="Уровень деталей"
                        value={`T${Math.min(5, Math.round(assembly_part_tier || 1))}`}
                        accent="#7ec3e4" />
                    </Stack.Item>
                    <Stack.Item grow ml={1}>
                      <StatusCard
                        label="ПО"
                        value={preinstalled_software}
                        accent={preinstalled_software === 'Да' ? '#8fd1ba' : '#9fb5c3'} />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>

                <Stack.Item mt={1}>
                  <Stack align="center">
                    <Stack.Item grow>
                    <Box
                      bold
                      style={{
                        ...badgeStyle,
                        color: '#e8f3fa',
                      }}>
                        {busy
                          ? `Сборка идет: осталось ${assembly_remaining_seconds} сек.`
                          : `Время сборки: ${estimated_time_seconds} сек.`}
                      </Box>
                    </Stack.Item>
                    <Stack.Item>
                      {missing_optional_parts.length ? (
                        <Button.Confirm
                          icon="cogs"
                          content="Собрать IPC"
                          confirmContent={assembleConfirmText}
                          disabled={busy || !can_assemble}
                          onClick={() => act('assemble', { designation })} />
                      ) : (
                        <Button
                          icon="cogs"
                          content="Собрать IPC"
                          disabled={busy || !can_assemble}
                          onClick={() => act('assemble', { designation })} />
                      )}
                    </Stack.Item>
                  </Stack>
                </Stack.Item>

                {busy && (
                  <Stack.Item mt={1}>
                    <Box mb={0.5} color="label" style={{ textShadow: '0 0 6px rgba(126, 195, 228, 0.14)' }}>
                      {assembly_status_text}
                    </Box>
                    <Box mb={0.5}>Прогресс сборки</Box>
                    <Box className="ipc-progress-shell" style={insetPanelStyle}>
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
                    </Box>
                  </Stack.Item>
                )}
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Section>

      <Section title={sectionTitle('Установленные детали')} style={panelStyle}>
        <Stack align="stretch">
          <Stack.Item grow>
            <Section title={sectionTitle('Шасси')} style={insetPanelStyle}>
              <LabeledList>
                {bodyparts.map(slot => (
                  <SlotListItem key={slot.id} slot={slot} busy={busy} limbStyles={limb_styles} />
                ))}
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item grow ml={1}>
            <Section title={sectionTitle('Внутренние модули')} style={insetPanelStyle}>
              <LabeledList>
                {organs.map(slot => (
                  <SlotListItem key={slot.id} slot={slot} busy={busy} limbStyles={limb_styles} />
                ))}
              </LabeledList>
            </Section>
          </Stack.Item>
        </Stack>
      </Section>

      <Section title={sectionTitle('Импланты')} style={panelStyle}>
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

      <Section title={sectionTitle('Загруженные ресурсы')} style={panelStyle}>
        <Box bold mb={0.5}>Сталь</Box>
        <Box className="ipc-progress-shell" style={insetPanelStyle}>
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
        </Box>
        <Box mt={0.5} mb={1} color="label">
          Хранилище: {stored_metal} / {material_capacity} листов
        </Box>

        <Box bold mb={0.5}>Стекло</Box>
        <Box className="ipc-progress-shell" style={insetPanelStyle}>
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
        </Box>
        <Box mt={0.5} color="label">
          Хранилище: {stored_glass} / {material_capacity} листов
        </Box>

        {!!required_plastic && (
          <>
            <Box bold mt={1} mb={0.5}>Пластик</Box>
            <Box className="ipc-progress-shell" style={insetPanelStyle}>
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
            </Box>
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
    <Section title={sectionTitle('Половые системы')} style={panelStyle}>
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
              <Section title={sectionTitle('Типы и размеры')} style={insetPanelStyle}>
                <LabeledList>
                  {genital_size_options.map(option => (
                    <GenitalSizeItem key={option.id} option={option} busy={busy} />
                  ))}
                </LabeledList>
              </Section>
            </Stack.Item>
            <Stack.Item>
              <Section title={sectionTitle('Цвета')} style={insetPanelStyle}>
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
      <Window.Content scrollable style={shellStyle}>
        <Box className="ipc-shell-backdrop" />
        <Box
          className="ipc-shell-content"
          style={{
            position: 'relative',
            zIndex: 1,
            padding: '10px 10px 16px',
          }}>
        <Tabs fluid textAlign="center" mb={1}>
          <Tabs.Tab
            selected={shownTab === 'constructor'}
            style={tabStyle(shownTab === 'constructor')}
            onClick={() => setActiveTab('constructor')}>
            Конструктор
          </Tabs.Tab>
          <Tabs.Tab
            selected={shownTab === 'genitals'}
            style={tabStyle(shownTab === 'genitals')}
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
        </Box>
        <style>{`
          .ipc-shell-backdrop {
            position: absolute;
            inset: 0;
            background-image:
              linear-gradient(rgba(102, 155, 183, 0.035) 1px, transparent 1px),
              linear-gradient(90deg, rgba(102, 155, 183, 0.035) 1px, transparent 1px),
              linear-gradient(180deg, rgba(177, 230, 255, 0.03), transparent 16%);
            background-size: 34px 34px, 34px 34px, 100% 100%;
            pointer-events: none;
          }
          .ipc-shell-content > .Tabs {
            padding: 2px;
            border-radius: 999px;
            background: rgba(8, 14, 19, 0.4);
            border: 1px solid rgba(97, 135, 158, 0.12);
            backdrop-filter: blur(2px);
          }
          .ipc-section-title {
            position: relative;
            padding-left: 12px;
          }
          .ipc-section-title::before {
            content: "";
            position: absolute;
            left: 0;
            top: 50%;
            width: 6px;
            height: 6px;
            border-radius: 999px;
            background: #7ec3e4;
            box-shadow: 0 0 8px rgba(126, 195, 228, 0.3);
            transform: translateY(-50%);
          }
          .ipc-preview-frame::before {
            content: "";
            position: absolute;
            inset: 14px;
            border: 1px solid rgba(129, 184, 216, 0.08);
            border-radius: 4px;
            pointer-events: none;
            z-index: 1;
          }
          .ipc-preview-grid {
            position: absolute;
            inset: 0;
            background-image:
              linear-gradient(rgba(106, 163, 193, 0.05) 1px, transparent 1px),
              linear-gradient(90deg, rgba(106, 163, 193, 0.05) 1px, transparent 1px);
            background-size: 24px 24px;
            mask-image: linear-gradient(180deg, rgba(255,255,255,0.7), rgba(255,255,255,0.18));
            pointer-events: none;
            z-index: 0;
          }
          .ipc-preview-scan {
            position: absolute;
            left: 0;
            right: 0;
            top: -18%;
            height: 28%;
            background: linear-gradient(180deg, transparent, rgba(110, 200, 236, 0.1), transparent);
            animation: ipc-preview-scan 5.8s linear infinite;
            pointer-events: none;
            z-index: 0;
          }
          .ipc-status-card::after {
            content: "";
            position: absolute;
            left: 0;
            right: 0;
            top: 0;
            height: 3px;
            background: linear-gradient(90deg, rgba(126, 195, 228, 0.06), rgba(126, 195, 228, 0.28), rgba(126, 195, 228, 0.06));
          }
          .ipc-progress-shell {
            position: relative;
            overflow: hidden;
            padding: 4px;
          }
          .ipc-progress-shell::after {
            content: "";
            position: absolute;
            top: 0;
            bottom: 0;
            width: 28%;
            background: linear-gradient(90deg, transparent, rgba(126, 195, 228, 0.1), transparent);
            animation: ipc-progress-sheen 2.8s linear infinite;
            pointer-events: none;
          }
          @keyframes ipc-preview-scan {
            0% { transform: translateY(0); opacity: 0; }
            12% { opacity: 1; }
            78% { opacity: 1; }
            100% { transform: translateY(420px); opacity: 0; }
          }
          @keyframes ipc-progress-sheen {
            0% { left: -30%; }
            100% { left: 110%; }
          }
        `}</style>
      </Window.Content>
    </Window>
  );
};
