import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Button, NoticeBox, Section, Table } from '../components';
import { Window } from '../layouts';
import { Credits, formatCredits } from './common/Economy';

type Evidence = {
  ref: string;
  name: string;
  value: number;
};

export type EvidenceLockerData = {
  can_use: BooleanLike;
  pays_here: BooleanLike;
  catalog_ready: BooleanLike;
  count: number;
  items: Evidence[];
  per_tc: number;
  default_value: number;
  premium_percent: number;
  resale_percent: number;
  cap_hour: number;
  cap_left: number;
};

const Rules = () => {
  const { data } = useBackend<EvidenceLockerData>();
  const { per_tc, default_value, premium_percent, resale_percent, cap_hour, cap_left } = data;
  return (
    <Section title="Как платит NT">
      <Box color="label">
        За переданную NT контрабанду бюджет СБ получает по текущему рынку контрабанды {formatCredits(per_tc)} за каждый
        телекристалл её цены в аплинке Синдиката ({formatCredits(default_value)}, если цены нет). Офицер, передавший
        улику, получает премию {premium_percent}% от суммы. Вместе с премией выплата не больше нынешней цены предмета на
        чёрном рынке, а за купленное там или в автомате - не больше {resale_percent}% уплаченного.
      </Box>
      <Box color="label" mt={1}>
        За час NT оплачивает изъятий не больше чем на {formatCredits(cap_hour)}, в этом часе осталось{' '}
        <Box inline bold color={cap_left > 0 ? 'good' : 'bad'}>
          {formatCredits(cap_left)}
        </Box>
        . Улика, на которую не хватает остатка, ждёт в хранилище; улику дороже часового лимита NT оплачивает по нему.
        Переданные улики уходят с рынка сектора: цены контрабанды и чёрного рынка растут.
      </Box>
      <Box color="label" mt={1}>
        Предметы, которые экипаж получает и без Синдиката (фабрикаторы, карго, автоматы, призы, снаряжение должностей и
        лоадаут), контрабандой не считаются.
      </Box>
    </Section>
  );
};

/** Хранилище улик: СБ держит контрабанду до суда, передаёт NT за выплату отделу или забирает обратно. */
export const EvidenceLockerContent = () => {
  const { act, data } = useBackend<EvidenceLockerData>();
  const { can_use, pays_here, catalog_ready, count, items, cap_left } = data;
  return (
    <>
      {!pays_here && <NoticeBox danger>Хранилище стоит вне станции: NT за улики отсюда не платит и их не забирает.</NoticeBox>}
      {!catalog_ready && <NoticeBox warning>Хранилище ещё сверяет каталог NT: улики пока не принимаются.</NoticeBox>}
      <Section title={`Улики: ${count}`}>
        {!can_use ? (
          <Box color="bad">Нет доступа: улики видит, передаёт и забирает только СБ.</Box>
        ) : items.length === 0 ? (
          <Box color="label">Хранилище пусто. Положите контрабанду рукой, чтобы сдать её на хранение.</Box>
        ) : (
          <Table>
            {items.map((item) => (
              <Table.Row key={item.ref} className="candystripe">
                <Table.Cell>{item.name}</Table.Cell>
                <Table.Cell collapsing textAlign="right" nowrap>
                  <Credits amount={item.value} />
                </Table.Cell>
                <Table.Cell collapsing nowrap>
                  <Button
                    icon="truck"
                    content="Передать NT"
                    disabled={!pays_here || item.value > cap_left}
                    onClick={() => act('hand_over', { ref: item.ref })}
                  />
                  <Button icon="eject" content="Забрать" onClick={() => act('eject', { ref: item.ref })} />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
        )}
      </Section>
      {!!pays_here && <Rules />}
    </>
  );
};

export const EvidenceLocker = () => {
  return (
    <Window width={460} height={520}>
      <Window.Content scrollable>
        <EvidenceLockerContent />
      </Window.Content>
    </Window>
  );
};
