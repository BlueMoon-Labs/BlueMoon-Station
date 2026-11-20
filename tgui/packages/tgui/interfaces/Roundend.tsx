import { BooleanLike } from 'common/react';
import { useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

// ======================= Типы данных =======================

type SurvivalStatus = 'survived' | 'marooned' | 'dead' | 'unknown';

type Survival = {
  status: SurvivalStatus;
  message: string;
};

type RoundInfo = {
  id: string;
  stats_url: string;
  duration: string;
  knottings?: number;
};

type StationInfo = {
  nuked: BooleanLike;
  integrity: number;
};

type Evacuation = {
  escaped: number;
  escaped_percent: number;
  shuttle: number;
  shuttle_percent: number;
  pods: number;
  pods_percent: number;
};

type Personnel = {
  total: number;
  dead: number;
  alive: number;
  dead_percent: number;
  alive_percent: number;
  evacuated: BooleanLike;
  evacuation?: Evacuation;
};

type FirstDeath = {
  name: string;
  role: string;
  area: string;
  damage: string;
  last_words: string;
};

type DynamicInfo = {
  threat_level: string;
  budget: number;
  rules_html: string;
};

type RoundendData = {
  survival: Survival;
  round_info: RoundInfo;
  station_info: StationInfo;
  personnel: Personnel;
  first_death: FirstDeath | null;
  dynamic: DynamicInfo | null;
  common_report_html: string;
  personal_extra_html: string;
};

// ======================= Стили для HTML-отчёта =======================
// Часть отчёта (антаги, законы, медали и т.д.) приходит из DM готовым HTML.
// Эти стили — адаптация html/browser/roundend.css под тёмную тему tgui.

const reportStyles = `
.roundend-report { line-height: 1.5; overflow-wrap: anywhere; }
.roundend-report .greentext { color: #90ee90; font-weight: bold; }
.roundend-report .redtext { color: #ef2f3c; font-weight: bold; }
.roundend-report .bluetext { color: #517fff; font-weight: bold; }
.roundend-report .marooned { color: #a6a6ff; font-weight: bold; }
.roundend-report .header { font-size: 1.5rem; font-weight: bold; }
.roundend-report .big { font-size: 1.5rem; }
.roundend-report .medaltext { color: #add8e6; }
.roundend-report .panel {
  background: rgba(0, 0, 0, 0.25);
  padding: 10px;
  border-radius: 6px;
  margin-bottom: 8px;
}
.roundend-report .redborder { border-bottom: 2px solid #ef2f3c; }
.roundend-report .greenborder { border-bottom: 2px solid #90ee90; }
.roundend-report .stationborder { border-bottom: 2px solid #add8e6; }
.roundend-report .clockborder { border-bottom: 2px solid #b18b25; }
.roundend-report hr { border: 0; border-top: 1px solid rgba(255, 255, 255, 0.15); margin: 8px 0; }
.roundend-report li { margin-bottom: 0.2rem; }
.roundend-report a { color: #60b6ff; }
.roundend-report .playerlist { padding-left: 20px; }
`;

const HtmlReport = (props: { html: string }) => (
  <>
    <Box dangerouslySetInnerHTML={{ __html: `<style>${reportStyles}</style>` }} />
    <Box
      className="roundend-report"
      dangerouslySetInnerHTML={{
        __html: props.html || '<i>Отчёт отсутствует.</i>',
      }}
    />
  </>
);

// ======================= Вспомогательные компоненты =======================

const Percent = (props: { value: number }) => (
  <> ({props.value}%)</>
);

const survivalColor = (status?: SurvivalStatus) => {
  switch (status) {
    case 'survived':
      return 'good';
    case 'marooned':
      return 'blue';
    case 'dead':
      return 'bad';
    default:
      return 'label';
  }
};

// ======================= Сводка (персональный отчёт) =======================

const Summary = (props: { data: RoundendData }) => {
  const { data } = props;
  const survival: Survival = data.survival || {
    status: 'unknown',
    message: '',
  };
  const roundInfo: RoundInfo = data.round_info || ({} as RoundInfo);
  const station: StationInfo = data.station_info || ({} as StationInfo);
  const personnel: Personnel = data.personnel || ({} as Personnel);
  const evacuation = personnel.evacuation;
  const firstDeath = data.first_death;
  const dynamic = data.dynamic;

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Box bold fontSize="1.8rem" textAlign="center">
          Конец раунда
        </Box>
        <Box color="label" textAlign="center">
          Подсчитываем выживших…
        </Box>
      </Stack.Item>

      {survival.message ? (
        <Stack.Item mt={1}>
          <NoticeBox color={survivalColor(survival.status)}>
            {survival.message}
          </NoticeBox>
        </Stack.Item>
      ) : null}

      <Stack.Item mt={1}>
        <Section title="Информация о раунде">
          <LabeledList>
            <LabeledList.Item label="ID раунда">
              {roundInfo.stats_url ? (
                <a href={roundInfo.stats_url} target="_blank" rel="noreferrer">
                  {roundInfo.id || 'недоступно'}
                </a>
              ) : (
                roundInfo.id || <i>недоступно</i>
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Длительность смены">
              {roundInfo.duration || '—'}
            </LabeledList.Item>
            {roundInfo.knottings ? (
              <LabeledList.Item label="Узлирований членов экипажа за раунд">
                {roundInfo.knottings}
              </LabeledList.Item>
            ) : null}
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Section title="Информация о станции">
          <LabeledList>
            <LabeledList.Item label="Состояние станции">
              {station.nuked ? (
                <Box color="bad" bold>
                  уничтожена системой ядерного самоуничтожения
                </Box>
              ) : station.integrity === 100 ? (
                <Box color="good" bold>
                  нетронута
                </Box>
              ) : (
                <Box bold>{station.integrity}%</Box>
              )}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Section title="Информация о персонале">
          {personnel.total ? (
            <LabeledList>
              <LabeledList.Item label="За всю смену на станцию прибыло">
                <Box bold>{personnel.total}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Из прибывших погибло">
                <Box bold color="bad">
                  {personnel.dead}
                </Box>
                <Percent value={personnel.dead_percent} /> от прибывших
              </LabeledList.Item>
              <LabeledList.Item label="Из прибывших выжило">
                <Box bold color="good">
                  {personnel.alive}
                </Box>
                <Percent value={personnel.alive_percent} /> от прибывших
              </LabeledList.Item>

              <LabeledList.Item label="Эвакуация">
                {personnel.evacuated && evacuation ? (
                  <LabeledList>
                    <LabeledList.Item label="Эвакуировались">
                      <Box bold>{evacuation.escaped}</Box>
                      <Percent value={evacuation.escaped_percent} /> от выживших
                    </LabeledList.Item>
                    <LabeledList.Item label="На шаттле">
                      <Box bold>{evacuation.shuttle}</Box>
                      <Percent value={evacuation.shuttle_percent} /> от выживших
                    </LabeledList.Item>
                    <LabeledList.Item label="На подах (или иными способами)">
                      <Box bold>{evacuation.pods}</Box>
                      <Percent value={evacuation.pods_percent} /> от выживших
                    </LabeledList.Item>
                  </LabeledList>
                ) : (
                  <Box color="bad" italic>
                    Из выживших никто не эвакуировался — ни на шаттле, ни на
                    поде, ни любым другим способом.
                  </Box>
                )}
              </LabeledList.Item>
            </LabeledList>
          ) : (
            <Box color="bad" italic>
              Персонал станции отсутствует. Кто вызвал шаттл и закончил раунд?
            </Box>
          )}
        </Section>
      </Stack.Item>

      <Stack.Item mt={1}>
        <Section title="Информация о первой смерти">
          {firstDeath ? (
            <LabeledList>
              <LabeledList.Item label="Имя">
                <Box bold>{firstDeath.name}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Должность">
                <Box bold>{firstDeath.role}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Локация">
                <Box bold>{firstDeath.area}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Повреждения">
                <Box bold>{firstDeath.damage}</Box>
              </LabeledList.Item>
              <LabeledList.Item label="Его последние слова">
                <Box bold>{firstDeath.last_words}</Box>
              </LabeledList.Item>
            </LabeledList>
          ) : (
            <Box color="good">Никто не умер за смену!</Box>
          )}
        </Section>
      </Stack.Item>

      {dynamic ? (
        <Stack.Item mt={1}>
          <Section title="Информация о динамическом режиме">
            <LabeledList>
              <LabeledList.Item label="Уровень угрозы">
                {dynamic.threat_level}
              </LabeledList.Item>
              <LabeledList.Item label="Оставшаяся угроза">
                {dynamic.budget}
              </LabeledList.Item>
              <LabeledList.Item label="Правила">
                <HtmlReport html={dynamic.rules_html} />
              </LabeledList.Item>
            </LabeledList>
          </Section>
        </Stack.Item>
      ) : null}

      {data.personal_extra_html ? (
        <Stack.Item mt={1}>
          <HtmlReport html={data.personal_extra_html} />
        </Stack.Item>
      ) : null}
    </Stack>
  );
};

// ======================= Корневой интерфейс =======================

export const Roundend = () => {
  const { act, data, config } = useBackend<RoundendData>();
  const [tab, setTab] = useState(1);

  return (
    <Window width={900} height={720} title={config.title || 'Конец раунда'}>
      <Window.Content scrollable>
        <Tabs>
          <Tabs.Tab
            selected={tab === 1}
            icon="clipboard-list"
            onClick={() => setTab(1)}>
            Итоги смены
          </Tabs.Tab>
          <Tabs.Tab
            selected={tab === 2}
            icon="file-alt"
            onClick={() => setTab(2)}>
            Подробный отчёт
          </Tabs.Tab>
        </Tabs>

        {tab === 1 ? <Summary data={data} /> : null}
        {tab === 2 ? <HtmlReport html={data.common_report_html} /> : null}

        <Box mt={2} textAlign="center">
          <Button onClick={() => act('close')} icon="times">
            Закрыть
          </Button>
        </Box>
      </Window.Content>
    </Window>
  );
};
