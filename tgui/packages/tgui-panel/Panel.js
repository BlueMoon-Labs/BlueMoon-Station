/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { useState } from 'react';
import { Button, Section, Stack } from 'tgui/components';
import { KitchenSink, useDebug } from 'tgui/debug';
import { IS_DEVELOPMENT } from 'tgui/env';
import { Pane } from 'tgui/layouts';

import { NowPlayingWidget, useAudio } from './audio';
import { ChatHistoryButton, ChatPanel, ChatScrollButton, ChatSearchBar, ChatTabs } from './chat';
import { EmotePanel, useEmotes } from './emotes';
import { useGame } from './game';
import { Notifications } from './Notifications';
import { SettingsPanel, useSettings } from './settings';
import { getPaneTheme } from './themes';

export const Panel = (props) => {
  const emotes = useEmotes();
  const audio = useAudio();
  const settings = useSettings();
  const game = useGame();
  const [searchOpen, setSearchOpen] = useState(false);
  if (IS_DEVELOPMENT) {
    const debug = useDebug();
    if (debug.kitchenSink) {
      return (
        <KitchenSink panel />
      );
    }
  }
  return (
    <Pane theme={getPaneTheme(settings.theme)}>
      <Stack fill vertical>
        <Stack.Item>
          <Section fitted>
            <Stack mr={1} align="center">
              <Stack.Item
                grow
                overflowX="auto"
                style={{ minWidth: 0 }}>
                <ChatTabs />
              </Stack.Item>
              <Stack.Item shrink={0}>
                <Button
                  color="grey"
                  selected={searchOpen}
                  icon="search"
                  tooltip="Поиск"
                  tooltipPosition="bottom-start"
                  onClick={() => setSearchOpen(!searchOpen)} />
              </Stack.Item>
              <Stack.Item>
                <Button
                  color="grey"
                  selected={emotes.visible}
                  icon="asterisk"
                  tooltip="Панель эмоций"
                  tooltipPosition="bottom-start"
                  onClick={() => emotes.toggle()} />
              </Stack.Item>
              <Stack.Item shrink={0}>
                <Button
                  color="grey"
                  selected={audio.visible}
                  icon="music"
                  tooltip="Музыкальный плеер"
                  tooltipPosition="bottom-start"
                  onClick={() => audio.toggle()} />
              </Stack.Item>
              <Stack.Item shrink={0}>
                <Button
                  icon={settings.visible ? 'times' : 'cog'}
                  selected={settings.visible}
                  tooltip={settings.visible
                    ? 'Закрыть настройки'
                    : 'Открыть настройки'}
                  tooltipPosition="bottom-start"
                  onClick={() => settings.toggle()} />
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
        {emotes.visible && (
          <Stack.Item>
            <Section>
              <EmotePanel />
            </Section>
          </Stack.Item>
        )}
        {audio.visible && (
          <Stack.Item>
            <Section>
              <NowPlayingWidget />
            </Section>
          </Stack.Item>
        )}
        {settings.visible && (
          <Stack.Item shrink={1} style={{ minHeight: 0 }}>
            <SettingsPanel />
          </Stack.Item>
        )}
        <Stack.Item grow basis={0} minHeight="max(8em, 30%)">
          <Section fill fitted position="relative">
            {searchOpen && (
              <ChatSearchBar
                onClose={() => setSearchOpen(false)} />
            )}
            <Pane.Content scrollable>
              <ChatPanel lineHeight={settings.lineHeight} />
            </Pane.Content>
            <ChatHistoryButton />
            <ChatScrollButton />
            <Notifications>
              {game.connectionLostAt && (
                <Notifications.Item
                  rightSlot={(
                    <Button
                      color="white"
                      onClick={() => Byond.command('.reconnect')}>
                      Переподключиться
                    </Button>
                  )}>
                  Вы либо AFK, испытываете лаги, либо соединение
                  было разорвано.
                </Notifications.Item>
              )}
              {game.roundRestartedAt && (
                <Notifications.Item>
                  Соединение было закрыто, так как сервер
                  перезапускается. Пожалуйста, подождите автоматического переподключения.
                </Notifications.Item>
              )}
            </Notifications>
          </Section>
        </Stack.Item>
      </Stack>
    </Pane>
  );
};
