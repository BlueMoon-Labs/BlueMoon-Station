import { multiline } from '../../common/string';
import { useBackend } from '../backend';
import { Button, Icon, LabeledControls, NoticeBox, Section, Slider, Stack, Tooltip } from '../components';
import { Window } from '../layouts';

type SimpleBotContext = {
  can_hack: number;
  locked: number;
  emagged: number;
  pai: Pai;
  settings: Settings;
  custom_controls: Controls;
};

type Pai = {
  allow_pai: number;
  card_inserted: number;
};

type Settings = {
  power: number;
  airplane_mode: number;
  maintenance_lock: number;
  patrol_station: number;
};

type Controls = {
  [Control: string]: number | string;
};

const controlLabels: Record<string, string> = {
  clean_blood: 'Уборка крови',
  clean_trash: 'Уборка мусора',
  clean_graffiti: 'Граффити',
  pest_control: 'Вредители',
  beaker: 'Мензурка',
  reagents: 'Реагенты',
  injection_amount: 'Доза инъекции',
  use_beaker: 'Использовать мензурку',
  treat_virus: 'Лечить вирусы',
  heal_threshold: 'Порог лечения',
  speaker: 'Динамик',
  crit_alerts: 'Сигнал о крит. состоянии',
  stationary_mode: 'Стационарный режим',
  sync_tech: 'Синхронизация с сетью',
  tile_hull: 'Заделывать пробоины',
  place_tiles: 'Укладывать плитку',
  place_custom: 'Заменять плитку',
  repair_damage: 'Ремонтировать пол',
  traction_magnets: 'Фиксирующие магниты',
  tile_stack: 'Запас плитки',
  line_mode: 'Укладка по прямой',
  extinguish_fires: 'Тушить пожары',
  extinguish_people: 'Тушить людей',
  check_id: 'Проверять ID-карты',
  check_weapons: 'Проверять оружие',
  check_warrants: 'Проверять статус розыска',
  handcuff_targets: 'Надевать наручники',
  arrest_alert: 'Сообщать об арестах',
  maximum_sanity: 'Порог рассудка',
  mode_selected: 'Режим взаимодействия',
  tania_mode: 'Режим Тани',
};

