import { useBackend } from '../backend';
import { AnimatedNumber, Button, LabeledList, ProgressBar, Section } from '../components';
import { Window } from '../layouts';
import { BeakerContents } from './common/BeakerContents';

const damageTypes = [
  {
    label: "Травмы",
    type: "bruteLoss",
  },
  {
    label: "Ожоги",
    type: "fireLoss",
  },
  {
    label: "Токсины",
    type: "toxLoss",
  },
  {
    label: "Гипоксия",
    type: "oxyLoss",
  },
];

export const Cryo = () => {
  return (
    <Window
      width={400}
      height={550}>
      <Window.Content overflow="auto">
        <CryoContent />
      </Window.Content>
    </Window>
  );
};

const CryoContent = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <>
      <Section title="Пациент">
        <LabeledList>
          <LabeledList.Item label="Пациент">
            {data.occupant.name || 'Отсутствует'}
          </LabeledList.Item>
          {!!data.hasOccupant && (
            <>
              <LabeledList.Item
                label="Состояние"
                color={data.occupant.statstate}>
                {data.occupant.stat}
              </LabeledList.Item>
              <LabeledList.Item
                label="Температура"
                color={data.occupant.temperaturestatus}>
                <AnimatedNumber
                  value={data.occupant.bodyTemperature} />
                {' K'}
              </LabeledList.Item>
              <LabeledList.Item label="Здоровье">
                <ProgressBar
                  value={data.occupant.health / data.occupant.maxHealth}
                  color={data.occupant.health > 0 ? 'good' : 'average'}>
                  <AnimatedNumber
                    value={data.occupant.health} />
                </ProgressBar>
              </LabeledList.Item>
              {(damageTypes.map(damageType => (
                <LabeledList.Item
                  key={damageType.id}
                  label={damageType.label}>
                  <ProgressBar
                    value={data.occupant[damageType.type]/100}>
                    <AnimatedNumber
                      value={data.occupant[damageType.type]} />
                  </ProgressBar>
                </LabeledList.Item>
              )))}
            </>
          )}
        </LabeledList>
      </Section>
      <Section title="Капсула">
        <LabeledList>
          <LabeledList.Item label="Питание">
            <Button
              icon={data.isOperating ? "power-off" : "times"}
              disabled={data.isOpen}
              onClick={() => act('power')}
              color={data.isOperating && 'green'}>
              {data.isOperating ? "On" : "Off"}
            </Button>
          </LabeledList.Item>
          <LabeledList.Item label="Температура">
            <AnimatedNumber value={data.cellTemperature} /> K
          </LabeledList.Item>
          <LabeledList.Item label="Створки">
            <Button
              icon={data.isOpen ? "unlock" : "lock"}
              onClick={() => act('door')}
              content={data.isOpen ? "Открыты" : "Закрыты"} />
            <Button
              icon={data.autoEject ? "sign-out-alt" : "sign-in-alt"}
              onClick={() => act('autoeject')}
              content={data.autoEject ? "Auto" : "Manual"} />
          </LabeledList.Item>
        </LabeledList>
      </Section>
      <Section
        title="Внутренняя ёмкость"
        buttons={(
          <Button
            icon="eject"
            disabled={!data.isBeakerLoaded}
            onClick={() => act('ejectbeaker')}
            content="Извлечь" />
        )}>
        <BeakerContents
          beakerLoaded={data.isBeakerLoaded}
          beakerContents={data.beakerContents} />
      </Section>
    </>
  );
};
