/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { toFixed } from 'common/math';
import { useDispatch, useSelector } from 'common/redux';
import { useLocalState } from 'tgui/backend';
import { Box, Button, Divider, Dropdown, Flex, Input, LabeledList, NumberInput, Section, Stack, Tabs, TextArea } from 'tgui/components';

import { ChatPageSettings } from '../chat';
import { rebuildChat, saveChatToDisk } from '../chat/actions';
import { THEMES } from '../themes';
import { changeSettingsTab, updateSettings } from './actions';
import { CHAT_ANIM_SPEEDS, CHAT_ANIMATIONS, CHAT_BG_ANIMATIONS, CHAT_STYLES, FONTS, MESSAGE_STYLE_ANIMATIONS, MESSAGE_STYLE_FONTS, MESSAGE_STYLES, SETTINGS_TABS, TEXT_GLOW_OPTIONS, TIME_DIVIDER_INTERVALS, TIMESTAMP_FORMATS } from './constants';
import { selectActiveTab, selectSettings } from './selectors';

/**
 * Color input with a native color picker and text field.
 */
const ColorInput = (props) => {
  const { value, defaultColor, placeholder, onChange, onClear } = props;
  const displayColor = value || defaultColor || '#000000';
  // Native color picker needs a valid 7-char hex
  const pickerColor = /^#[0-9a-fA-F]{6}$/.test(displayColor)
    ? displayColor : '#000000';
  return (
    <Stack inline align="center">
      <Stack.Item>
        <Box
          as="input"
          type="color"
          value={pickerColor}
          style={{
            'width': '22px',
            'height': '22px',
            'padding': '0',
            'border': '1px solid rgba(255,255,255,0.2)',
            'border-radius': '2px',
            'background': 'transparent',
            'cursor': 'pointer',
          }}
          onChange={e => onChange(e.target.value)}
        />
      </Stack.Item>
      <Stack.Item>
        <Input
          width="6em"
          monospace
          placeholder={placeholder}
          value={value}
          onInput={(e, v) => onChange(v)}
        />
      </Stack.Item>
      {!!value && onClear && (
        <Stack.Item>
          <Button
            icon="times"
            ml={1}
            onClick={onClear}
          />
        </Stack.Item>
      )}
    </Stack>
  );
};

export const SettingsPanel = (props, context) => {
  const activeTab = useSelector(context, selectActiveTab);
  const dispatch = useDispatch(context);
  return (
    <Stack fill>
      <Stack.Item>
        <Section fitted fill minHeight="8em">
          <Tabs vertical>
            {SETTINGS_TABS.map(tab => (
              <Tabs.Tab
                key={tab.id}
                selected={tab.id === activeTab}
                onClick={() => dispatch(changeSettingsTab({
                  tabId: tab.id,
                }))}>
                {tab.name}
              </Tabs.Tab>
            ))}
          </Tabs>
        </Section>
      </Stack.Item>
      <Stack.Item grow={1} basis={0}>
        {activeTab === 'general' && (
          <SettingsGeneral />
        )}
        {activeTab === 'appearance' && (
          <SettingsAppearance />
        )}
        {activeTab === 'textStyles' && (
          <SettingsTextStyles />
        )}
        {activeTab === 'chatPage' && (
          <ChatPageSettings />
        )}
      </Stack.Item>
    </Stack>
  );
};

