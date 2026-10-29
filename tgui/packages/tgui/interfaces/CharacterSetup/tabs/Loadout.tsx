import { useState } from 'react';

import { useBackend } from '../../../backend';
import {
  Box,
  Button,
  Input,
  NoticeBox,
  Section,
  Stack,
} from '../../../components';
import { ColorChip, FieldRow, TabDataMissing } from '../components';

interface LoadoutColor {
  value: string | null;
  matrix: boolean;
}

interface LoadoutRow {
  id: string;
  category: string;
  name: string;
  cost: number;
  preview: string | null;
  description?: string;
  restrictions?: string | null;
  progress?: string;
  donor: boolean;
  isClothing: boolean;
  isCollar: boolean;
  isLipstick: boolean;
  canName: boolean;
  canDescription: boolean;
  canPoly: boolean;
  unlocked: boolean;
  selected: boolean;
  noPoints: boolean;
  canBuy: boolean;
  customName?: string;
  isHeirloom?: boolean;
  tagName?: string;
  examTooltip?: string;
  examTooltipAlways?: boolean;
  colors?: LoadoutColor[];
  availabilityReason?: string;
  roleMismatch?: boolean;
  roleWarning?: string;
  conflicts?: string[];
}

interface InvalidRow {
  item: string;
  data: string;
}

interface CategoryEntry {
  value: string;
  label: string;
}

interface LoadoutData {
  empty?: boolean;
  categories: CategoryEntry[];
  category: string;
  selectedView: boolean;
  selectedCount: number;
  subcategories: CategoryEntry[];
  subcategory: string;
  points: number;
  errors: number;
  slot: number;
  slotCount: number;
  presetSlot: number;
  presetName?: string | null;
  enabled: boolean;
  showCkeyId: boolean;
  items: LoadoutRow[];
  invalid: InvalidRow[];
  plannedJob?: string;
}

interface LoadoutContext {
  loadout?: LoadoutData;
}

const CATEGORY_ICONS: Record<string, string> = {
  Accessory: 'gem',
  'In backpack': 'briefcase',
  Neck: 'user-tie',
  Mask: 'mask',
  Hands: 'hand-paper',
  Uniform: 'tshirt',
  Suit: 'vest',
  Head: 'hat-cowboy',
  Shoes: 'shoe-prints',
  Gloves: 'mitten',
  Glasses: 'glasses',
  Donator: 'star',
  Unlockable: 'unlock',
  Errors: 'exclamation-triangle',
};

const ColorView = (props: { color: LoadoutColor }) => {
  const { color } = props;
  if (color.matrix) {
    return (
      <Box color="label" title="Цвет задан цветовой матрицей">
        Матрица
      </Box>
    );
  }
  return (
    <Box color={color.value || '#ffffff'} title={color.value || ''}>
      ■
    </Box>
  );
};

