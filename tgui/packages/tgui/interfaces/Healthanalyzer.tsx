import { round } from 'common/math';
import { BooleanLike } from 'common/react';
import { decodeHtmlEntities } from 'common/string';
import { Fragment, useLayoutEffect, useRef, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Icon, LabeledList, NoticeBox, ProgressBar, Section, Table } from '../components';
import { Window } from '../layouts';

type ScanLine = { text: string; warning: BooleanLike };
type ScanSection = { title: string; lines: ScanLine[] };
type Wound = { name: string; icon: string; severity: string; treatment: string; details: string };
type Limb = { name: string; missing: BooleanLike; missingIcon?: string; brute: number; burn: number; wounds: Wound[]; embeds: string[] };
type Organ = { name: string; icon: string; damage: number | null; status: string; warning: BooleanLike; critical: BooleanLike };
type Reagent = { name: string; volume: number; overdosed: BooleanLike; inactive: BooleanLike };
type Scan = {
  scanTime: string;
  woundOnly?: BooleanLike;
  chemicalOnly?: BooleanLike;
  health: number;
  dead: BooleanLike;
  unknown: BooleanLike;
  robotic: BooleanLike;
  species?: string;
  similarSpecies?: string;
  temperatureC?: number;
  temperatureF?: number;
  diagnosis?: ScanLine[];
  damageLevels?: Record<string, number>;
  damageLocalization?: Limb[];
  organs?: Organ[];
  missingOrgans?: { name: string; icon: string }[];
  sections: ScanSection[];
  reagents?: Reagent[];
  addictions?: string[];
  blood?: { percent: number; volume: number; incoming: number; type: string; low: BooleanLike; critical: BooleanLike };
};
type HealthanalyzerData = { advanced: BooleanLike; printing: BooleanLike; scanNumber: number; scan: Scan | null; live?: BooleanLike; canPrint?: BooleanLike; canClear?: BooleanLike; deviceLabel?: string };

const damageTypes = [
  { key: 'brute', label: 'Травмы', color: 'red' },
  { key: 'burn', label: 'Ожоги', color: 'orange' },
  { key: 'tox', label: 'Токсины', color: 'green' },
  { key: 'oxy', label: 'Удушение', color: 'blue' },
];

export const Healthanalyzer = () => {
  const { act, data } = useBackend<HealthanalyzerData>();
  const { scan, advanced, printing, scanNumber, live = false, canPrint = advanced, canClear = true, deviceLabel } = data;
  return (
    <Window title={live ? 'Мониторинг организма' : 'Анализатор здоровья'} width={570} height={780}>
      <Window.Content scrollable>
        <Section title="Медицинский отчёт" buttons={(
          <>
            <Button icon="comment-medical" disabled={!scan} onClick={() => act('chat')}>Текстом</Button>
            {!!canPrint && (
              <Button icon="print" disabled={!scan || !!printing} onClick={() => act('print')}>
                {printing ? 'Печать…' : 'Печать'}
              </Button>
            )}
            {!!canClear && <Button.Confirm icon="trash" disabled={!scan} content="Очистить" confirmContent="Очистить?" onClick={() => act('clear')} />}
          </>
        )}>
          {scan ? (
            <>
              {(!!scan.species || scan.temperatureC !== undefined) && (
                <Box mb={0.5}>
                  {!!scan.species && <>Раса: {scan.species}</>}
                  {!!scan.species && !!scan.similarSpecies && scan.similarSpecies !== scan.species && <> | Схожая раса: {scan.similarSpecies}</>}
                  {scan.temperatureC !== undefined && <>{scan.species ? ' | ' : ''}Температура тела: {round(scan.temperatureC, 3)} °C ({round(scan.temperatureF, 3)} °F)</>}
                </Box>
              )}
              {!!scan.damageLevels && <VitalSigns scan={scan} />}
            </>
          ) : <NoticeBox>В памяти нет результатов обследования. Просканируйте пациента.</NoticeBox>}
        </Section>
        {scan && <ScanResults key={scanNumber} scan={scan} advanced={!!advanced} live={!!live} deviceLabel={deviceLabel} />}
      </Window.Content>
    </Window>
  );
};

