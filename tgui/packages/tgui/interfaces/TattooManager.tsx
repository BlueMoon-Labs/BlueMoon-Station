import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Stack, Collapsible, NoticeBox, Dimmer, Icon } from '../components';
import { Window } from '../layouts';

interface TattooData {
  zone: string;
  zone_name: string;
  tattoos: SingleTattoo[];
}

interface SingleTattoo {
  index: number;
  text: string;
  display_text: string;
  color: string;
  style: string;
  pending_removal: boolean;
}

interface TattooManagerData {
  tattoo_zones: TattooData[];
  has_tattoos: boolean;
  has_pending_removals: boolean;
  pending_removal_count: number;
}

const getZoneIcon = (zone: string): string => {
  switch (zone) {
    case 'head':
      return 'head-side';
    case 'chest':
      return 'tshirt';
    case 'groin':
    case 'precise groin':
      return 'venus-mars';
    case 'l_arm':
    case 'r_arm':
      return 'hand-paper';
    case 'l_leg':
    case 'r_leg':
      return 'shoe-prints';
    case 'butt':
      return 'moon';
    case 'pussy':
    case 'testicles':
    case 'penis':
      return 'venus-mars';
    case 'breasts':
      return 'heart';
    default:
      return 'palette';
  }
};

export const TattooManager = (props, context) => {
  const { act, data } = useBackend<TattooManagerData>(context);
  const { tattoo_zones, has_tattoos, has_pending_removals, pending_removal_count } = data;

  return (
    <Window
      title="Управление татуировками"
      width={500}
      height={600}
    >
      <Window.Content scrollable>
        <Stack vertical fill>
          {!!has_pending_removals && (
            <Stack.Item>
              <NoticeBox warning>
                <Icon name="exclamation-triangle" mr={1} />
                {pending_removal_count} татуировок{pending_removal_count === 1 ? 'а' : ''} помечено для удаления.
                Удаление произойдёт при следующем респауне персонажа.
              </NoticeBox>
            </Stack.Item>
          )}

          {!has_tattoos ? (
            <Stack.Item grow>
              <Section fill>
                <Box textAlign="center" color="label" mt={4}>
                  <Icon name="paint-brush" size={4} mb={2} />
                  <Box fontSize="1.2em">У персонажа нет татуировок</Box>
                  <Box mt={1} color="gray">
                    Татуировки можно получить на станции с помощью тату-машинки
                  </Box>
                </Box>
              </Section>
            </Stack.Item>
          ) : (
            <Stack.Item grow>
              <Section
                title="Татуировки персонажа"
                buttons={(
                  <Button
                    icon="undo"
                    color="caution"
                    disabled={!has_pending_removals}
                    onClick={() => act('clear_pending')}
                  >
                    Отменить удаления
                  </Button>
                )}
              >
                <Stack vertical>
                  {tattoo_zones.map((zone) => (
                    <Stack.Item key={zone.zone}>
                      <TattooZoneSection zone={zone} />
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}

          <Stack.Item>
            <Section>
              <Box color="gray" fontSize="0.9em" textAlign="center">
                <Icon name="info-circle" mr={1} />
                Удаление татуировок вступит в силу при следующем появлении персонажа на станции.
                <br />
                Это позволяет отменить решение до респауна.
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

interface TattooZoneSectionProps {
  zone: TattooData;
}

const TattooZoneSection = (props: TattooZoneSectionProps, context) => {
  const { act } = useBackend<TattooManagerData>(context);
  const { zone } = props;

  return (
    <Collapsible
      title={(
        <Box inline>
          <Icon name={getZoneIcon(zone.zone)} mr={1} />
          {zone.zone_name}
          <Box inline ml={1} color="label">
            ({zone.tattoos.length})
          </Box>
        </Box>
      )}
      open
    >
      <Box ml={2}>
        <Stack vertical>
          {zone.tattoos.map((tattoo) => (
            <Stack.Item key={tattoo.index}>
              <TattooItem tattoo={tattoo} zone={zone.zone} />
            </Stack.Item>
          ))}
        </Stack>
      </Box>
    </Collapsible>
  );
};

interface TattooItemProps {
  tattoo: SingleTattoo;
  zone: string;
}

const TattooItem = (props: TattooItemProps, context) => {
  const { act } = useBackend<TattooManagerData>(context);
  const { tattoo, zone } = props;

  const [confirmDelete, setConfirmDelete] = useLocalState(
    context,
    `confirm_${zone}_${tattoo.index}`,
    false
  );

  const handleRemove = () => {
    if (!confirmDelete) {
      setConfirmDelete(true);
      return;
    }
    act('toggle_removal', { zone: zone, index: tattoo.index });
    setConfirmDelete(false);
  };

  const handleCancel = () => {
    setConfirmDelete(false);
  };

  const handleRestore = () => {
    act('toggle_removal', { zone: zone, index: tattoo.index });
  };

  return (
    <Box
      p={1}
      mb={1}
      style={{
        background: tattoo.pending_removal
          ? 'rgba(219, 40, 40, 0.15)'
          : 'rgba(255, 255, 255, 0.05)',
        borderRadius: '3px',
        border: tattoo.pending_removal
          ? '1px solid rgba(219, 40, 40, 0.3)'
          : '1px solid rgba(255, 255, 255, 0.1)',
        position: 'relative',
      }}
    >
      {!!tattoo.pending_removal && (
        <Box
          style={{
            position: 'absolute',
            top: '2px',
            right: '2px',
          }}
        >
          <Icon name="trash-alt" color="bad" />
        </Box>
      )}
      <Stack vertical>
        <Stack.Item>
          <Box
            style={{
              color: tattoo.color || '#4A4A4A',
              textDecoration: tattoo.pending_removal ? 'line-through' : 'none',
              opacity: tattoo.pending_removal ? 0.6 : 1,
            }}
          >
            {tattoo.style === 'text' ? (
              <span>&quot;{tattoo.display_text}&quot;</span>
            ) : (
              <span>{tattoo.display_text}</span>
            )}
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item grow>
              <Box color="label" fontSize="0.85em">
                <Icon
                  name={tattoo.style === 'text' ? 'quote-left' : 'image'}
                  mr={1}
                />
                {tattoo.style === 'text' ? 'Надпись' : 'Описание'}
              </Box>
            </Stack.Item>
            <Stack.Item>
              {tattoo.pending_removal ? (
                <Button
                  icon="undo"
                  color="good"
                  onClick={handleRestore}
                >
                  Восстановить
                </Button>
              ) : confirmDelete ? (
                <Stack>
                  <Stack.Item>
                    <Button
                      icon="check"
                      color="bad"
                      onClick={handleRemove}
                    >
                      Подтвердить
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="times"
                      onClick={handleCancel}
                    >
                      Отмена
                    </Button>
                  </Stack.Item>
                </Stack>
              ) : (
                <Button
                  icon="trash-alt"
                  color="caution"
                  onClick={handleRemove}
                >
                  Удалить
                </Button>
              )}
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Box>
  );
};