export const SimpleBot = (_) => {
  const { data } = useBackend<SimpleBotContext>();
  const { can_hack, locked } = data;
  const access = (!locked || can_hack);

  return (
    <Window width={450} height={300}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section title="Настройки" buttons={<TabDisplay />}>
              {!access
                ? (<NoticeBox>Панель заблокирована!</NoticeBox>)
                : (<SettingsDisplay />)}
            </Section>
          </Stack.Item>
          {access && (
            <Stack.Item grow>
              <Section fill scrollable title="Управление">
                <ControlsDisplay />
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

/** Creates a lock button at the top of the controls */
const TabDisplay = (_) => {
  const { act, data } = useBackend<SimpleBotContext>();
  const { can_hack, locked, pai } = data;
  const { allow_pai } = pai;

  return (
    <>
      {!!can_hack && <HackButton />}
      {!!allow_pai && <PaiButton />}
      <Button
        color="transparent"
        icon={locked ? 'lock' : 'lock-open'}
        onClick={() => act('lock')}
        selected={locked}
        tooltip={locked ? 'Разблокировать панель.' : 'Заблокировать панель.'}>
        Замок панели
      </Button>
    </>
  );
};

/** If user is a bad silicon, they can press this button to hack the bot */
const HackButton = (_) => {
  const { act, data } = useBackend<SimpleBotContext>();
  const { can_hack, emagged } = data;

  return (
    <Button
      color="danger"
      disabled={!can_hack}
      icon={emagged ? 'bug' : 'lock'}
      onClick={() => act('hack')}
      selected={!emagged}
      tooltip={
        !emagged
          ? 'Отключить протоколы безопасности.'
          : 'Сбросить операционную систему бота.'
      }>
      {emagged ? 'Сбой' : 'Защита'}
    </Button>
  );
};

/** Creates a button indicating PAI status and offers the eject action */
const PaiButton = (_) => {
  const { act, data } = useBackend<SimpleBotContext>();
  const { card_inserted } = data.pai;

  if (!card_inserted) {
    return (
      <Button
        color="transparent"
        icon="robot"
        tooltip="Вставьте активную карту ПИИ для управления ботом.">
        Без ПИИ
      </Button>
    );
  } else {
    return (
      <Button
        disabled={!card_inserted}
        icon="eject"
        onClick={() => act('eject_pai')}
        tooltip="Извлечь установленную карту ПИИ.">
        Извлечь ПИИ
      </Button>
    );
  }
};

/** Displays the bot's standard settings: Power, patrol, etc. */
const SettingsDisplay = (_) => {
  const { act, data } = useBackend<SimpleBotContext>();
  const { settings } = data;
  const { airplane_mode, patrol_station, power, maintenance_lock } = settings;

  return (
    <LabeledControls>
      <LabeledControls.Item label="Питание">
        <Tooltip content={power ? 'Выключить бота.' : 'Включить бота.'}>
          <Icon
            size={2}
            name="power-off"
            color={power ? 'good' : 'gray'}
            onClick={() => act('power')}
          />
        </Tooltip>
      </LabeledControls.Item>
      <LabeledControls.Item label="Авиарежим">
        <Tooltip
          content={airplane_mode
            ? 'Разрешить удалённый доступ через консоль.'
            : 'Запретить удалённый доступ через консоль.'}>
          <Icon
            size={2}
            name="plane"
            color={airplane_mode ? 'yellow' : 'gray'}
            onClick={() => act('airplane')}
          />
        </Tooltip>
      </LabeledControls.Item>
      <LabeledControls.Item label="Патруль">
        <Tooltip
          content={patrol_station
            ? 'Остановить автоматическое патрулирование станции.'
            : 'Запустить автоматическое патрулирование станции.'}>
          <Icon
            size={2}
            name="map-signs"
            color={patrol_station ? 'good' : 'gray'}
            onClick={() => act('patrol')}
          />
        </Tooltip>
      </LabeledControls.Item>
      <LabeledControls.Item label="Сервисный люк">
        <Tooltip
          content={
            maintenance_lock
              ? 'Открыть люк для ремонта.'
              : 'Закрыть сервисный люк.'
          }>
          <Icon
            size={2}
            name="toolbox"
            color={maintenance_lock ? 'yellow' : 'gray'}
            onClick={() => act('maintenance')}
          />
        </Tooltip>
      </LabeledControls.Item>
    </LabeledControls>
  );
};

/** Iterates over custom controls.
 * Calls the helper to identify which button to use.
 */
const ControlsDisplay = (_) => {
  const { data } = useBackend<SimpleBotContext>();
  const { custom_controls } = data;

  return (
    <LabeledControls wrap>
      {Object.entries(custom_controls).map((control) => {
        return (
          <LabeledControls.Item
            pb={2}
            key={control[0]}
            label={controlLabels[control[0]] ?? control[0]
              .replace('_', ' ')
              .replace(/(^\w{1})|(\s+\w{1})/g, (letter) =>
                letter.toUpperCase())}>
            <ControlHelper control={control} />
          </LabeledControls.Item>
        );
      })}
    </LabeledControls>
  );
};

/** Helper function which identifies which button to create.
 * Might need some fine tuning if you are using more advanced controls.
 */
const ControlHelper = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;
  if (control[0] === 'sync_tech') {
    /** Control is for sync - this is medbot specific */
    return <MedbotSync />;
  } else if (control[0] === 'heal_threshold') {
    /** Control is a threshold - this is medbot specific */
    return <MedbotThreshold control={control} />;
  } else if (control[0] === 'injection_amount') {
    /** Control is for injection - this is medbot specific */
    return <InjectionThreshold control={control} />;
  } else if (control[0] === 'tile_stack') {
    return <FloorbotTiles control={control} />;
  } else if (control[0] === 'line_mode') {
    return <FloorbotLine control={control} />;
  } else if (control[0] === 'maximum_sanity') {
    /** Control is for maximum sanity - this is hugbot specific */
    return <MaximumSanity control={control} />;
  } else if (control[0] === 'mode_selected') {
    /** Control is for zone selection - this is hugbot specific */
    return <ModeSelection control={control} />;
  } else {
    /** Control is a boolean of some type */
    return (
      <Icon
        color={control[1] ? 'good' : 'gray'}
        name={control[1] ? 'toggle-on' : 'toggle-off'}
        size={2}
        onClick={() => act(control[0])}
      />
    );
  }
};

/** Small button to sync medbots with research. */
const MedbotSync = (_) => {
  const { act } = useBackend<SimpleBotContext>();

  return (
    <Tooltip
      content={multiline`Синхронизировать хирургические данные с исследовательской сетью.
        Повышает эффективность лечения.`}>
      <Icon
        color="purple"
        name="cloud-download-alt"
        size={2}
        onClick={() => act('sync_tech')}
      />
    </Tooltip>
  );
};

/** Slider button for medbot injection thresholds */
const InjectionThreshold = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;

  return (
    <Tooltip content="Установить объём реагентов для одной инъекции.">
      <Slider
        minValue={1}
        maxValue={15}
        ranges={{
          bad: [-Infinity, 5],
          average: [6, 10],
          good: [11, Infinity],
        }}
        step={2}
        unit="ед."
        value={control[1]}
        onChange={(_, value) => act(control[0], { amount: value })}
      />
    </Tooltip>
  );
};

/** Slider button for medbot healing thresholds */
const MedbotThreshold = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;

  return (
    <Tooltip content="Установить порог повреждений, при котором бот начнёт лечение.">
      <Slider
        minValue={5}
        maxValue={75}
        ranges={{
          good: [-Infinity, 15],
          average: [15, 55],
          bad: [55, Infinity],
        }}
        step={5}
        unit="ед."
        value={control[1]}
        onChange={(_, value) => act(control[0], { threshold: value })}
      />
    </Tooltip>
  );
};

/** Tile stacks for floorbots - shows number and eject button */
const FloorbotTiles = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;

  return (
    <Button
      disabled={!control[1]}
      icon={control[1] ? 'eject' : ''}
      onClick={() => act('eject_tiles')}
      tooltip="Количество плиток в боте. Нажмите, чтобы выгрузить их.">
      {control[1] ? `${control[1]}` : 'Пусто'}
    </Button>
  );
};