const VitalSigns = ({ scan }: { scan: Scan }) => (
  <LabeledList>
    {!!scan.unknown && <LabeledList.Item label="Общее состояние"><Box color="average">Неизвестно</Box></LabeledList.Item>}
    {damageTypes.map(({ key, label, color }) => (
      <LabeledList.Item key={key} label={key === 'tox' && scan.robotic ? 'Коррозия' : label}>
        <ProgressBar value={scan.damageLevels![key] / 100} color={color}>{round(scan.damageLevels![key], 3)}</ProgressBar>
      </LabeledList.Item>
    ))}
    {!!scan.blood && (
      <LabeledList.Item label={scan.robotic ? 'Гидравлическая жидкость' : 'Кровь'}>
        <ProgressBar value={scan.blood.percent / 100} color={scan.blood.critical ? 'bad' : scan.blood.low ? 'average' : 'good'}>
          {scan.blood.critical ? 'КРИТИЧЕСКИЙ УРОВЕНЬ · ' : scan.blood.low ? 'НИЗКИЙ УРОВЕНЬ · ' : ''}
          {round(scan.blood.percent, 1)} % · {round(scan.blood.volume, 3)} cl · {scan.blood.type}
        </ProgressBar>
        {scan.blood.incoming > 0 && <Box mt={0.5}>Переливается ещё {round(scan.blood.incoming, 3)} cl</Box>}
      </LabeledList.Item>
    )}
    {!!scan.diagnosis?.length && (
      <LabeledList.Item label="Диагностика"><ScanLines lines={scan.diagnosis} compact /></LabeledList.Item>
    )}
  </LabeledList>
);

const ScanResults = ({ scan, advanced, live, deviceLabel = advanced ? 'Продвинутый анализатор' : 'Обычный анализатор' }: { scan: Scan; advanced: boolean; live: boolean; deviceLabel?: string }) => {
  const sections = scan.sections.filter(section => section.title !== 'Реагенты в организме');
  return (
    <>
      {!scan.woundOnly && !scan.chemicalOnly && (
        <Section title="Состояние тела">
          <LimbTable scan={scan} />
        </Section>
      )}
      {(!!scan.organs?.length || !!scan.missingOrgans?.length) && (
        <Section title="Состояние органов">
          {!!scan.organs?.length && (
            <Table>
              <Table.Row header><Table.Cell collapsing>Орган</Table.Cell>{advanced && <Table.Cell collapsing>Повреждения</Table.Cell>}<Table.Cell>Диагностика</Table.Cell></Table.Row>
              {scan.organs.map((organ, index) => (
                <Table.Row key={index} bold={!!organ.critical} className={organ.critical ? 'Healthanalyzer__organCritical' : undefined}>
                  <Table.Cell collapsing verticalAlign="top" pr={1}>
                    {!!organ.icon && <img className="Healthanalyzer__organIcon" src={`data:image/png;base64,${organ.icon}`} alt="" />}
                    {organ.name}
                  </Table.Cell>
                  {advanced && <Table.Cell collapsing verticalAlign="top" pr={1} color={organ.critical ? undefined : 'bad'}>{round(organ.damage, 0)}%</Table.Cell>}
                  <Table.Cell className="Healthanalyzer__organDiagnosis" verticalAlign="top" pb={0.5} color={!organ.critical && organ.warning ? 'bad' : undefined}>{decodeHtmlEntities(organ.status)}</Table.Cell>
                </Table.Row>
              ))}
            </Table>
          )}
          {!!scan.missingOrgans?.length && (
            <Box bold color="bad" mt={scan.organs?.length ? 0.5 : 0}>
              Отсутствует: {scan.missingOrgans.map((organ, index) => (
                <Fragment key={index}>
                  {index > 0 && ', '}
                  <span className="Healthanalyzer__missingOrgan">
                    <img className="Healthanalyzer__organIcon" src={`data:image/png;base64,${organ.icon}`} alt="" />
                    {organ.name}
                  </span>
                </Fragment>
              ))}
            </Box>
          )}
        </Section>
      )}
      {sections.map((section, index) => (
        <Section key={index} title={section.title}><ScanLines lines={section.lines} /></Section>
      ))}
      {!scan.woundOnly && scan.reagents !== undefined && <Reagents reagents={scan.reagents} addictions={scan.addictions || []} />}
      <Box color="label" textAlign="center" mt={0.8} mb={0.5}>{live ? 'Последнее обновление:' : 'Снимок от'} {scan.scanTime}{deviceLabel && ` · ${deviceLabel}`}</Box>
      <Box color="label" textAlign="center" mb={1}>{live ? 'Показатели обновляются автоматически.' : 'Для обновления показателей проведите повторное обследование.'}</Box>
    </>
  );
};

