/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { useSelector } from 'common/redux';
import { useLocalState } from 'tgui/backend';
import { Button, Section, Stack } from 'tgui/components';
import { KitchenSink, useDebug } from 'tgui/debug';
import { IS_DEVELOPMENT } from 'tgui/env';
import { Pane } from 'tgui/layouts';

import { NowPlayingWidget, useAudio } from './audio';
import { ChatPanel, ChatSearchBar, ChatTabs } from './chat';
import { chatRenderer } from './chat/renderer';
import { selectChat } from './chat/selectors';
import { EmotePanel, useEmotes } from './emotes';
import { useGame } from './game';
import { Notifications } from './Notifications';
import { PingIndicator } from './ping';
import { SettingsPanel, useSettings } from './settings';

export const Panel = (props, context) => {
  const emotes = useEmotes(context);
  const audio = useAudio(context);
  const settings = useSettings(context);
  const game = useGame(context);
  const chat = useSelector(context, selectChat);
  const [searchOpen, setSearchOpen] = useLocalState(
    context, 'chatSearchOpen', false);
  if (IS_DEVELOPMENT) {
    const debug = useDebug(context);
    if (debug.kitchenSink) {
      return (
        <KitchenSink panel />
      );
    }
  }
  return (
    <Pane theme={settings.theme === 'default' ? 'light' : settings.theme}>
      <Stack fill vertical>
        <Stack.Item>
          <Section fitted>
            <Stack mr={1} align="center">
              <Stack.Item
                grow
                overflowX="auto"
                style={{ 'min-width': 0 }}>
                <ChatTabs />
              </Stack.Item>
              <Stack.Item shrink={0}>
                <PingIndicator />
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
          <Stack.Item>
            <SettingsPanel />
          </Stack.Item>
        )}
        <Stack.Item grow>
          <Section fill fitted position="relative">
            {searchOpen && (
              <ChatSearchBar
                onClose={() => setSearchOpen(false)} />
            )}
            <Pane.Content scrollable>
              <ChatPanel lineHeight={settings.lineHeight} />
            </Pane.Content>
            {!chat.scrollTracking && (
              <Button
                className="Chat__scrollButton"
                icon="arrow-down"
                onClick={() => chatRenderer.scrollToBottom()}>
                Прокрутить вниз
              </Button>
            )}
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
