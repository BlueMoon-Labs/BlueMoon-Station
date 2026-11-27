import { useBackend } from '../backend';
import { Button, Dropdown, Flex, Input, LabeledList, ProgressBar, Section } from '../components';
import { Window } from '../layouts';
import { InterfaceLockNoticeBox } from './common/InterfaceLockNoticeBox';

export const Mule = (props) => {
  const { act, data } = useBackend();
  const {
    on,
    cell,
    cellPercent,
    load,
    mode,
    modeStatus,
    haspai,
    autoReturn,
    autoPickup,
    reportDelivery,
    destination,
    home,
    id,
    destinations = [],
  } = data;
  const locked = data.locked && !data.siliconUser;
  return (
    <Window
      width={420}
      height={425}>
      <Window.Content>
        <InterfaceLockNoticeBox
          lockLabel="Блокировка панели:"
          lockedText="Заблокирована"
          unlockedText="Разблокирована"
          swipeText={locked
            ? 'Проведите ID-картой, чтобы разблокировать панель.'
            : 'Проведите ID-картой, чтобы заблокировать панель.'} />
        <Section
          title="Состояние"
          minHeight="110px"
          buttons={!locked && (
            <Button
              icon={on ? 'power-off' : 'times'}
              content={on ? 'Вкл.' : 'Выкл.'}
              selected={on}
              onClick={() => act('power')} />
          )}>
          <ProgressBar
            value={cell ? (cellPercent / 100) : 0}
            color={cell ? 'good' : 'bad'} />
          <Flex mt={1}>
            <Flex.Item grow={1} basis={0}>
              <LabeledList>
                <LabeledList.Item label="Режим" color={modeStatus}>
                  {mode}
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
            <Flex.Item grow={1} basis={0}>
              <LabeledList>
                <LabeledList.Item
                  label="Груз"
                  color={load ? 'good' : 'average'}>
                  {load || 'Нет'}
                </LabeledList.Item>
              </LabeledList>
            </Flex.Item>
          </Flex>
        </Section>
        {!locked && (
          <Section
            title="Управление"
            buttons={(
              <>
                {!!load && (
                  <Button
                    icon="eject"
                    content="Выгрузить"
                    onClick={() => act('unload')} />
                )}
                {!!haspai && (
                  <Button
                    icon="eject"
                    content="Извлечь ПИИ"
                    onClick={() => act('ejectpai')} />
                )}
              </>
            )}>
            <LabeledList>
              <LabeledList.Item label="ID">
                <Input
                  value={id}
                  onChange={(e, value) => act('setid', { value })} />
              </LabeledList.Item>
              <LabeledList.Item label="Назначение">
                <Dropdown
                  over
                  selected={destination || 'Не задано'}
                  options={destinations}
                  width="150px"
                  onSelected={value => act('destination', { value })} />
                <Button
                  icon="stop"
                  content="Стоп"
                  onClick={() => act('stop')} />
                <Button
                  icon="play"
                  content="Старт"
                  onClick={() => act('go')} />
              </LabeledList.Item>
              <LabeledList.Item label="База">
                <Dropdown
                  over
                  selected={home}
                  options={destinations}
                  width="150px"
                  onSelected={value => act('destination', { value })} />
                <Button
                  icon="home"
                  content="На базу"
                  onClick={() => act('home')} />
              </LabeledList.Item>
              <LabeledList.Item label="Настройки">
                <Button.Checkbox
                  checked={autoReturn}
                  content="Автовозврат"
                  onClick={() => act('autored')} />
                <br />
                <Button.Checkbox
                  checked={autoPickup}
                  content="Автоподбор груза"
                  onClick={() => act('autopick')} />
                <br />
                <Button.Checkbox
                  checked={reportDelivery}
                  content="Сообщать о доставке"
                  onClick={() => act('report')} />
              </LabeledList.Item>
            </LabeledList>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