const ScanLines = ({ lines, compact = false }: { lines: ScanLine[]; compact?: boolean }) => (
  <Box>
    {lines.map((line, index) => (
      <Fragment key={index}>
        {compact && index > 0 && ' · '}
        <Box as={compact ? 'span' : 'div'} mb={compact ? 0 : 0.4} color={line.warning ? 'bad' : undefined}>
          {decodeHtmlEntities(line.text)}
        </Box>
      </Fragment>
    ))}
  </Box>
);

const Reagents = ({ reagents, addictions }: { reagents: Reagent[]; addictions: string[] }) => (
  <Section title="Реагенты в организме">
    {reagents.length > 0 ? (
      <Table>
        <Table.Row header><Table.Cell>Реагент</Table.Cell><Table.Cell>Объём</Table.Cell><Table.Cell /></Table.Row>
        {reagents.map((reagent, index) => (
          <Table.Row key={index} color={reagent.overdosed ? 'bad' : reagent.inactive ? 'label' : undefined}>
            <Table.Cell>{reagent.name}</Table.Cell><Table.Cell>{round(reagent.volume, 3)} u</Table.Cell>
            <Table.Cell>{reagent.overdosed ? 'ПЕРЕДОЗИРОВКА' : ''}</Table.Cell>
          </Table.Row>
        ))}
      </Table>
    ) : <Box color="label">Реагенты не обнаружены.</Box>}
    <Box mt={0.7} color={addictions.length > 0 ? 'bad' : 'label'}>
      {addictions.length > 0 ? `Зависимости: ${addictions.join(', ')}.` : 'Химические зависимости не обнаружены.'}
    </Box>
  </Section>
);

const LimbTable = ({ scan }: { scan: Scan }) => {
  const limbs = scan.damageLocalization || [];
  const affected = limbs.filter(limb => !!limb.missing || limb.brute > 0 || limb.burn > 0 || limb.wounds.length > 0 || limb.embeds.length > 0);
  return (
    <Box>
      <Box className="Healthanalyzer__limbRow" bold>
        <Box />
        {damageTypes.map(({ key, label, color }) => (
          <Box key={key} color={color}>{key === 'tox' && scan.robotic ? 'Коррозия' : label}</Box>
        ))}
      </Box>
      <Box className="Healthanalyzer__limbRow" mb={0.3}>
        <Box bold>Всего</Box>
        {damageTypes.map(({ key, color }) => (
          <Box key={key} bold color={round(scan.damageLevels?.[key] ?? 0, 3) === 0 ? 'label' : color}>{round(scan.damageLevels?.[key] ?? 0, 3)}</Box>
        ))}
      </Box>
      {affected.map(limb => (
        <Fragment key={limb.name}>
          {limb.missing ? (
            <Box bold color="bad">
              {!!limb.missingIcon && <Icon name={limb.missingIcon} mr={0.5} />}
              {limb.name} отсутствует
            </Box>
          ) : (
            <Box className="Healthanalyzer__limbRow">
              <Box>{limb.name}</Box>
              <Box bold color={round(limb.brute, 3) === 0 ? 'label' : 'red'}>{round(limb.brute, 3)}</Box>
              <Box bold color={round(limb.burn, 3) === 0 ? 'label' : 'orange'}>{round(limb.burn, 3)}</Box>
            </Box>
          )}
          {limb.embeds.map((embed, index) => (
            <Box key={`embed-${index}`} color="bad">Инородное тело: {embed}.</Box>
          ))}
          {limb.wounds.map((wound, index) => (
            <Box key={`wound-${wound.name}-${index}`}><WoundHint wound={wound} /></Box>
          ))}
        </Fragment>
      ))}
      {!affected.length && <Box color="good">Повреждения конечностей не обнаружены.</Box>}
    </Box>
  );
};

