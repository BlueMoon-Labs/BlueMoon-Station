import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Button, LabeledList, NoticeBox, Section } from '../components';
import { Window } from '../layouts';
import { formatCredits } from './common/Economy';

export type PowerExportNodeData = {
  active: BooleanLike;
  connected: BooleanLike;
  panel_open: BooleanLike;
  on_station: BooleanLike;
  target_kw: number;
  max_kw: number;
  step_kw: number;
  station_cap_kw: number;
  export_w: number;
  surplus_w: number;
  base_price_per_mj: number;
  market_percent: number;
  price_per_mj: number;
  income_per_minute: number;
  payout_minutes: number;
  payout_bulk: number;
  demand_percent: number;
  demand_floor_percent: number;
  demand_recovery_percent: number;
  shift_minutes: number;
};

const WATTS_PER_KILOWATT = 1000;

const formatKw = (watts: number) => `${Math.round(watts / WATTS_PER_KILOWATT)} кВт`;

/** Узел экспорта энергии: продаёт излишек станционной сети сектору, доход - в бюджет инженерии. */
export const PowerExportNodeContent = () => {
  const { act, data } = useBackend<PowerExportNodeData>();
  const {
    active,
    connected,
    panel_open,
    on_station,
    target_kw,
    max_kw,
    step_kw,
    station_cap_kw,
    export_w,
    surplus_w,
    base_price_per_mj,
    market_percent,
    price_per_mj,
    income_per_minute,
    payout_minutes,
    payout_bulk,
    demand_percent,
    demand_floor_percent,
    demand_recovery_percent,
    shift_minutes,
  } = data;
  const overdraw = target_kw > 0 && target_kw * WATTS_PER_KILOWATT > surplus_w;
  const surplusKw = Math.min(Math.floor(surplus_w / WATTS_PER_KILOWATT / step_kw) * step_kw, max_kw);
  return (
    <>
      {!connected && <NoticeBox danger>Под узлом нет кабеля: подключите его к сети гаечным ключом.</NoticeBox>}
      {!!panel_open && <NoticeBox warning>Панель открыта: продажа остановлена.</NoticeBox>}
      {!on_station && (
        <NoticeBox danger>Узел стоит вне станции: сектор покупает энергию только из станционной сети.</NoticeBox>
      )}
      <Section
        title="Экспорт энергии"
        buttons={
          <Button
            icon="power-off"
            selected={active}
            content={active ? 'Включён' : 'Выключен'}
            onClick={() => act('toggle')}
          />
        }>
        <LabeledList>
          <LabeledList.Item label="Отбор">
            <Button
              icon="minus"
              disabled={target_kw <= 0}
              onClick={() => act('set_draw', { kw: target_kw - step_kw })}
            />
            <Box inline bold mx={1}>
              {target_kw} кВт
            </Box>
            <Button
              icon="plus"
              disabled={target_kw >= max_kw}
              onClick={() => act('set_draw', { kw: target_kw + step_kw })}
            />
            <Button ml={1} content="По излишку" onClick={() => act('set_draw', { kw: surplusKw })} />
            <Button content="Максимум" onClick={() => act('set_draw', { kw: max_kw })} />
          </LabeledList.Item>
          <LabeledList.Item label="Излишек сети">{formatKw(surplus_w)}</LabeledList.Item>
          <LabeledList.Item label="Продаётся">{formatKw(export_w)}</LabeledList.Item>
          <LabeledList.Item label="Цена">
            {formatCredits(price_per_mj, { decimals: 2 })} за МДж ({formatCredits(base_price_per_mj, { decimals: 2 })}{' '}
            × рынок энергии {market_percent}%)
          </LabeledList.Item>
          <LabeledList.Item label="Спрос сектора">{demand_percent}%</LabeledList.Item>
          <LabeledList.Item label="Доход">~{formatCredits(income_per_minute)} в минуту в бюджет инженерии</LabeledList.Item>
        </LabeledList>
        {overdraw && (
          <NoticeBox danger mt={1}>
            Сеть не тянет: заданная мощность выше излишка. Недостающее всё равно тянется из сети - станция проседает,
            APC садят батареи, а узел искрит.
          </NoticeBox>
        )}
      </Section>
      <Section title="Как платит сектор">
        <Box color="label">
          Узел продаёт только то, что осталось в сети после всех потребителей и зарядки СМЕС, шагом {step_kw} кВт, до{' '}
          {max_kw} кВт. Цена следует рынку энергии и падает от объёма: каждая продажа сбивает спрос сектора, и цена
          опускается вплоть до {demand_floor_percent}% рыночной. Без продаж спрос возвращается на {demand_recovery_percent}% каждые ~
          {shift_minutes} мин. Узел продаёт только из станционной сети. Сектор оплачивает не больше {station_cap_kw} кВт со всех узлов
          станции вместе, сверх этого энергия уходит бесплатно. Доход приходит в бюджет инженерии не реже раза в{' '}
          {payout_minutes} мин., а при сумме от {formatCredits(payout_bulk)} - сразу.
        </Box>
      </Section>
    </>
  );
};

export const PowerExportNode = () => {
  return (
    <Window width={440} height={420}>
      <Window.Content scrollable>
        <PowerExportNodeContent />
      </Window.Content>
    </Window>
  );
};
