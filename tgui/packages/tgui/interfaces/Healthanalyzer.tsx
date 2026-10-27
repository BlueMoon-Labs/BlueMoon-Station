import { BooleanLike } from 'common/react';
import { Fragment, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, LabeledList, NoticeBox, ProgressBar, Section, Stack, Table } from '../components';
import { Window } from '../layouts';

type ScanLine = { text: string; warning: BooleanLike };
type ScanSection = { title: string; lines: ScanLine[] };
type Wound = { name: string; severity: string; treatment: string };
type Limb = {
  name: string;
  missing: BooleanLike;
  brute: number;
  burn: number;
  wounds: Wound[];
  embeds: string[];
};
type Organ = { name: string; damage: number | null; status: string; warning: BooleanLike };
type Reagent = { name: string; volume: number; overdosed: BooleanLike; inactive: BooleanLike };
type Scan = {
  patient: string;
  scanTime: string;
  scanmode: number;
  verbose: BooleanLike;
  health: number;
  dead: BooleanLike;
  unknown: BooleanLike;
  robotic: BooleanLike;
  damageLevels: Record<string, number>;
  damageLocalization: Limb[];
  organs: Organ[];
  sections: ScanSection[];
  reagents: Reagent[];
  blood?: { percent: number; volume: number; incoming: number; low: BooleanLike; critical: BooleanLike };
};
type HealthanalyzerData = { advanced: BooleanLike; printing: BooleanLike; scan: Scan | null };

const scanModes = ['Здоровье', 'Реагенты', 'Раны'];
const damageTypes = [
  { key: 'brute', label: 'Травмы', color: 'red' },
  { key: 'burn', label: 'Ожоги', color: 'orange' },
  { key: 'tox', label: 'Токсины', color: 'green' },
  { key: 'oxy', label: 'Удушение', color: 'blue' },
];
const prioritySections = ['Общая диагностика', 'Органы и радиация', 'Жизненные показатели и операции'];

export const Healthanalyzer = () => {
  const { act, data } = useBackend<HealthanalyzerData>();
  const { scan, advanced, printing } = data;
  return (
    <Window title="Анализатор здоровья" width={620} height={740}>
      <Window.Content scrollable>
        <Section buttons={(
          <>
            <Button icon="comment-medical" disabled={!scan} onClick={() => act('chat')}>В чат</Button>
            {!!advanced && (
              <Button icon="print" disabled={!scan || !!printing} onClick={() => act('print')}>
                {printing ? 'Печать…' : 'Печать'}
              </Button>
            )}
            <Button.Confirm icon="trash" disabled={!scan} confirmContent="Очистить?" onClick={() => act('clear')}>Очистить</Button.Confirm>
          </>
        )} title={scan ? scanModes[scan.scanmode] : 'Нет данных'}>
          {scan ? (
            <>
              <Box bold fontSize={1.3}>{scan.patient}</Box>
              <Box color="label" mt={0.5}>Снимок от {scan.scanTime} · {advanced ? 'Продвинутый' : 'Обычный'} анализатор</Box>
            </>
          ) : (
            <NoticeBox>Просканируйте пациента, чтобы получить отчёт. Ctrl-Click по анализатору открывает последний снимок.</NoticeBox>
          )}
        </Section>
        {scan && <ScanResults key={`${scan.scanTime}-${scan.patient}-${scan.scanmode}`} scan={scan} advanced={!!advanced} />}
      </Window.Content>
    </Window>
  );
};

