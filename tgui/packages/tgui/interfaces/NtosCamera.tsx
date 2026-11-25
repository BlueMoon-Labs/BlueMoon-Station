import { useEffect, useRef, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Icon,
  Input,
  LabeledList,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
  Tabs,
  TextArea,
} from '../components';
import { NtosWindow } from '../layouts';
import { type PhotoMedia, PhotoPreview } from './PhotoViewer';

type CameraTab = 'camera' | 'local' | 'cloud';
type ByondFlag = boolean | 0 | 1;

type GalleryPhoto = {
  id: string;
  name: string;
  thumbnail?: string | null;
  uploaded?: ByondFlag;
};

type SelectedPhoto = GalleryPhoto & PhotoMedia & {
  description: string;
  caption: string;
};

type CameraData = {
  tab: CameraTab;
  flash: ByondFlag;
  frameWidth: number;
  frameHeight: number;
  maxFrameSize: number;
  viewfinder: 'idle' | 'aiming' | 'blocked';
  capturing: ByondFlag;
  localCount: number;
  gallery: GalleryPhoto[] | null;
  photo: SelectedPhoto | null;
  page: number;
  pages: number;
  editMode: 'upload' | 'edit' | null;
  nameLimit: number;
  descriptionLimit: number;
  captionLimit: number;
  printOpen: ByondFlag;
  printerNearby?: ByondFlag;
  printerError?: string | null;
  printJob: number | null;
  printDuration: number;
  printMessage: string | null;
  printTransferred: ByondFlag;
};

const CameraSettings = () => {
  const { act, data } = useBackend<CameraData>();
  const { frameWidth, frameHeight, maxFrameSize, capturing } = data;
  const [open, setOpen] = useState(false);
  const container = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) {
      return;
    }
    const closeOutside = (event: MouseEvent) => {
      if (!container.current?.contains(event.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener('click', closeOutside, true);
    return () => document.removeEventListener('click', closeOutside, true);
  }, [open]);

  const dimensions = [
    { label: 'Ширина, м', action: 'set_width', value: frameWidth },
    { label: 'Высота, м', action: 'set_height', value: frameHeight },
  ];
  const sizes = Array.from({ length: Math.ceil(maxFrameSize / 2) }, (_, index) => index * 2 + 1);

  return (
    <div ref={container} style={{ position: 'relative' }}>
      <Button
        icon="cog"
        selected={open}
        disabled={!!capturing}
        aria-label="Настройки кадра"
        aria-expanded={open}
        width="3.5rem"
        lineHeight="2.8rem"
        textAlign="center"
        onClick={() => setOpen(previous => !previous)}
      />
      {open && (
        <Box
          role="dialog"
          aria-label="Размер кадра"
          position="absolute"
          left={0}
          bottom="calc(100% + 0.35rem)"
          width="16rem"
          style={{ zIndex: 10, boxShadow: '0 0.25rem 0.75rem #0008' }}>
          <Section title="Размер кадра">
            <LabeledList>
              {dimensions.map(({ label, action, value }) => (
                <LabeledList.Item key={action} label={label}>
                  {sizes.map(size => (
                    <Button
                      key={size}
                      selected={value === size}
                      aria-pressed={value === size}
                      disabled={!!capturing}
                      onClick={() => act(action, { size })}>
                      {size}
                    </Button>
                  ))}
                </LabeledList.Item>
              ))}
            </LabeledList>
          </Section>
        </Box>
      )}
    </div>
  );
};

