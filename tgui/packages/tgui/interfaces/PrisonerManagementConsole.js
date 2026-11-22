import { useBackend } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Table,
} from '../components';
import { Window } from '../layouts';

/**
 * Консоль управления заключёнными
 *
 * После авторизации с доступом к бригу позволяет управлять вставленным
 * ID заключённого и имплантами на том же уровне станции.
 */
export const PrisonerManagementConsole = (props) => {
  const { act, data } = useBackend();
  const {
    logged_in,
    has_id,
    id_name,
    id_points,
    id_goal,
    chem_implants = [],
    tracking_implants = [],
  } = data;

  return (
    <Window width={480} height={540}>
      <Window.Content scrollable>
        {!logged_in ? (
          <Section title="Требуется авторизация">
            <NoticeBox color="bad">
              Для работы с консолью требуется доступ к бригу. Войдите, чтобы
              продолжить.
            </NoticeBox>
            <Button
              fluid
              icon="lock"
              content="Войти"
              textAlign="center"
              onClick={() => act('login')}
            />
          </Section>
        ) : (
          <>
            <Section
              title="Управление ID заключённых"
              buttons={
                <Button
                  icon="unlock"
                  content="Выйти"
                  onClick={() => act('logout')}
                />
              }>
              {has_id ? (
                <LabeledList>
                  <LabeledList.Item
                    label="ID заключённого"
                    buttons={
                      <Button
                        icon="eject"
                        content="Извлечь"
                        onClick={() => act('id_eject')}
                      />
                    }>
                    {id_name}
                  </LabeledList.Item>
                  <LabeledList.Item
                    label="Набранные очки"
                    buttons={
                      <Button
                        icon="eraser"
                        content="Сбросить"
                        onClick={() => act('id_reset')}
                      />
                    }>
                    {id_points}
                  </LabeledList.Item>
                  <LabeledList.Item
                    label="Цель карты"
                    buttons={
                      <Button
                        icon="edit"
                        content="Задать"
                        onClick={() => act('id_setgoal')}
                      />
                    }>
                    {id_goal}
                  </LabeledList.Item>
                </LabeledList>
              ) : (
                <Button
                  fluid
                  icon="id-card"
                  content="Вставить ID заключённого"
                  textAlign="center"
                  onClick={() => act('id_insert')}
                />
              )}
              <Box mt={1} color="label" fontSize="12px">
                Космический закон рекомендует квоту 100 очков в минуту того
                срока, который заключённый должен был бы отбыть в бриге.
              </Box>
            </Section>

            <Section title="Химические импланты">
              {!chem_implants.length ? (
                <NoticeBox>Химические импланты не обнаружены.</NoticeBox>
              ) : (
                <Table>
                  <Table.Row bold>
                    <Table.Cell>Носитель</Table.Cell>
                    <Table.Cell collapsing textAlign="center">
                      Единиц
                    </Table.Cell>
                    <Table.Cell collapsing textAlign="center">
                      Ввести
                    </Table.Cell>
                  </Table.Row>
                  {chem_implants.map((implant) => (
                    <Table.Row key={implant.ref}>
                      <Table.Cell>{implant.name}</Table.Cell>
                      <Table.Cell collapsing textAlign="center">
                        {implant.units}
                      </Table.Cell>
                      <Table.Cell collapsing>
                        {[1, 5, 10].map((amount) => (
                          <Button
                            key={amount}
                            color="bad"
                            content={amount}
                            onClick={() =>
                              act('inject', {
                                ref: implant.ref,
                                amount: amount,
                              })
                            }
                          />
                        ))}
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>

            <Section title="Импланты слежения">
              {!tracking_implants.length ? (
                <NoticeBox>Импланты слежения не обнаружены.</NoticeBox>
              ) : (
                <Table>
                  <Table.Row bold>
                    <Table.Cell>Носитель</Table.Cell>
                    <Table.Cell>Местоположение</Table.Cell>
                    <Table.Cell collapsing textAlign="center">
                      Связь
                    </Table.Cell>
                  </Table.Row>
                  {tracking_implants.map((implant) => (
                    <Table.Row key={implant.ref}>
                      <Table.Cell>{implant.name}</Table.Cell>
                      <Table.Cell>{implant.location}</Table.Cell>
                      <Table.Cell collapsing textAlign="center">
                        <Button
                          icon="comment"
                          color="bad"
                          content="Сообщить"
                          onClick={() =>
                            act('warn', { ref: implant.ref })
                          }
                        />
                      </Table.Cell>
                    </Table.Row>
                  ))}
                </Table>
              )}
            </Section>
          </>
        )}
      </Window.Content>
    </Window>
  );
};
