import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Collapsible,
  Icon,
  LabeledList,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tabs,
  Tooltip,
} from '../../components';
import type { MainData, MechModule } from './data';
import { useHonk } from './honk';

const cardinalDirections: Record<number, string> = {
  1: 'Север',
  2: 'Юг',
  4: 'Восток',
  8: 'Запад',
};

const moduleResource = (module: MechModule) => {
  const extra = module.snowflake;
  switch (extra?.kind) {
    case 'ballistic': return `Боезапас ${extra.total_ammo}/${extra.max_ammo}`;
    case 'extinguisher': return `Пена ${extra.reagents}/${extra.total_reagents}`;
    case 'generator': return `Топливо ${extra.fuel_amount}/${extra.max_fuel} см³`;
    case 'sleeper': return extra.patient ? extra.patient.patient_name : 'Слипер свободен';
    case 'syringe': return `Шприцы ${extra.syringe}/${extra.max_syringe} · ${Math.round(extra.reagents * 10) / 10} ед.`;
    case 'rcd': return extra.modes.find(mode => mode.id === extra.mode)?.name;
    case 'mode': return extra.modes[extra.mode - extra.first_mode];
    default: return null;
  }
};

const moduleStatus = (module: MechModule) => {
  if (module.unavailable_reason) {
    return { text: module.unavailable_reason, color: 'average', icon: 'exclamation-triangle' };
  }
  if (module.snowflake?.kind === 'ballistic' && module.snowflake.total_ammo <= 0) {
    return { text: 'Нет боеприпасов', color: 'bad', icon: 'exclamation-triangle' };
  }
  if (module.snowflake?.kind === 'extinguisher' && module.snowflake.reagents < 1) {
    return { text: 'Резервуар пуст', color: 'average', icon: 'exclamation-triangle' };
  }
  if (module.snowflake?.kind === 'sleeper' && module.snowflake.patient) {
    const capsule = module.snowflake;
    return {
      text: !capsule.life_support_active ? 'Нет жизнеобеспечения' : capsule.stasis_enabled ? 'Стазис' : 'Жизнеобеспечение',
      color: capsule.life_support_active ? 'good' : 'bad',
      icon: capsule.stasis_enabled ? 'snowflake' : 'heart',
    };
  }
  if (module.can_be_toggled) {
    return { text: module.active ? 'Включён' : 'Выключен', color: module.active ? 'good' : 'label', icon: 'power-off' };
  }
  return { text: 'Готов', color: 'good', icon: 'check' };
};

export const ManipulatorPane = ({ onSelect }: { onSelect: (ref: string) => void }) => {
  const { data } = useBackend<MainData>();
  return (
    <Stack className="Mecha__manipulators" mt={1}>
      {(['left', 'right'] as const).map(side => {
        const module = data.modules.find(item => side === 'left' ? item.selected_left : item.selected_right);
        const status = module && moduleStatus(module);
        return (
          <Stack.Item key={side} basis="50%" minWidth={0}>
            <Box className="Mecha__manipulatorLabel">{side === 'left' ? 'Левый' : 'Правый'} манипулятор</Box>
            <Button
              fluid
              className="Mecha__manipulator"
              disabled={!module}
              tooltip={module ? module.name : 'Модуль не назначен. Выберите его в списке модулей.'}
              onClick={() => module && onSelect(module.ref)}>
              {module ? (
                <>
                  <img alt="" src={`data:image/png;base64,${module.image}`} width={32} height={32} />
                  <Box className="Mecha__ellipsis">{module.name}</Box>
                  <Box className="Mecha__ellipsis" fontSize="10px" color="label">{moduleResource(module)}</Box>
                  {status?.text !== 'Готов' && (
                    <Box fontSize="10px" color={status?.color}>
                      <Icon name={status!.icon} mr={0.5} />{status?.text}
                    </Box>
                  )}
                </>
              ) : <Box color="label">Не назначен</Box>}
            </Button>
          </Stack.Item>
        );
      })}
    </Stack>
  );
};

