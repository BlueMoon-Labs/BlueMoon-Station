import yaml from 'js-yaml';
import { useEffect, useMemo, useState } from 'react';

import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Box, Button, Icon, Input, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';
import {
  AuthorBlock,
  avatarUrl,
  CATEGORIES,
  countByCategory,
  countEntries,
  countNew,
  DayBlock,
  filterBase,
  filterDays,
  formatDay,
  formatMonth,
  groupByPr,
  groupByYear,
  isNewDate,
  kindOf,
  monthHasNew,
  monthHasNewOutside,
  monthName,
  parseMonth,
  prUrl,
} from './ChangelogModel';

type ChangelogData = {
  dates: string[];
  last_seen: string;
};

type MonthState = { month?: string } & (
  | { status: 'loading' }
  | { status: 'error' }
  | { status: 'ready'; days: DayBlock[] }
);

const MAX_ATTEMPTS = 6;

/** Разобранные месяцы за жизнь окна: повторный выбор месяца не гоняет ассет заново. */
const monthCache = new Map<string, DayBlock[]>();

export const resetChangelogCache = () => monthCache.clear();

/**
 * Месяц архива. Ассет приходит асинхронно после act('get_month'), поэтому первые
 * запросы могут вернуть "Cannot find" - тогда повтор с нарастающей паузой.
 */
const useMonth = (month: string | undefined, reloadKey: number): MonthState => {
  const { act } = useBackend<ChangelogData>();
  const [state, setState] = useState<MonthState>({ month, status: 'loading' });

  useEffect(() => {
    if (!month) {
      setState({ month, status: 'error' });
      return;
    }
    const cached = monthCache.get(month);
    if (cached) {
      setState({ month, status: 'ready', days: cached });
      return;
    }
    setState({ month, status: 'loading' });
    let cancelled = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    act('get_month', { date: month });

    const attempt = (number: number) => {
      const retry = () => {
        if (cancelled) {
          return;
        }
        if (number >= MAX_ATTEMPTS) {
          setState({ month, status: 'error' });
          return;
        }
        timer = setTimeout(() => attempt(number + 1), 50 + number * 100);
      };
      fetch(resolveAsset(`${month}.yml`))
        .then((response) => response.text())
        .then((text) => {
          if (cancelled) {
            return;
          }
          if (/^Cannot find/.test(text)) {
            retry();
            return;
          }
          const days = parseMonth(yaml.load(text, { schema: yaml.CORE_SCHEMA }));
          monthCache.set(month, days);
          setState({ month, status: 'ready', days });
        })
        .catch(retry);
    };
    attempt(1);

    return () => {
      cancelled = true;
      if (timer) {
        clearTimeout(timer);
      }
    };
  }, [month, reloadKey]);

  // Первый рендер после смены месяца ещё держит состояние прошлого: его не отдаём.
  return state.month === month ? state : { month, status: 'loading' };
};