export const SettingsGeneral = (props, context) => {
  const {
    theme,
    fontFamily,
    fontSize,
    lineHeight,
    highlightText,
    highlightColor,
    highlightSoundEnabled,
    matchWord,
    matchCase,
    enableTimestamps,
    timestampFormat,
    enableTimeDividers,
    timeDividerInterval,
  } = useSelector(context, selectSettings);
  const dispatch = useDispatch(context);
  const [freeFont, setFreeFont] = useLocalState(context, "freeFont", false);
  const selectedTsFormat = TIMESTAMP_FORMATS.find(
    f => f.id === timestampFormat);
  const selectedDivInterval = TIME_DIVIDER_INTERVALS.find(
    i => i.id === timeDividerInterval);
  return (
    <Section>
      <LabeledList>
        <LabeledList.Item label="Тема">
          <Dropdown
            selected={theme}
            options={THEMES}
            onSelected={value => dispatch(updateSettings({
              theme: value,
            }))} />
        </LabeledList.Item>
        <LabeledList.Item label="Шрифт">
          <Stack inline align="baseline">
            <Stack.Item>
              {!freeFont && (
                <Dropdown
                  selected={fontFamily}
                  options={FONTS}
                  onSelected={value => dispatch(updateSettings({
                    fontFamily: value,
                  }))} />
              ) || (
                <Input
                  value={fontFamily}
                  onChange={(e, value) => dispatch(updateSettings({
                    fontFamily: value,
                  }))}
                />
              )}
            </Stack.Item>
            <Stack.Item>
              <Button
                content="Свой шрифт"
                icon={freeFont? "lock-open" : "lock"}
                color={freeFont? "good" : "bad"}
                ml={1}
                onClick={() => {
                  setFreeFont(!freeFont);
                }}
              />
            </Stack.Item>
          </Stack>
        </LabeledList.Item>
        <LabeledList.Item label="Размер шрифта">
          <NumberInput
            width="4em"
            step={1}
            stepPixelSize={10}
            minValue={8}
            maxValue={32}
            value={fontSize}
            unit="px"
            format={value => toFixed(value)}
            onChange={(e, value) => dispatch(updateSettings({
              fontSize: value,
            }))} />
        </LabeledList.Item>
        <LabeledList.Item label="Высота строки">
          <NumberInput
            width="4em"
            step={0.01}
            stepPixelSize={2}
            minValue={0.8}
            maxValue={5}
            value={lineHeight}
            format={value => toFixed(value, 2)}
            onDrag={(e, value) => dispatch(updateSettings({
              lineHeight: value,
            }))} />
        </LabeledList.Item>
      </LabeledList>
      <Divider />
      <Box>
        <Flex mb={1} color="label" align="baseline">
          <Flex.Item grow={1}>
            Подсветка текста (через запятую):
          </Flex.Item>
          <Flex.Item shrink={0}>
            <ColorInput
              value={highlightColor}
              defaultColor="#ffdd44"
              placeholder="#ffdd44"
              onChange={v => dispatch(updateSettings({
                highlightColor: v,
              }))}
            />
          </Flex.Item>
        </Flex>
        <TextArea
          height="3em"
          value={highlightText}
          onInput={(e, value) => dispatch(updateSettings({
            highlightText: value,
          }))} />
        <Button.Checkbox
          checked={highlightSoundEnabled}
          onClick={() => dispatch(updateSettings({
            highlightSoundEnabled: !highlightSoundEnabled,
          }))}>
          Звук при подсветке
        </Button.Checkbox>
        <Button.Checkbox
          checked={matchWord}
          tooltipPosition="bottom-start"
          tooltip="Не совместимо с пунктуацией."
          onClick={() => dispatch(updateSettings({
            matchWord: !matchWord,
          }))}>
          Целое слово
        </Button.Checkbox>
        <Button.Checkbox
          checked={matchCase}
          onClick={() => dispatch(updateSettings({
            matchCase: !matchCase,
          }))}>
          Учитывать регистр
        </Button.Checkbox>
      </Box>
      <Divider />
      <Button.Checkbox
        checked={enableTimestamps}
        onClick={() => {
          dispatch(updateSettings({
            enableTimestamps: !enableTimestamps,
          }));
          dispatch(rebuildChat());
        }}>
        Время сообщений
      </Button.Checkbox>
      {enableTimestamps && (
        <Box ml={2.5} mb={0.5}>
          <LabeledList>
            <LabeledList.Item label="Формат">
              <Dropdown
                selected={selectedTsFormat?.name
                  || TIMESTAMP_FORMATS[0].name}
                options={TIMESTAMP_FORMATS.map(f => f.name)}
                onSelected={value => {
                  const fmt = TIMESTAMP_FORMATS.find(
                    f => f.name === value);
                  dispatch(updateSettings({
                    timestampFormat: fmt?.id || 'hm',
                  }));
                  dispatch(rebuildChat());
                }}
              />
            </LabeledList.Item>
          </LabeledList>
        </Box>
      )}
      <Button.Checkbox
        checked={enableTimeDividers}
        onClick={() => {
          dispatch(updateSettings({
            enableTimeDividers: !enableTimeDividers,
          }));
          dispatch(rebuildChat());
        }}>
        Разделители по времени
      </Button.Checkbox>
      {enableTimeDividers && (
        <Box ml={2.5} mb={0.5}>
          <LabeledList>
            <LabeledList.Item label="Интервал">
              <Dropdown
                selected={selectedDivInterval?.name
                  || TIME_DIVIDER_INTERVALS[1].name}
                options={TIME_DIVIDER_INTERVALS.map(i => i.name)}
                onSelected={value => {
                  const interval = TIME_DIVIDER_INTERVALS.find(
                    i => i.name === value);
                  dispatch(updateSettings({
                    timeDividerInterval: interval?.id || 300000,
                  }));
                  dispatch(rebuildChat());
                }}
              />
            </LabeledList.Item>
          </LabeledList>
        </Box>
      )}
      <Divider />
      <Box>
        <Button
          icon="check"
          onClick={() => dispatch(rebuildChat())}>
          Применить
        </Button>
        <Box inline fontSize="0.9em" ml={1} color="label">
          Может подвесить чат на некоторое время.
        </Box>
      </Box>
      <Divider />
      <Button
        icon="save"
        onClick={() => dispatch(saveChatToDisk())}>
        Сохранить лог чата
      </Button>
    </Section>
  );
};