const GearRow = (props: { row: LoadoutRow }) => {
  const { act } = useBackend<LoadoutContext>();
  const { row } = props;
  const [expanded, setExpanded] = useState(false);
  const colors = row.colors || [];
  const mainColor = colors[0];
  const cantAfford = !row.selected && !!row.noPoints;

  return (
    <Box
      mb={1}
      p={1}
      style={{
        border:
          '1px solid ' +
          (row.selected
            ? 'rgba(120, 205, 148, 0.5)'
            : 'rgba(255, 255, 255, 0.1)'),
        borderRadius: '3px',
        backgroundColor: row.selected
          ? 'rgba(70, 165, 108, 0.12)'
          : 'rgba(0, 0, 0, 0.18)',
      }}
    >
      <Stack align="center">
        <Stack.Item width="32px">
          {row.preview ? (
            <Box
              as="img"
              src={`data:image/png;base64,${row.preview}`}
              style={{
                width: '32px',
                height: '32px',
                imageRendering: 'pixelated',
              }}
            />
          ) : (
            <Box width="32px" />
          )}
        </Stack.Item>
        <Stack.Item grow>
          <Box bold title={row.name}>
            {row.customName || row.name}
          </Box>
          <Box color="label" fontSize="0.9em">
            {row.category}
          </Box>
          {!!row.progress && (
            <Box color="label" fontSize="0.9em">
              {row.progress}
            </Box>
          )}
          {!!row.isHeirloom && (
            <Box color="label" fontSize="0.9em">
              Ваша семейная реликвия!
            </Box>
          )}
        </Stack.Item>
        {!!row.selected && (
          <Stack.Item>
            <Button
              icon={expanded ? 'chevron-up' : 'sliders-h'}
              selected={expanded}
              tooltip={
                expanded
                  ? 'Свернуть настройки вещи'
                  : 'Настроить цвет, имя и описание'
              }
              onClick={() => setExpanded(!expanded)}
            />
          </Stack.Item>
        )}
        <Stack.Item width="76px">
          <Box textAlign="right" color={cantAfford ? 'red' : undefined}>
            {row.cost} оч.
          </Box>
        </Stack.Item>
        <Stack.Item width="88px">
          <Button
            fluid
            icon={row.selected ? 'minus' : 'plus'}
            content={row.selected ? 'Убрать' : 'Взять'}
            selected={row.selected}
            disabled={!row.selected && !row.canBuy}
            tooltip={row.selected ? 'Убрать вещь из набора' : row.availabilityReason}
            onClick={() => act('loadout_toggle_gear', { name: row.id })}
          />
        </Stack.Item>
      </Stack>

      {!!row.restrictions && (
        <Box color="label" fontSize="0.9em">
          {row.restrictions}
        </Box>
      )}
      {!!row.roleWarning && (
        <Box color="average" mt={0.5}>{row.roleWarning}</Box>
      )}
      {!!row.availabilityReason && (
        <Box color="average" mt={0.5}>{row.availabilityReason}</Box>
      )}
      {!!row.conflicts?.length && (
        <Box color="average" mt={0.5}>
          Общий слот с: {row.conflicts.join(', ')}.{' '}
        </Box>
      )}
      {!!row.description && (
        <Box color="label" fontSize="0.9em">
          {row.description}
        </Box>
      )}

      {!row.selected ? (
        !!row.noPoints && (
          <Box color="label" fontSize="0.9em">
            Не хватает очков.
          </Box>
        )
      ) : expanded ? (
        <Box
          mt={1}
          pl={1}
          style={{ borderLeft: '2px solid rgba(255,255,255,0.15)' }}
        >
          <FieldRow
            label="Цвет"
            labelBasis="150px"
            tooltip="Цветовая матрица или сложный режим меняется в колормейте."
          >
            <Button
              content="Колормейт"
              onClick={() => act('loadout_open_color', { name: row.id })}
            />
            {!!mainColor && (
              <Box inline ml={1}>
                {mainColor.matrix ? (
                  <ColorView color={mainColor} />
                ) : (
                  <ColorChip
                    value={mainColor.value}
                    action="loadout_set_poly_color"
                    params={{ name: row.id, index: 1 }}
                  />
                )}
              </Box>
            )}
          </FieldRow>

          {!!row.canPoly && colors.length > 1 && (
            <FieldRow label="Каналы" labelBasis="150px">
              {colors.map((color, index) =>
                index === 0 ? null : (
                  <Box key={index + 1} inline mr={1}>
                    {color.matrix ? (
                      <ColorView color={color} />
                    ) : (
                      <ColorChip
                        value={color.value}
                        action="loadout_set_poly_color"
                        params={{ name: row.id, index: index + 1 }}
                        tooltip={`Канал ${index + 1}`}
                      />
                    )}
                  </Box>
                )
              )}
            </FieldRow>
          )}

          {!!row.canName && (
            <FieldRow label="Имя" labelBasis="150px">
              <Button
                icon="pen"
                content={row.customName || 'Переименовать'}
                onClick={() => act('loadout_set_name', { name: row.id })}
              />
            </FieldRow>
          )}

          {!!row.canDescription && (
            <FieldRow label="Описание" labelBasis="150px">
              <Button
                icon="file-alt"
                content={row.description ? 'Изменить' : 'Добавить'}
                onClick={() => act('loadout_set_description', { name: row.id })}
              />
            </FieldRow>
          )}

          <FieldRow label="Семейная реликвия" labelBasis="150px">
            <Button.Confirm
              content={row.isHeirloom ? 'Снять' : 'Взять'}
              confirmContent={row.isHeirloom ? 'Снять?' : 'Взять?'}
              selected={!!row.isHeirloom}
              onClick={() =>
                act('loadout_set_heirloom', {
                  name: row.id,
                  value: row.isHeirloom ? 0 : 1,
                })
              }
            />
          </FieldRow>

          {!!row.isClothing && (
            <FieldRow label="Подсказка при осмотре" labelBasis="150px">
              <Button
                icon="comment"
                content={row.examTooltip ? 'Изменить' : 'Добавить'}
                onClick={() => act('loadout_set_examtooltip', { name: row.id })}
              />
            </FieldRow>
          )}

          {!!row.isCollar && (
            <FieldRow label="Имя на бирке" labelBasis="150px">
              <Button
                icon="tag"
                content={row.tagName || 'Задать'}
                onClick={() => act('loadout_set_tagname', { name: row.id })}
              />
            </FieldRow>
          )}

          {!!row.isLipstick && (
            <FieldRow label="Цвет помады" labelBasis="150px">
              <Button
                icon="palette"
                content="Выбрать"
                onClick={() =>
                  act('loadout_pick_lipstick_color', { name: row.id })
                }
              />
            </FieldRow>
          )}
        </Box>
      ) : null}
    </Box>
  );
};

