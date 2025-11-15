import { useBackend, useSharedState } from '../backend';
import {
  Box,
  Button,
  Input,
  Knob,
  LabeledList,
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export const Jukebox = (props, context) => {
  const { act, data, config } = useBackend(context);

  const {
    active,
    track_selected,
    track_length,
    volume,
    is_emagged,
    cost_for_play,
    has_access,
    repeat,
    random_mode,
    songs = [],
    queued_tracks = [],
    favorite_tracks = [],
  } = data;

  // Получаем тему из конфигурации. Для будущих изменений, если найдется тот кто сделает нормальную ретротему для обычного джукбокса.
  const theme = config?.title?.toLowerCase() === 'jukebox' ? 'main' :
    config?.title?.toLowerCase() === 'handled jukebox' ? 'main' :
      'main';

  const [query, setQuery] = useSharedState(context, 'query', '');
  const [page, setPage] = useSharedState(context, 'page', 1);
  const [tab, setTab] = useSharedState(context, 'tab', 1);
  const [inFavorites, setInFavorites] = useSharedState(context, 'inFavorites', false);
  const [inputPage, setInputPage] = useSharedState(context, 'inputPage', page);

  const songsPerPage = 25;
  const filteredSongs = !query
    ? (inFavorites ? [...favorite_tracks].reverse() : songs)
    : (inFavorites ? [...favorite_tracks].reverse() : songs)
      .filter(name => name.toLowerCase().includes(query.toLowerCase()));

  const totalPages = Math.max(1, Math.ceil(filteredSongs.length / songsPerPage));
  const safePage = Math.max(1, Math.min(page, totalPages));
  const startIndex = (safePage - 1) * songsPerPage;
  const currentSongs = filteredSongs.slice(startIndex, startIndex + songsPerPage);

  const validQueuedTracks = Array.isArray(queued_tracks) ? queued_tracks : [];

  const truncate = (text, maxLength) => {
    return text.length > maxLength ? `${text.slice(0, maxLength)}...` : text;
  };

  const handlePageChange = () => {
    const targetPage = parseInt(inputPage, 10);
    if (!isNaN(targetPage) && targetPage >= 1 && targetPage <= totalPages) {
      setPage(targetPage);
    } else {
      setInputPage(page); // Reset to current page if invalid input
    }
  };

  return (
    <Window width={520} height={680} theme={theme}>
      <Window.Content scrollable>
        <Section title="Настройки" buttons={
          <Box>
            <Button
              content={repeat ? 'Повтор' : '1 Раз'}
              selected={repeat}
              disabled={!has_access}
              onClick={() => act('repeat')}
            />
            <Button
              icon={active ? 'pause' : 'play'}
              content={active ? 'Стоп' : 'Играть'}
              selected={active}
              disabled={!has_access}
              onClick={() => act('toggle')}
            />
          </Box>
        }>
          <Stack>
            <Stack.Item>
              <LabeledList>
                <LabeledList.Item label="Текущий трек">
                  {track_selected || 'Трек не выбран'}
                </LabeledList.Item>
                <LabeledList.Item label="Продолжительность">
                  {track_length || 'Трек не выбран'}
                </LabeledList.Item>
              </LabeledList>
            </Stack.Item>
            <Stack.Item>
              <Box position="relative">
                <Knob
                  size={2.4}
                  color={volume > 750 ? 'red' : 'green'}
                  value={volume}
                  unit="%"
                  minValue={0}
                  maxValue={is_emagged ? 1000 : 100}
                  step={1}
                  disabled={!has_access}
                  onDrag={(e, value) => act('set_volume', { volume: value })}
                />
                <Button
                  position="absolute"
                  top="67px"
                  right="66px"
                  color="transparent"
                  icon="fast-backward"
                  disabled={!has_access}
                  onClick={() => act('set_volume', { volume: 'min' })}
                />
                <Button
                  position="absolute"
                  top="67px"
                  right="-14px"
                  color="transparent"
                  icon="fast-forward"
                  disabled={!has_access}
                  onClick={() => act('set_volume', { volume: 'max' })}
                />
                <Button
                  position="absolute"
                  top="67px"
                  right="84px"
                  color="transparent"
                  icon="undo"
                  disabled={!has_access}
                  onClick={() => act('set_volume', { volume: 'reset' })}
                />
              </Box>
            </Stack.Item>
          </Stack>
          <LabeledList>
            <LabeledList.Item label="Цена добавления в очередь">
              {has_access ? 'Бесплатно' : `${cost_for_play} CR`}
            </LabeledList.Item>
          </LabeledList>
        </Section>

        <Tabs>
          <Tabs.Tab selected={tab === 1} onClick={() => setTab(1)}
            rightSlot={
              <Button
                icon={"star" + (inFavorites ? "" : "-o")}
                color="transparent"
                selected={inFavorites}
                onClick={() => setInFavorites(!inFavorites)}
                tooltip={`${inFavorites ? "Показать все" : "Показать избранное"}`}
              />
            }>
            Треки
          </Tabs.Tab>
          <Tabs.Tab selected={tab === 2} onClick={() => setTab(2)}>
            Очередь
          </Tabs.Tab>
          <Stack.Item grow />
          <Button
            color="transparent"
            icon="shuffle"
            tooltip="Добавить случайную песню в очередь"
            onClick={() => {
              if (songs.length === 0) return;
              const randomSongName = songs[Math.floor(Math.random() * songs.length)];
              act('add_to_queue', { track: randomSongName, up: false });
            }}
          />
        </Tabs>

        {tab === 1 && (
          <Section>
            <Input
              fluid
              placeholder="Найти треки..."
              value={query}
              onInput={(e, value) => setQuery(value)}
            />

            {currentSongs.length === 0 ? (
              <Box textAlign="center" color="gray" mt={2}>
                Нет треков
              </Box>
            ) : (
              currentSongs.map(track => {
                const isAvailable = songs.includes(track);
                const isFavorite = favorite_tracks.includes(track);

                return (
                  <Stack key={track} mb={1} align="center">
                    <Stack.Item grow>
                      <Box
                        color={isAvailable ? "gray" : "red"}
                        style={!isAvailable ? { textDecoration: 'line-through' } : null}>
                        {truncate(track, 50)}
                      </Box>
                    </Stack.Item>
                    <Stack.Item>
                      {inFavorites && (
                        <>
                          <Button
                            icon="up-long"
                            color="green"
                            tooltip="Вверх в избранном"
                            onClick={() => act('move_favorite', { track, up: true })}
                          />

                          <Button
                            icon="down-long"
                            color="green"
                            tooltip="Вниз в избранном"
                            onClick={() => act('move_favorite', { track, up: false })}
                          />
                        </>
                      )}
                      {isAvailable && (
                        <>
                          <Button
                            icon="up-long"
                            tooltip="В начало очереди"
                            onClick={() => act('add_to_queue', { track, up: true })}
                          />
                          <Button
                            icon="down-long"
                            tooltip="В конец очереди"
                            onClick={() => act('add_to_queue', { track, up: false })}
                          />
                        </>
                      )}
                      <Button
                        icon="star"
                        color="transparent"
                        selected={isFavorite}
                        onClick={() => act('toggle_favorite', { track })}
                      />
                    </Stack.Item>
                  </Stack>
                );
              })
            )}

            {totalPages > 1 && (
              <Box textAlign="center" mt={2}>
                <Button icon="chevron-left"
                  onClick={() => setPage(safePage - 1)}
                  disabled={safePage <= 1}
                />
                <Box inline ml={2} mr={2}>
                  Страница {safePage}/{totalPages}
                </Box>
                <Button icon="chevron-right"
                  onClick={() => setPage(safePage + 1)}
                  disabled={safePage >= totalPages}
                />
                <Box inline ml={2}>
                  <Button
                    content="Перейти к"
                    onClick={handlePageChange}
                  />
                  <Input
                    inline
                    width="50px"
                    textAlign="center"
                    value={inputPage}
                    onInput={(e, value) => setInputPage(value)}
                  />
                </Box>
              </Box>
            )}
          </Section>
        )}

        {tab === 2 && (
          <Section>
            {validQueuedTracks.length === 0 ? (
              <Box textAlign="center" color="gray" mt={2}>
                Очередь пуста
              </Box>
            ) : (
              validQueuedTracks.map(track => (
                <Stack key={track.index} mb={1} align="center">
                  <Stack.Item grow>
                    <Box>{truncate(track.name, 50)}</Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="up-long"
                      tooltip="Переместить выше"
                      onClick={() => act('move_queue', { index: track.index, up: true })}
                      disabled={!has_access}
                    />
                    <Button
                      icon="down-long"
                      tooltip="Переместить ниже"
                      onClick={() => act('move_queue', { index: track.index, up: false })}
                      disabled={!has_access}
                    />
                    <Button
                      icon="trash"
                      tooltip="Удалить из очереди"
                      onClick={() => act('remove_from_queue', { index: track.index })}
                      disabled={!has_access}
                    />
                  </Stack.Item>
                </Stack>
              ))
            )}
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
