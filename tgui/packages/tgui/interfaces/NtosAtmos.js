import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { toFixed } from 'common/math';

import { useBackend, useLocalState } from '../backend';
import {
  LabeledList,
  ProgressBar,
  Section,
  Tabs,
} from '../components';
import { getGasColor, getGasLabel } from '../constants';
import { NtosWindow } from '../layouts';
import { AtmosHandbookContent } from './common/AtmosHandbookContent';

const TAB_SCAN = 'scan';
const TAB_HANDBOOK = 'handbook';

export const NtosAtmos = (props) => {
  const { data } = useBackend();
  const [tab, setTab] = useLocalState('tab', TAB_SCAN);
  const {
    AirTemp,
    AirPressure,
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
        {/* Тело справочника общее с отдельным окном, которое открывают консоль
            атмоса и газоанализатор: три копии разметки однажды разошлись бы. */}
        {tab === TAB_HANDBOOK && (
          <AtmosHandbookContent data={data} />
        )}
      </NtosWindow.Content>
    </NtosWindow>
  );
};
