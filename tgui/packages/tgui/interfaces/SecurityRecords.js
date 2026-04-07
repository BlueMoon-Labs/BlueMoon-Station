import { createSearch } from 'common/string';
import { Fragment } from 'inferno';

import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Flex,
  Icon,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';
import { LoginInfo } from './common/LoginInfo';
import { LoginScreen } from './common/LoginScreen';

const CRIMINAL_STATUSES = [
  { value: 'Ничего', label: 'Ничего', icon: 'file', color: 'label' },
  { value: '*Арестовать*', label: 'Арестовать', icon: 'handcuffs', color: 'red' },
  { value: '*Уничтожить*', label: 'Уничтожить', icon: 'skull', color: 'purple' },
  { value: 'Отбывает Срок', label: 'Отбывает Срок', icon: 'lock', color: 'orange' },
  { value: 'Выпустили', label: 'Выпустили', icon: 'door-open', color: 'blue' },
  { value: 'УДО', label: 'УДО', icon: 'user-check', color: 'teal' },
  { value: 'Уволить', label: 'Уволить', icon: 'user-minus', color: 'green' },
  { value: 'Искать', label: 'Искать', icon: 'magnifying-glass', color: 'yellow' },
  { value: 'Наблюдать', label: 'Наблюдать', icon: 'eye', color: 'blue' },
  { value: 'Сняты Обвинения', label: 'Сняты Обвинения', icon: 'check', color: 'green' },
];

const statusStyles = {
  '*Арестовать*': 'arrest',
  '*Уничтожить*': 'execute',
  'Отбывает Срок': 'incarcerated',
  'УДО': 'parolled',
  'Выпустили': 'released',
  'Уволить': 'demote',
  'Искать': 'search',
  'Наблюдать': 'monitor',
  'Сняты Обвинения': 'discharged',
};

export const SecurityRecords = (properties, context) => {
  const { data } = useBackend(context);
  const { loginState, currentPage } = data;

  if (!loginState.logged_in) {
    return (
      <Window
        title="Записи безопасности"
        theme="security"
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
  if (currentPage === 1) {
    body = <PageRecordList />;
  } else if (currentPage === 2) {
    body = <PageMaintenance />;
  } else if (currentPage === 3) {
    body = <PageRecordView />;
  } else if (currentPage === 4) {
    body = <PageAllLogs />;
  }

  return (
    <Window
      title="Записи безопасности"
      theme="security"
      width={800}
      height={600}
      resizable>
      <Window.Content scrollable className="Layout__content--flexColumn">
        <LoginInfo />
        <TempNotice />
        <NavigationTabs />
        <Section flexGrow="1">
          {body}
        </Section>
      </Window.Content>
    </Window>
  );
};

const TempNotice = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { temp } = data;
  if (!temp) {
    return null;
  }
  const colorMap = {
    danger: 'bad',
    success: 'good',
    info: 'info',
  };
  return (
    <NoticeBox
      mb="0.5rem"
      color={colorMap[temp.style] || 'info'}
      onDismiss={() => act('cleartemp')}>
      {temp.text}
    </NoticeBox>
  );
};

const NavigationTabs = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { currentPage, general } = data;
  return (
    <Tabs>
      <Tabs.Tab
        selected={currentPage === 1}
        onClick={() => act('page', { page: 1 })}>
        <Icon name="list" /> Список записей
      </Tabs.Tab>
      <Tabs.Tab
        selected={currentPage === 2}
        onClick={() => act('page', { page: 2 })}>
        <Icon name="wrench" /> Обслуживание
      </Tabs.Tab>
      <Tabs.Tab
        selected={currentPage === 4}
        onClick={() => act('page', { page: 4 })}>
        <Icon name="clipboard-list" /> Логи
      </Tabs.Tab>
      {currentPage === 3 && general && !general.empty && (
        <Tabs.Tab selected>
          <Icon name="file" /> {general.name}
        </Tabs.Tab>
      )}
    </Tabs>
  );
};

// ============= LIST PAGE =============

