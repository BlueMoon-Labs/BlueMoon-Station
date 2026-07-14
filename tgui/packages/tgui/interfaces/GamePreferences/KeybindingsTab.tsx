import { Component, createRef, type KeyboardEvent } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, NoticeBox, Section, Stack, Tooltip } from '../../components';
import { keyToByond } from '../../keyToByond';

type KeybindingInfo = {
  name: string;
  full_name: string;
  description: string;
  category: string;
  keys: string[];
  independent_key: string | null;
  default_keys: string[];
  can_independent: boolean;
};

type KbCapture = {
  keybinding: string;
  old_key: string;
  independent: number;
  full_name: string;
  description?: string;
  special?: boolean;
};

type KeybindingsData = {
  hotkeys: boolean;
  keybindings: KeybindingInfo[];
  kb_capture: KbCapture | null;
};

const MAX_KEYS = 4;

class KeyCaptureOverlay extends Component<{
  capture: KbCapture;
  onCancel: () => void;
  onKey: (event: KeyboardEvent<HTMLDivElement>) => void;
}> {
  focusRef = createRef<HTMLDivElement>();

  componentDidMount() {
    this.focusRef.current?.focus();
  }

  componentDidUpdate() {
    this.focusRef.current?.focus();
  }

  render() {
    const { capture, onCancel, onKey } = this.props;

    return (
      <NoticeBox color="blue" className="GamePreferences__capture">
        <div
          ref={this.focusRef}
          tabIndex={0}
          className="GamePreferences__captureFocus"
          onKeyDown={(event: KeyboardEvent<HTMLDivElement>) => {
            event.preventDefault();
            event.stopPropagation();
            onKey(event);
          }}
        >
          <Stack vertical>
            <Stack.Item>
              <Box bold>
                {capture.independent
                  ? 'Назначение клавиши без модификаторов'
                  : 'Назначение горячей клавиши'}
              </Box>
            </Stack.Item>
            <Stack.Item>
              Действие: <b>{capture.full_name}</b>
            </Stack.Item>
            {capture.description && (
              <Stack.Item>
                <Box italic opacity={0.8}>{capture.description}</Box>
              </Stack.Item>
            )}
            <Stack.Item>
              Заменяется: <b>{capture.old_key || 'Не назначено'}</b>
            </Stack.Item>
            <Stack.Item>
              Нажмите клавишу — <b>Esc</b> очистит привязку
            </Stack.Item>
            <Stack.Item>
              <Button icon="times" onClick={onCancel}>
                Отмена
              </Button>
            </Stack.Item>
          </Stack>
        </div>
      </NoticeBox>
    );
  }
}

const BindButton = (props: {
  content: string;
  selected?: boolean;
  color?: string;
  fluid?: boolean;
  onClick: () => void;
}) => (
  <Button
    content={props.content}
    selected={props.selected}
    color={props.color}
    fluid={props.fluid}
    className="GamePreferences__bindButton"
    onClick={props.onClick}
  />
);

