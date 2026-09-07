import { useBackend, useLocalState } from '../backend';
import { Button, NoticeBox, Section, Table, Tabs, ProgressBar, Box, Input, Flex, Icon, Divider } from '../components';
import { Window } from '../layouts';

export const BrigAssistantConsole = (props) => {
  const { act, data } = useBackend();
  const { has_id, id_name, id_balance, scanning, scan_progress, scan_time_left, fines = [], fines_total, fines_paid, fines_count, wanted = [], remove = [] } = data;
  const [tab, setTab] = useLocalState('brigTab', 0); // 0 = fines, 1 = wanted

  return (
    <Window
      title="Консоль заданий брига"
      width={650}
      height={600}>
      <Window.Content scrollable>
        <Tabs>
          <Tabs.Tab selected={tab === 0} onClick={() => setTab(0)} icon="credit-card">
            Оплата штрафов {fines_count ? `(${fines_count})` : ''}
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 1} onClick={() => setTab(1)} icon="file-contract">
            Розыск и задания {wanted.length ? `(${wanted.length})` : ''}
          </Tabs.Tab>
        </Tabs>

        {tab === 0 && (
          <>
            <Section title="Терминал оплаты штрафов" buttons={
              <>
                {has_id ? (
                  <Button icon="eject" content="Извлечь карту" onClick={() => act('eject_id')} disabled={scanning} />
                ) : (
                  <Button icon="id-card" content="Вставьте ID-карту" disabled tooltip="Вставьте карту в консоль (клик картой по консоли)" />
                )}
                {!!has_id && !scanning ? (
                  <Button icon="sync" content="Сканировать заново" onClick={() => act('rescan')} />
                ) : null}
              </>
            }>
              {!has_id ? (
                <NoticeBox info>
                  <Icon name="info" /> Вставьте вашу ID-карту в консоль для проверки задолженности. Приложите карту к консоли.
                  <br />Консоль запустит сверку с базой данных СБ и покажет ваши неоплаченные штрафы, сумму, таймер и статьи.
                </NoticeBox>
              ) : null}
              {!!has_id && !!scanning ? (
                <Box>
                  <Box mb={1} color="average">
                    <Icon name="spinner" spin /> Сканирование и сверка с базой данных СБ... <b>{id_name}</b>
                  </Box>
                  <ProgressBar value={scan_progress} minValue={0} maxValue={1} color="good">
                    {Math.round(scan_progress * 100)}% - осталось {Math.ceil(scan_time_left / 10)}с
                  </ProgressBar>
                  <Box mt={1} color="label" fontSize="0.9em">
                    Проверка биометрии, сверка отпечатков, запрос в DataCore...
                  </Box>
                </Box>
              ) : null}
              {!!has_id && !scanning ? (
                <Box>
                  <Flex align="center" mb={1}>
                    <Flex.Item grow={1}>
                      <Box bold>Карта: <Box as="span" color="good">{id_name}</Box></Box>
                      <Box color="label">Баланс: <Box as="span" color={id_balance >= 0 ? 'good' : 'bad'}>{id_balance ?? '???'} кр.</Box></Box>
                    </Flex.Item>
                    <Flex.Item>
                      <Icon name="check-circle" color="good" size={2} />
                    </Flex.Item>
                  </Flex>
                  <Divider />
                  {fines.length === 0 ? (
                    <NoticeBox success mt={1}>
                      <Icon name="check" /> Задолженностей не найдено. Вы чисты перед законом!
                    </NoticeBox>
                  ) : (
                    <Box mt={1}>
                      <Box mb={1} color="average">
                        Найдено штрафов: <b>{fines.length}</b> | Общая сумма: <b>{fines_total} кр.</b> | Уплачено: <b>{fines_paid} кр.</b> | К доплате: <b style={{ color: '#ff5555' }}>{fines_total - fines_paid} кр.</b>
                      </Box>
                      <Table>
                        <Table.Row header>
                          <Table.Cell>Статья</Table.Cell>
                          <Table.Cell>Детали</Table.Cell>
                          <Table.Cell>Сумма</Table.Cell>
                          <Table.Cell>Таймер</Table.Cell>
                          <Table.Cell>Оплата</Table.Cell>
                        </Table.Row>
                        {fines.map(f => <FineRow key={f.dataId} fine={f} balance={id_balance} />)}
                      </Table>
                      <NoticeBox info mt={1} fontSize="0.85em">
                        При неуплате в срок - автоматический розыск по статье <b>303 - Неуплата установленного штрафа в срок</b> и перевод в статус <b>*Арестовать*</b>. Частичная оплата не останавливает таймер, только полная.
                      </NoticeBox>
                    </Box>
                  )}
                </Box>
              ) : null}
            </Section>
            {!!has_id && !scanning && fines.length > 0 ? (
              <Section title="Квитанции" level={2}>
                <Box color="label" fontSize="0.9em">
                  После каждой оплаты автоматически печатается квитанция с печатью Службы Безопасности. Заберите её из лотка консоли.
                </Box>
              </Section>
            ) : null}
          </>
        )}

        {tab === 1 && (
          <>
            <Section title="Развешивание плакатов с разыскиваемыми">
              <Table>
                <Table.Row header>
                  <Table.Cell>Имя</Table.Cell>
                  <Table.Cell>Статус</Table.Cell>
                  <Table.Cell>Взято</Table.Cell>
                  <Table.Cell collapsing>Действие</Table.Cell>
                </Table.Row>
                {wanted.map(w => (
                  <Table.Row key={w.id}>
                    <Table.Cell>{w.name}</Table.Cell>
                    <Table.Cell bold color={w.status === '*Арестовать*' ? 'bad' : 'average'}>{w.status}</Table.Cell>
                    <Table.Cell>
                      {w.takes_count}/{3}
                      {w.reason && ` (${w.reason})`}
                    </Table.Cell>
                    <Table.Cell collapsing>
                      <Button
                        content="Взять задание"
                        disabled={!w.can_take}
                        tooltip={!w.has_photo ? "Нет фото в досье" : null}
                        onClick={() => act('take_task', { id: w.id })} />
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
              {wanted.length === 0 && (
                <NoticeBox info>
                  Нет разыскиваемых в базе данных. Добавьте записи через консоль СБ.
                </NoticeBox>
              )}
            </Section>
            <Section title="Снятие плакатов (пойманные)">
              <Table>
                <Table.Row header>
                  <Table.Cell>Имя</Table.Cell>
                  <Table.Cell>Статус</Table.Cell>
                  <Table.Cell collapsing>Действие</Table.Cell>
                </Table.Row>
                {remove.map(r => (
                  <Table.Row key={r.id}>
                    <Table.Cell>{r.name}</Table.Cell>
                    <Table.Cell>{r.status}</Table.Cell>
                    <Table.Cell collapsing>
                      <Button
                        content={r.has_task ? "Задание взято" : "Взять задание"}
                        disabled={r.has_task}
                        tooltip="Снимите плакаты кусачками. Награда: 75-100 кредитов."
                        onClick={() => act('take_remove_task', { id: r.id })} />
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table>
              {remove.length === 0 && (
                <NoticeBox info>
                  Нет пойманных в базе. Плакаты снимают после смены статуса в консоли СБ.
                </NoticeBox>
              )}
            </Section>
          </>
        )}
      </Window.Content>
    </Window>
  );
};

const FineRow = (props) => {
  const { act } = useBackend();
  const { fine, balance } = props;
  const [amount, setAmount] = useLocalState(`fine_amt_${fine.dataId}`, Math.min(100, fine.fine) || 1);
  const timeColor = fine.overdue ? 'bad' : fine.time_left < 3000 ? 'average' : 'good';
  const canPay = fine.fine > 0 && balance !== null && balance >= 1;
  const displayLeft = fine.fine === 0 ? 'ОПЛАЧЕН' : fine.overdue ? 'ПРОСРОЧЕНО!' : fine.display_time_left;
  return (
    <Table.Row className={fine.overdue ? 'candystripe' : ''}>
      <Table.Cell>
        <Box bold color={fine.overdue ? 'bad' : undefined}>{fine.name}</Box>
        <Box color="label" fontSize="0.8em">Выписал: {fine.author} {fine.time}</Box>
      </Table.Cell>
      <Table.Cell>
        <Box fontSize="0.9em">{fine.details}</Box>
        <Box color="label" fontSize="0.8em">Срок: {fine.display_duration}</Box>
      </Table.Cell>
      <Table.Cell textAlign="center">
        <Box color="yellow">{fine.total} кр.</Box>
        <Box color="good" fontSize="0.85em">Опл: {fine.paid} кр.</Box>
        <Box color={fine.fine > 0 ? 'bad' : 'good'} bold>{fine.fine} кр. к доплате</Box>
      </Table.Cell>
      <Table.Cell textAlign="center" color={timeColor}>
        <Box bold>{displayLeft}</Box>
        {fine.fine > 0 && !fine.overdue ? (
          <ProgressBar value={fine.time_left} maxValue={fine.duration} minValue={0} color={timeColor} />
        ) : null}
        {!!fine.overdue ? <Box color="bad" fontSize="0.8em">→ 303 + розыск</Box> : null}
      </Table.Cell>
      <Table.Cell collapsing>
        {fine.fine === 0 ? (
          <Box color="good" bold><Icon name="check" /> Оплачено</Box>
        ) : (
          <Flex direction="column" wrap>
            <Flex.Item>
              <Input
                width="80px"
                value={amount}
                onInput={(e, v) => setAmount(Math.max(1, Math.min(fine.fine, parseInt(v, 10) || 1)))}
                type="number"
              />
              <Box as="span" color="label" fontSize="0.75em"> кр.</Box>
            </Flex.Item>
            <Flex.Item mt={0.25}>
              <Button
                icon="coins"
                content="Оплатить"
                color="good"
                disabled={!canPay}
                tooltip={balance !== null && balance < amount ? `Недостаточно средств (${balance} кр.)` : `Списать ${amount} кр.`}
                onClick={() => act('pay_fine', { cdataid: fine.dataId, amount: amount })}
              />
            </Flex.Item>
            <Flex.Item mt={0.15}>
              <Button
                icon="money-bill-wave"
                content={`Полностью (${fine.fine} кр.)`}
                color="yellow"
                disabled={!canPay || balance < fine.fine}
                onClick={() => act('pay_fine_full', { cdataid: fine.dataId })}
              />
            </Flex.Item>
          </Flex>
        )}
      </Table.Cell>
    </Table.Row>
  );
};
