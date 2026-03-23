import { createSearch } from 'common/string';
import { Fragment } from 'inferno';

import { useBackend, useLocalState } from "../backend";
import { Box, Button, Collapsible, Flex, Icon, Input, LabeledList, Section, Table, Tabs } from "../components";
import { ComplexModal, modalOpen, modalRegisterBodyOverride } from "../interfaces/common/ComplexModal";
import { Window } from "../layouts";
import { LoginInfo } from './common/LoginInfo';
import { LoginScreen } from './common/LoginScreen';
import { TemporaryNotice } from './common/TemporaryNotice';

const severities = {
  "Minor": "good",
  "Medium": "average",
  "Dangerous!": "bad",
  "Harmful": "bad",
  "BIOHAZARD THREAT!": "bad",
};

const doEdit = (context, field) => {
  modalOpen(context, 'edit', {
    field: field.edit,
    value: field.value,
  });
};

const virusModalBodyOverride = (modal, context) => {
  const virus = modal.args;
  return (
    <Section
      level={2}
      m="-1rem"
      pb="1rem"
      title={virus.name || "Вирус"}>
      <Box mx="0.5rem">
        <LabeledList>
          <LabeledList.Item label="Кол-во стадий">
            {virus.max_stages}
          </LabeledList.Item>
          <LabeledList.Item label="Распространение">
            {virus.spread_text}
          </LabeledList.Item>
          <LabeledList.Item label="Возможное лечение">
            {virus.cure}
          </LabeledList.Item>
          <LabeledList.Item label="Описание">
            {virus.desc}
          </LabeledList.Item>
          <LabeledList.Item label="Опасность"
            color={severities[virus.severity]}>
            {virus.severity}
          </LabeledList.Item>
        </LabeledList>
      </Box>
    </Section>
  );
};

export const MedicalRecords = (_properties, context) => {
  const { data } = useBackend(context);
  const {
    loginState,
    screen,
  } = data;
  if (!loginState.logged_in) {
    return (
      <Window
        title="Медицинские записи"
        theme="ntos"
        width={800}
        height={600}
        resizable>
        <Window.Content>
          <LoginScreen />
        </Window.Content>
      </Window>
    );
  }

  let body;
  if (screen === 2) {
    body = <MedicalRecordsList />;
  } else if (screen === 3) {
    body = <MedicalRecordsMaintenance />;
  } else if (screen === 4) {
    body = <MedicalRecordsView />;
  } else if (screen === 5) {
    body = <MedicalRecordsViruses />;
  } else if (screen === 6) {
    body = <MedicalRecordsMedbots />;
  }

  return (
    <Window
      title="Медицинские записи"
      theme="ntos"
      width={800}
      height={600}
      resizable>
      <ComplexModal />
      <Window.Content scrollable className="Layout__content--flexColumn">
        <LoginInfo />
        <TemporaryNotice />
        <MedicalRecordsNavigation />
        <Section flexGrow="1">
          {body}
        </Section>
      </Window.Content>
    </Window>
  );
};