const PageRecordList = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { records, isPrinting } = data;
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');
  const [sortId, _setSortId] = useLocalState(context, 'sortId', 'name');
  const [sortOrder, _setSortOrder] = useLocalState(context, 'sortOrder', true);

  const filteredRecords = (records || [])
    .filter(
      createSearch(searchText, (record) => {
        return (
          record.name
          + '|' + record.id
          + '|' + record.rank
          + '|' + record.fingerprint
          + '|' + record.status
        );
      })
    )
    .sort((a, b) => {
      const i = sortOrder ? 1 : -1;
      return String(a[sortId] || '').localeCompare(String(b[sortId] || '')) * i;
    });

  return (
    <Fragment>
      <Flex mb="0.5rem">
        <Flex.Item>
          <Button
            content="Новая запись"
            icon="plus"
            onClick={() => act('new_general')}
          />
        </Flex.Item>
        <Flex.Item grow="1" ml="0.5rem">
          <Input
            placeholder="Поиск по имени, ID, должности, отпечатку, статусу..."
            width="100%"
            onInput={(e, value) => setSearchText(value)}
          />
        </Flex.Item>
      </Flex>
      <Table className="SecurityRecords__list">
        <Table.Row bold>
          <Table.Cell collapsing />
          <SortButton id="name">Имя</SortButton>
          <SortButton id="id">ID</SortButton>
          <SortButton id="rank">Должность</SortButton>
          <SortButton id="fingerprint">Отпечаток</SortButton>
          <SortButton id="status">Статус</SortButton>
        </Table.Row>
        {filteredRecords.map((record) => (
          <Table.Row
            key={record.ref}
            className={
              'SecurityRecords__listRow--' + (statusStyles[record.status] || '')
            }
            style={{ cursor: 'pointer' }}
            onClick={() => act('view', { ref: record.ref })}>
            <Table.Cell collapsing>
              {record.thumb ? (
                <img
                  src={'data:image/png;base64,' + record.thumb}
                  className="SecurityRecords__photo"
                  style={{
                    width: '24px',
                    height: '24px',
                    verticalAlign: 'middle',
                  }}
                />
              ) : (
                <Icon name="user" />
              )}
            </Table.Cell>
            <Table.Cell>{record.name}</Table.Cell>
            <Table.Cell>{record.id}</Table.Cell>
            <Table.Cell>{record.rank}</Table.Cell>
            <Table.Cell>{record.fingerprint}</Table.Cell>
            <Table.Cell>{record.status}</Table.Cell>
          </Table.Row>
        ))}
      </Table>
    </Fragment>
  );
};

const SortButton = (properties, context) => {
  const [sortId, setSortId] = useLocalState(context, 'sortId', 'name');
  const [sortOrder, setSortOrder] = useLocalState(context, 'sortOrder', true);
  const { id, children } = properties;
  return (
    <Table.Cell>
      <Button
        color={sortId !== id ? 'transparent' : undefined}
        width="100%"
        onClick={() => {
          if (sortId === id) {
            setSortOrder(!sortOrder);
          } else {
            setSortId(id);
            setSortOrder(true);
          }
        }}>
        {children}
        {sortId === id && (
          <Icon
            name={sortOrder ? 'sort-up' : 'sort-down'}
            ml="0.25rem"
          />
        )}
      </Button>
    </Table.Cell>
  );
};

// ============= MAINTENANCE PAGE =============

const PageMaintenance = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { canDeleteAll } = data;
  return (
    <Box>
      {canDeleteAll ? (
        <Button.Confirm
          icon="trash"
          color="bad"
          content="Удалить все записи безопасности"
          onClick={() => act('delete_security_all')}
        />
      ) : (
        <Box color="label" italic>
          Недостаточно полномочий для операций обслуживания.
        </Box>
      )}
    </Box>
  );
};

// ============= ALL LOGS PAGE =============

const PageAllLogs = (_properties, context) => {
  const { data } = useBackend(context);
  const { allLogs } = data;
  const [searchLogs, setSearchLogs] = useLocalState(context, 'searchLogs', '');

  const logs = allLogs || [];
  const filteredLogs = logs.filter(
    createSearch(searchLogs, (entry) => {
      return entry.name + '|' + entry.id + '|' + entry.text;
    })
  );

  return (
    <Fragment>
      <Flex mb="0.5rem">
        <Flex.Item grow="1">
          <Input
            placeholder="Поиск по имени, ID, тексту лога..."
            width="100%"
            onInput={(e, value) => setSearchLogs(value)}
          />
        </Flex.Item>
      </Flex>
      <Section title={'Все логи (' + filteredLogs.length + ')'}>
        {filteredLogs.length === 0 ? (
          <Box color="label" italic>
            Нет логов.
          </Box>
        ) : (
          <Box
            maxHeight="450px"
            overflowY="auto"
            p="0.25rem"
            backgroundColor="rgba(0,0,0,0.2)"
            style={{ borderRadius: '3px' }}>
            {filteredLogs.map((entry, i) => (
              <Box key={i} py="0.15rem" fontSize="0.85rem">
                <Box as="span" bold color="average">
                  [{entry.name} ({entry.id})]
                </Box>
                {' '}
                <Box
                  as="span"
                  color="label"
                  dangerouslySetInnerHTML={{ __html: entry.text }}
                />
              </Box>
            ))}
          </Box>
        )}
      </Section>
    </Fragment>
  );
};