const WoundHint = ({ wound }: { wound: Wound }) => {
  const anchor = useRef<HTMLSpanElement>(null);
  const tooltip = useRef<HTMLDivElement>(null);
  const [hovered, setHovered] = useState(false);
  const [expanded, setExpanded] = useState(false);
  const visible = hovered || expanded;
  useLayoutEffect(() => {
    if (!visible) return;
    const place = () => {
      const root = anchor.current;
      const popup = tooltip.current;
      if (!root || !popup) return;
      const rect = root.getBoundingClientRect();
      const container = root.closest('.Layout__content')?.getBoundingClientRect();
      const bounds = { left: Math.max(0, container?.left || 0), top: Math.max(0, container?.top || 0), right: Math.min(window.innerWidth, container?.right || window.innerWidth), bottom: Math.min(window.innerHeight, container?.bottom || window.innerHeight) };
      // Подсказка остаётся под тем же CSS zoom; экранные отступы переводим в локальные пиксели.
      const scale = rect.width / root.offsetWidth || 1;
      const padding = 8 * scale;
      popup.style.maxWidth = `${Math.max(1, (bounds.right - bounds.left - padding * 2) / scale)}px`;
      popup.style.maxHeight = `${Math.max(1, (bounds.bottom - bounds.top - padding * 2) / scale)}px`;
      const size = popup.getBoundingClientRect();
      const left = Math.max(bounds.left + padding, Math.min(rect.left, bounds.right - size.width - padding));
      const preferredTop = rect.bottom + padding + size.height > bounds.bottom - padding ? rect.top - size.height - padding : rect.bottom + padding;
      const top = Math.max(bounds.top + padding, Math.min(preferredTop, bounds.bottom - size.height - padding));
      popup.style.left = `${(left - rect.left) / scale}px`;
      popup.style.top = `${(top - rect.top) / scale}px`;
    };
    const close = (event: PointerEvent) => {
      if (!anchor.current?.contains(event.target as Node)) { setExpanded(false); setHovered(false); }
    };
    const escape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') { setExpanded(false); setHovered(false); }
    };
    place();
    window.addEventListener('resize', place);
    document.addEventListener('scroll', place, true);
    document.addEventListener('pointerdown', close);
    document.addEventListener('keydown', escape);
    return () => {
      window.removeEventListener('resize', place);
      document.removeEventListener('scroll', place, true);
      document.removeEventListener('pointerdown', close);
      document.removeEventListener('keydown', escape);
    };
  }, [visible, expanded]);
  return (
    <span ref={anchor} className="Healthanalyzer__wound" onMouseEnter={() => setHovered(true)} onMouseLeave={() => setHovered(false)}>
      <Button className="Healthanalyzer__woundButton" icon={wound.icon} selected={expanded} aria-expanded={expanded} onClick={() => setExpanded(!expanded)}>
        ↳ {wound.name} · {wound.severity}
      </Button>
      {visible && (
        <div ref={tooltip} className="Tooltip Healthanalyzer__woundTooltip" role="tooltip">
          <Box bold mb={0.5}>{wound.name} · {wound.severity}</Box>
          <Box preserveWhitespace>{decodeHtmlEntities(expanded ? wound.details : wound.treatment)}</Box>
          {!expanded && <Box color="label" mt={0.5}>Нажмите, чтобы открыть подробное заключение.</Box>}
        </div>
      )}
    </span>
  );
};