// Инлайн-стиль превью: настройки применяются к чату через переменные
// и динамическую таблицу на корне .Chat, панель настроек ими не
// покрывается, поэтому превью собирает те же значения инлайном.
const getStylePreviewStyle = (override, spanAnimations) => {
  if (!override || override.disabled) {
    return undefined;
  }
  const style = {};
  if (override.color) {
    style['color'] = override.color;
  }
  if (override.font === 'normal') {
    style['font-weight'] = 'normal';
    style['font-style'] = 'normal';
  }
  else if (override.font === 'italic') {
    style['font-weight'] = 'normal';
    style['font-style'] = 'italic';
  }
  else if (override.font === 'bold') {
    style['font-weight'] = 'bold';
    style['font-style'] = 'normal';
  }
  else if (override.font === 'bolditalic') {
    style['font-weight'] = 'bold';
    style['font-style'] = 'italic';
  }
  const size = parseFloat(override.size);
  if (size && size !== 100) {
    style['font-size'] = Math.min(200, Math.max(50, size)) + '%';
  }
  // Как и в чате (.Chat--fxAnimOff), глобальный тумблер гасит
  // пользовательские анимации и в превью.
  if (spanAnimations !== false) {
    const anim = MESSAGE_STYLE_ANIMATIONS.find(a => a.id === override.anim);
    if (anim?.css) {
      style['animation'] = anim.css;
    }
  }
  return Object.keys(style).length > 0 ? style : undefined;
};

