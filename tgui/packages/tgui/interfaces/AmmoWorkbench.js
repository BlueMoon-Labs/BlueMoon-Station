import { plural } from 'common/ru/plural';
import { useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Flex,
  NoticeBox,
  NumberInput,
  ProgressBar,
  Section,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';
const plurallists = (n) => plural(n, 'лист', 'листа', 'листов');

export const AmmoWorkbench = () => {
  const [tab, setTab] = useState(1);
  return (
    <Window width={600} height={600} theme="hackerman" title="Патронный станок">
      <Window.Content scrollable>
        <Tabs>
          <Tabs.Tab selected={tab === 1} onClick={() => setTab(1)}>
            Боеприпасы
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 2} onClick={() => setTab(2)}>
            Сырьё
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 3} onClick={() => setTab(3)}>
            Диски данных
          </Tabs.Tab>
        </Tabs>
        {tab === 1 && <AmmunitionsTab />}
        {tab === 2 && <MaterialsTab />}
        {tab === 3 && <DatadiskTab />}
      </Window.Content>
    </Window>
  );
};

const AmmunitionsTab = () => {
  const { act, data } = useBackend();
  const {
    mag_loaded,
    system_busy,
    hacked,
    error,
    error_type,
    mag_name,
    turboBoost,
    current_rounds,
    max_rounds,
    efficiency,
    time,
    available_rounds = [],
  } = data;

  return (
    <>
      {!!error && (
        <NoticeBox textAlign="center" color={error_type}>
          {error}
        </NoticeBox>
      )}
      <Section
        title="Параметры станка"
        buttons={
          <Button.Checkbox
              textAlign="right"
              content="Турбо-режим"
              tooltip="Повышает скорость работы станка за счёт повышения трат сырья"
              tooltipPosition="left"
              checked={turboBoost}
              onClick={() => act('turboBoost')}
            />
        }
        >
        <Box inline mr={4}>
          Текущая эффективность: {efficiency.toFixed(1)}x
        </Box>
        <Box>Времязатраты на патрон: {time} сек.</Box>
      </Section>
      <Section
        title="Слот магазина"
        buttons={
          <>
            {!!mag_loaded && (
              <Box inline mr={2}>
                <ProgressBar
                  value={current_rounds}
                  minValue={0}
                  maxValue={max_rounds}
                />
              </Box>
            )}
            <Button
              icon="eject"
              content="Извлечь"
              disabled={!mag_loaded}
              onClick={() => act('EjectMag')}
            />
          </>
        }
      >
        {!!mag_loaded && <Box>{mag_name}</Box>}
        {!!mag_loaded && (
          <Box bold textAlign="right">
            {current_rounds} / {max_rounds}
          </Box>
        )}
      </Section>
      <Section title="Доступные виды боеприпасов">
        {!!mag_loaded && (
          <Flex.Item grow={1} basis={0}>
            {available_rounds.map((available_round) => (
              <Box
                key={available_round.name}
                className="candystripe"
                p={1}
                pb={2}
              >
                <Flex.Item>
                  <Button
                    content={available_round.name}
                    disabled={system_busy}
                    tooltip={available_round.mats_list}
                    tooltipPosition="right"
                    onClick={() =>
                      act('FillMagazine', {
                        selected_type: available_round.typepath,
                      })
                    }
                  />
                </Flex.Item>
              </Box>
            ))}
          </Flex.Item>
        )}
      </Section>
      {!!hacked && (
        <NoticeBox textAlign="center" color="bad">
          !ВНИМАНИЕ! – ПРОТОКОЛЫ БЕЗОПАСНОСТИ ARMADYNE НЕ ЗАДЕЙСТВОВАНЫ! ИСПОЛЬЗОВАНИЕ
          НЕ ПОКРЫВАЕТСЯ ГАРАНТИЕЙ. ИСПОЛЬЗОВАНИЕ НЕКОТОРЫХ ТИПОВ БОЕПРИПАСОВ МОЖЕТ ЯВЛЯТЬСЯ
          ВОЕННЫМ ПРЕСТУПЛЕНИЕМ В ВАШЕЙ ЗОНЕ. СВЯЖИТЕСЬ С АДМИНИСТРАТОРОМ ARMADYNE НЕМЕДЛЕННО.
        </NoticeBox>
      )}
    </>
  );
};

const MaterialsTab = () => {
  const { act, data } = useBackend();
  const { materials = [] } = data;

  return (
    <Section title="Сырьё">
      <Table>
        {materials.map((material) => (
          <MaterialRow
            key={material.id}
            material={material}
            onRelease={(amount) =>
              act('Release', {
                id: material.id,
                sheets: amount,
              })
            }
          />
        ))}
      </Table>
    </Section>
  );
};

const DatadiskTab = () => {
  const { act, data } = useBackend();
  const {
    loaded_datadisks = [],
    datadisk_loaded,
    datadisk_name,
    datadisk_desc,
    disk_error,
    disk_error_type,
  } = data;

  return (
    <>
      {!!disk_error && (
        <NoticeBox textAlign="center" color={disk_error_type}>
          {disk_error}
        </NoticeBox>
      )}
      <Section
        title="Диски с данными"
        buttons={
          <>
            <Button
              icon="save"
              content="Загрузить данные"
              disabled={!datadisk_loaded}
              onClick={() => act('ReadDisk')}
            />
            <Button
              icon="eject"
              content="Извлечь"
              disabled={!datadisk_loaded}
              onClick={() => act('EjectDisk')}
            />
          </>
        }
      >
        {!!datadisk_loaded && (
          <Box>
            Вставленный диск данных: {datadisk_name}
            <Box textAlign="right">
              Описание: {datadisk_desc}
            </Box>
          </Box>
        )}
      </Section>
      <Section title="Загруженные данные">
        <Table>
          {loaded_datadisks.map((loaded_datadisk) => (
            <Box key={loaded_datadisk.loaded_disk_name}>
              {loaded_datadisk.loaded_disk_name}
              <Box textAlign="right">
                Описание: {loaded_datadisk.loaded_disk_desc}
              </Box>
            </Box>
          ))}
        </Table>
      </Section>
    </>
  );
};

const MaterialRow = (props) => {
  const { material, onRelease } = props;
  const [amount, setAmount] = useState(1);
  const amountAvailable = Math.floor(material.amount);

  return (
    <Table.Row>
      <Table.Cell>{toTitleCase(material.name)}</Table.Cell>
      <Table.Cell collapsing textAlign="right">
        <Box mr={2} color="label" inline>
          {amountAvailable} {plurallists(amountAvailable)}
        </Box>
      </Table.Cell>
      <Table.Cell collapsing>
        <NumberInput
          width="32px"
          step={1}
          stepPixelSize={5}
          minValue={1}
          maxValue={50}
          value={amount}
          onChange={(e, value) => setAmount(value)}
        />
        <Button
          disabled={amountAvailable < 1}
          content="Извлечь"
          onClick={() => onRelease(amount)}
        />
      </Table.Cell>
    </Table.Row>
  );
};

// Вспомогательная функция (заимствована из Fabricator)
const toTitleCase = (str) => {
  return str.replace(/\w\S*/g, (txt) => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase());
};
