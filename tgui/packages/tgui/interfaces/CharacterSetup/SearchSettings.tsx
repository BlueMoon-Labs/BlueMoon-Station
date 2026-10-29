import { useEffect, useMemo, useRef, useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, Input, Stack } from '../../components';
import { FeatureField } from './components';

interface SearchEntry {
  tab: number;
  group: string;
  label: string;
  id?: string;
  keywords?: string;
}

interface SearchData {
  tab: number;
  defaultSlot: number;
  characterRevision: number;
  featureFields?: FeatureField[];
  mutantPartLabels?: Record<string, string>;
  tabs: { id: number; label: string }[];
}

const GROUPS: [number, string, string[]][] = [
  [0, 'Личность', ['Имя', 'Возраст', 'Без имени', 'Всегда случайное имя', 'Скрывать ckey', 'Свой цвет крови', 'Цвет крови', 'Скафандр поверх хвоста']],
  [0, 'Профессии', ['Настройка профессий', 'Отдел охраны', 'Экран ядра ИИ']],
  [0, 'Особые имена', ['Запасное', 'Клоун', 'Мим', 'Киборг', 'ИИ', 'Религия', 'Божество']],
  [0, 'КПК', ['Цвет интерфейса КПК', 'Стиль КПК', 'Модель КПК', 'Рингтон КПК', 'Тема КПК']],
  [0, 'Синтетики', ['Свод законов']],
  [0, 'Одежда и снаряжение', ['Стиль комбинезона', 'Капля слизи', 'Очистить шрамы']],
  [0, 'Согласие', ['Задания антагов']],
  [1, 'Описания', ['Описание при осмотре', 'Описание без одежды', 'Описание силикона', 'Описание вкуса', 'Описание запаха', 'Охранные записи', 'Медицинские записи']],
  [1, 'Предыстория и смерть', ['Предыстория вида', 'OOC-заметки', 'Эмоут смерти']],
  [1, 'Фотографии', ['Фотографии', 'Фотографии (NSFW)', 'Ass Shot']],
  [2, 'Тело', ['Пол', 'Телосложение', 'Вид', 'Кастомная раса', 'Продвинутая раскраска', 'Модификация конечностей', 'Спрайт тела']],
  [2, 'Цвет тела и размер', ['Тон кожи', 'Цвет тона', 'Вес персонажа']],
  [2, 'Глаза и волосы', ['Форма глаз', 'Светящиеся глаза', 'Цвет глаз', 'Причёска', 'Борода', 'Градиент']],
  [2, 'Гениталии', ['Форма пениса']],
  [3, 'Маркинги', ['Татуировки персонажа', 'Голова', 'Грудь', 'Левая нога', 'Правая нога', 'Левая рука', 'Правая рука']],
  [4, 'Речевые предпочтения', ['Глагол речи', 'Использовать русские глаголы', 'Акцент', 'Смех', 'Свой цвет руначата', 'Цвет руначата']],
  [4, 'Голос', ['Звук голоса', 'Скорость голоса', 'Высота голоса', 'Разброс голоса', 'Звук смерти']],
  [4, 'Дополнительные языки', ['Дополнительные языки']],
  [5, 'Экипировка', ['Выбрано', 'Заменять', 'Каталог экипировки']],
  [6, 'Особенности', ['Особенности']],
  [6, 'Настройки отдельных особенностей', ['Фобия', 'Тип крика', 'Прозвище призываемого', 'Останки «Одной Жизни»', 'Отстранённость при появлении']],
  [-1, 'Внешний вид', ['Фон превью', 'Возбуждён', 'Масштаб просмотра', 'Ракурсы', 'Поворот', 'Приближение', 'Силуэт 100%']],
];