export const LoadoutTab = () => {
  const { act, data } = useBackend<LoadoutContext>();
  const loadout = data.loadout;
  const [search, setSearch] = useState('');

  if (!loadout) {
    return <TabDataMissing title="Экипировка" />;
  }

  if (loadout.empty) {
    return (
      <Section fill scrollable title="Экипировка">
        <NoticeBox>Каталог лодаута пуст.</NoticeBox>
      </Section>
    );
  }

  const slots: number[] = [];
  for (let i = 1; i <= loadout.slotCount; i += 1) {
    slots.push(i);
  }

  const isErrors = !loadout.selectedView && loadout.category === 'Errors';
  const query = search.trim().toLocaleLowerCase();
  const items = loadout.items.filter((row) =>
    [row.name, row.customName, row.description, row.category].some((text) =>
      text?.toLocaleLowerCase().includes(query)
    )
  );

  return (
    <Section fill scrollable title="Экипировка">
      {!!loadout.selectedView && (
        <Box color="label" mb={1}>
          Проверка профессии: {loadout.plannedJob || 'профессия с приоритетом не выбрана'}.{' '}
        </Box>
      )}
      {!loadout.enabled && (
        <NoticeBox warning>
          Стандартная одежда останется на персонаже. Вещи лодаута для занятых
          слотов будут помещены в сумку; пустые слоты заполнятся как обычно.
        </NoticeBox>
      )}
      <Stack align="center" mb={1} wrap>
        <Stack.Item>
          <Stack>
            <Stack.Item>
              <Button
                compact
                icon="layer-group"
                selected={loadout.slot === loadout.presetSlot}
                content="Пресет"
                tooltip={loadout.presetName
                  ? `Отдельный комплект пресета «${loadout.presetName}»`
                  : 'Отдельный комплект для пресета. Его можно настроить вручную или скопировать из общего слота.'}
                onClick={() => act('loadout_select_slot', { slot: loadout.presetSlot })}
              />
            </Stack.Item>
            {slots.map((slot) => (
              <Stack.Item key={slot}>
                <Button
                  compact
                  width="26px"
                  selected={loadout.slot === slot}
                  content={slot}
                  onClick={() => act('loadout_select_slot', { slot })}
                />
              </Stack.Item>
            ))}
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Box bold color={loadout.points <= 0 ? 'red' : undefined} nowrap>
            Осталось очков: {loadout.points}
          </Box>
        </Stack.Item>
        <Stack.Item grow={1} />
        <Stack.Item>
          <Button
            icon={loadout.enabled ? 'check-square-o' : 'square-o'}
            selected={loadout.enabled}
            content="Заменять"
            tooltip="Включено: одежда лодаута заменяет стандартную, снятые вещи помещаются в сумку. Выключено: стандартная одежда остаётся, а вещи лодаута для занятых слотов отправляются в сумку. Пустые слоты заполняются в обоих режимах."
            onClick={() => act('loadout_toggle_enabled')}
          />
        </Stack.Item>
        <Stack.Item>
          <Button.Confirm
            icon="eraser"
            color="bad"
            content="Очистить"
            confirmContent="Очистить слот?"
            onClick={() => act('loadout_clear')}
          />
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="copy"
            content="Копировать"
            onClick={() => act('loadout_copy_slot')}
          />
        </Stack.Item>
        {loadout.slot !== loadout.presetSlot && (
          <Stack.Item>
            <Button
              icon="file-import"
              content="В пресет"
              tooltip="Скопировать текущий общий лодаут в отдельный комплект пресета и перейти к нему"
              onClick={() => act('loadout_copy_slot', {
                target: loadout.presetSlot, activate: true,
              })}
            />
          </Stack.Item>
        )}
      </Stack>

      <Box mb={1} style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
        <Button
          icon="check-double"
          selected={loadout.selectedView}
          content={'Выбрано (' + loadout.selectedCount + ')'}
          onClick={() => {
            setSearch('');
            act('loadout_selected');
          }}
        />
        {loadout.categories.map((category) => (
          <Button
            key={category.value}
            icon={CATEGORY_ICONS[category.value] || 'box'}
            selected={
              !loadout.selectedView && loadout.category === category.value
            }
            content={
              category.value === 'Errors' && loadout.errors > 0
                ? `${category.label} (!)`
                : category.label
            }
            onClick={() => {
              setSearch('');
              act('loadout_select_category', { value: category.value });
            }}
          />
        ))}
      </Box>

      {!isErrors &&
        !loadout.selectedView &&
        loadout.subcategories.length > 0 && (
          <Box mb={1} style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
            {loadout.subcategories.map((subcategory) => (
              <Button
                key={subcategory.value}
                selected={loadout.subcategory === subcategory.value}
                content={subcategory.label}
                onClick={() =>
                  act('loadout_select_subcategory', {
                    value: subcategory.value,
                  })
                }
              />
            ))}
          </Box>
        )}

      {!!loadout.showCkeyId && (
        <Button
          icon="key"
          content="Получить свой ckey ID"
          mb={1}
          onClick={() => act('loadout_show_ckey_id')}
        />
      )}

      {!isErrors && (
        <Input
          fluid
          mb={1}
          placeholder={
            loadout.selectedView
              ? 'Поиск среди выбранных вещей'
              : 'Поиск в категории'
          }
          value={search}
          onInput={(event, value) => setSearch(value)}
        />
      )}
      {isErrors ? (
        <Section>
          {loadout.invalid.length === 0 ? (
            <Box color="label">Битых записей в этом слоте нет.</Box>
          ) : (
            loadout.invalid.map((row) => (
              <Stack key={row.data} mb={1}>
                <Stack.Item>
                  <Button
                    icon="trash"
                    color="bad"
                    content={row.item || 'без пути'}
                    disabled={!row.item}
                    onClick={() =>
                      act('loadout_clear_invalid', { item: row.item })
                    }
                  />
                </Stack.Item>
                <Stack.Item grow>
                  <Box color="label">{row.data}</Box>
                </Stack.Item>
              </Stack>
            ))
          )}
        </Section>
      ) : (
        <Section>
          {items.length === 0 ? (
            <Box color="label">
              {query
                ? 'По вашему запросу ничего не найдено.'
                : loadout.selectedView
                  ? 'В этом наборе пока ничего не выбрано. Добавьте вещи из каталога.'
                  : 'В этой подкатегории нет доступных вещей.'}
            </Box>
          ) : (
            items.map((row) => <GearRow key={row.id} row={row} />)
          )}
        </Section>
      )}
    </Section>
  );
};
