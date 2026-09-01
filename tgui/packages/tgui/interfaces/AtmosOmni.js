import { useBackend } from '../backend';
import { Box, Button, Dropdown, LabeledList, NumberInput, Section } from '../components';
import { getGasLabel } from '../constants';
import { Window } from '../layouts';
import { formatPressure, formatTemperature } from './common/AtmosPorts';

export const AtmosOmni = (props) => {
  const { act, data } = useBackend();
  const ports = data.ports || [];
  const filterTypes = data.filter_types || [];
  const isFilter = data.kind === 'filter';
  return (
    <Window width={510} height={isFilter ? 340 : 300}>
      <Window.Content scrollable>
        <Section>
          <LabeledList>
            <LabeledList.Item label="Питание">
              <Button
                icon="power-off"
                content={data.on ? 'Вкл' : 'Выкл'}
                selected={data.on}
                onClick={() => act('power')} />
            </LabeledList.Item>
            <LabeledList.Item label={data.setting_label}>
              <NumberInput
                animated
                value={data.setting}
                unit={data.setting_unit}
                width="82px"
                minValue={0}
                maxValue={data.setting_max}
                onChange={(e, value) => act('setting', { value })} />
              <Button
                ml={1}
                content="Макс"
                onClick={() => act('setting', { value: 'max' })} />
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Порты">
          {ports.map(port => (
            <LabeledList key={port.index}>
              <LabeledList.Item label={port.name}>
                <Button
                  selected={port.role === 'input'}
                  content="Вход"
                  onClick={() => act('role', { index: port.index, role: 'input' })} />
                <Button
                  selected={port.role === 'output'}
                  content={isFilter ? 'Чистый выход' : 'Выход'}
                  onClick={() => act('role', { index: port.index, role: 'output' })} />
                {isFilter && (
                  <Button
                    selected={port.role === 'filter'}
                    content="Фильтрат"
                    onClick={() => act('role', { index: port.index, role: 'filter' })} />
                )}
                <Button
                  selected={port.role === 'disabled'}
                  content="Отключен"
                  onClick={() => act('role', { index: port.index, role: 'disabled' })} />
                {/* Подпись выбранного газа Dropdown берёт из самих options;
                    свой displayText нужен только пока газ не выбран. */}
                {isFilter && port.role === 'filter' && (
                  <Dropdown
                    ml={1}
                    width="160px"
                    selected={port.gas}
                    displayText={port.gas ? undefined : 'Выбрать газ'}
                    options={filterTypes.map(gas => ({
                      value: gas.id,
                      displayText: getGasLabel(gas.id, gas.name),
                    }))}
                    onSelected={value => act('gas', {
                      index: port.index,
                      gas: value,
                    })} />
                )}
                {!isFilter && port.role === 'input' && (
                  <NumberInput
                    ml={1}
                    animated
                    value={port.concentration}
                    unit="%"
                    width="65px"
                    minValue={0}
                    maxValue={100}
                    onChange={(e, value) => act('concentration', {
                      index: port.index,
                      value,
                    })} />
                )}
                {/* Что реально стоит на порту: роль без показаний
                    настраивается вслепую. */}
                <Box mt={0.5} color={port.connected ? 'label' : 'average'}>
                  {port.connected
                    ? `${formatPressure(port.pressure)} · ${formatTemperature(port.temperature)}`
                    : 'Труба не подключена'}
                </Box>
              </LabeledList.Item>
            </LabeledList>
          ))}
        </Section>
      </Window.Content>
    </Window>
  );
};
