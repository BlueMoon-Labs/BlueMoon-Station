import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Button, ByondUi, Icon, NoticeBox, Section } from '../components';
import { Window } from '../layouts';

export type TribuneVenue = { id: string; name: string; kind: 'sector' | 'pad'; holder: string | null; scenario: string | null };
export type TribuneData = {
  mapRef: string;
  venues: TribuneVenue[];
  venue: string | null;
  cameras: { name: string }[];
  activeCamera: { name: string; status: BooleanLike } | null;
};

/** Соседние камеры для стрелок над картинкой. */
export const neighbourCameras = (cameras: { name: string }[], active: string | null | undefined) => {
  const index = cameras.findIndex((camera) => camera.name === active);
  if (index === -1) return [undefined, undefined];
  return [cameras[index - 1]?.name, cameras[index + 1]?.name];
};

export const AntagTrainingTribune = () => {
  const { act, data } = useBackend<TribuneData>();
  const cameras = [...(data.cameras || [])].sort((first, second) => first.name.localeCompare(second.name));
  const [previous, next] = neighbourCameras(cameras, data.activeCamera?.name);
  const venues = data.venues || [];
  return (
    <Window width={870} height={640} title="Экран трибуны">
      <div className="CameraConsole__left">
        <Window.Content scrollable>
          <Section title="Что показывать">
            {!venues.length && <Box color="label">Сейчас ни один сектор не забронирован и ни одна площадка не занята. Как только группа займёт место, оно появится здесь.</Box>}
            {venues.map((venue) => (
              <Button key={venue.id} fluid icon={venue.kind === 'pad' ? 'border-all' : 'map'} selected={venue.id === data.venue} onClick={() => act('select_venue', { id: venue.id })}>
                {venue.name}
                {venue.scenario ? ` · «${venue.scenario}»` : ''}
              </Button>
            ))}
          </Section>
          {!!data.venue && (
            <Section title="Камеры">
              {!cameras.length && <Box color="label">Камер здесь нет.</Box>}
              {cameras.map((camera) => (
                <Button key={camera.name} fluid color="transparent" selected={camera.name === data.activeCamera?.name} onClick={() => act('switch_camera', { name: camera.name })}>
                  {camera.name}
                </Button>
              ))}
            </Section>
          )}
        </Window.Content>
      </div>
      <div className="CameraConsole__right">
        <div className="CameraConsole__toolbar">
          {venues.find((venue) => venue.id === data.venue)?.holder ? (
            <>
              <Icon name="flag" mr={0.5} />
              {venues.find((venue) => venue.id === data.venue)?.holder} · {data.activeCamera?.name || '—'}
            </>
          ) : (
            <b>{data.activeCamera?.name || 'Место не выбрано'}</b>
          )}
        </div>
        <div className="CameraConsole__toolbarRight">
          <Button icon="chevron-left" disabled={!previous} onClick={() => act('switch_camera', { name: previous })} />
          <Button icon="chevron-right" disabled={!next} onClick={() => act('switch_camera', { name: next })} />
        </div>
        {data.venue ? (
          <ByondUi className="CameraConsole__map" params={{ id: data.mapRef, type: 'map' }} />
        ) : (
          <div className="CameraConsole__map">
            <NoticeBox>Выберите сектор или площадку слева.</NoticeBox>
          </div>
        )}
      </div>
    </Window>
  );
};