export const Changelog = () => {
  const { data } = useBackend<ChangelogData>();
  const dates = data.dates || [];
  const lastSeen = data.last_seen || '';

  const [month, setMonth] = useState(dates[0]);
  const [reloadKey, setReloadKey] = useState(0);
  const [query, setQuery] = useState('');
  const [categories, setCategories] = useState<string[]>([]);
  const [onlyNew, setOnlyNew] = useState(false);
  const [showAbout, setShowAbout] = useState(false);
  const [archiveOpen, setArchiveOpen] = useState(false);
  const [newByMonth, setNewByMonth] = useState<Record<string, number>>({});

  const monthState = useMonth(month, reloadKey);
  const days = monthState.status === 'ready' ? monthState.days : [];

  useEffect(() => {
    if (monthState.status === 'ready' && month && newByMonth[month] === undefined) {
      setNewByMonth((counts) => ({ ...counts, [month]: countNew(monthState.days, lastSeen) }));
    }
  }, [monthState, month]);

  const filters = { query, categories, onlyNew, lastSeen };
  const base = useMemo(() => filterBase(days, filters), [days, query, onlyNew, lastSeen]);
  const visible = useMemo(() => filterDays(days, filters), [days, query, onlyNew, lastSeen, categories]);
  const categoryCounts = useMemo(() => countByCategory(base), [base]);
  const newCount = useMemo(() => countNew(days, lastSeen), [days, lastSeen]);

  const index = month ? dates.indexOf(month) : -1;
  const selectMonth = (next: string) => {
    setShowAbout(false);
    setMonth(next);
  };
  const toggleCategory = (id: string) =>
    setCategories((current) => (current.includes(id) ? current.filter((value) => value !== id) : [...current, id]));
  const resetFilters = () => {
    setQuery('');
    setCategories([]);
    setOnlyNew(false);
  };

  return (
    <Window title="Список изменений" width={920} height={680}>
      <Window.Content className="Changelog">
        <Stack fill>
          {archiveOpen && (
            <Stack.Item width="190px">
              <Sidebar dates={dates} month={month} lastSeen={lastSeen} newByMonth={newByMonth} onSelect={selectMonth} />
            </Stack.Item>
          )}
          <Stack.Item grow basis={0}>
            {showAbout ? (
              <About onBack={() => setShowAbout(false)} />
            ) : (
              <Stack vertical fill>
                <Stack.Item>
                  <Section className="Changelog__toolbar">
                    <Stack align="center">
                      <Stack.Item>
                        <Button
                          icon="folder-tree"
                          selected={archiveOpen}
                          tooltip={archiveOpen ? 'Скрыть архив' : 'Архив месяцев'}
                          onClick={() => setArchiveOpen(!archiveOpen)}
                        >
                          {!archiveOpen && monthHasNewOutside(dates, month, lastSeen, newByMonth) && (
                            <span className="Changelog__dot" title="В других месяцах есть новое" />
                          )}
                        </Button>
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          icon="chevron-left"
                          tooltip="Месяц новее"
                          disabled={index <= 0}
                          onClick={() => selectMonth(dates[index - 1])}
                        />
                      </Stack.Item>
                      <Stack.Item className="Changelog__month">
                        {month ? formatMonth(month) : 'Архив пуст'}
                      </Stack.Item>
                      <Stack.Item>
                        <Button
                          icon="chevron-right"
                          tooltip="Месяц старше"
                          disabled={index < 0 || index >= dates.length - 1}
                          onClick={() => selectMonth(dates[index + 1])}
                        />
                      </Stack.Item>
                      <Stack.Item grow>
                        <Input
                          fluid
                          placeholder="Поиск по тексту, автору или #номеру PR"
                          value={query}
                          onInput={(_e: unknown, value: string) => setQuery(value)}
                        />
                      </Stack.Item>
                      {!!lastSeen && (
                        <Stack.Item>
                          <Button
                            icon="star"
                            selected={onlyNew}
                            disabled={!newCount && !onlyNew}
                            tooltip="Записи, появившиеся после прошлого просмотра"
                            onClick={() => setOnlyNew(!onlyNew)}
                          >
                            {`Новое: ${newCount}`}
                          </Button>
                        </Stack.Item>
                      )}
                      <Stack.Item>
                        <Button icon="circle-info" tooltip="О проекте" onClick={() => setShowAbout(true)} />
                      </Stack.Item>
                    </Stack>
                    <Box className="Changelog__chips">
                      <Button selected={!categories.length} onClick={() => setCategories([])}>
                        {`Все ${countEntries(base)}`}
                      </Button>
                      {CATEGORIES.map((category) => (
                        <Button
                          key={category.id}
                          icon={category.icon}
                          selected={categories.includes(category.id)}
                          disabled={!categoryCounts[category.id] && !categories.includes(category.id)}
                          onClick={() => toggleCategory(category.id)}
                        >
                          {`${category.label} ${categoryCounts[category.id] || 0}`}
                        </Button>
                      ))}
                    </Box>
                  </Section>
                </Stack.Item>
                <Stack.Item grow basis={0}>
                  <Section key={month} fill scrollable>
                    {monthState.status === 'loading' && (
                      <Box className="Changelog__placeholder">
                        <Icon name="spinner" spin mr={1} />
                        Загружаем записи...
                      </Box>
                    )}
                    {monthState.status === 'error' && (
                      <NoticeBox danger>
                        <Stack align="center">
                          <Stack.Item grow>Не удалось загрузить месяц.</Stack.Item>
                          <Stack.Item>
                            <Button icon="rotate-right" onClick={() => setReloadKey(reloadKey + 1)}>
                              Повторить
                            </Button>
                          </Stack.Item>
                        </Stack>
                      </NoticeBox>
                    )}
                    {monthState.status === 'ready' && !visible.length && (
                      <Box className="Changelog__placeholder">
                        {days.length ? 'Под эти фильтры ничего не подходит.' : 'В этом месяце записей нет.'}
                        {!!days.length && (
                          <Box mt={1}>
                            <Button icon="filter-circle-xmark" onClick={resetFilters}>
                              Сбросить фильтры
                            </Button>
                          </Box>
                        )}
                      </Box>
                    )}
                    {visible.map((day) => (
                      <Day key={day.date} day={day} isNew={isNewDate(day.date, lastSeen)} />
                    ))}
                  </Section>
                </Stack.Item>
              </Stack>
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

type SidebarProps = {
  dates: string[];
  month: string | undefined;
  lastSeen: string;
  newByMonth: Record<string, number>;
  onSelect: (month: string) => void;
};

const Sidebar = (props: SidebarProps) => {
  const { dates, month, lastSeen, newByMonth, onSelect } = props;
  const years = useMemo(() => groupByYear(dates), [dates]);
  const selectedYear = month?.split('-')[0];
  const [openYears, setOpenYears] = useState<string[]>(selectedYear ? [selectedYear] : []);
  const toggleYear = (year: string) =>
    setOpenYears((current) => (current.includes(year) ? current.filter((value) => value !== year) : [...current, year]));

  // Стрелками можно уйти в другой год - он должен раскрыться, иначе выбранный месяц не виден.
  useEffect(() => {
    if (selectedYear) {
      setOpenYears((current) => (current.includes(selectedYear) ? current : [...current, selectedYear]));
    }
  }, [selectedYear]);

  return (
    <Section fill scrollable title="Архив" className="Changelog__archive">
      {years.map(({ year, months }) => {
        const open = openYears.includes(year);
        return (
          <Box key={year} mb={0.5}>
            <Button
              fluid
              color="transparent"
              icon={open ? 'chevron-down' : 'chevron-right'}
              className="Changelog__year"
              onClick={() => toggleYear(year)}
            >
              {year}
            </Button>
            {open &&
              months.map((value) => (
                <Button
                  key={value}
                  fluid
                  color="transparent"
                  selected={value === month}
                  className="Changelog__monthButton"
                  onClick={() => onSelect(value)}
                >
                  {monthName(value)}
                  {monthHasNew(value, lastSeen, newByMonth[value]) && (
                    <span className="Changelog__dot" title="Есть новое" />
                  )}
                </Button>
              ))}
          </Box>
        );
      })}
    </Section>
  );
};

const Day = (props: { day: DayBlock; isNew: boolean }) => {
  const { day, isNew } = props;
  return (
    <Box className={isNew ? 'Changelog__day Changelog__day--new' : 'Changelog__day'}>
      <Box className="Changelog__dayTitle">
        {formatDay(day.date)}
        {isNew && <span className="Changelog__newBadge">новое</span>}
      </Box>
      {day.authors.map((block) => (
        <Author key={block.author} block={block} />
      ))}
    </Box>
  );
};

const PrLink = (props: { pr: number }) => (
  <a className="Changelog__pr" href={prUrl(props.pr)} title="Открыть PR на GitHub">
    {`#${props.pr}`}
  </a>
);

const Avatar = (props: { author: string; onLoad: () => void }) => {
  const url = avatarUrl(props.author);
  const [failed, setFailed] = useState(false);
  if (!url || failed) {
    return <Icon className="Changelog__avatar Changelog__avatar--none" name="user" />;
  }
  return <img className="Changelog__avatar" src={url} alt="" onLoad={props.onLoad} onError={() => setFailed(true)} />;
};

const Author = (props: { block: AuthorBlock }) => {
  const { block } = props;
  // Ссылку на профиль даём, только когда GitHub отдал аватарку: значит, такой логин есть.
  const [onGithub, setOnGithub] = useState(false);
  const groups = groupByPr(block.changes);
  const singlePr = groups.length === 1 ? groups[0].pr : undefined;
  return (
    <Box className="Changelog__author">
      <Box className="Changelog__authorName">
        <Avatar author={block.author} onLoad={() => setOnGithub(true)} />
        {onGithub ? <a href={`https://github.com/${block.author}`}>{block.author}</a> : block.author}
        {singlePr !== undefined && <PrLink pr={singlePr} />}
      </Box>
      {groups.map((group, groupIndex) => (
        <Box key={groupIndex} className="Changelog__group">
          {singlePr === undefined && group.pr !== undefined && (
            <Box className="Changelog__groupTitle">
              <PrLink pr={group.pr} />
            </Box>
          )}
          {group.changes.map((change, number) => {
            const kind = kindOf(change.type);
            return (
              <Box key={number} className="Changelog__change">
                <Icon className="Changelog__changeIcon" name={kind.icon} color={kind.color} title={kind.label} />
                <span>{change.text}</span>
              </Box>
            );
          })}
        </Box>
      ))}
    </Box>
  );
};

const About = (props: { onBack: () => void }) => (
  <Section
    fill
    scrollable
    title="О проекте"
    buttons={
      <Button icon="arrow-left" onClick={props.onBack}>
        К изменениям
      </Button>
    }
  >
    <Box className="Changelog__about">
      <h2>BlueMoon</h2>
      <p>
        <b>Спасибо: </b>
        S.P.L.U.R.T. Station 13, Citadel Station 13, /tg/station, Baystation 12, /vg/station, NTstation, CDK Station
        devs, FacepunchStation, GoonStation devs, the original Space Station 13 developers, Invisty for the title image
        and the countless others who have contributed to the game, issue tracker or wiki over the years.
      </p>
      <p>
        {'Мейнтейнеры проекта: '}
        <a href="https://github.com/SPLURT-Station/S.P.L.U.R.T-Station-13/graphs/contributors">список</a>
        {', недавние участники на GitHub: '}
        <a href="https://github.com/SPLURT-Station/S.P.L.U.R.T-Station-13/pulse/monthly">здесь</a>
        {'. Наш Discord: '}
        <a href="https://discord.gg/e6pRWzMVMA">discord.gg/e6pRWzMVMA</a>.
      </p>
      <h3>GoonStation 13 Development Team</h3>
      <p>
        <b>Coders: </b>
        Stuntwaffle, Showtime, Pantaloons, Nannek, Keelin, Exadv1, hobnob, Justicefries, 0staf, sniperchance,
        AngriestIBM, BrianOBlivion
      </p>
      <p>
        <b>Spriters: </b>
        Supernorn, Haruhi, Stuntwaffle, Pantaloons, Rho, SynthOrange, I Said No
      </p>
      <p>
        Traditional Games Space Station 13 is thankful to the GoonStation 13 Development Team for its work on the game up
        to the
        {' r4407 release. The changelog for changes up to r4407 can be seen '}
        <a href="https://wiki.ss13.co/Changelog#April_2010">here</a>.
      </p>
      <p>
        {'Except where otherwise noted, Goon Station 13 is licensed under a '}
        <a href="https://creativecommons.org/licenses/by-nc-sa/3.0/">
          Creative Commons Attribution-Noncommercial-Share Alike 3.0 License
        </a>
        {'. Rights are currently extended to '}
        <a href="http://forums.somethingawful.com/">SomethingAwful Goons</a>
        {' only.'}
      </p>
      <h3>Traditional Games Space Station 13 License</h3>
      <p>
        {'All code after '}
        <a href={'https://github.com/tgstation/tgstation/commit/' + '333c566b88108de218d882840e61928a9b759d8f'}>
          commit 333c566b88108de218d882840e61928a9b759d8f on 2014/31/12 at 4:38 PM PST
        </a>
        {' is licensed under '}
        <a href="https://www.gnu.org/licenses/agpl-3.0.html">GNU AGPL v3</a>
        {'. All code before that commit is licensed under '}
        <a href="https://www.gnu.org/licenses/gpl-3.0.html">GNU GPL v3</a>
        {', including tools unless their readme specifies otherwise. See '}
        <a href="https://github.com/tgstation/tgstation/blob/master/LICENSE">LICENSE</a>
        {' and '}
        <a href="https://github.com/tgstation/tgstation/blob/master/GPLv3.txt">GPLv3.txt</a>
        {' for more details.'}
      </p>
      <p>
        The TGS DMAPI API is licensed as a subproject under the MIT license.
        {' See the footer of '}
        <a href={'https://github.com/tgstation/tgstation/blob/master' + '/code/__DEFINES/tgs.dm'}>code/__DEFINES/tgs.dm</a>
        {' and '}
        <a href={'https://github.com/tgstation/tgstation/blob/master' + '/code/modules/tgs/LICENSE'}>
          code/modules/tgs/LICENSE
        </a>
        {' for the MIT license.'}
      </p>
      <p>
        {'All assets including icons and sound are under a '}
        <a href="https://creativecommons.org/licenses/by-sa/3.0/">Creative Commons 3.0 BY-SA license</a>
        {' unless otherwise indicated.'}
      </p>
    </Box>
  </Section>
);
