import { Fragment } from 'react';

import { useBackend } from '../backend';
import { Button, Input, LabeledList, NoticeBox, NumberInput, Section, Table } from '../components';
import { Window } from '../layouts';

export const NaniteRemote = (props) => {
  return (
    <Window
      width={420}
      height={500}
      resizable>
      <Window.Content overflow="auto">
        <NaniteRemoteContent />
      </Window.Content>
    </Window>
  );
};

export const NaniteRemoteContent = (props) => {
  const { act, data } = useBackend();
  const {
    code,
    locked,
    mode,
    program_name,
    relay_code,
    comms,
    message,
    saved_settings = [],
  } = data;

  const modes = [
    "Off",
    "Local",
    "Targeted",
    "Area",
    "Relay",
  ];

  // Ключи режимов приходят с бэкенда и используются в логике, поэтому
  // переводится только отображаемая подпись.
  const modeLabels = {
    Off: 'Выкл.',
    Local: 'Локальный',
    Targeted: 'На цель',
    Area: 'По области',
    Relay: 'Ретрансляция',
  };

  if (locked) {
    return (
      <NoticeBox>
        Этот интерфейс заблокирован.
      </NoticeBox>
    );
  }

  return (
    <>
      <Section
        title="Управление нанитами"
        buttons={(
          <Button
            icon="lock"
            content="Заблокировать интерфейс"
            onClick={() => act('lock')} />
        )}>
        <LabeledList>
          <LabeledList.Item label="Название">
            <Input
              value={program_name}
              maxLength={14}
              width="130px"
              onChange={(e, value) => act('update_name', {
                name: value,
              })} />
            <Button
              icon="save"
              content="Сохранить"
              onClick={() => act('save')} />
          </LabeledList.Item>
          <LabeledList.Item label={comms ? "Код связи" : "Код сигнала"}>
            <NumberInput
              value={code}
              minValue={0}
              maxValue={9999}
              width="47px"
              step={1}
              stepPixelSize={2}
              onChange={(e, value) => act('set_code', {
                code: value,
              })} />
          </LabeledList.Item>
          {!!comms && (
            <LabeledList.Item label="Сообщение">
              <Input
                value={message}
                width="270px"
                onChange={(e, value) => act('set_message', {
                  value: value,
                })} />
            </LabeledList.Item>
          )}
          {mode === "Relay" && (
            <LabeledList.Item label="Код ретрансляции">
              <NumberInput
                value={relay_code}
                minValue={0}
                maxValue={9999}
                width="47px"
                step={1}
                stepPixelSize={2}
                onChange={(e, value) => act('set_relay_code', {
                  code: value,
                })} />
            </LabeledList.Item>
          )}
          <LabeledList.Item label="Режим сигнала">
            {modes.map(key => (
              <Button
                key={key}
                content={modeLabels[key]}
                selected={mode === key}
                onClick={() => act('select_mode', {
                  mode: key,
                })} />
            ))}
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <Section title="Сохранённые настройки">
        {saved_settings.length > 0 ? (
          <Table>
            <Table.Row header>
              <Table.Cell width="35%">
                Название
              </Table.Cell>
              <Table.Cell width="20%">
                Режим
              </Table.Cell>
              <Table.Cell collapsing>
                Код
              </Table.Cell>
              <Table.Cell collapsing>
                Ретрансляция
              </Table.Cell>
            </Table.Row>
            {saved_settings.map(setting => (
              <Table.Row
                key={setting.id}
                className="candystripe">
                <Table.Cell bold color="label">
                  {setting.name}:
                </Table.Cell>
                <Table.Cell>
                  {modeLabels[setting.mode] || setting.mode}
                </Table.Cell>
                <Table.Cell>
                  {setting.code}
                </Table.Cell>
                <Table.Cell>
                  {setting.mode === "Relay" && setting.relay_code}
                </Table.Cell>
                <Table.Cell textAlign="right">
                  <Button
                    icon="upload"
                    color="good"
                    onClick={() => act('load', {
                      save_id: setting.id,
                    })} />
                  <Button
                    icon="minus"
                    color="bad"
                    onClick={() => act('remove_save', {
                      save_id: setting.id,
                    })} />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        ) : (
          <NoticeBox>
            Нет сохранённых настроек
          </NoticeBox>
        )}
      </Section>
    </>
  );
};