export const KeybindingsTab = (props) => {
  const { act, data } = useBackend<KeybindingsData>();
  const { hotkeys, keybindings, kb_capture } = data;

  const categories: Record<string, KeybindingInfo[]> = {};
  for (const kb of keybindings || []) {
    if (!categories[kb.category]) {
      categories[kb.category] = [];
    }
    categories[kb.category].push(kb);
  }
  const categoryKeys = Object.keys(categories).sort();

  const submitCapture = (event: KeyboardEvent<HTMLDivElement>) => {
    if (!kb_capture) {
      return;
    }
    const clearKey = event.key === 'Escape' ? 1 : 0;
    const byondKey = keyToByond(event);
    if (!clearKey && !byondKey) {
      return;
    }
    act('keybindings_set', {
      keybinding: kb_capture.keybinding,
      old_key: kb_capture.old_key,
      independent: kb_capture.independent ? 1 : 0,
      clear_key: clearKey,
      key: byondKey || '',
      alt: event.altKey ? 1 : 0,
      ctrl: event.ctrlKey ? 1 : 0,
      shift: event.shiftKey ? 1 : 0,
      numpad: /^Numpad/.test(event.code) ? 1 : 0,
    });
  };

  const startCapture = (
    kb: KeybindingInfo,
    oldKey: string,
    independent: number,
  ) => {
    act('keybinding_capture', {
      keybinding: kb.name,
      old_key: oldKey,
      independent,
    });
  };

  const isCapturing = (kb: KeybindingInfo, independent: number, oldKey?: string) => {
    if (!kb_capture || kb_capture.keybinding !== kb.name) {
      return false;
    }
    if (!!kb_capture.independent !== !!independent) {
      return false;
    }
    if (oldKey !== undefined && kb_capture.old_key !== oldKey) {
      return false;
    }
    return true;
  };

  return (
    <Stack vertical fill className="GamePreferences__keybindings">
      {kb_capture && (
        <Stack.Item>
          <KeyCaptureOverlay
            capture={kb_capture}
            onCancel={() => act('keybinding_cancel')}
            onKey={submitCapture}
          />
        </Stack.Item>
      )}
      <Stack.Item>
        <Section fitted>
          <Stack fill px={1}>
            <Stack.Item grow>
              <Tooltip content={'В режиме "горячие клавиши" нажатие кнопок сразу выполняет действия (движение, открытие окон и т.д.). В режиме «ввод текста» клавиши печатают символы - для команд нужно зажать Ctrl или переключиться в горячий режим через Ctrl+Shift'}>
                <Button
                  fluid
                  selected={hotkeys}
                  icon={hotkeys ? 'toggle-on' : 'toggle-off'}
                  content={hotkeys ? 'Режим: горячие клавиши' : 'Режим: ввод текста'}
                  onClick={() => act('toggle_hotkeys')}
                />
              </Tooltip>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="undo"
                content="Сбросить"
                onClick={() => act('keybinding_reset')}
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item grow basis={0}>
        <Section fill scrollable>
          <Stack vertical>
            {categoryKeys.map(cat => (
              <Section key={cat} title={cat} level={2}>
                <Stack vertical fill>
                  <Stack.Item>
                    <Stack fill className="GamePreferences__kbHeader" px={1}>
                      <Stack.Item basis="34%">
                        <Box bold>Действие</Box>
                      </Stack.Item>
                      <Stack.Item grow basis={0}>
                        <Box bold>Клавиши</Box>
                      </Stack.Item>
                      <Stack.Item basis="22%">
                        <Box bold>Без модиф.</Box>
                      </Stack.Item>
                    </Stack>
                  </Stack.Item>
                  {categories[cat].map(kb => (
                    <Stack.Item key={kb.name} className="GamePreferences__kbRow">
                      <Stack fill align="center" px={1} py={0.5}>
                        <Stack.Item basis="34%">
                          <Box>{kb.full_name}</Box>
                          {kb.description && (
                            <Box opacity={0.65} fontSize="0.9em">
                              {kb.description}
                            </Box>
                          )}
                        </Stack.Item>
                        <Stack.Item grow basis={0}>
                          <Stack wrap>
                            {(kb.keys || []).map((key, idx) => (
                              <Stack.Item key={`${kb.name}-${key}-${idx}`}>
                                <BindButton
                                  content={key}
                                  selected={isCapturing(kb, 0, key)}
                                  onClick={() => startCapture(kb, key, 0)}
                                />
                              </Stack.Item>
                            ))}
                            {(kb.keys || []).length === 0 && (
                              <Stack.Item>
                                <BindButton
                                  content="Не назначено"
                                  color="bad"
                                  selected={isCapturing(kb, 0, 'Unbound')}
                                  onClick={() => startCapture(kb, 'Unbound', 0)}
                                />
                              </Stack.Item>
                            )}
                            {(kb.keys || []).length < MAX_KEYS && (
                              <Stack.Item>
                                <BindButton
                                  content="+"
                                  onClick={() => startCapture(kb, 'Unbound', 0)}
                                />
                              </Stack.Item>
                            )}
                            {!!kb.default_keys?.length && (
                              <Stack.Item>
                                <Box ml={1} opacity={0.55}>
                                  По умолч.: {kb.default_keys.join(', ')}
                                </Box>
                              </Stack.Item>
                            )}
                          </Stack>
                        </Stack.Item>
                        <Stack.Item basis="22%">
                          {kb.can_independent ? (
                            <BindButton
                              fluid
                              content={kb.independent_key || 'Не назначено'}
                              color={kb.independent_key ? 'default' : 'bad'}
                              selected={isCapturing(
                                kb,
                                1,
                                kb.independent_key || 'Unbound',
                              )}
                              onClick={() => startCapture(
                                kb,
                                kb.independent_key || 'Unbound',
                                1,
                              )}
                            />
                          ) : (
                            <Box opacity={0.45} italic>—</Box>
                          )}
                        </Stack.Item>
                      </Stack>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            ))}
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