const GENERAL_GROUPS: Record<string, string> = {
  backbag: 'Одежда и снаряжение', uplink_spawn_loc: 'Одежда и снаряжение', persistent_scars: 'Одежда и снаряжение',
  erppref: 'Согласие', nonconpref: 'Согласие', vorepref: 'Согласие', mobsexpref: 'Согласие', tattoopref: 'Согласие', unholypref: 'Согласие', unholyhardpref: 'Согласие', extremepref: 'Согласие', extremeharm: 'Согласие',
  lust_tolerance: 'Секс и беременность', sexual_potency: 'Секс и беременность', virility: 'Секс и беременность', fertility: 'Секс и беременность', inert_eggs: 'Секс и беременность', pregnancy_inflation: 'Секс и беременность', pregnancy_breast_growth: 'Секс и беременность', egg_shell: 'Секс и беременность',
};

const GENITAL_GROUPS: Record<string, string> = {
  cock: 'Пенис', balls: 'Яички', vag: 'Влагалище', womb: 'Влагалище', breasts: 'Грудь', butt: 'Попа', anus: 'Попа', belly: 'Живот',
};

const normalize = (text: string) => text.toLocaleLowerCase().replaceAll('ё', 'е');

export const SearchSettings = () => {
  const { act, data } = useBackend<SearchData>();
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [active, setActive] = useState(0);
  const [keyboardNavigation, setKeyboardNavigation] = useState(false);
  const [pending, setPending] = useState<{ entry: SearchEntry; slot: number }>();
  const [notice, setNotice] = useState('');
  const root = useRef<HTMLDivElement>(null);
  const entries = useMemo(() => {
    const result: SearchEntry[] = GROUPS.flatMap(([tab, group, labels]) =>
      labels.map((label) => ({ tab, group, label }))
    );
    for (const field of data.featureFields || []) {
      const prefix = field.key.replace(/^has_/, '').split('_')[0];
      const genital = GENITAL_GROUPS[prefix];
      const general = GENERAL_GROUPS[field.key];
      const group = general || genital || (
        /hair|grad|eye/.test(field.key) ? 'Глаза и волосы' :
          /mcolor|size|fuzzy|skintone/.test(field.key) ? 'Цвет тела и размер' : 'Тело'
      );
      result.push({ tab: general ? 0 : 2, group, label: field.label, id: field.key, keywords: field.hint });
    }
    for (const [id, label] of Object.entries(data.mutantPartLabels || {})) {
      result.push({ tab: 2, group: 'Части тела', label, id: 'part:' + id });
    }
    return result.map((entry) => ({
      ...entry,
      searchText: normalize([entry.label, entry.keywords || '', entry.id || ''].join(' ')),
      searchLabel: normalize(entry.label),
      searchGroup: normalize(entry.group),
    }));
  }, [data.featureFields, data.mutantPartLabels]);
  const normalizedQuery = normalize(query).trim();
  const words = normalizedQuery.split(/\s+/).filter(Boolean);
  const matches = useMemo(() => {
    if (!normalizedQuery) return [];
    const queryWords = normalizedQuery.split(/\s+/);
    return entries.filter((entry) => {
      return queryWords.every((word) => entry.searchText.includes(word))
        || entry.searchGroup.includes(normalizedQuery);
    }).sort((a, b) =>
      Number(b.searchLabel.includes(normalizedQuery))
      - Number(a.searchLabel.includes(normalizedQuery))
    );
  }, [entries, normalizedQuery]);

  useEffect(() => {
    const outside = (event: PointerEvent) => {
      if (!root.current?.contains(event.target as Node)) setOpen(false);
    };
    document.addEventListener('pointerdown', outside);
    return () => {
      document.removeEventListener('pointerdown', outside);
    };
  }, []);

  useEffect(() => {
    setNotice('');
  }, [data.defaultSlot]);

  useEffect(() => {
    if (open) {
      root.current?.querySelector('.CharacterSetup__search-results .Button--selected')
        ?.scrollIntoView({ block: 'nearest' });
    }
  }, [active, open]);

  useEffect(() => {
    if (!pending) return;
    if (pending.slot !== data.defaultSlot) {
      setPending(undefined);
      return;
    }
    const { entry } = pending;
    if (entry.tab >= 0 && entry.tab !== data.tab) return;
    const frame = requestAnimationFrame(() => {
      const container = root.current?.closest('.CharacterSetup');
      const area = container?.querySelector(entry.tab < 0 ? '.CharacterSetup__preview-toolbar' : '.CharacterSetup__content');
      const labels = Array.from(area?.querySelectorAll<HTMLElement>('[data-search-label]') || []);
      let target = labels.find((node) => entry.id ? node.dataset.searchId === entry.id : node.dataset.searchLabel === entry.label);
      if (!target) {
        target = Array.from(area?.querySelectorAll<HTMLElement>('.Section__title, .CharacterSetup__card-title, [data-search-label]') || [])
          .find((node) => node.dataset.searchLabel === entry.group || node.textContent?.trim() === entry.label || node.textContent?.trim() === entry.group);
        setNotice(`«${entry.label}»: открыта категория «${entry.group}». Само поле может быть скрыто настройками или недоступно для текущего вида.`);
      } else {
        setNotice('');
      }
      if (target) {
        target.scrollIntoView({ block: 'center', inline: 'nearest' });
        target.classList.add('CharacterSetup__search-highlight');
        setTimeout(() => target?.classList.remove('CharacterSetup__search-highlight'), 3500);
      }
      setPending(undefined);
    });
    return () => cancelAnimationFrame(frame);
  }, [pending, data.tab, data.defaultSlot, data.characterRevision]);

  const select = (entry: SearchEntry) => {
    setPending({ entry, slot: data.defaultSlot });
    setOpen(false);
    if (entry.tab >= 0 && entry.tab !== data.tab) act('set_tab', { tab: entry.tab });
  };

  return (
    <div
      className="CharacterSetup__search"
      ref={root}
      onKeyDownCapture={(event) => {
        if (event.key === 'Escape') {
          setOpen(false);
          event.stopPropagation();
        }
        if (!open || !matches.length) return;
        if (['ArrowDown', 'ArrowUp', 'Enter'].includes(event.key)) {
          event.preventDefault();
          event.stopPropagation();
          if (event.key === 'Enter') {
            select(matches[Math.min(active, matches.length - 1)]);
          } else {
            setKeyboardNavigation(true);
            setActive((active + (event.key === 'ArrowDown' ? 1 : matches.length - 1)) % matches.length);
          }
        }
      }}
    >
      <Stack align="center">
        <Stack.Item grow>
          <Input
            fluid
            placeholder="Поиск настроек во всех вкладках"
            value={query}
            onFocus={() => setOpen(true)}
            onInput={(event, value) => {
              setQuery(value);
              setActive(0);
              setKeyboardNavigation(false);
              setOpen(true);
            }}
          />
        </Stack.Item>
        {!!query && (
          <Stack.Item>
            <Button
              icon="times"
              tooltip="Очистить поиск"
              onClick={() => {
                setQuery('');
                setOpen(false);
                setNotice('');
              }}
            />
          </Stack.Item>
        )}
      </Stack>
      {!!notice && <Box color="label" mt={0.5}>{notice}</Box>}
      {open && words.length > 0 && (
        <div className="CharacterSetup__search-results">
          <Box color="label" mb={0.5}>Найдено: {matches.length}</Box>
          {matches.map((entry, index) => (
            <Button
              key={`${entry.tab}:${entry.id || entry.label}`}
              fluid
              color="transparent"
              selected={keyboardNavigation && active === index}
              onMouseEnter={() => {
                setActive(index);
                setKeyboardNavigation(false);
              }}
              onClick={() => select(entry)}
            >
              {entry.label}
              <Box color="label">
                {data.tabs?.find((tab) => tab.id === entry.tab)?.label || 'Превью'} · {entry.group}
              </Box>
            </Button>
          ))}
          {!matches.length && (
            <Box>Настройки не найдены. Попробуйте другое название.</Box>
          )}
        </div>
      )}
    </div>
  );
};