const MessageStyleRow = (props, context) => {
  const { style, override, setOverride, spanAnimations } = props;
  const selectedFont = MESSAGE_STYLE_FONTS.find(
    f => f.id === (override.font || ''));
  const selectedAnim = MESSAGE_STYLE_ANIMATIONS.find(
    a => a.id === (override.anim || ''));
  return (
    <Box mb={1.5}>
      <Stack align="center" mb={0.5}>
        <Stack.Item grow>
          <Box as="span" bold color="label" mr={1}>
            {style.name}:
          </Box>
          {!override.disabled && (
            <Box
              as="span"
              className={style.id}
              style={getStylePreviewStyle(override, spanAnimations)}>
              {style.example}
            </Box>
          ) || (
            <Box as="span">
              {style.example}
            </Box>
          )}
        </Stack.Item>
        <Stack.Item shrink={0}>
          <Button.Checkbox
            checked={!!override.disabled}
            tooltip="Показывать как обычный текст"
            onClick={() => setOverride(style.id, {
              disabled: !override.disabled,
            })}>
            Откл.
          </Button.Checkbox>
        </Stack.Item>
      </Stack>
      {!override.disabled && (
        <Flex wrap align="center">
          <Flex.Item mr={1} mb={0.5}>
            <ColorInput
              value={override.color || ''}
              placeholder="авто"
              onChange={v => setOverride(style.id, {
                color: v,
              })}
              onClear={() => setOverride(style.id, {
                color: '',
              })}
            />
          </Flex.Item>
          <Flex.Item mr={1} mb={0.5}>
            <Dropdown
              width="8em"
              selected={selectedFont?.name || MESSAGE_STYLE_FONTS[0].name}
              options={MESSAGE_STYLE_FONTS.map(f => f.name)}
              onSelected={value => {
                const font = MESSAGE_STYLE_FONTS.find(f => f.name === value);
                setOverride(style.id, {
                  font: font?.id || '',
                });
              }}
            />
          </Flex.Item>
          <Flex.Item mr={1} mb={0.5}>
            <NumberInput
              width="5.5em"
              step={5}
              stepPixelSize={4}
              minValue={50}
              maxValue={200}
              unit="%"
              value={parseFloat(override.size) || 100}
              format={value => toFixed(value)}
              onChange={(e, value) => setOverride(style.id, {
                size: value,
              })}
            />
          </Flex.Item>
          <Flex.Item mb={0.5}>
            <Dropdown
              width="8em"
              selected={selectedAnim?.name || MESSAGE_STYLE_ANIMATIONS[0].name}
              options={MESSAGE_STYLE_ANIMATIONS.map(a => a.name)}
              onSelected={value => {
                const anim = MESSAGE_STYLE_ANIMATIONS.find(
                  a => a.name === value);
                setOverride(style.id, {
                  anim: anim?.id || '',
                });
              }}
            />
          </Flex.Item>
        </Flex>
      )}
    </Box>
  );
};

export const SettingsTextStyles = (props, context) => {
  const {
    styleOverrides,
    spanAnimations,
  } = useSelector(context, selectSettings);
  const dispatch = useDispatch(context);
  const setOverride = (styleId, patch) => {
    const prevEntry = styleOverrides?.[styleId] || {};
    dispatch(updateSettings({
      styleOverrides: {
        ...styleOverrides,
        [styleId]: {
          ...prevEntry,
          ...patch,
        },
      },
    }));
  };
  return (
    <Section>
      <Box color="label" mb={1}>
        Настройте вид частых стилей сообщений под себя: цвет,
        начертание, размер и анимацию - или полностью стандартный
        текст. Пустой цвет и вариант Тема = как в оформлении темы.
      </Box>
      {MESSAGE_STYLES.map(style => (
        <MessageStyleRow
          key={style.id}
          style={style}
          override={styleOverrides?.[style.id] || {}}
          setOverride={setOverride}
          spanAnimations={spanAnimations}
        />
      ))}
      <Divider />
      <Button.Checkbox
        checked={spanAnimations !== false}
        tooltip="Мерцание и пульсация особых стилей: гипноз, глитч ИИ, помехи, делам и т.п. Выключает и ваши анимации выше."
        onClick={() => dispatch(updateSettings({
          spanAnimations: spanAnimations === false,
        }))}>
        Анимации особых стилей
      </Button.Checkbox>
      <Divider />
      <Button
        icon="undo"
        onClick={() => dispatch(updateSettings({
          styleOverrides: {},
          spanAnimations: true,
        }))}>
        Сбросить стили текста
      </Button>
    </Section>
  );
};