type ModulesPaneProps = {
  selected: string | null;
  onSelect: (ref: string) => void;
  tab: number;
  onTabChange: (tab: number) => void;
};

export const ModulesPane = ({ selected, onSelect, tab, onTabChange }: ModulesPaneProps) => {
  const { act, data } = useBackend<MainData>();
  const honk = useHonk(data.ui_honked ? 0.4 : 0);
  const module = data.modules.find(item => item.ref === selected) || data.modules[0];
  return (
    <Stack vertical fill>
      <Stack.Item>
        <Tabs>
          <Tabs.Tab icon="table" selected={tab === 0} onClick={() => onTabChange(0)}>
            {honk('Модули')}
          </Tabs.Tab>
          {!!data.cargo && (
            <Tabs.Tab icon="box" selected={tab === 1} onClick={() => onTabChange(1)}>
              {honk('Груз')}
            </Tabs.Tab>
          )}
          <Tabs.Tab icon="cog" selected={tab === 2} onClick={() => onTabChange(2)}>
            {honk('Настройки')}
          </Tabs.Tab>
        </Tabs>
      </Stack.Item>
      <Stack.Item grow>
        {tab === 0 && (
          <Stack fill>
            <Stack.Item width="205px" shrink={0}>
              <Section
                fill
                scrollable
                title={`${honk('Модули')} ${data.modules.length}/${data.max_equip}`}
                buttons={(
                  <Button
                    icon="question"
                    tooltip="Двойной клик по модулю: включить или выключить переключаемый модуль; назначить активный модуль на ЛКМ или снять назначение. ПКМ: включить или выключить переключаемый модуль; назначить активный модуль на ПКМ или снять назначение." />
                )}>
                {data.modules.map(item => (
                  <Button
                    key={item.ref}
                    fluid
                    className="Mecha__moduleRow"
                    selected={module?.ref === item.ref}
                    tooltip={item.name}
                    onClick={() => onSelect(item.ref)}
                    onContextMenu={(event: Event) => {
                      event.preventDefault();
                      event.stopPropagation();
                      if (!data.can_equipment) {
                        return;
                      }
                      if (item.can_be_toggled) {
                        act('equip_act', { ref: item.ref, gear_action: item.toggle_action });
                      } else if (item.can_be_triggered) {
                        act('select_module', { ref: item.ref, button: 'right' });
                      }
                    }}
                    onDoubleClick={() => {
                      if (!data.can_equipment) {
                        return;
                      }
                      if (item.can_be_toggled) {
                        act('equip_act', { ref: item.ref, gear_action: item.toggle_action });
                      } else if (item.can_be_triggered) {
                        act('select_module', { ref: item.ref, button: 'left' });
                      }
                    }}>
                    <Stack align="center">
                      <Stack.Item>
                        <img
                          src={`data:image/png;base64,${item.image}`}
                          width={32}
                          height={32}
                          style={{ imageRendering: 'pixelated', verticalAlign: 'middle' }} />
                      </Stack.Item>
                      <Stack.Item grow minWidth={0}>
                        <Box className="Mecha__ellipsis" bold>{item.name}</Box>
                        <Box fontSize="10px" color="label" className="Mecha__ellipsis">{moduleResource(item)}</Box>
                        {moduleStatus(item).text !== 'Готов' && (
                          <Box fontSize="10px" color={moduleStatus(item).color} className="Mecha__ellipsis">
                            <Icon name={moduleStatus(item).icon} mr={0.5} />{moduleStatus(item).text}
                          </Box>
                        )}
                        {!!(item.selected_left || item.selected_right) && (
                          <Box className="Mecha__assignment">
                            {item.selected_left ? 'Левый' : ''}{item.selected_left && item.selected_right ? ' · ' : ''}{item.selected_right ? 'Правый' : ''}
                          </Box>
                        )}
                      </Stack.Item>
                    </Stack>
                  </Button>
                ))}
                {!data.modules.length && <Box color="label">Нет модулей</Box>}
              </Section>
            </Stack.Item>
            <Stack.Item grow minWidth="0px">
              <Section fill scrollable>
                {module ? <ModuleDetails module={module} /> : <NoticeBox>Оборудование не установлено.</NoticeBox>}
              </Section>
            </Stack.Item>
          </Stack>
        )}
        {tab === 1 && !!data.cargo && <CargoPane />}
        {tab === 2 && <SettingsPane />}
      </Stack.Item>
      <Stack.Item>
        <Collapsible title="Управление" marginBottom={0}>
          <Section maxHeight="130px" scrollable>
            {data.actions.map(action => (
              <Button
                key={action.ref}
                maxWidth="220px"
                ellipsis
                content={action.name}
                onClick={() => act('trigger_action', { ref: action.ref })} />
            ))}
          </Section>
        </Collapsible>
      </Stack.Item>
    </Stack>
  );
};

