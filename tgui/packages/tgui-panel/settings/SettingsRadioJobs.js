import { useDispatch, useSelector } from 'common/redux';
import { useRef, useState } from 'react';
import { Box, Button, LabeledList, Stack } from 'tgui/components';

import { getRadioJobRoot } from '../chat/rootAppearance';
import { getPaneTheme } from '../themes';
import { updateSettings } from './actions';
import { createLatestEditor } from './colorCommit';
import { RADIO_JOB_COLOR_MODES, RADIO_JOB_DEFAULTS, RADIO_JOB_GROUPS, RADIO_JOB_HEAD_MARKS, RADIO_JOB_PALETTE } from './radioJobs';
import { selectSettings } from './selectors';
import { ColorInput } from './SettingsPanel';

const PALETTE_BY_ID = Object.fromEntries(
  RADIO_JOB_PALETTE.map(entry => [entry.id, entry]));

const NAMES_TOOLTIP = 'Имя говорящего в рации того же цвета, что и тег'
  + ' его должности. Работает и со скрытыми должностями.';

const ICONS_TOOLTIP = 'Значок профессии перед тегом должности: врача,'
  + ' агента внутренних дел или представителя NT видно сразу, не читая тег.'
  + ' Значок по показанной должности, свободное название идёт без значка.'
  + ' Со скрытыми должностями остаётся один значок.';

const withColor = (colors, id, value) => {
  const next = { ...colors };
  if (value) {
    next[id] = value;
  }
  else {
    delete next[id];
  }
  return next;
};

// Образцы собираются теми же классами, что приходят из рации.
const SampleTag = props => {
  const { id, text } = props;
  return (
    <span className="radio">
      <span className="name">
        <span className={'radiojob-legacy-' + id + ' radiojob radiojob-' + id}>
          [{text}]
        </span>
      </span>
    </span>
  );
};

const ChoiceRow = props => {
  const { options, selected, onSelect } = props;
  return (
    <Box>
      {options.map(option => (
        <Button
          key={option.id}
          selected={option.id === selected}
          tooltip={option.tooltip}
          onClick={() => onSelect(option.id)}>
          {option.name}
        </Button>
      ))}
    </Box>
  );
};

export const SettingsRadioJobs = props => {
  const settings = useSelector(selectSettings);
  const {
    showRadioJobs,
    radioJobColorMode,
    radioJobHeadMark,
    radioJobColorNames,
    radioJobIcons,
    radioJobColors = {},
  } = settings;
  const dispatch = useDispatch();
  const [colorsShown, setColorsShown] = useState(false);
  const colorsRef = useRef(null);
  if (!colorsRef.current) {
    colorsRef.current = createLatestEditor(
      next => dispatch(updateSettings({ radioJobColors: next })));
  }
  const colors = colorsRef.current;
  colors.sync(radioJobColors);
  const { classes, props: rootProps } = getRadioJobRoot(settings);
  const rootStyle = {};
  for (const [key, value] of Object.entries(rootProps)) {
    if (value) {
      rootStyle[key] = value;
    }
  }
  const customCount = Object.keys(radioJobColors).length;
  const isLight = getPaneTheme(settings.theme) === 'light';
  return (
    <Box>
      <Button.Checkbox
        checked={showRadioJobs !== false}
        tooltip="Тег должности перед именем говорящего в рации."
        onClick={() => dispatch(updateSettings({
          showRadioJobs: showRadioJobs === false,
        }))}>
        Должности в рации
      </Button.Checkbox>
      <Box ml={2.5} mt={0.5}>
        <LabeledList>
          <LabeledList.Item label="Цвет">
            <ChoiceRow
              options={RADIO_JOB_COLOR_MODES}
              selected={radioJobColorMode || 'department'}
              onSelect={id => dispatch(updateSettings({
                radioJobColorMode: id,
              }))}
            />
          </LabeledList.Item>
          <LabeledList.Item label="Главы">
            <ChoiceRow
              options={RADIO_JOB_HEAD_MARKS}
              selected={radioJobHeadMark || 'icon'}
              onSelect={id => dispatch(updateSettings({
                radioJobHeadMark: id,
              }))}
            />
          </LabeledList.Item>
        </LabeledList>
        <Button.Checkbox
          mt={0.5}
          checked={!!radioJobColorNames}
          tooltip={NAMES_TOOLTIP}
          onClick={() => dispatch(updateSettings({
            radioJobColorNames: !radioJobColorNames,
          }))}>
          Имя в цвет отдела
        </Button.Checkbox>
        <Button.Checkbox
          mt={0.5}
          checked={radioJobIcons !== false}
          tooltip={ICONS_TOOLTIP}
          onClick={() => dispatch(updateSettings({
            radioJobIcons: radioJobIcons === false,
          }))}>
          Значок профессии
        </Button.Checkbox>
        <Box mt={0.5}>
          <Button
            icon={colorsShown ? 'chevron-down' : 'chevron-right'}
            onClick={() => setColorsShown(!colorsShown)}>
            Цвета отделов{customCount > 0 ? ' (свои: ' + customCount + ')' : ''}
          </Button>
          <Button
            icon="undo"
            disabled={customCount === 0}
            tooltip="Вернуть цвета отделов по умолчанию."
            onClick={() => colors.update(() => ({}))}>
            Сбросить цвета
          </Button>
        </Box>
        {colorsShown && (
          <div
            className={['Chat', 'SettingsRadioJobs__colors', ...classes]
              .join(' ')}
            style={rootStyle}>
            {RADIO_JOB_GROUPS.map(group => (
              <Box key={group.name} mt={0.5}>
                <Box color="label" mb={0.25}>{group.name}</Box>
                {group.ids.map(id => {
                  const entry = PALETTE_BY_ID[id];
                  return (
                    <Stack key={id} align="center" mb={0.25}>
                      <Stack.Item shrink={0}>
                        <ColorInput
                          compact
                          value={radioJobColors[id] || ''}
                          defaultColor={(radioJobColorMode === 'legacy'
                            && entry.legacy)
                            || (isLight ? entry.light : entry.dark)}
                          placeholder="Цвет по умолчанию"
                          onChange={value => colors.update(
                            current => withColor(current, id, value))}
                          onClear={() => colors.update(
                            current => withColor(current, id, ''))}
                        />
                      </Stack.Item>
                      <Stack.Item basis="10em" shrink={0}>
                        {entry.name}
                      </Stack.Item>
                      <Stack.Item grow basis={0} style={{ minWidth: 0 }}>
                        <SampleTag id={id} text={entry.sample} />
                      </Stack.Item>
                    </Stack>
                  );
                })}
              </Box>
            ))}
          </div>
        )}
        <Button
          mt={0.5}
          icon="undo"
          onClick={() => dispatch(updateSettings({
            ...RADIO_JOB_DEFAULTS,
            showRadioJobs: true,
          }))}>
          Сбросить должности
        </Button>
      </Box>
    </Box>
  );
};
