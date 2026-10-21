import { useState } from 'react';

import { useBackend } from '../../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
  Table,
  Tabs,
} from '../../components';
import type { MainData, MechModule } from './data';
import { useHonk } from './honk';

export const ModulesPane = () => {
  const { act, data } = useBackend<MainData>();
  const [tab, setTab] = useState(0);
  const [selected, setSelected] = useState<string | null>(null);
  const honk = useHonk(data.ui_honked ? 0.4 : 0);
  const module = data.modules.find(item => item.ref === selected) || data.modules[0];
  return (
    <Stack vertical fill>
      <Stack.Item>
        <Tabs>
          <Tabs.Tab icon="table" selected={tab === 0} onClick={() => setTab(0)}>
            {honk('Модули')}
          </Tabs.Tab>
          {!!data.cargo && (
            <Tabs.Tab icon="box" selected={tab === 1} onClick={() => setTab(1)}>
              {honk('Груз')}
            </Tabs.Tab>
          )}
          <Tabs.Tab icon="cog" selected={tab === 2} onClick={() => setTab(2)}>
            {honk('Настройки')}
          </Tabs.Tab>
        </Tabs>
      </Stack.Item>
      <Stack.Item grow>
        {tab === 0 && (
          <Stack fill>
            <Stack.Item width="225px" shrink={0}>
              <Section fill scrollable title={`${honk('Модули')} ${data.modules.length}/${data.max_equip}`}>
                {data.modules.map(item => (
                  <Button
                    key={item.ref}
                    fluid
                    selected={module?.ref === item.ref}
                    tooltip={item.name}
                    onClick={() => setSelected(item.ref)}>
                    <Stack align="center">
                      <Stack.Item>
                        <img
                          src={`data:image/png;base64,${item.image}`}
                          width={32}
                          height={32}
                          style={{ imageRendering: 'pixelated', verticalAlign: 'middle' }} />
                      </Stack.Item>
                      <Stack.Item grow style={{ overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {item.name}
                        <Box fontSize="11px" color="label">
                          {item.selected_left ? 'ЛКМ ' : ''}
                          {item.selected_right ? 'ПКМ ' : ''}
                          {item.active ? 'Вкл' : ''}
                        </Box>
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
        <Section title="Управление" maxHeight="130px" scrollable>
          {data.actions.map(action => (
            <Button
              key={action.ref}
              maxWidth="220px"
              ellipsis
              tooltip={action.name}
              content={action.name}
              onClick={() => act('trigger_action', { ref: action.ref })} />
          ))}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

const ModuleDetails = ({ module }: { module: MechModule }) => {
  const { act, data } = useBackend<MainData>();
  const honk = useHonk(data.ui_honked ? 0.4 : 0);
  return (
    <>
      <Section
        className="Mecha__moduleHeader"
        title={module.name}
        buttons={module.detachable && (
          <Button.Confirm
            icon="eject"
            tooltip="Отсоединить модуль"
            disabled={!data.can_equipment}
            onClick={() => act('equip_act', { ref: module.ref, gear_action: 'detach' })} />
        )}>
        {module.desc}
      </Section>
      <Section className="Mecha__moduleDetails">
        <LabeledList>
          {module.integrity < 1 && (
            <LabeledList.Item label="Состояние">
              <ProgressBar value={module.integrity} />
            </LabeledList.Item>
          )}
          {!!module.energy_per_use && (
            <LabeledList.Item label="Затраты энергии">
              {module.energy_per_use} за использование
            </LabeledList.Item>
          )}
          {!!module.equip_cooldown && (
            <LabeledList.Item label={honk('Перезарядка')}>
              {module.equip_cooldown}
            </LabeledList.Item>
          )}
          {!!module.can_be_triggered && (
            <LabeledList.Item label="Использование">
              <Button
                selected={module.selected_left}
                disabled={!data.can_equipment}
                content="ЛКМ"
                tooltip="Назначить на левую кнопку мыши. Повторное нажатие снимает назначение."
                onClick={() => act('select_module', { ref: module.ref, button: 'left' })} />
              <Button
                selected={module.selected_right}
                disabled={!data.can_equipment}
                content="ПКМ"
                tooltip="Назначить на правую кнопку мыши. Повторное нажатие снимает назначение."
                onClick={() => act('select_module', { ref: module.ref, button: 'right' })} />
            </LabeledList.Item>
          )}
          {!!module.can_be_toggled && (
            <LabeledList.Item label="Работа модуля">
              <Button
                icon="power-off"
                selected={module.active}
                disabled={!data.can_equipment}
                content={honk(module.active ? 'Включен' : 'Выключен')}
                onClick={() => act('equip_act', { ref: module.ref, gear_action: module.toggle_action })} />
            </LabeledList.Item>
          )}
          {module.snowflake && <ModuleDetailsExtra module={module} />}
        </LabeledList>
      </Section>
    </>
  );
};

const ModuleDetailsExtra = ({ module }: { module: MechModule }) => {
  const { act, data } = useBackend<MainData>();
  const extra = module.snowflake;
  const control = (gear_action: string, params = {}) => act('equip_act', { ref: module.ref, gear_action, ...params });
  const disabled = !data.can_equipment;
  switch (extra.kind) {
    case 'mode':
      return (
        <>
          <LabeledList.Item label="Режим">
            {extra.modes.map((name, index) => (
              <Button
                key={name}
                content={name}
                disabled={disabled}
                selected={extra.mode === index + extra.first_mode}
                onClick={() => control('mode', { mode: index + extra.first_mode })} />
            ))}
          </LabeledList.Item>
          {!!extra.target && <LabeledList.Item label="Цель">{extra.target}</LabeledList.Item>}
        </>
      );
    case 'extinguisher':
      return (
        <LabeledList.Item label="Вода">
          <ProgressBar value={extra.reagents / extra.total_reagents}>
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
            {!!extra.can_rearm && (
              <Button
                mt={1}
                icon="redo"
                content="Перезарядить"
                disabled={disabled || extra.total_ammo >= extra.max_ammo}
                onClick={() => control('rearm')} />
            )}
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
                onClick={() => control('lethalPunch')} />
            </LabeledList.Item>
          )}
        </>
      );
    case 'sleeper':
      return !extra.patient ? <LabeledList.Item label="Пациент">Отсутствует</LabeledList.Item> : (
        <>
          <LabeledList.Item label="Пациент">
            {extra.patient.patient_name}
            <Button icon="eject" ml={1} disabled={disabled} onClick={() => control('eject')} />
          </LabeledList.Item>
          <LabeledList.Item label="Здоровье">
            <ProgressBar value={extra.patient.patient_health} />
          </LabeledList.Item>
          <LabeledList.Item label="Состояние">{extra.patient.patient_state}</LabeledList.Item>
          <LabeledList.Item label="Температура">{extra.patient.core_temp} °C</LabeledList.Item>
          <LabeledList.Item label="Травмы / ожоги">{extra.patient.brute_loss} / {extra.patient.burn_loss}</LabeledList.Item>
          <LabeledList.Item label="Токсины / кислород">{extra.patient.toxin_loss} / {extra.patient.oxygen_loss}</LabeledList.Item>
          {extra.contained_reagents.map(reagent => (
            <LabeledList.Item key={reagent.name} label={reagent.name}>{reagent.volume} ед.</LabeledList.Item>
          ))}
          {extra.injectible_reagents.map(reagent => (
            <LabeledList.Item key={reagent.id} label={reagent.name}>
              <Button
                content={`Ввести (${reagent.volume} ед.)`}
                disabled={disabled}
                onClick={() => control('inject_reagent', { reagent: reagent.id })} />
            </LabeledList.Item>
          ))}
        </>
      );
    case 'syringe':
      return (
        <>
          <LabeledList.Item label="Шприцы">{extra.syringe} / {extra.max_syringe}</LabeledList.Item>
          <LabeledList.Item label="Реагенты">
            <ProgressBar value={extra.reagents / extra.total_reagents}>
              {extra.reagents} / {extra.total_reagents} ед.
            </ProgressBar>
          </LabeledList.Item>
          <LabeledList.Item label="Режим">
            <Button content={extra.mode} disabled={disabled} onClick={() => control('change_mode')} />
          </LabeledList.Item>
          <LabeledList.Item label="Синтез">
            <Button
              icon="power-off"
              selected={extra.synthesizing}
              disabled={disabled}
              content={extra.synthesizing ? 'Остановить' : 'Запустить'}
              onClick={() => control('synthesize')} />
            {extra.analyzed_reagents.map(reagent => (
              <Button.Checkbox
                key={reagent.id}
                fluid
                checked={reagent.enabled}
                content={reagent.name}
                disabled={disabled}
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
                onClick={() => control('purge_reagent', { reagent: reagent.id })} />
            </LabeledList.Item>
          ))}
          <LabeledList.Item>
            <Button.Confirm
              color="bad"
              content="Очистить резервуар"
              disabled={disabled}
              onClick={() => control('purge_all')} />
          </LabeledList.Item>
        </>
      );
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
                  tooltip="Выгрузить"
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
              tooltip="Микрофон"
              disabled={!data.can_settings}
              onClick={() => act('toggle_microphone')} />
            <Button
              selected={radio.speaker}
              icon={radio.speaker ? 'volume-up' : 'volume-mute'}
              tooltip="Динамик"
              disabled={!data.can_settings}
              onClick={() => act('toggle_speaker')} />
            <NumberInput
              width="90px"
              value={radio.frequency / 10}
              minValue={radio.minFrequency / 10}
              maxValue={radio.maxFrequency / 10}
              step={0.2}
              disabled={!data.can_settings}
              format={value => value.toFixed(1)}
              onChange={(event, value) => act('set_frequency', { new_frequency: value * 10 })} />
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
                disabled={!data.can_settings}
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
              onClick={() => act('play_sound', { sound })} />
          ))}
        </Section>
      )}
    </Section>
  );
};
