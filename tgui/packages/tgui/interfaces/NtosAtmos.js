import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { toFixed } from 'common/math';

import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Collapsible,
  LabeledList,
  ProgressBar,
  Section,
  Tabs,
} from '../components';
import { getGasColor, getGasLabel } from '../constants';
import { NtosWindow } from '../layouts';

const TAB_SCAN = 'scan';
const TAB_HANDBOOK = 'handbook';

export const NtosAtmos = (props) => {
  const { data } = useBackend();
  const [tab, setTab] = useLocalState('tab', TAB_SCAN);
  const {
    AirTemp,
    AirPressure,
    reactionInfo = [],
    gasInfo = [],
  } = data;
  const gases = flow([
    filter(gas => gas.percentage >= 0.01),
    sortBy(gas => -gas.percentage),
  ])(data.AirData || []);
  const gasMaxPercentage = Math.max(1, ...gases.map(gas => gas.percentage));

  return (
    <NtosWindow
      width={420}
      height={480}>
      <NtosWindow.Content overflow="auto">
        <Tabs>
          <Tabs.Tab
            selected={tab === TAB_SCAN}
            onClick={() => setTab(TAB_SCAN)}>
            Сканер
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === TAB_HANDBOOK}
            onClick={() => setTab(TAB_HANDBOOK)}>
            Справочник
          </Tabs.Tab>
        </Tabs>
        {tab === TAB_SCAN && (
          <>
            <Section>
              <LabeledList>
                <LabeledList.Item label="Температура">
                  {AirTemp}°C
                </LabeledList.Item>
                <LabeledList.Item label="Давление">
                  {AirPressure} kPa
                </LabeledList.Item>
              </LabeledList>
            </Section>
            <Section>
              <LabeledList>
                {gases.map(gas => (
                  <LabeledList.Item
                    key={gas.name}
                    label={getGasLabel(gas.name)}>
                    <ProgressBar
                      color={getGasColor(gas.name)}
                      value={gas.percentage}
                      minValue={0}
                      maxValue={gasMaxPercentage}>
                      {toFixed(gas.percentage, 2) + '%'}
                    </ProgressBar>
                  </LabeledList.Item>
                ))}
              </LabeledList>
            </Section>
          </>
        )}
        {tab === TAB_HANDBOOK && (
          <Section title="Реакции">
            {reactionInfo.map(reaction => (
              <Collapsible
                key={reaction.id}
                title={reaction.disabled
                  ? `${reaction.name} (отключена)`
                  : reaction.name}
                color="transparent">
                {reaction.description && (
                  <Box mb={1} color="label">
                    {reaction.description}
                  </Box>
                )}
                <LabeledList>
                  {(reaction.factors || []).map((factor, index) => (
                    <LabeledList.Item
                      key={`${reaction.id}-${index}`}
                      label={factor.factor_name}
                      tooltip={factor.tooltip}>
                      {factor.desc}
                    </LabeledList.Item>
                  ))}
                </LabeledList>
              </Collapsible>
            ))}
            {!!gasInfo.length && (
              <Section title="Газы" mt={1}>
                {gasInfo.map(gas => (
                  <Collapsible
                    key={gas.id}
                    title={gas.name}
                    color="transparent">
                    <LabeledList>
                      <LabeledList.Item label="ID">
                        {gas.id}
                      </LabeledList.Item>
                      <LabeledList.Item label="Теплоёмкость">
                        {gas.specific_heat}
                      </LabeledList.Item>
                      {!!Object.keys(gas.reactions || {}).length && (
                        <LabeledList.Item label="Реакции">
                          {Object.values(gas.reactions).join(', ')}
                        </LabeledList.Item>
                      )}
                    </LabeledList>
                  </Collapsible>
                ))}
              </Section>
            )}
          </Section>
        )}
      </NtosWindow.Content>
    </NtosWindow>
  );
};