// ============= RECORD VIEW PAGE =============

const PageRecordView = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { general, security, isPrinting, canDeleteLogs } = data;

  return (
    <Fragment>
      <Button
        icon="arrow-left"
        content="Назад к списку"
        mb="0.5rem"
        onClick={() => act('back')}
      />
      <ViewGeneral />
      <ViewSecurity />
    </Fragment>
  );
};

// ----- General Section -----

const ViewGeneral = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { general, isPrinting, canEditRank } = data;

  if (!general || general.empty) {
    return (
      <Section title="Общие данные" color="bad">
        <Box color="bad">Общие записи утеряны!</Box>
      </Section>
    );
  }

  return (
    <Section
      title="Общие данные"
      buttons={
        <Fragment>
          <Button
            disabled={isPrinting}
            icon={isPrinting ? 'spinner' : 'print'}
            iconSpin={!!isPrinting}
            content="Печать"
            onClick={() => act('print_record')}
          />
          <Button
            disabled={isPrinting}
            icon={isPrinting ? 'spinner' : 'scroll'}
            iconSpin={!!isPrinting}
            content="Плакат"
            onClick={() => act('print_poster')}
          />
          <Button
            disabled={isPrinting}
            icon={isPrinting ? 'spinner' : 'file-contract'}
            iconSpin={!!isPrinting}
            content="Ордер"
            onClick={() => act('generate_warrant')}
          />
          <Button.Confirm
            icon="trash"
            color="bad"
            content="Удалить всё"
            onClick={() => act('delete_general')}
          />
        </Fragment>
      }>
      <Flex>
        <Flex.Item grow="1">
          <LabeledList>
            <LabeledList.Item label="Имя">
              {general.name}
              <Button
                icon="pen"
                ml="0.5rem"
                onClick={() => act('edit_field', { field: 'name', value: general.name })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="ID">
              {general.id}
              <Button
                icon="pen"
                ml="0.5rem"
                onClick={() => act('edit_field', { field: 'id', value: general.id })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Пол">
              {general.gender}
              <Button
                icon="venus-mars"
                ml="0.5rem"
                onClick={() => act('edit_field', { field: 'gender', value: general.gender })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Возраст">
              {general.age}
              <Button
                icon="pen"
                ml="0.5rem"
                onClick={() => act('edit_field', { field: 'age', value: general.age })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Вид">
              {general.species}
              <Button
                icon="pen"
                ml="0.5rem"
                onClick={() => act('edit_field', { field: 'species', value: general.species })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Должность">
              {general.rank}
              {!!canEditRank && (
                <Button
                  icon="pen"
                  ml="0.5rem"
                  onClick={() => act('edit_field', { field: 'rank', value: general.rank })}
                />
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Отпечаток">
              {general.fingerprint}
              <Button
                icon="pen"
                ml="0.5rem"
                onClick={() => act('edit_field', { field: 'fingerprint', value: general.fingerprint })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Физ. статус">
              <Box color={general.p_stat === 'Active' ? 'good' : 'bad'}>
                {general.p_stat}
              </Box>
            </LabeledList.Item>
            <LabeledList.Item label="Псих. статус">
              <Box color={general.m_stat === 'Stable' ? 'good' : 'bad'}>
                {general.m_stat}
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Flex.Item>
        <Flex.Item ml="1rem" textAlign="center">
          <PhotoBox
            photoData={general.photos && general.photos.front}
            label="Фас"
            side="front"
          />
          <PhotoBox
            photoData={general.photos && general.photos.side}
            label="Профиль"
            side="side"
          />
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const PhotoBox = (properties, context) => {
  const { act } = useBackend(context);
  const { photoData, label, side } = properties;
  return (
    <Box display="inline-block" textAlign="center" mr="0.5rem" mb="0.5rem">
      {photoData ? (
        <img
          src={'data:image/png;base64,' + photoData}
          className="SecurityRecords__photo"
          style={{
            width: '96px',
            height: '96px',
            border: '2px solid rgba(255,255,255,0.2)',
            cursor: 'pointer',
          }}
          onClick={() => act('show_photo', { side: side })}
        />
      ) : (
        <Box
          width="96px"
          height="96px"
          backgroundColor="rgba(255,255,255,0.05)"
          style={{ border: '2px dashed rgba(255,255,255,0.2)' }}>
          <Icon name="image" size={3} color="label" mt="30px" />
        </Box>
      )}
      <Box color="label" fontSize="0.8rem" mt="0.25rem">
        {label}
      </Box>
      <Button
        icon="camera"
        tooltip="Обновить фото"
        onClick={() => act('upd_photo', { side: side })}
      />
      <Button
        icon="print"
        tooltip="Печать фото"
        onClick={() => act('print_photo', { side: side })}
      />
    </Box>
  );
};

// ----- Security Section -----

const ViewSecurity = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { security, isPrinting, canDeleteLogs, hasCentcomAuth } = data;

  if (!security || security.empty) {
    return (
      <Section title="Данные безопасности">
        <Box color="average">Записи безопасности отсутствуют.</Box>
        <Button
          icon="plus"
          content="Создать запись безопасности"
          mt="0.5rem"
          onClick={() => act('new_security')}
        />
      </Section>
    );
  }

  return (
    <Fragment>
      <Section
        title="Данные безопасности"
        buttons={
          <Button.Confirm
            icon="trash"
            color="bad"
            content="Удалить запись безоп."
            onClick={() => act('delete_security')}
          />
        }>
        <CriminalStatusSelector />
        <Box mt="0.75rem">
          <CrimeTable
            title="Некрупные правонарушения"
            crimes={security.mi_crim || []}
            addAction="mi_crim_add"
            deleteAction="mi_crim_delete"
            hasCentcomAuth={hasCentcomAuth}
          />
        </Box>
        <Box mt="0.75rem">
          <CrimeTable
            title="Крупные правонарушения"
            crimes={security.ma_crim || []}
            addAction="ma_crim_add"
            deleteAction="ma_crim_delete"
            hasCentcomAuth={hasCentcomAuth}
          />
        </Box>
        <Box mt="0.75rem">
          <LabeledList>
            <LabeledList.Item label="Заметки">
              {security.notes}
              <Button
                icon="pen"
                ml="0.5rem"
                onClick={() => act('edit_field', { field: 'notes', value: security.notes })}
              />
            </LabeledList.Item>
          </LabeledList>
        </Box>
      </Section>
      <ActionLogs />
      <CommentsSection />
    </Fragment>
  );
};

const CriminalStatusSelector = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { security } = data;
  const [showStatusPicker, setShowStatusPicker] = useLocalState(
    context,
    'showStatusPicker',
    false
  );
  const [statusReason, setStatusReason] = useLocalState(
    context,
    'statusReason',
    ''
  );

  const currentStatus = security.criminal || 'Ничего';
  const currentStyle = statusStyles[currentStatus];

  return (
    <Box>
      <Flex align="center">
        <Flex.Item>
          <Box bold inline>
            Криминальный статус:{' '}
          </Box>
        </Flex.Item>
        <Flex.Item>
          <Button
            content={currentStatus}
            color={currentStyle ? undefined : 'label'}
            className={
              currentStyle
                ? 'SecurityRecords__listRow--' + currentStyle
                : undefined
            }
            icon="gavel"
            onClick={() => setShowStatusPicker(!showStatusPicker)}
          />
        </Flex.Item>
      </Flex>
      {showStatusPicker && (
        <Box
          mt="0.5rem"
          p="0.5rem"
          backgroundColor="rgba(0,0,0,0.3)"
          style={{ borderRadius: '4px' }}>
          <Box mb="0.5rem" color="label">
            Выберите статус:
          </Box>
          <Flex wrap="wrap">
            {CRIMINAL_STATUSES.map((s) => (
              <Flex.Item key={s.value} m="0.15rem">
                <Button
                  selected={currentStatus === s.value}
                  icon={s.icon}
                  color={s.color}
                  content={s.label}
                  onClick={() => {
                    act('set_criminal', {
                      status: s.value,
                      reason: statusReason,
                    });
                    setShowStatusPicker(false);
                    setStatusReason('');
                  }}
                />
              </Flex.Item>
            ))}
          </Flex>
          <Box mt="0.5rem">
            <Input
              placeholder="Причина (обязательно для Уничтожить/Уволить)"
              width="100%"
              value={statusReason}
              onInput={(e, value) => setStatusReason(value)}
            />
          </Box>
        </Box>
      )}
    </Box>
  );
};

const CrimeTable = (properties, context) => {
  const { act } = useBackend(context);
  const { title, crimes, addAction, deleteAction, hasCentcomAuth } = properties;

  return (
    <Section
      title={title + ' (' + crimes.length + ')'}
      level={2}
      buttons={
        <Button
          icon="plus"
          content="Добавить"
          onClick={() => act(addAction)}
        />
      }>
      {crimes.length === 0 ? (
        <Box color="label" italic>
          Нет записей.
        </Box>
      ) : (
        <Table>
          <Table.Row bold header>
            <Table.Cell>Название</Table.Cell>
            <Table.Cell>Подробности</Table.Cell>
            <Table.Cell>Автор</Table.Cell>
            <Table.Cell>Время</Table.Cell>
            <Table.Cell textAlign="center">Наказание</Table.Cell>
            <Table.Cell textAlign="center">Действия</Table.Cell>
          </Table.Row>
          {crimes.map((crime) => (
            <Table.Row key={crime.dataId}>
              <Table.Cell>
                {crime.name}
                {!!crime.centcom && (
                  <Box
                    as="span"
                    ml="0.5rem"
                    color="green"
                    bold
                    fontSize="0.8rem">
                    [ЦК]
                  </Box>
                )}
              </Table.Cell>
              <Table.Cell>{crime.details}</Table.Cell>
              <Table.Cell color="label">{crime.author}</Table.Cell>
              <Table.Cell color="label">{crime.time}</Table.Cell>
              <Table.Cell textAlign="center">
                <Button
                  icon={crime.incurred ? 'check' : 'times'}
                  color={crime.incurred ? 'good' : 'bad'}
                  tooltip={crime.incurred ? 'Понесено' : 'Не понесено'}
                  onClick={() =>
                    act('crim_incur_switch', { cdataid: crime.dataId })
                  }
                />
              </Table.Cell>
              <Table.Cell textAlign="center">
                <Button.Confirm
                  icon="trash"
                  color="bad"
                  onClick={() =>
                    act(deleteAction, { cdataid: crime.dataId })
                  }
                />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table>
      )}
    </Section>
  );
};

const ActionLogs = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { security, isPrinting, canDeleteLogs } = data;
  const logs = security.logs || [];

  return (
    <Section
      title={'Логи действий (' + logs.length + ')'}
      buttons={
        <Fragment>
          <Button
            disabled={isPrinting}
            icon={isPrinting ? 'spinner' : 'print'}
            iconSpin={!!isPrinting}
            content="Печать логов"
            onClick={() => act('print_logs')}
          />
          {!!canDeleteLogs && (
            <Button.Confirm
              icon="trash"
              color="bad"
              content="Очистить"
              onClick={() => act('delete_logs')}
            />
          )}
        </Fragment>
      }>
      {logs.length === 0 ? (
        <Box color="label" italic>
          Нет логов.
        </Box>
      ) : (
        <Box
          maxHeight="200px"
          overflowY="auto"
          p="0.25rem"
          backgroundColor="rgba(0,0,0,0.2)"
          style={{ borderRadius: '3px' }}>
          {logs.map((log, i) => (
            <Box
              key={i}
              py="0.15rem"
              color="label"
              fontSize="0.85rem"
              dangerouslySetInnerHTML={{ __html: log }}
            />
          ))}
        </Box>
      )}
    </Section>
  );
};

const CommentsSection = (_properties, context) => {
  const { act, data } = useBackend(context);
  const { security } = data;
  const comments = security.comments || [];

  return (
    <Section
      title={'Комментарии (' + comments.length + ')'}
      buttons={
        <Button
          icon="comment"
          content="Добавить"
          onClick={() => act('add_comment')}
        />
      }>
      {comments.length === 0 ? (
        <Box color="label" italic>
          Нет комментариев.
        </Box>
      ) : (
        comments.map((comment) => (
          <Box
            key={comment.id}
            py="0.25rem"
            style={{
              borderBottom: '1px solid rgba(255,255,255,0.1)',
            }}>
            {comment.deleted ? (
              <Box color="bad" italic>
                [Удалено]
              </Box>
            ) : (
              <Fragment>
                <Box
                  fontSize="0.85rem"
                  dangerouslySetInnerHTML={{ __html: comment.text }}
                />
                <Button
                  icon="trash"
                  color="bad"
                  mt="0.25rem"
                  onClick={() => act('delete_comment', { id: comment.id })}
                />
              </Fragment>
            )}
          </Box>
        ))
      )}
    </Section>
  );
};
