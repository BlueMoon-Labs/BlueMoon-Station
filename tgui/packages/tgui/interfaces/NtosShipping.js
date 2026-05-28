import { useBackend } from '../backend';
import { Box, Button, LabeledList, Section } from '../components';
import { NtosWindow } from '../layouts';

export const NtosShipping = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <NtosWindow
      width={450}
      height={350}>
      <NtosWindow.Content overflow="auto">
        <Section
          title="Центр доставки NTOS."
          buttons={(
            <Button
              icon="eject"
              content="Извлечь ID"
              onClick={() => act('ejectid')} />
          )}>
          <LabeledList>
            <LabeledList.Item label="Текущий пользователь">
              {data.current_user || "N/A"}
            </LabeledList.Item>
            <LabeledList.Item label="Вставленная карта">
              {data.card_owner || "N/A"}
            </LabeledList.Item>
            <LabeledList.Item label="Доступная бумага">
              {data.has_printer ? data.paperamt : "N/A"}
            </LabeledList.Item>
            <LabeledList.Item label="Прибыль от продажи">
              {data.barcode_split}%
            </LabeledList.Item>
          </LabeledList>
        </Section>
        <Section title="Настройки доставки">
          <Box>
            <Button
              icon="id-card"
              tooltip="Текущая ID-карта станет текущим пользователем."
              tooltipPosition="right"
              disabled={!data.has_id_slot}
              onClick={() => act('selectid')}
              content="Установить текущий ID" />
          </Box>
          <Box>
            <Button
              icon="print"
              tooltip="Напечатать штрих-код для упакованного товара."
              tooltipPosition="right"
              disabled={!data.has_printer || !data.current_user}
              onClick={() => act('print')}
              content="Напечатать штрих-код" />
          </Box>
          <Box>
            <Button
              icon="tags"
              tooltip="Установить желаемую прибыль с посылки."
              tooltipPosition="right"
              onClick={() => act('setsplit')}
              content="Установить маржу прибыли" />
          </Box>
          <Box>
            <Button
              icon="sync-alt"
              content="Сбросить ID"
              onClick={() => act('resetid')} />
          </Box>
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