const ModuleDetails = ({ module }: { module: MechModule }) => {
  const { act, data } = useBackend<MainData>();
  const honk = useHonk(data.ui_honked ? 0.4 : 0);
  const controlReason = !data.can_equipment ? 'С этого места нельзя управлять оборудованием.' : null;
  const detachReason = controlReason || module.detach_reason;
  const status = moduleStatus(module);
  return (
    <>
      <Section
        className="Mecha__moduleHeader"
        title={module.name}
        buttons={!!module.detachable && (
          <Button.Confirm
            icon="eject"
            tooltip={detachReason || 'Отсоединить модуль'}
            disabled={!!detachReason}
            onClick={() => act('equip_act', { ref: module.ref, gear_action: 'detach' })} />
        )}>
        {module.desc}
      </Section>
      <Section title="Состояние" className="Mecha__moduleDetails">
        <LabeledList>
          <LabeledList.Item label="Готовность">
            <Box color={status.color}><Icon name={status.icon} mr={0.5} />{status.text}</Box>
          </LabeledList.Item>
          {!!module.energy_per_use && (
            <LabeledList.Item label="Затраты энергии">
              {module.energy_per_use} за использование
            </LabeledList.Item>
          )}
          {!!module.equip_cooldown && (
            <LabeledList.Item label={honk('Задержка применения')}>
              {module.equip_cooldown}
            </LabeledList.Item>
          )}
        </LabeledList>
      </Section>
      {!!(module.can_be_triggered || module.can_be_toggled) && (
        <Section title="Управление" className="Mecha__moduleDetails">
          <LabeledList>
            {!!module.can_be_triggered && (
              <LabeledList.Item label="Использование">
                <Button
                  selected={module.selected_left}
                  disabled={!data.can_equipment}
                  content="Левый"
                  tooltip={controlReason || 'Назначить на левый манипулятор (ЛКМ). Колесо мыши переключает модуль.'}
                  onClick={() => act('select_module', { ref: module.ref, button: 'left' })} />
                <Button
                  selected={module.selected_right}
                  disabled={!data.can_equipment}
                  content="Правый"
                  tooltip={controlReason || 'Назначить на правый манипулятор (ПКМ). Shift + колесо мыши переключает модуль.'}
                  onClick={() => act('select_module', { ref: module.ref, button: 'right' })} />
              </LabeledList.Item>
            )}
            {!!module.can_be_toggled && (
              <LabeledList.Item label="Работа модуля">
                <Button
                  icon="power-off"
                  selected={module.active}
                  disabled={!data.can_equipment}
                  tooltip={controlReason}
                  content={honk(module.active ? 'Включен' : 'Выключен')}
                  onClick={() => act('equip_act', { ref: module.ref, gear_action: module.toggle_action })} />
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
      )}
      {!!module.snowflake && (
        <Section
          title={module.snowflake.kind === 'sleeper' ? 'Медицинская капсула' : ['rcd', 'mode'].includes(module.snowflake.kind) ? 'Настройки модуля' : 'Ресурсы'}
          className="Mecha__moduleDetails">
          <LabeledList><ModuleDetailsExtra module={module} /></LabeledList>
        </Section>
      )}
    </>
  );
};

const ModuleDetailsExtra = ({ module }: { module: MechModule }) => {
  const { act, data } = useBackend<MainData>();
  const extra = module.snowflake;
  const control = (gear_action: string, params = {}) => act('equip_act', { ref: module.ref, gear_action, ...params });
  const disabled = !data.can_equipment;
  const controlReason = disabled ? 'С этого места нельзя управлять оборудованием.' : null;
  if (!extra) {
    return null;
  }
  switch (extra.kind) {
    case 'rcd':
      return (
        <>
          <LabeledList.Item className="Mecha__wideRow" label="Настройка РЦД">
            <Button
              fluid
              icon="th"
              content="Радиальное меню"
              disabled={disabled}
                tooltip={controlReason}
              onClick={() => control('menu')} />
          </LabeledList.Item>
          <LabeledList.Item className="Mecha__wideRow" label="Режим">
            {extra.modes.map(mode => (
              <Button
                key={mode.id}
                fluid
                content={mode.name}
                disabled={disabled}
                tooltip={controlReason}
                selected={extra.mode === mode.id}
                onClick={() => control('mode', { mode: mode.id })} />
            ))}
          </LabeledList.Item>
          {!!extra.window_mode && (
            <LabeledList.Item label="Окна">
              <Button
                fluid
                content={extra.reinforced_windows ? 'Армированное стекло' : 'Обычное стекло'}
                disabled={disabled}
                tooltip={controlReason}
                onClick={() => control('window_type')} />
            </LabeledList.Item>
          )}
          {!!extra.computer_mode && (
            <LabeledList.Item label="Направление компьютера">
              <Button
                fluid
                content={cardinalDirections[extra.computer_direction]}
                disabled={disabled}
                tooltip={controlReason}
                onClick={() => control('computer_direction')} />
            </LabeledList.Item>
          )}
          {!!extra.airlock_mode && (
            <>
              <LabeledList.Item className="Mecha__wideRow" label="Тип шлюза">
                <Box mb={1}>{extra.airlock_name}</Box>
                <Button
                  fluid
                  icon="door-open"
                  content="Выбрать тип"
                  disabled={disabled}
                tooltip={controlReason}
                  onClick={() => control('airlock_type')} />
              </LabeledList.Item>
              <LabeledList.Item className="Mecha__wideRow" label="Доступ к шлюзу">
                <Button.Checkbox
                  fluid
                  content="Достаточно одного доступа"
                  checked={extra.one_access}
                  disabled={disabled}
                tooltip={controlReason}
                  onClick={() => control('one_access')} />
                <Button
                  fluid
                  icon="unlock"
                  content="Сбросить ограничения"
                  disabled={disabled || !extra.selected_accesses.length}
                  tooltip={controlReason || (!extra.selected_accesses.length ? 'Ограничения доступа уже сняты.' : undefined)}
                  onClick={() => control('clear_access')} />
                {!extra.selected_accesses.length && <Box color="label" my={1}>Общий доступ</Box>}
                {extra.access_regions.map(region => (
                  <Collapsible key={region.name} title={region.name}>
                    {region.accesses.map(access => (
                      <Button.Checkbox
                        key={access.id}
                        fluid
                        content={access.name}
                        checked={extra.selected_accesses.includes(access.id)}
                        disabled={disabled}
                tooltip={controlReason}
                        onClick={() => control('access', { access: String(access.id) })} />
                    ))}
                  </Collapsible>
                ))}
              </LabeledList.Item>
            </>
          )}
        </>
      );
    case 'mode':
      return (
        <>
          <LabeledList.Item className="Mecha__wideRow" label="Режим">
            {extra.modes.map((name, index) => (
              <Button
                key={name}
                content={name}
                disabled={disabled}
                tooltip={controlReason}
                selected={extra.mode === index + extra.first_mode}
                onClick={() => control('mode', { mode: index + extra.first_mode })} />
            ))}
          </LabeledList.Item>
          {!!extra.target && <LabeledList.Item label="Цель">{extra.target}</LabeledList.Item>}
        </>
      );
    case 'extinguisher':
      return (
        <LabeledList.Item label="Пена">
          <ProgressBar value={extra.total_reagents ? extra.reagents / extra.total_reagents : 0}>
            {extra.reagents} / {extra.total_reagents}
          </ProgressBar>
        </LabeledList.Item>
      );
    case 'generator':
      return (
        <LabeledList.Item label="Топливо">
          <ProgressBar value={extra.fuel_amount / extra.max_fuel}>
            {extra.fuel_amount} см³
          </ProgressBar>
        </LabeledList.Item>
      );
    case 'ballistic':
      return (
        <>
          <LabeledList.Item label="Боеприпасы">
            <ProgressBar value={extra.max_ammo ? extra.total_ammo / extra.max_ammo : 0}>
              {extra.total_ammo} / {extra.max_ammo}
            </ProgressBar>
            <Button
                mt={1}
                icon="redo"
                content="Перезарядить"
                disabled={disabled || !!extra.rearm_reason}
                tooltip={controlReason || extra.rearm_reason}
              onClick={() => control('rearm')} />
          </LabeledList.Item>
          {!!extra.cache_max && (
            <LabeledList.Item label="Резерв">{extra.cache} / {extra.cache_max}</LabeledList.Item>
          )}
          {!!extra.punching && (
            <LabeledList.Item label="Режим удара">
              <Button
                selected={extra.harmful}
                content={extra.harmful ? 'Удар' : 'Поглаживание'}
                disabled={disabled}
                tooltip={controlReason}
                onClick={() => control('lethalPunch')} />
            </LabeledList.Item>
          )}
        </>
      );
    case 'sleeper':
      return (
        <>
          <LabeledList.Item label="Стазис">
            <Button
              icon="snowflake"
              selected={extra.stasis_enabled}
              content={extra.stasis_enabled ? 'Включён' : 'Выключен'}
              tooltip={controlReason || 'Приостанавливает биологические процессы и обмен лекарств, как стазис-стол. Требует питания.'}
              disabled={disabled}
              onClick={() => control('stasis')} />
          </LabeledList.Item>
          {!extra.patient ? <LabeledList.Item label="Пациент">Отсутствует</LabeledList.Item> : (
            <>
              <LabeledList.Item label="Поддержка">
                <Box color={extra.life_support_active ? 'good' : 'bad'}>
                  {extra.life_support_active ? 'Кислород и микроклимат в норме' : 'Нет питания'}
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Пациент">
                {extra.patient.patient_name}
                <Button icon="eject" ml={1} disabled={disabled}
                tooltip={controlReason || 'Извлечь пациента'} onClick={() => control('eject')} />
              </LabeledList.Item>
              <LabeledList.Item label="Здоровье">
                <ProgressBar
                  value={extra.patient.patient_health}
                  minValue={extra.patient.min_health}
                  maxValue={extra.patient.max_health}
                  ranges={{
                    good: [50, Infinity],
                    average: [0, 50],
                    bad: [-Infinity, 0],
                  }} />
              </LabeledList.Item>
              <LabeledList.Item label="Состояние">{extra.patient.patient_state}</LabeledList.Item>
              <LabeledList.Item label="Температура">{extra.patient.core_temp} °C</LabeledList.Item>
              {[
                { label: 'Травмы', value: extra.patient.brute_loss },
                { label: 'Ожоги', value: extra.patient.burn_loss },
                { label: 'Токсины', value: extra.patient.toxin_loss },
                { label: 'Гипоксия', value: extra.patient.oxygen_loss },
              ].map(damage => (
                <LabeledList.Item key={damage.label} label={damage.label}>
                  <ProgressBar
                    value={damage.value}
                    minValue={0}
                    maxValue={extra.patient!.max_health}
                    color="bad" />
                </LabeledList.Item>
              ))}
              <LabeledList.Item className="Mecha__wideRow" label="Встроенные препараты">
                {extra.chems.map(chem => (
                  <Button
                    key={chem.id}
                    fluid
                    content={`${chem.name} (10 ед.)`}
                    tooltip={controlReason || extra.injection_reason || (!chem.allowed ? 'Достигнут предел препарата в организме или состояние пациента не позволяет инъекцию.' : `Передозировка: ${chem.overdose_threshold ?? 'нет'}. Зависимость: ${chem.addiction_threshold ?? 'нет'}.`)}
                    disabled={disabled || !!extra.injection_reason || !chem.allowed}
                    onClick={() => control('inject_chem', { chem: chem.id })} />
                ))}
              </LabeledList.Item>
              <LabeledList.Item className="Mecha__wideRow">
                <Section title="Реагенты">
                  {extra.contained_reagents.length ? (
                    <Table>
                      {extra.contained_reagents.map(reagent => (
                        <Table.Row key={reagent.name}>
                          <Table.Cell>{reagent.name}</Table.Cell>
                          <Table.Cell collapsing textAlign="right" style={{ whiteSpace: 'nowrap' }}>{reagent.volume} ед.</Table.Cell>
                        </Table.Row>
                      ))}
                    </Table>
                  ) : <Box color="label">Отсутствуют</Box>}
                </Section>
              </LabeledList.Item>
              {extra.injectible_reagents.map(reagent => (
                <LabeledList.Item key={reagent.id} label={reagent.name}>
                  <Button
                    content={`Ввести (${reagent.volume} ед.)`}
                    disabled={disabled || !!extra.injection_reason || reagent.allowed === false}
                    tooltip={controlReason || extra.injection_reason || (reagent.allowed === false ? 'Достигнут предел препарата в организме или состояние пациента не позволяет инъекцию.' : undefined)}
                    onClick={() => control('inject_reagent', { reagent: reagent.id })} />
                </LabeledList.Item>
              ))}
            </>
          )}
        </>
      );
    case 'syringe':
      return (
        <>
          <LabeledList.Item label="Шприцы">{extra.syringe} / {extra.max_syringe}</LabeledList.Item>
          <LabeledList.Item label="Реагенты">
            <ProgressBar value={extra.total_reagents ? extra.reagents / extra.total_reagents : 0}>
              {extra.reagents} / {extra.total_reagents} ед.
            </ProgressBar>
          </LabeledList.Item>
          <LabeledList.Item className="Mecha__wideRow" label="Режим">
            <Button content={extra.mode} disabled={disabled}
                tooltip={controlReason} onClick={() => control('change_mode')} />
          </LabeledList.Item>
          <LabeledList.Item className="Mecha__wideRow" label="Синтез">
            <Button
              icon="power-off"
              selected={extra.synthesizing}
              disabled={disabled}
                tooltip={controlReason}
              content={extra.synthesizing ? 'Остановить' : 'Запустить'}
              onClick={() => control('synthesize')} />
            {extra.analyzed_reagents.map(reagent => (
              <Button.Checkbox
                key={reagent.id}
                fluid
                checked={reagent.enabled}
                content={reagent.name}
                disabled={disabled}
                tooltip={controlReason}
                onClick={() => control('toggle_reagent', { reagent: reagent.id })} />
            ))}
          </LabeledList.Item>
          {extra.contained_reagents.map(reagent => (
            <LabeledList.Item key={reagent.id} label={reagent.name}>
              {reagent.volume} ед.
              <Button
                icon="trash"
                ml={1}
                disabled={disabled}
                tooltip={controlReason}
                onClick={() => control('purge_reagent', { reagent: reagent.id })} />
            </LabeledList.Item>
          ))}
          <LabeledList.Item className="Mecha__wideRow">
            <Button.Confirm
              color="bad"
              content="Очистить резервуар"
              disabled={disabled}
                tooltip={controlReason}
              onClick={() => control('purge_all')} />
          </LabeledList.Item>
        </>
      );
    default:
      return null;
  }
};

const CargoPane = () => {
  const { act, data } = useBackend<MainData>();
  return (
    <Section fill scrollable title={data.cargo ? `Груз ${data.cargo.cargo_list.length}/${data.cargo.capacity}` : 'Груз'}>
      {!data.cargo ? <NoticeBox>У этого меха нет грузового отсека.</NoticeBox> : (
        <Table>
          {data.cargo.cargo_list.map(item => (
            <Table.Row key={item.ref}>
              <Table.Cell>{item.name}</Table.Cell>
              <Table.Cell collapsing>{item.amount}</Table.Cell>
              <Table.Cell collapsing>
                <Button
                  icon="eject"
                  tooltip={!data.can_equipment ? 'С этого места нельзя управлять грузовым отсеком.' : 'Выгрузить'}
                  disabled={!data.can_equipment}
                  onClick={() => act('drop_from_cargo', { cargo_item: item.ref })} />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

const SettingsPane = () => {
  const { act, data } = useBackend<MainData>();
  const radio = data.radio_data;
  const settingsReason = !data.can_settings ? 'С этого места нельзя управлять настройками меха.' : null;
  const sounds = {
    sadtrombone: 'Грустный тромбон', bikehorn: 'Клаксон', airhorn2: 'Горн',
    carhorn: 'Автомобиль', party_horn: 'Дудка', reee: 'Крик', weeoo1: 'Сирена',
    hiss1: 'Шипение', armbomb: 'Граната', saberon: 'Энергомеч',
    airlock_alien_prying: 'Взлом шлюза', lightningbolt: 'Молния', explosionfar: 'Взрыв',
  };
  return (
    <Section fill scrollable title="Настройки">
      <LabeledList>
        <LabeledList.Item label="Панель загрузки ID">
          <Button
            icon={data.id_upload ? 'lock-open' : 'lock'}
            selected={data.id_upload}
            content={data.id_upload ? 'Разблокирована' : 'Заблокирована'}
            disabled={!data.can_settings}
            tooltip={settingsReason}
            onClick={() => act('toggle_id_upload')} />
        </LabeledList.Item>
        <LabeledList.Item label="Доступы">
          {data.accesses.join(', ') || 'Не требуются'}
        </LabeledList.Item>
        {!!radio && (
          <LabeledList.Item label="Радио">
            <Button
              selected={radio.microphone}
              icon={radio.microphone ? 'microphone' : 'microphone-slash'}
              tooltip={settingsReason || 'Микрофон'}
              disabled={!data.can_settings}
              onClick={() => act('toggle_microphone')} />
            <Button
              selected={radio.speaker}
              icon={radio.speaker ? 'volume-up' : 'volume-mute'}
              tooltip={settingsReason || 'Динамик'}
              disabled={!data.can_settings}
              onClick={() => act('toggle_speaker')} />
            {settingsReason ? (
              <Tooltip content={settingsReason}>
                <Box inline color="label">{(radio.frequency / 10).toFixed(1)}</Box>
              </Tooltip>
            ) : <NumberInput
              width="90px"
              value={radio.frequency / 10}
              minValue={radio.minFrequency / 10}
              maxValue={radio.maxFrequency / 10}
              step={0.2}
              format={value => value.toFixed(1)}
              onChange={(event, value) => act('set_frequency', { new_frequency: value * 10 })} />}
          </LabeledList.Item>
        )}
        {!!data.has_tank && (
          <>
            <LabeledList.Item label="Баллон">{data.tank_pressure} кПа, {data.tank_temp} °C</LabeledList.Item>
            <LabeledList.Item label="Газовый порт">
              <Button
                icon="plug"
                selected={data.port_connected}
                content={data.port_connected ? 'Отключить' : 'Подключить'}
                disabled={!data.can_settings || (!data.port_connected && !data.has_port)}
                tooltip={settingsReason || (!data.port_connected && !data.has_port ? 'Под мехом нет газового порта.' : undefined)}
                onClick={() => act('toggle_port_connection')} />
            </LabeledList.Item>
          </>
        )}
      </LabeledList>
      {!!data.ui_honked && (
        <Section title="Звуки H.O.N.K.">
          {Object.entries(sounds).map(([sound, label]) => (
            <Button
              key={sound}
              content={label}
              disabled={!data.can_settings}
              tooltip={settingsReason}
              onClick={() => act('play_sound', { sound })} />
          ))}
        </Section>
      )}
    </Section>
  );
};