const Viewfinder = () => {
  const { act, data } = useBackend<CameraData>();
  const { flash, viewfinder, capturing, localCount } = data;
  const aiming = viewfinder === 'aiming';
  const blocked = viewfinder === 'blocked';

  return (
    <Stack fill vertical>
      <Stack.Item grow>
        <Box
          height="100%"
          backgroundColor={blocked || aiming ? '#101216' : '#555b62'}
          style={{
            minHeight: '17rem',
            border: '1px solid rgba(255, 255, 255, 0.16)',
            display: 'grid',
            placeItems: 'center',
          }}>
          <Box textAlign="center" textColor="#eee" mx={2}>
            {!blocked && <Icon name={aiming ? 'crosshairs' : 'camera'} size={4} />}
            {aiming && <Box mt={1}>Щёлкните по цели на игровой карте.</Box>}
            {blocked && (
              <Box>Для съёмки держите ПДА в руке и выйдите на открытое место.</Box>
            )}
          </Box>
        </Box>
      </Stack.Item>
      <Stack.Item>
        <Stack>
          <Stack.Item>
            <Button
              icon="lightbulb"
              selected={!!flash}
              disabled={!!capturing}
              tooltip={flash ? 'Выключить вспышку' : 'Включить вспышку'}
              aria-label={flash ? 'Выключить вспышку' : 'Включить вспышку'}
              width="3.5rem"
              lineHeight="2.8rem"
              textAlign="center"
              onClick={() => act('toggle_flash')}
            />
          </Stack.Item>
          <Stack.Item>
            <CameraSettings />
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              color="good"
              selected={aiming || blocked}
              disabled={!!capturing}
              bold
              lineHeight="2.8rem"
              textAlign="center"
              onClick={() => act('shutter')}>
              {capturing ? 'Съёмка…' : aiming || blocked ? 'Отменить' : 'Фото'}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="images"
              tooltip={localCount > 0 ? `Галерея · ${localCount}` : 'Галерея'}
              aria-label="Галерея"
              width="3.5rem"
              lineHeight="2.8rem"
              textAlign="center"
              onClick={() => act('tab', { tab: 'local' })}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const GalleryGrid = () => {
  const { act, data } = useBackend<CameraData>();
  const { gallery, page, pages, tab } = data;

  return (
    <>
      {gallery?.length ? (
        <Box
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(4, minmax(0, 1fr))',
            gap: '0.5rem',
          }}>
          {gallery.map(({ id, name, thumbnail, uploaded }) => (
            <button
              key={id}
              type="button"
              title={name}
              aria-label={name}
              style={{
                position: 'relative',
                display: 'grid',
                placeItems: 'center',
                aspectRatio: '1 / 1',
                minWidth: 0,
                overflow: 'hidden',
                padding: 0,
                border: '1px solid #ffffff40',
                background: '#181c23',
                color: '#aeb8c2',
                cursor: 'pointer',
              }}
              onClick={() => act('select', { id })}>
              {thumbnail ? (
                <img
                  src={`data:image/png;base64,${thumbnail}`}
                  alt=""
                  style={{
                    width: '100%',
                    height: '100%',
                    objectFit: 'cover',
                    imageRendering: 'pixelated',
                  }}
                />
              ) : (
                <Icon name="image" size={1.75} />
              )}
              {!!uploaded && (
                <Box
                  position="absolute"
                  top={0.25}
                  right={0.25}
                  px={0.25}
                  backgroundColor="#000b"
                  style={{ borderRadius: '0.2rem' }}>
                  <Icon name="check" color="blue" />
                </Box>
              )}
            </button>
          ))}
        </Box>
      ) : (
        <NoticeBox>
          {tab === 'local' ? 'На ПДА пока нет фотографий.' : 'В облаке пока нет фотографий.'}
        </NoticeBox>
      )}
      {pages > 1 && (
        <Stack justify="center" align="center" mt={1}>
          <Stack.Item>
            <Button
              icon="chevron-left"
              tooltip="Предыдущая страница"
              aria-label="Предыдущая страница"
              disabled={page <= 1}
              onClick={() => act('page', { page: page - 1 })}
            />
          </Stack.Item>
          <Stack.Item>{page} / {pages}</Stack.Item>
          <Stack.Item>
            <Button
              icon="chevron-right"
              tooltip="Следующая страница"
              aria-label="Следующая страница"
              disabled={page >= pages}
              onClick={() => act('page', { page: page + 1 })}
            />
          </Stack.Item>
        </Stack>
      )}
    </>
  );
};