const MedicalRecordsList = (_properties, context) => {
  const { act, data } = useBackend(context);
  const {
    records,
  } = data;
  const [searchText, setSearchText] = useLocalState(context, 'medSearchText', '');

  const filteredRecords = (records || [])
    .filter(
      createSearch(searchText, (record) => {
        return record.name + '|' + record.id;
      })
    );

  return (
    <Fragment>
      <Flex mb="0.5rem">
        <Flex.Item grow="1">
          <Input
            fluid
            placeholder="Поиск по имени или ID..."
            onInput={(_event, value) => setSearchText(value)}
          />
        </Flex.Item>
      </Flex>
      <Table>
        <Table.Row bold header>
          <Table.Cell>ID</Table.Cell>
          <Table.Cell>Имя</Table.Cell>
        </Table.Row>
        {filteredRecords.map((record, i) => (
          <Table.Row
            key={i}
            style={{ cursor: 'pointer' }}
            onClick={() => act('d_rec', { d_rec: record.ref })}>
            <Table.Cell collapsing color="label">
              {record.id}
            </Table.Cell>
            <Table.Cell>
              <Icon name="user" mr="0.5rem" />
              {record.name}
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Fragment>
  );
};

const MedicalRecordsMaintenance = (_properties, context) => {
  const { act } = useBackend(context);
  return (
    <Box>
      <Button
        icon="download"
        content="Резервное копирование"
        disabled
        mb="0.5rem"
      />
      <br />
      <Button
        icon="upload"
        content="Загрузка с диска"
        disabled
        mb="0.5rem"
      />
      <br />
      <Button.Confirm
        icon="trash"
        color="bad"
        content="Удалить все медицинские записи"
        onClick={() => act('del_all')}
      />
    </Box>
  );
};

const MedicalRecordsView = (_properties, context) => {
  const { act, data } = useBackend(context);
  const {
    medical,
    printing,
  } = data;
  return (
    <Fragment>
      <Flex mb="0.5rem">
        <Flex.Item>
          <Button
            icon="arrow-left"
            content="Назад"
            onClick={() => act('screen', { screen: 2 })}
          />
        </Flex.Item>
        <Flex.Item grow="1" />
        <Flex.Item>
          <Button
            icon={printing ? 'spinner' : 'print'}
            disabled={printing}
            iconSpin={!!printing}
            content="Печать"
            onClick={() => act('print_p')}
          />
        </Flex.Item>
        <Flex.Item ml="0.5rem">
          <Button.Confirm
            icon="trash"
            disabled={!!medical.empty}
            content="Удалить запись"
            color="bad"
            onClick={() => act('del_r')}
          />
        </Flex.Item>
      </Flex>
      <Section title="Общие данные" level={2}>
        <MedicalRecordsViewGeneral />
      </Section>
      <Section title="Медицинские данные" level={2}>
        <MedicalRecordsViewMedical />
      </Section>
    </Fragment>
  );
};

const MedicalRecordsViewGeneral = (_properties, context) => {
  const { data } = useBackend(context);
  const {
    general,
  } = data;
  if (!general || !general.fields) {
    return (
      <Box color="bad">
        Общие записи утеряны!
      </Box>
    );
  }
  return (
    <Fragment>
      <Box width="50%" float="left">
        <LabeledList>
          {general.fields.map((field, i) => (
            <LabeledList.Item key={i} label={field.field}>
              <Box display="inline-block" verticalAlign="middle">
                {field.value}
              </Box>
              {!!field.edit && (
                <Button
                  icon="pen"
                  ml="0.5rem"
                  onClick={() => doEdit(context, field)}
                />
              )}
            </LabeledList.Item>
          ))}
        </LabeledList>
      </Box>
      <Box width="50%" float="right" textAlign="right">
        {!!general.has_photos && (
          general.photos.map((p, i) => (
            <Box
              key={i}
              display="inline-block"
              textAlign="center"
              color="label">
              <img
                src={'data:image/png;base64,' + p}
                className="SecurityRecords__photo"
                style={{
                  width: '96px',
                  marginBottom: '0.5rem',
                }}
              /><br />
              Фото #{i + 1}
            </Box>
          ))
        )}
      </Box>
    </Fragment>
  );
};

const MedicalRecordsViewMedical = (_properties, context) => {
  const { act, data } = useBackend(context);
  const {
    medical,
  } = data;
  if (!medical || !medical.fields) {
    return (
      <Box color="bad">
        Медицинские записи утеряны!
        <Button
          icon="pen"
          content="Новая запись"
          ml="0.5rem"
          onClick={() => act('new')}
        />
      </Box>
    );
  }
  return (
    <Fragment>
      <LabeledList>
        {medical.fields.map((field, i) => (
          <LabeledList.Item
            key={i}
            label={field.field}>
            <Box display="inline" verticalAlign="middle">
              {field.value}
            </Box>
            <Button
              icon="pen"
              ml="0.5rem"
              onClick={() => doEdit(context, field)}
            />
            {!!field.line_break && <Box mb="0.5rem" />}
          </LabeledList.Item>
        ))}
      </LabeledList>
      <Section title="Комментарии" level={2}>
        {medical.comments.length === 0 ? (
          <Box color="label">
            Нет комментариев.
          </Box>
        )
          : medical.comments.map((comment, i) => (
            <Box key={i} prewrap>
              <Box color="label" display="inline">
                {comment.header}
              </Box><br />
              {comment.text}
              <Button
                icon="comment-slash"
                color="bad"
                ml="0.5rem"
                onClick={() => act('del_c', { del_c: i + 1 })}
              />
            </Box>
          ))}

        <Button
          icon="comment-medical"
          content="Добавить"
          color="good"
          mt="0.5rem"
          mb="0"
          onClick={() => modalOpen(context, 'add_c')}
        />
      </Section>
    </Fragment>
  );
};

const MedicalRecordsViruses = (_properties, context) => {
  const { act, data } = useBackend(context);
  const {
    virus,
  } = data;
  const sorted = [...(virus || [])].sort(
    (a, b) => (a.name || '').localeCompare(b.name || '')
  );
  return (
    <Table>
      <Table.Row bold header>
        <Table.Cell>Вирус</Table.Cell>
      </Table.Row>
      {sorted.map((vir, i) => (
        <Table.Row
          key={i}
          style={{ cursor: 'pointer' }}
          onClick={() => act('vir', { vir: vir.D })}>
          <Table.Cell>
            <Icon name="flask" mr="0.5rem" />
            {vir.name}
          </Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};

const MedicalRecordsMedbots = (_properties, context) => {
  const { data } = useBackend(context);
  const {
    medbots,
  } = data;
  if (medbots.length === 0) {
    return (
      <Box color="label">
        Медботы не обнаружены.
      </Box>
    );
  }
  return medbots.map((medbot, i) => (
    <Collapsible
      key={i}
      open
      title={medbot.name}>
      <Box px="0.5rem">
        <LabeledList>
          <LabeledList.Item label="Местоположение">
            {medbot.area || 'Неизвестно'} ({medbot.x}, {medbot.y})
          </LabeledList.Item>
          <LabeledList.Item label="Статус">
            {medbot.on ? (
              <Fragment>
                <Box color="good">
                  Онлайн
                </Box>
                <Box mt="0.5rem">
                  {medbot.use_beaker
                    ? ("Резервуар: "
                    + medbot.total_volume + "/" + medbot.maximum_volume)
                    : "Использует внутренний синтезатор."}
                </Box>
              </Fragment>
            ) : (
              <Box color="average">
                Оффлайн
              </Box>
            )}
          </LabeledList.Item>
        </LabeledList>
      </Box>
    </Collapsible>
  ));
};

const MedicalRecordsNavigation = (_properties, context) => {
  const { act, data } = useBackend(context);
  const {
    screen,
    general,
  } = data;
  return (
    <Tabs>
      <Tabs.Tab
        selected={screen === 2}
        onClick={() => act('screen', { screen: 2 })}>
        <Icon name="list" /> Список записей
      </Tabs.Tab>
      <Tabs.Tab
        selected={screen === 5}
        onClick={() => act('screen', { screen: 5 })}>
        <Icon name="virus" /> База вирусов
      </Tabs.Tab>
      <Tabs.Tab
        selected={screen === 6}
        onClick={() => act('screen', { screen: 6 })}>
        <Icon name="robot" /> Медботы
      </Tabs.Tab>
      <Tabs.Tab
        selected={screen === 3}
        onClick={() => act('screen', { screen: 3 })}>
        <Icon name="wrench" /> Обслуживание
      </Tabs.Tab>
      {screen === 4 && general && general.fields && (
        <Tabs.Tab selected>
          <Icon name="file-medical" />{' '}
          {general.fields.find(f => f.field === 'Имя')?.value || 'Запись'}
        </Tabs.Tab>
      )}
    </Tabs>
  );
};

modalRegisterBodyOverride('virus', virusModalBodyOverride);
