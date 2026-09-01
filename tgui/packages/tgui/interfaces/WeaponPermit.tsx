/**
 * BLUEMOON EDITED
 */
import { useBackend } from '../backend';
import { Box, Button, Section } from '../components';
import { Window } from '../layouts';
import { LabeledList } from './../components/LabeledList';

type WeaponPermitData = {
  owner_name: string;
  owner_assignment: string;
  issuer_name: string;
  issuer_assignment: string;
  permitted_weapons: string;
  notes: string;
  locked: boolean;
  can_interact: boolean;
  has_access: boolean;
  issue_time: string;
  centcomm_issued: boolean;
};

export const WeaponPermit = (props) => {
  const { act, data } = useBackend<WeaponPermitData>();
  return (
    <Window title="Разрешение на оружие" width={800} height={450}>
      <Window.Content overflow="auto">
        <Section
          title="Данные о разрешении"
          buttons={
            !data.locked ? (
              <Button /** Выдать лицензию и закрыть */
                color="red"
                disabled={
                  !data.can_interact ||
                  !data.has_access ||
                  data.locked ||
                  data.centcomm_issued
                }
                icon="sign-out-alt"
                tooltip={
                  !data.has_access
                    ? 'У вас нет доступа для выдачи лицензий'
                    : data.centcomm_issued
                    ? 'Данная лицензия выдана Центральным Командованием. Вы не можете её редактировать.'
                    : !data.can_interact
                    ? 'Вы не можете взаимодействовать с данной лицензией. Возможно, она слишком далеко'
                    : 'Нажмите, чтобы выдать лицензию и завершить работу'
                }
                tooltipPosition="left"
                onClick={() => act('submit_license')}
              />
            ) : (
              <Button /** Удалить текущую лицензию и начать заполнение заново */
                color="yellow"
                disabled={
                  !data.can_interact ||
                  !data.has_access ||
                  !data.locked ||
                  data.centcomm_issued
                }
                icon="sign-in-alt"
                tooltip={
                  !data.has_access
                    ? 'У вас нет доступа для выдачи лицензий'
                    : data.centcomm_issued
                    ? 'Данная лицензия выдана Центральным Командованием. Вы не можете её редактировать.'
                    : !data.can_interact
                    ? 'Вы не можете взаимодействовать с данной лицензией. Возможно, она слишком далеко'
                    : 'Нажмите, чтобы отозвать текущую лицензию и оформить её заново.'
                }
                tooltipPosition="left"
                onClick={() => act('reopen_license')}
              />)
          }>
          <LabeledList>
            <LabeledList.Item
              label="Имя обладателя лицензии"
              color="green"
              buttons={
                !data.locked && data.can_interact && !data.centcomm_issued ? (
                  <Button
                    icon="edit"
                    disabled={
                      !data.can_interact || data.locked || data.centcomm_issued
                    }
                    content="Присвоить"
                    tooltip="Присвоит имени и должности обладателя соответствующую информацию с ID-карты на костюме сотрудника, производящего настройку."
                    onClick={() => act('submit_owner')}
                  />
                ) : ''
              }>
              {data.owner_name ? data.owner_name : '---'}
            </LabeledList.Item>
            <LabeledList.Item
              label="Должность обладателя лицензии"
              color="green">
              {data.owner_assignment ? data.owner_assignment : '---'}
            </LabeledList.Item>
            <LabeledList.Item label="Имя эмитента лицензии" color="yellow">
              {data.issuer_name ? data.issuer_name : '---'}
            </LabeledList.Item>
            <LabeledList.Item
              label="Должность эмитента лицензии"
              color="yellow">
              {data.issuer_assignment ? data.issuer_assignment : '---'}
            </LabeledList.Item>
            <LabeledList.Item label="Дата выдачи лицензии" color="blue">
              {data.issue_time ? data.issue_time : '---'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Состав разрешения">
          <LabeledList>
            <LabeledList.Item
              label="Перечень разрешённого снаряжения"
              color="orange"
              buttons={
                !data.locked && data.can_interact && !data.centcomm_issued ? (
                  <Button
                    icon="edit"
                    disabled={
                      !data.can_interact || data.locked || data.centcomm_issued
                    }
                    content="Редактировать"
                    tooltip="Ввести новый перечень разрешённого к использованию оружия."
                    onClick={() => act('input_weapons')}
                  />
                ) : ''
              }>
              {data.permitted_weapons ? data.permitted_weapons : '---'}
            </LabeledList.Item>
            <LabeledList.Item
              label="Примечания"
              color="orange"
              buttons={
                !data.locked && data.can_interact && !data.centcomm_issued ? (
                  <Button
                    icon="edit"
                    disabled={
                      !data.can_interact || data.locked || data.centcomm_issued
                    }
                    content="Редактировать"
                    tooltip="Введите примечания и заметки для службы безопасности по поводу данной лицензии."
                    onClick={() => act('input_notes')}
                  />
                ) : ''
              }>
              {data.notes ? data.notes : '---'}
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Box color="green" fontSize="8px" textAlign="center">
            ДЛЯ ВЛАДЕЛЬЦА ЛИЦЕНЗИИ:
            <br />
            Данное разрешение недействительно в случае нарушения боевой
            политики.
            <br />
            Сотрудники СБ имеют право потребовать бумажный документ в случае
            сомнения.
            <br />
        </Box>
        <Box color="red" fontSize="8px" textAlign="center">
          ДЛЯ ЭМИТЕНТА ЛИЦЕНЗИИ:
          <br />
          Не забудьте ОБЯЗАТЕЛЬНО заблокировать разрешение кнопкой вверху.
          <br />
          Выдавайте разрешения в соответствии с НРП и Боевой Политикой.
        </Box>
      </Window.Content>
    </Window>
  );
};
