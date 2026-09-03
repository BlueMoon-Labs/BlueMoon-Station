import { decodeHtmlEntities } from 'common/string';

import { useBackend } from '../../../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
} from '../../../components';
import { AirAlarmData, VentInfo } from '../types';

const MAX_VENT_PRESSURE = 5066;

const VentControl = (props: { readonly vent: VentInfo }) => {
  const { vent } = props;
  const { act } = useBackend();
  const {
    id_tag,
    long_name,
    power,
    checks,
    excheck,
    incheck,
    direction,
    external,
    internal,
    extdefault,
    intdefault,
  } = vent;
  return (
    <Section
      title={decodeHtmlEntities(long_name)}
      buttons={
        <Button
          icon={power ? 'power-off' : 'times'}
          selected={power}
          content={power ? 'Вкл' : 'Выкл'}
          onClick={() => act('power', { id_tag, val: Number(!power) })}
        />
      }>
      <LabeledList>
        <LabeledList.Item label="Режим">
          <Button
            icon={direction ? 'sign-in-alt' : 'sign-out-alt'}
            content={direction ? 'Нагнетание' : 'Откачка'}
            color={!direction && 'danger'}
            onClick={() => act('direction', { id_tag, val: Number(!direction) })}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Регулятор">
          <Button
            icon="sign-in-alt"
            content="По внутреннему"
            selected={incheck}
            tooltip="Следить за давлением внутри трубы"
            onClick={() => act('incheck', { id_tag, val: checks })}
          />
          <Button
            icon="sign-out-alt"
            content="По внешнему"
            selected={excheck}
            tooltip="Следить за давлением в помещении"
            onClick={() => act('excheck', { id_tag, val: checks })}
          />
        </LabeledList.Item>
        {!incheck && !excheck && (
          <LabeledList.Item label="Внимание" color="average">
            Регулятор отключён: вент гонит воздух без ограничения по давлению.
          </LabeledList.Item>
        )}
        {!!incheck && (
          <LabeledList.Item label="Порог внутри">
            <NumberInput
              value={Math.round(internal)}
              unit="кПа"
              width="75px"
              minValue={0}
              step={10}
              maxValue={MAX_VENT_PRESSURE}
              onChange={(_event, value) =>
                act('set_internal_pressure', { id_tag, value })
              }
            />
            <Button
              icon="undo"
              disabled={intdefault}
              content="Сброс"
              onClick={() => act('reset_internal_pressure', { id_tag })}
            />
          </LabeledList.Item>
        )}
        {!!excheck && (
          <LabeledList.Item label="Порог снаружи">
            <NumberInput
              value={Math.round(external)}
              unit="кПа"
              width="75px"
              minValue={0}
              step={10}
              maxValue={MAX_VENT_PRESSURE}
              onChange={(_event, value) =>
                act('set_external_pressure', { id_tag, value })
              }
            />
            <Button
              icon="undo"
              disabled={extdefault}
              content="Сброс"
              onClick={() => act('reset_external_pressure', { id_tag })}
            />
          </LabeledList.Item>
        )}
      </LabeledList>
    </Section>
  );
};

export const Vents = () => {
  const { act, data } = useBackend<AirAlarmData>();
  const vents = data.vents || [];
  if (vents.length === 0) {
    return <NoticeBox>В этой зоне нет вентиляторов на этой частоте.</NoticeBox>;
  }
  return (
    <>
      <Box mb={1}>
        <Button
          icon="power-off"
          content="Включить все"
          onClick={() => act('power_all', { target: 'vents', val: 1 })}
        />
        <Button
          icon="times"
          content="Выключить все"
          onClick={() => act('power_all', { target: 'vents', val: 0 })}
        />
      </Box>
      {vents.map((vent) => (
        <VentControl key={vent.id_tag} vent={vent} />
      ))}
    </>
  );
};
