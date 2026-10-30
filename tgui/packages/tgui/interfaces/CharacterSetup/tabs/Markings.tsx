import { useBackend } from '../../../backend';
import { Box, Button, Dropdown, Section, Stack } from '../../../components';
import { ColorChip, SettingsGrid, TabDataMissing } from '../components';

export interface MarkingColor {
  index: number;
  value: string;
}

export interface MarkingRow {
  index: number;
  name: string;
  colors: MarkingColor[];
  glow: boolean;
}

export interface MarkingLimb {
  name: string;
  label: string;
  markings: MarkingRow[];
}

export interface MarkingsData {
  supported: boolean;
  hasMarkings: boolean;
  total: number;
  limbs: MarkingLimb[];
}

interface MarkingsContext {
  emissivesAllowed: boolean;
  markings?: MarkingsData;
  markingOptions?: Record<string, string[]>;
}

const MarkingRowView = (props: { row: MarkingRow; total: number; limb: string }) => {
  const { act, data } = useBackend<MarkingsContext>();
  const { row, total } = props;
  const first = row.index <= 1;
  const last = row.index >= total;

  return (
    <Box
      p={1}
      mb={1}
      style={{
        border: '1px solid rgba(255,255,255,0.12)',
        borderRadius: '2px',
        background: 'rgba(0,0,0,0.2)',
      }}
    >
      <Stack align="center">
        <Stack.Item width="34px">
          <Box color="label" textAlign="right" nowrap>
            #{row.index}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="angle-double-up"
            disabled={first}
            tooltip="В начало"
            onClick={() =>
              act('marking_move', { index: row.index, mode: 'top' })
            }
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="angle-up"
            disabled={first}
            tooltip="Вверх"
            onClick={() =>
              act('marking_move', { index: row.index, mode: 'up' })
            }
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="angle-down"
            disabled={last}
            tooltip="Вниз"
            onClick={() =>
              act('marking_move', { index: row.index, mode: 'down' })
            }
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="angle-double-down"
            disabled={last}
            tooltip="В конец"
            onClick={() =>
              act('marking_move', { index: row.index, mode: 'bottom' })
            }
          />
        </Stack.Item>
        <Stack.Item grow={1} />
        {!!data.emissivesAllowed && (
          <Stack.Item>
            <Button
              className="CharacterSetup__icon-button"
              icon="lightbulb"
              selected={row.glow}
              tooltip={row.glow ? 'Свечение включено' : 'Свечение выключено'}
              aria-label="Свечение маркинга"
              onClick={() => act('marking_glow', { index: row.index })}
            />
          </Stack.Item>
        )}
        <Stack.Item>
          <Button
            icon="times"
            color="bad"
            tooltip="Удалить"
            onClick={() => act('marking_remove', { index: row.index })}
          />
        </Stack.Item>
      </Stack>

      <Stack align="center" mt={1}>
        <Stack.Item>
          <Button
            className="CharacterSetup__cycle-arrow"
            icon="chevron-left"
            tooltip="Предыдущая разметка"
            onClick={() =>
              act('marking_cycle', { index: row.index, dir: 'prev' })
            }
          />
        </Stack.Item>
        <Stack.Item grow textAlign="center">
          <Dropdown width="100%" searchable selected={row.name}
            options={data.markingOptions?.[props.limb] || []}
            onSelected={(value) => act('marking_set', { index: row.index, value })} />
        </Stack.Item>
        <Stack.Item>
          <Button
            className="CharacterSetup__cycle-arrow"
            icon="chevron-right"
            tooltip="Следующая разметка"
            onClick={() =>
              act('marking_cycle', { index: row.index, dir: 'next' })
            }
          />
        </Stack.Item>
      </Stack>

      {row.colors.length > 0 && (
        <Stack align="center" mt={1}>
          <Stack.Item>
            <Box color="label">Цвета</Box>
          </Stack.Item>
          {row.colors.map((chip) => (
            <Stack.Item key={chip.index}>
              <ColorChip
                value={chip.value}
                action="set_marking_color"
                params={{ index: row.index, colorIndex: chip.index }}
              />
            </Stack.Item>
          ))}
        </Stack>
      )}
    </Box>
  );
};

const MarkingLimbCard = (props: { limb: MarkingLimb; total: number }) => {
  const { act, data } = useBackend<MarkingsContext>();
  const { limb, total } = props;
  const hasMarkings = limb.markings.length > 0;
  const options = data.markingOptions?.[limb.name] || [];

  return (
    <Box
      data-search-label={limb.label}
      p={1}
      style={{
        width: '100%',
        border: '1px solid rgba(255,255,255,0.15)',
        borderRadius: '2px',
      }}
    >
      <Stack align="center" mb={1}>
        <Stack.Item grow>
          <Box bold className="CharacterSetup__limb-title">{limb.label}</Box>
        </Stack.Item>
        <Stack.Item>
          <Button.Confirm
            icon="eraser"
            color="bad"
            content="Очистить"
            confirmContent="Очистить?"
            disabled={!hasMarkings}
            onClick={() => act('marking_clear_limb', { limb: limb.name })}
          />
        </Stack.Item>
      </Stack>

      <Box mb={1}>
        <Dropdown
          width="100%"
          icon="plus"
          selected={null}
          displayText="Добавить маркинг…"
          aria-label={'Добавить маркинг: ' + limb.label}
          options={options}
          disabled={!options.length}
          onSelected={(value) => act('marking_add', { limb: limb.name, value })}
        />
      </Box>

      {!hasMarkings ? (
        <Box color="label">На этой части тела нет разметок.</Box>
      ) : (
        <Box
          className="CharacterSetup__limb-markings"
          maxHeight="280px"
          overflowY="auto"
        >
          {limb.markings.map((row) => (
            <MarkingRowView key={row.index} row={row} total={total} limb={limb.name} />
          ))}
        </Box>
      )}
    </Box>
  );
};

export const MarkingsTab = () => {
  const { act, data } = useBackend<MarkingsContext>();
  const markings = data.markings;

  if (!markings) {
    return <TabDataMissing title="Маркинги" />;
  }

  if (!markings.supported) {
    return (
      <Section fill scrollable title="Маркинги">
        <Box color="label">Ваш вид не умеет наносить отметины на тело.</Box>
      </Section>
    );
  }

  return (
    <Section fill scrollable title="Маркинги">
      <Stack align="center" wrap="wrap" mb={1}>
        <Stack.Item>
          <Button
            icon="user-tag"
            content="Татуировки персонажа"
            tooltip="Отдельное окно управления татуировками."
            onClick={() => act('open_tattoo_manager')}
          />
        </Stack.Item>
        <Stack.Item grow basis="230px">
          <Dropdown
            width="100%"
            icon="plus"
            selected={null}
            displayText="Добавить на всё тело…"
            aria-label="Добавить маркинг на всё тело"
            options={data.markingOptions?.All || []}
            disabled={!data.markingOptions?.All?.length}
            onSelected={(value) => act('marking_add', { limb: 'All', value })}
          />
        </Stack.Item>
        <Stack.Item>
          <Button.Confirm
            icon="trash"
            color="bad"
            content="Удалить все маркинги"
            confirmContent="Удалить все маркинги?"
            confirmIcon="trash"
            disabled={!markings.hasMarkings}
            onClick={() => act('markings_remove')}
          />
        </Stack.Item>
      </Stack>

      <SettingsGrid>
        {(markings.limbs || []).map((limb) => (
          <MarkingLimbCard
            key={limb.name}
            limb={limb}
            total={markings.total || 0}
          />
        ))}
      </SettingsGrid>
    </Section>
  );
};