const EditPhoto = ({ photo }: { photo: SelectedPhoto }) => {
  const { act, data } = useBackend<CameraData>();
  const [name, setName] = useState(photo.name);
  const [description, setDescription] = useState(photo.description);
  const [caption, setCaption] = useState(photo.caption);

  return (
    <Section title={data.editMode === 'upload' ? 'Загрузка в облако' : 'Редактирование'}>
      <Stack vertical>
        <Stack.Item>
          <Box as="label" display="block">
            Название
            <Input fluid value={name} maxLength={data.nameLimit} onInput={(_, value) => setName(value)} />
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box as="label" display="block">
            Описание
            <TextArea
              fluid
              height="5rem"
              maxLength={data.descriptionLimit}
              value={description}
              onInput={(_, value) => setDescription(value)}
            />
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Box as="label" display="block">
            Подпись на обратной стороне
            <TextArea
              fluid
              height="4rem"
              maxLength={data.captionLimit}
              value={caption}
              onInput={(_, value) => setCaption(value)}
            />
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button onClick={() => act('cancel_edit')}>Отмена</Button>
          <Button
            icon={data.editMode === 'upload' ? 'cloud-upload-alt' : 'check'}
            onClick={() => act('save', { id: photo.id, name, description, caption })}>
            {data.editMode === 'upload' ? 'Загрузить' : 'Сохранить'}
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const PrintProgress = ({ duration }: { duration: number }) => {
  const [percent, setPercent] = useState(0);

  useEffect(() => {
    const startedAt = performance.now();
    const interval = window.setInterval(() => {
      setPercent(Math.min(99, Math.floor((performance.now() - startedAt) * 100 / duration)));
    }, 50);
    return () => window.clearInterval(interval);
  }, [duration]);

  return <ProgressBar value={percent} maxValue={100} animated={false} />;
};

const PrintPhoto = ({ photo }: { photo: SelectedPhoto }) => {
  const { act, data } = useBackend<CameraData>();
  const { printJob, printTransferred, printDuration, printMessage, printerNearby, printerError } = data;

  return (
    <Section title={photo.name}>
      {printMessage && <NoticeBox>{printMessage}</NoticeBox>}
      {printJob ? (
        <>
          <Box mb={0.5}>Передача на принтер</Box>
          <PrintProgress key={printJob} duration={printDuration} />
        </>
      ) : (
        <>
          {!!printTransferred && <ProgressBar value={100} maxValue={100} color="good" />}
          {!printerNearby && !printMessage && <NoticeBox>Подойдите вплотную к принтеру.</NoticeBox>}
          {!!printerNearby && (
            <>
              {!!printerError && <NoticeBox>{printerError}</NoticeBox>}
              <Button
                icon="print"
                disabled={!!printerError}
                onClick={() => act('start_print', { id: photo.id })}>
                Печатать фото
              </Button>
            </>
          )}
        </>
      )}
      <Button onClick={() => act('cancel_print')}>
        {printJob ? 'Отменить передачу' : 'Назад к фотографии'}
      </Button>
    </Section>
  );
};

const PhotoDetails = ({ photo }: { photo: SelectedPhoto }) => {
  const { act, data } = useBackend<CameraData>();
  if (data.printOpen) {
    return <PrintPhoto photo={photo} />;
  }

  return (
    <>
      <Section
        title={photo.name}
        buttons={!data.editMode && (
          <>
            <Button icon="arrow-left" tooltip="К списку фотографий" onClick={() => act('back')} />
            {data.tab === 'local' ? (
              <Button
                icon={photo.uploaded ? 'check' : 'cloud-upload-alt'}
                iconColor={photo.uploaded ? 'blue' : undefined}
                disabled={!!photo.uploaded}
                tooltip={photo.uploaded ? 'Загружено в облако' : 'Сохранить в облаке'}
                onClick={() => act('upload')}
              />
            ) : (
              <>
                <Button icon="pen" tooltip="Редактировать" onClick={() => act('edit')} />
                <Button.Confirm
                  icon="trash"
                  confirmIcon="trash"
                  tooltip="Удалить из облака"
                  confirmContent="Удалить?"
                  onClick={() => act('delete', { id: photo.id })}
                />
              </>
            )}
            <Button icon="print" tooltip="Печать" onClick={() => act('request_print')} />
          </>
        )}>
        <Box mx="auto" style={{ maxWidth: '19rem' }}>
          <PhotoPreview {...photo} />
        </Box>
        {!data.editMode && (
          <>
            {!!photo.description && <Box mt={1} style={{ overflowWrap: 'anywhere' }}>{photo.description}</Box>}
            {!!photo.caption && <Box mt={1} italic style={{ overflowWrap: 'anywhere' }}>{photo.caption}</Box>}
          </>
        )}
      </Section>
      {!!data.editMode && <EditPhoto key={photo.id} photo={photo} />}
    </>
  );
};

export const NtosCamera = () => {
  const { act, data } = useBackend<CameraData>();
  const { tab, photo } = data;

  return (
    <NtosWindow title="Камера" width={550} height={550}>
      <NtosWindow.Content scrollable={tab !== 'camera'}>
        {tab === 'camera' ? (
          <Viewfinder />
        ) : (
          <>
            <Stack mb={1} align="center">
              <Stack.Item grow>
                <Tabs>
                  <Tabs.Tab selected={tab === 'local'} onClick={() => act('tab', { tab: 'local' })}>
                    Локальное хранилище
                  </Tabs.Tab>
                  <Tabs.Tab selected={tab === 'cloud'} onClick={() => act('tab', { tab: 'cloud' })}>
                    Облако
                  </Tabs.Tab>
                </Tabs>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="question"
                  aria-label="О хранилищах"
                  tooltip={(
                    <>
                      Локальные снимки удаляются в конце смены.
                      <br />
                      Снимки в облаке сохраняются между сменами.
                    </>
                  )}
                  tooltipPosition="bottom-end"
                />
              </Stack.Item>
              <Stack.Item>
                <Button icon="camera" onClick={() => act('tab', { tab: 'camera' })}>
                  Камера
                </Button>
              </Stack.Item>
            </Stack>
            {photo ? <PhotoDetails photo={photo} /> : <GalleryGrid />}
          </>
        )}
      </NtosWindow.Content>
    </NtosWindow>
  );
};