export const SettingsAppearance = (props, context) => {
  const {
    chatStyle,
    chatAnimation,
    chatAnimSpeed,
    chatBgColor,
    chatTextColor,
    chatAccentColor,
    smoothScroll,
    hoverEffect,
    chatBgAnimation,
    chatBgAnimOpacity,
    textGlow,
    textGlowColor,
    messageSpacing,
    fontWeight,
    letterSpacing,
    borderRadius,
  } = useSelector(context, selectSettings);
  const dispatch = useDispatch(context);
  const selectedStyle = CHAT_STYLES.find(s => s.id === chatStyle);
  const selectedAnim = CHAT_ANIMATIONS.find(a => a.id === chatAnimation);
  const selectedSpeed = CHAT_ANIM_SPEEDS.find(s => s.id === chatAnimSpeed);
  const selectedBgAnim = CHAT_BG_ANIMATIONS.find(
    a => a.id === chatBgAnimation);
  const selectedGlow = TEXT_GLOW_OPTIONS.find(g => g.id === textGlow);
  return (
    <Section>
      <LabeledList>
        <LabeledList.Item label="Стиль чата">
          <Dropdown
            selected={selectedStyle?.name || CHAT_STYLES[0].name}
            options={CHAT_STYLES.map(s => s.name)}
            onSelected={value => {
              const style = CHAT_STYLES.find(s => s.name === value);
              dispatch(updateSettings({
                chatStyle: style?.id || 'classic',
              }));
            }}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Анимация сообщений">
          <Dropdown
            selected={selectedAnim?.name || CHAT_ANIMATIONS[0].name}
            options={CHAT_ANIMATIONS.map(a => a.name)}
            onSelected={value => {
              const anim = CHAT_ANIMATIONS.find(a => a.name === value);
              dispatch(updateSettings({
                chatAnimation: anim?.id || 'none',
              }));
            }}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Скорость анимации">
          <Dropdown
            selected={selectedSpeed?.name || CHAT_ANIM_SPEEDS[1].name}
            options={CHAT_ANIM_SPEEDS.map(s => s.name)}
            onSelected={value => {
              const speed = CHAT_ANIM_SPEEDS.find(s => s.name === value);
              dispatch(updateSettings({
                chatAnimSpeed: speed?.id || 'normal',
              }));
            }}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Анимация фона">
          <Dropdown
            selected={selectedBgAnim?.name || CHAT_BG_ANIMATIONS[0].name}
            options={CHAT_BG_ANIMATIONS.map(a => a.name)}
            onSelected={value => {
              const anim = CHAT_BG_ANIMATIONS.find(a => a.name === value);
              dispatch(updateSettings({
                chatBgAnimation: anim?.id || 'none',
              }));
            }}
          />
        </LabeledList.Item>
        {chatBgAnimation !== 'none' && (
          <LabeledList.Item label="Яркость фона">
            <NumberInput
              width="4em"
              step={0.05}
              stepPixelSize={5}
              minValue={0.05}
              maxValue={1}
              value={chatBgAnimOpacity}
              format={value => toFixed(value, 2)}
              onChange={(e, value) => dispatch(updateSettings({
                chatBgAnimOpacity: value,
              }))}
            />
          </LabeledList.Item>
        )}
      </LabeledList>
      <Divider />
      <LabeledList>
        <LabeledList.Item label="Свечение текста">
          <Dropdown
            selected={selectedGlow?.name || TEXT_GLOW_OPTIONS[0].name}
            options={TEXT_GLOW_OPTIONS.map(g => g.name)}
            onSelected={value => {
              const glow = TEXT_GLOW_OPTIONS.find(g => g.name === value);
              dispatch(updateSettings({
                textGlow: glow?.id || 'none',
              }));
            }}
          />
        </LabeledList.Item>
        {textGlow !== 'none' && (
          <LabeledList.Item label="Цвет свечения">
            <ColorInput
              value={textGlowColor}
              defaultColor={chatAccentColor || '#ffdd44'}
              placeholder="#ffdd44"
              onChange={v => dispatch(updateSettings({
                textGlowColor: v,
              }))}
              onClear={() => dispatch(updateSettings({
                textGlowColor: '',
              }))}
            />
          </LabeledList.Item>
        )}
      </LabeledList>
      <Divider />
      <LabeledList>
        <LabeledList.Item label="Цвет фона">
          <ColorInput
            value={chatBgColor}
            defaultColor="#202020"
            placeholder="#202020"
            onChange={v => dispatch(updateSettings({
              chatBgColor: v,
            }))}
            onClear={() => dispatch(updateSettings({
              chatBgColor: '',
            }))}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Цвет текста">
          <ColorInput
            value={chatTextColor}
            defaultColor="#abc6ec"
            placeholder="#abc6ec"
            onChange={v => dispatch(updateSettings({
              chatTextColor: v,
            }))}
            onClear={() => dispatch(updateSettings({
              chatTextColor: '',
            }))}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Цвет акцента">
          <ColorInput
            value={chatAccentColor}
            defaultColor="#ffdd44"
            placeholder="#ffdd44"
            onChange={v => dispatch(updateSettings({
              chatAccentColor: v,
            }))}
            onClear={() => dispatch(updateSettings({
              chatAccentColor: '',
            }))}
          />
        </LabeledList.Item>
      </LabeledList>
      <Divider />
      <LabeledList>
        <LabeledList.Item label="Отступы сообщений">
          <NumberInput
            width="4em"
            step={1}
            stepPixelSize={10}
            minValue={0}
            maxValue={10}
            value={messageSpacing}
            unit="px"
            format={value => toFixed(value)}
            onChange={(e, value) => dispatch(updateSettings({
              messageSpacing: value,
            }))}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Насыщенность шрифта">
          <NumberInput
            width="4em"
            step={100}
            stepPixelSize={10}
            minValue={100}
            maxValue={900}
            value={fontWeight}
            format={value => toFixed(value)}
            onChange={(e, value) => dispatch(updateSettings({
              fontWeight: value,
            }))}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Межбуквенный">
          <NumberInput
            width="4em"
            step={0.1}
            stepPixelSize={5}
            minValue={-0.5}
            maxValue={3}
            value={letterSpacing}
            unit="px"
            format={value => toFixed(value, 1)}
            onChange={(e, value) => dispatch(updateSettings({
              letterSpacing: value,
            }))}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Скругление углов">
          <NumberInput
            width="4em"
            step={1}
            stepPixelSize={10}
            minValue={0}
            maxValue={16}
            value={borderRadius}
            unit="px"
            format={value => toFixed(value)}
            onChange={(e, value) => dispatch(updateSettings({
              borderRadius: value,
            }))}
          />
        </LabeledList.Item>
      </LabeledList>
      <Divider />
      <Button.Checkbox
        checked={smoothScroll}
        onClick={() => dispatch(updateSettings({
          smoothScroll: !smoothScroll,
        }))}>
        Плавная прокрутка
      </Button.Checkbox>
      <Button.Checkbox
        checked={hoverEffect}
        onClick={() => dispatch(updateSettings({
          hoverEffect: !hoverEffect,
        }))}>
        Подсветка при наведении
      </Button.Checkbox>
      <Divider />
      <Button
        icon="undo"
        onClick={() => dispatch(updateSettings({
          chatStyle: 'classic',
          chatAnimation: 'none',
          chatAnimSpeed: 'normal',
          chatBgAnimation: 'none',
          chatBgAnimOpacity: 0.5,
          chatBgColor: '',
          chatTextColor: '',
          chatAccentColor: '',
          smoothScroll: false,
          hoverEffect: false,
          textGlow: 'none',
          textGlowColor: '',
          messageSpacing: 2,
          fontWeight: 400,
          letterSpacing: 0,
          borderRadius: 8,
        }))}>
        Сбросить оформление
      </Button>
    </Section>
  );
};
