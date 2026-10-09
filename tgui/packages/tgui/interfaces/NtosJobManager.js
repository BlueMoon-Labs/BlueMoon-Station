import { useBackend } from '../backend';
import { Box, Button, Icon, NoticeBox, Section, Table } from '../components';
import { NtosWindow } from '../layouts';

const PRIORITY_COLOR = '#ffcc66';

/** Приоритетные роли */
const priorityTitleStyle = {
  fontFamily: 'Georgia, "Times New Roman", serif',
  fontWeight: 700,
};

const badgeStyle = {
  flex: '0 0 auto',
  marginLeft: '6px',
  padding: '0 4px',
  border: `1px solid ${PRIORITY_COLOR}`,
  borderRadius: '3px',
  fontSize: '10px',
  lineHeight: '16px',
  color: PRIORITY_COLOR,
  whiteSpace: 'nowrap',
};

const checkboxStyle = (isPriority) => ({
  display: 'flex',
  alignItems: 'center',
  textAlign: 'left',
  ...(isPriority
    ? { backgroundColor: 'rgba(255, 204, 102, 0.22)', color: PRIORITY_COLOR }
    : null),
});

const contentStyle = {
  display: 'flex',
  alignItems: 'center',
  flex: '1 1 auto',
  minWidth: 0,
};

const titleStyle = (isPriority) => ({
  flex: '1 1 auto',
  minWidth: 0,
  overflow: 'hidden',
  textOverflow: 'ellipsis',
  whiteSpace: 'nowrap',
  color: isPriority ? PRIORITY_COLOR : '#ffffff',
  ...(isPriority ? priorityTitleStyle : null),
});

const priorityRowStyle = { backgroundColor: 'rgba(255, 204, 102, 0.10)' };
const priorityEdgeStyle = {
  ...priorityRowStyle,
  borderLeft: `3px solid ${PRIORITY_COLOR}`,
};

export const NtosJobManager = (props) => {
  return (
    <NtosWindow
      width={520}
      height={640}>
      <NtosWindow.Content overflow="auto">
        <NtosJobManagerContent />
      </NtosWindow.Content>
    </NtosWindow>
  );
};

export const NtosJobManagerContent = (props) => {
  const { act, data } = useBackend();
  const {
    authed,
    cooldown,
    slots = [],
    prioritized = [],
    priorityLimit = 5,
  } = data;
  if (!authed) {
    return (
      <NoticeBox>
        Вставленная ID-карта не даёт прав менять вакансии и приоритеты.
      </NoticeBox>
    );
  }
  return (
    <Section>
      <Box fontSize="12px" color="#c9d1d9">
        Отмеченная роль видна игрокам в лобби как «Приоритетная вакансия» и
        приносит <b style={{ color: PRIORITY_COLOR }}>×2 метадоллара</b> за час
        игры.
      </Box>
      <Box fontSize="12px" color="#c9d1d9" mt={1}>
        Приоритетов:{' '}
        <b style={{ color: PRIORITY_COLOR }}>{prioritized.length}</b> из{' '}
        {priorityLimit}
        {cooldown > 0 && (
          <span style={{ color: '#ff9b2f' }}> · Перезарядка: {cooldown} с</span>
        )}
      </Box>
      <Table mt={1}>
        <Table.Row header>
          <Table.Cell>Приоритет</Table.Cell>
          <Table.Cell collapsing>Слоты</Table.Cell>
          <Table.Cell collapsing>Управление</Table.Cell>
        </Table.Row>
        {slots.map(slot => {
          const isPriority = prioritized.includes(slot.title);
          const closed = slot.total <= 0;
          return (
            <Table.Row
              key={slot.title}
              className="candystripe">
              <Table.Cell style={isPriority ? priorityEdgeStyle : null}>
                <Button.Checkbox
                  fluid
                  content={
                    <Box as="span" style={contentStyle}>
                      {isPriority && (
                        <Icon
                          name="star"
                          style={{
                            flex: '0 0 auto',
                            color: PRIORITY_COLOR,
                            marginRight: '5px',
                          }}
                        />
                      )}
                      <Box as="span" style={titleStyle(isPriority)}>
                        {slot.title}
                      </Box>
                      {isPriority && (
                        <Box as="span" style={badgeStyle}>
                          М$ ×2
                        </Box>
                      )}
                    </Box>
                  }
                  style={checkboxStyle(isPriority)}
                  disabled={closed}
                  checked={isPriority}
                  onClick={() => act('PRG_priority', {
                    target: slot.title,
                  })} />
              </Table.Cell>
              <Table.Cell
                collapsing
                style={isPriority ? priorityRowStyle : null}>
                {slot.current} / {slot.total === -1 ? '∞' : slot.total}
              </Table.Cell>
              <Table.Cell
                collapsing
                style={isPriority ? priorityRowStyle : null}>
                <Button
                  content="Открыть"
                  disabled={!slot.status_open}
                  onClick={() => act('PRG_open_job', {
                    target: slot.title,
                  })} />
                <Button
                  content="Закрыть"
                  disabled={!slot.status_close}
                  onClick={() => act('PRG_close_job', {
                    target: slot.title,
                  })} />
              </Table.Cell>
            </Table.Row>
          );
        })}
      </Table>
      <Box mt={1} fontSize="11px" color="#7e90a7">
        Приоритет назначается только на вакансию со свободными слотами, поэтому
        сначала откройте нужное место. Открытие и закрытие вакансий идёт с
        паузой между операциями.
      </Box>
    </Section>
  );
};
