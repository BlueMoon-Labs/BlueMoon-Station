import { useBackend } from '../../../backend';
import {
  Box,
  Button,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from '../../../components';
import {
  FieldRow,
  quirkColor,
  SelectRow,
  TabDataMissing,
} from '../components';

interface QuirkRow {
  name: string;
  value: number;
  desc: string;
  cost: number;
  selected: boolean;
  locked: boolean;
  lockReason?: string | null;
}

interface QuirksData {
  enabled: boolean;
  loading?: boolean;
  balance?: number;
  positiveCount?: number;
  maxPositive?: number;
  category: string;
  categories: { value: string; label: string }[];
  current?: string[];
  quirkValues?: Record<string, number>;
  shriek?: string;
  shriekOptions?: string[];
  summonNickname?: string | null;
  phobia?: string;
  phobiaOptions?: string[];
  onelife?: string;
  onelifeOptions?: string[];
  items?: QuirkRow[];
}

interface QuirksContext {
  quirksTab?: QuirksData;
}

const QuirkRowView = (props: { row: QuirkRow }) => {
  const { act } = useBackend<QuirksContext>();
  const { row } = props;

  return (
    <Box
      mb={1}
      p={1}
      opacity={row.locked ? 0.55 : undefined}
      onClick={() => {
        if (!row.locked) {
          act('quirk_toggle', { name: row.name });
        }
      }}
      style={{
        border: '1px solid '
          + (row.selected
              ? 'rgba(120, 205, 148, 0.55)'
              : 'rgba(255, 255, 255, 0.12)'),
        borderRadius: '3px',
        backgroundColor: row.selected
          ? 'rgba(70, 165, 108, 0.14)'
          : 'rgba(0, 0, 0, 0.22)',
        cursor: row.locked ? 'not-allowed' : 'pointer',
      }}
    >
      <Stack align="flex-start">
        <Stack.Item grow>
          <Box
            color={quirkColor(row.value)}
            bold
            title={row.name}
            nowrap
          >
            {row.name}
          </Box>
          <Box color="label" mt={0.5}>
            {row.desc}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box
            color={quirkColor(row.value)}
            bold
            nowrap
            style={{ width: '66px', textAlign: 'right' }}
          >
            {row.cost > 0 ? `+${row.cost}` : row.cost} оч.
          </Box>
        </Stack.Item>
      </Stack>
      {!!row.locked && !!row.lockReason && (
        <Box color="bad" mt={0.5} ml={1}>
          {row.lockReason}
        </Box>
      )}
    </Box>
  );
};

export const QuirksTab = () => {
  const { act, data } = useBackend<QuirksContext>();
  const quirks = data.quirksTab;

  if (!quirks) {
    return <TabDataMissing title="Особенности" />;
  }

  if (!quirks.enabled) {
    return (
      <Section fill scrollable title="Особенности">
        <NoticeBox>Особенности отключены на этом сервере.</NoticeBox>
      </Section>
    );
  }

  if (quirks.loading) {
    return (
      <Section fill scrollable title="Особенности">
        <Box color="label">Список особенностей ещё загружается...</Box>
      </Section>
    );
  }

  const items = quirks.items || [];
  const current = quirks.current || [];
  const balance = quirks.balance ?? 0;
  const positiveCount = quirks.positiveCount ?? 0;
  const negativeCount = current.filter(
    (name) => (quirks.quirkValues?.[name] ?? 0) < 0
  ).length;
  const neutralCount = current.filter(
    (name) => (quirks.quirkValues?.[name] ?? 0) === 0
  ).length;
  const maxPositive = quirks.maxPositive ?? 0;
  const nickname = quirks.summonNickname;

  return (
    <Section fill scrollable title="Особенности">
      <Section title="Настройки отдельных особенностей">
        <Box color="label" mb={1}>
          Работают, только если выбрана соответствующая особенность.
        </Box>
        <SelectRow
          label="Тип крика"
          value={quirks.shriek}
          options={quirks.shriekOptions || []}
          action="quirk_set_shriek"
        />
        <FieldRow label="Прозвище призываемого">
          <Button
            icon="pen"
            content={nickname || 'Задать'}
            onClick={() => act('quirk_set_nickname')}
          />
        </FieldRow>
        <SelectRow
          label="Фобия"
          value={quirks.phobia}
          options={quirks.phobiaOptions || []}
          action="quirk_set_phobia"
        />
        <SelectRow
          label="Останки «Одной Жизни»"
          value={quirks.onelife}
          options={quirks.onelifeOptions || []}
          action="quirk_set_onelife"
        />
      </Section>

      <Section title="Выбранные особенности">
        <Stack mb={1} wrap>
          <Stack.Item>
            <Box inline bold mr={1} color="good">
              Положительных:
            </Box>
            <Box inline color="good">
              {positiveCount} / {maxPositive}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Box inline bold mr={1} color="bad">
              Отрицательных:
            </Box>
            <Box inline color="bad">
              {negativeCount}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Box inline bold mr={1} color="label">
              Нейтральных:
            </Box>
            <Box inline color="label">
              {neutralCount}
            </Box>
          </Stack.Item>
          <Stack.Item>
            <Box inline bold mr={1}>
              Очков осталось:
            </Box>
            <Box inline color={balance < 0 ? 'bad' : undefined}>
              {balance}
            </Box>
          </Stack.Item>
          <Stack.Item grow={1} />
          <Stack.Item>
            <Button.Confirm
              icon="undo"
              color="bad"
              content="Сбросить"
              confirmContent="Сбросить все особенности?"
              onClick={() => act('quirk_reset')}
            />
          </Stack.Item>
        </Stack>
        {balance < 0 && (
          <NoticeBox>
            Баланс в минусе - возьмите меньше позитивных особенностей или
            сбросьте список.
          </NoticeBox>
        )}

        <Tabs mb={1}>
          {(quirks.categories || []).map((category) => (
            <Tabs.Tab
              key={category.value}
              selected={quirks.category === category.value}
              onClick={() =>
                act('quirk_select_category', { value: category.value })
              }
            >
              {category.label}
            </Tabs.Tab>
          ))}
        </Tabs>

        {items.length === 0 ? (
          <Box color="label">В этой категории нет особенностей.</Box>
        ) : (
          items.map((row) => <QuirkRowView key={row.name} row={row} />)
        )}
      </Section>
    </Section>
  );
};