const ScanResults = ({ scan, advanced }: { scan: Scan; advanced: boolean }) => {
  const [showLimbs, setShowLimbs] = useState(!!scan.verbose);
  const { blood } = scan;
  return (
    <>
      {scan.scanmode === 0 && (
        <>
          <Section title="Состояние пациента">
            <LabeledList>
              <LabeledList.Item label="Общее состояние">
                {scan.unknown ? <Box color="average">Неизвестно</Box> : scan.dead ? (
                  <Box bold color="bad">Смерть</Box>
                ) : (
                  <ProgressBar value={scan.health / 100} color={scan.health > 50 ? 'good' : scan.health > 0 ? 'average' : 'bad'}>
                    {scan.health} %
                  </ProgressBar>
                )}
              </LabeledList.Item>
              {damageTypes.map(({ key, label, color }) => (
                <LabeledList.Item key={key} label={key === 'tox' && scan.robotic ? 'Коррозия' : label}>
                  <ProgressBar value={scan.damageLevels[key] / 100} color={color}>{scan.damageLevels[key]}</ProgressBar>
                </LabeledList.Item>
              ))}
              {blood && (
                <LabeledList.Item label={scan.robotic ? 'Гидравлическая жидкость' : 'Кровь'}>
                  <ProgressBar value={blood.percent / 100} color={blood.critical ? 'bad' : blood.low ? 'average' : 'good'}>
                    {blood.critical ? 'КРИТИЧЕСКИЙ УРОВЕНЬ · ' : blood.low ? 'НИЗКИЙ УРОВЕНЬ · ' : ''}
                    {blood.percent} % · {blood.volume} сл
                  </ProgressBar>
                  {blood.incoming > 0 && <Box mt={0.5}>Переливается ещё {blood.incoming} сл</Box>}
                </LabeledList.Item>
              )}
            </LabeledList>
          </Section>
          <DiagnosticSections sections={scan.sections.filter(section => prioritySections.includes(section.title))} />
          <Section title="Повреждения конечностей" buttons={(
            <Button icon="bone" selected={showLimbs} onClick={() => setShowLimbs(!showLimbs)}>
              {showLimbs ? 'Скрыть' : 'Показать'}
            </Button>
          )}>
            {showLimbs ? <LimbTable limbs={scan.damageLocalization} /> : <Box color="label">Подробная локализация скрыта.</Box>}
          </Section>
          {scan.organs.length > 0 && (
            <Section title="Состояние органов">
              <Table>
                <Table.Row header>
                  <Table.Cell>Орган</Table.Cell>
                  {advanced && <Table.Cell>Урон</Table.Cell>}
                  <Table.Cell>Диагностика</Table.Cell>
                </Table.Row>
                {scan.organs.map((organ, index) => (
                  <Table.Row key={index}>
                    <Table.Cell verticalAlign="top" pr={1}>{organ.name}</Table.Cell>
                    {advanced && <Table.Cell verticalAlign="top" pr={1}>{organ.damage}</Table.Cell>}
                    <Table.Cell pb={1} color={organ.warning ? 'bad' : undefined}>{organ.status}</Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          )}
        </>
      )}
      {scan.scanmode === 1 && scan.reagents.length > 0 && (
        <Section title="Реагенты в организме">
          <Table>
            <Table.Row header><Table.Cell>Реагент</Table.Cell><Table.Cell>Объём</Table.Cell><Table.Cell>Состояние</Table.Cell></Table.Row>
            {scan.reagents.map((reagent, index) => (
              <Table.Row key={index} color={reagent.overdosed ? 'bad' : reagent.inactive ? 'label' : undefined}>
                <Table.Cell>{reagent.name}</Table.Cell>
                <Table.Cell>{reagent.volume} ед.</Table.Cell>
                <Table.Cell>{reagent.overdosed ? 'ПЕРЕДОЗИРОВКА' : reagent.inactive ? 'Не усваивается' : 'Усваивается'}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        </Section>
      )}
      <DiagnosticSections sections={scan.sections.filter(section =>
        !(scan.scanmode === 0 && prioritySections.includes(section.title))
        && !(scan.scanmode === 1 && scan.reagents.length > 0 && section.title === 'Реагенты в организме'))} />
      <Box color="label" textAlign="center" mb={1}>Это сохранённый снимок. Для новых показателей просканируйте пациента ещё раз.</Box>
    </>
  );
};

const DiagnosticSections = ({ sections }: { sections: ScanSection[] }) => (
  <>
    {sections.map((section, index) => (
      <Section key={index} title={section.title}>
        {section.lines.map((line, lineIndex) => (
          <Box key={lineIndex} mb={lineIndex < section.lines.length - 1 ? 0.7 : 0} color={line.warning ? 'bad' : undefined}>
            {line.text}
          </Box>
        ))}
      </Section>
    ))}
  </>
);

const LimbTable = ({ limbs }: { limbs: Limb[] }) => {
  if (!limbs.length) {
    return <Box color="label">Локализация повреждений недоступна для этого организма.</Box>;
  }
  return (
    <Table>
      <Table.Row header><Table.Cell>Часть тела</Table.Cell><Table.Cell>Травмы</Table.Cell><Table.Cell>Ожоги</Table.Cell></Table.Row>
      {limbs.map(limb => (
        <Fragment key={limb.name}>
          <Table.Row>
            <Table.Cell bold>{limb.name}</Table.Cell>
            <Table.Cell color={limb.brute > 0 ? 'bad' : 'label'}>{limb.missing ? '—' : limb.brute}</Table.Cell>
            <Table.Cell color={limb.burn > 0 ? 'average' : 'label'}>{limb.missing ? '—' : limb.burn}</Table.Cell>
          </Table.Row>
          {limb.missing && (
            <Table.Row><Table.Cell colSpan={3}><NoticeBox danger>Отсутствует. Требуется хирургическое присоединение или протезирование.</NoticeBox></Table.Cell></Table.Row>
          )}
          {limb.embeds.map((embed, index) => (
            <Table.Row key={`embed-${index}`}><Table.Cell colSpan={3} color="bad">Инородное тело: {embed}. Извлеките хирургическим зажимом.</Table.Cell></Table.Row>
          ))}
          {limb.wounds.map((wound, index) => (
            <Table.Row key={`wound-${index}`}>
              <Table.Cell colSpan={3}>
                <Stack vertical my={0.5}>
                  <Stack.Item bold color="bad">{wound.name} · {wound.severity}</Stack.Item>
                  <Stack.Item>Лечение: {wound.treatment}</Stack.Item>
                </Stack>
              </Table.Cell>
            </Table.Row>
          ))}
        </Fragment>
      ))}
    </Table>
  );
};
