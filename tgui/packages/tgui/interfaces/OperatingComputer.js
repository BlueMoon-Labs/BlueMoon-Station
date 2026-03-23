import { Fragment } from 'inferno';

import { useBackend, useSharedState } from '../backend';
import { AnimatedNumber, Button, Divider, LabeledList, NoticeBox, ProgressBar, Section, Tabs } from '../components';
import { Window } from '../layouts';

const damageTypes = [
  {
    label: 'Травмы',
    type: 'bruteLoss',
    color: 'red',
  },
  {
    label: 'Ожоги',
    type: 'fireLoss',
    color: 'orange',
  },
  {
    label: 'Токсины',
    type: 'toxLoss',
    color: 'green',
  },
  {
    label: 'Гипоксия',
    type: 'oxyLoss',
    color: 'blue',
  },
];

export const OperatingComputer = (props, context) => {
  const [tab, setTab] = useSharedState(context, 'tab', 1);
  return (
    <Window
      width={350}
      height={470}
      resizable>
      <Window.Content overflow="auto">
        <Tabs>
          <Tabs.Tab
            selected={tab === 1}
            onClick={() => setTab(1)}>
            Состояние пациента
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 2}
            onClick={() => setTab(2)}>
            Хирургические процедуры
          </Tabs.Tab>
        </Tabs>
        {tab === 1 && (
          <PatientStateView />
        )}
        {tab === 2 && (
          <SurgeryProceduresView />
        )}
      </Window.Content>
    </Window>
  );
};

const PatientStateView = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    table,
    procedures = [],
    patient = {},
  } = data;
  if (!table) {
    return (
      <NoticeBox>
        Хирургический стол не обнаружен
      </NoticeBox>
    );
  }
  return (
    <Fragment>
      <Section title="Состояние пациента">
        {patient && (
          <LabeledList>
            <LabeledList.Item
              label="Состояние"
              color={patient.statstate}>
              {patient.stat}
            </LabeledList.Item>
            <LabeledList.Item label="Группа крови">
              {patient.blood_type}
            </LabeledList.Item>
            <LabeledList.Item label="Здоровье">
              <ProgressBar
                value={patient.health}
                minValue={patient.minHealth}
                maxValue={patient.maxHealth}
                color={patient.health >= 0 ? 'хорошо' : 'удовлетворительно'}>
                <AnimatedNumber value={patient.health} />
              </ProgressBar>
            </LabeledList.Item>
            {damageTypes.map(type => (
              <LabeledList.Item key={type.type} label={(patient.is_robotic_organism && type.label === 'Токсины') ? 'Коррозия' : type.label}>
                <ProgressBar
                  value={patient[type.type] / patient.maxHealth}
                  color={type.color}>
                  <AnimatedNumber value={patient[type.type]} />
                </ProgressBar>
              </LabeledList.Item>
            ))}
          </LabeledList>
        ) || (
            'Пациент не обнаружен'
          )}
      </Section>
      {procedures.length === 0 && (
        <Section>
          Нет активных процедур
        </Section>
      )}
      {procedures.map(procedure => (
        <Section
          key={procedure.name}
          title={procedure.name}>
          <LabeledList>
            <LabeledList.Item label="След. процедура">
              {procedure.next_step}
            </LabeledList.Item>
            {procedure.next_step_tools.length > 0 && (
              <LabeledList.Item label={`Инструмент${procedure.next_step_tools.length > 1 ? 'ы' : ''}`}>
                {procedure.next_step_tools.join(', ')}
              </LabeledList.Item>
            )}
            {procedure.chems_needed && (
              <LabeledList.Item label="Необходимые химикаты">
                {procedure.chems_needed}
              </LabeledList.Item>
            )}
            <LabeledList.Item label="Шанс успеха">
              {procedure.next_step_chance}
            </LabeledList.Item>
            {procedure.alternative_step && (
              <Fragment>
                <Divider />
                <LabeledList.Item label="Альт. процедура">
                  {procedure.alternative_step}
                </LabeledList.Item>
                {procedure.alternative_step_tools.length > 0 && (
                  <LabeledList.Item label={`Инструмент${procedure.next_step_tools.length > 1 ? 'ы' : ''}`}>
                    {procedure.alternative_step_tools.join(', ')}
                  </LabeledList.Item>
                )}
                {procedure.alt_chems_needed && (
                  <LabeledList.Item label="Необходимые химикаты">
                    {procedure.alt_chems_needed}
                  </LabeledList.Item>
                )}
                <LabeledList.Item label="Шанс успеха">
                  {procedure.alternative_step_chance}
                </LabeledList.Item>
              </Fragment>
            )}
          </LabeledList>
        </Section>
      ))}
    </Fragment>
  );
};

const SurgeryProceduresView = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    surgeries_base = [],
    surgeries = [],
  } = data;

  return (
    <Fragment>
      <Section title="Продвинутые хирургические операции">
        <Button
          icon="download"
          content="Синхронизировать БД исследований"
          onClick={() => act('sync')} />
        {surgeries.map(surgery => (
          <Section
            title={surgery.name}
            key={surgery.name}
            level={2}>
            {surgery.desc}
          </Section>
        ))}
      </Section>

      <Section title="Базовые хирургические операции">
        {surgeries_base.map(surgery => (
          <Section
            title={surgery.name}
            key={surgery.name}
            level={2}>
            {surgery.desc}
          </Section>
        ))}
      </Section>
    </Fragment>
  );
};