const directionLabels = {
  north: 'С',
  east: 'В',
  south: 'Ю',
  west: 'З',
};

/** Direction indicator for floorbot when line mode is chosen. */
const FloorbotLine = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;

  return (
    <Tooltip content="Выбрать направление укладки по прямой или отключить этот режим.">
      <Icon
        color={control[1] ? 'good' : 'gray'}
        name={control[1] ? 'compass' : 'toggle-off'}
        onClick={() => act('line_mode')}
        size={!control[1] ? 2 : 1.5}>
        {' '}
        {control[1] ? directionLabels[control[1]] : ''}
      </Icon>
    </Tooltip>
  );
};

/** Slider button for hugbot assistance thresholds */
const MaximumSanity = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;

  return (
    <Tooltip content="Бот помогает только тем, чей рассудок не выше заданного порога.">
      <Slider
        minValue={0}
        maxValue={125}
        ranges={{
          bad: [-Infinity, 25],
          average: [26, 75],
          good: [76, Infinity],
        }}
        step={10}
        unit="ед."
        value={control[1]}
        onChange={(_, value) => act(control[0], { amount: value })}
      />
    </Tooltip>
  );
};

const limbToInteraction = {
  chest: 'Обнять',
  head: 'Погладить',
  mouth: 'Ткнуть в нос',
};

/** Active mode for hugbots. */
const ModeSelection = (props) => {
  const { act } = useBackend<SimpleBotContext>();
  const { control } = props;

  return (
    <Tooltip content="Выбрать, как бот будет взаимодействовать с окружающими.">
      <Icon
        color={control[1] ? 'good' : 'gray'}
        name={control[1] ? 'sync-alt' : 'toggle-off'}
        onClick={() => act('op_mode')}
        size={!control[1] ? 2 : 1.5}>
        {' '}
        {control[1] ? limbToInteraction[control[1]] : ''}
      </Icon>
    </Tooltip>
  );
};
