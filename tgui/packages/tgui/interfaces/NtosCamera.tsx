import { useEffect, useRef, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  ByondUi,
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
import { PhotoGallery, PhotoGalleryPagination, PhotoTile } from './common/PhotoGallery';
import { type PhotoMedia, PhotoPreview } from './PhotoViewer';

type CameraTab = 'camera' | 'local' | 'cloud';
type ByondFlag = boolean | 0 | 1;

type GalleryPhoto = {
  id: string;
  name: string;
  thumbnail?: string | null;
  thumbnailUrl?: string | null;
  uploaded?: ByondFlag;
};

type SelectedPhoto = GalleryPhoto & PhotoMedia & {
  description: string;
  caption: string;
  stationCaptureTime?: string | null;
  captureTimeZone?: string | null;
  serverCaptureTime?: string | null;
};

type ShareContact = {
  ref: string;
  name: string;
  job: string;
};

type CameraData = {
  tab: CameraTab;
  flash: ByondFlag;
  frameWidth: number;
  frameHeight: number;
  maxFrameSize: number;
  viewfinder: 'idle' | 'aiming' | 'blocked';
  viewfinderMap: string | null;
  capturing: ByondFlag;
  localCount: number;
  gallery: GalleryPhoto[] | null;
  photo: SelectedPhoto | null;
  page: number;
  pages: number;
  editMode: 'upload' | 'edit' | null;
  shareContacts: Record<string, ShareContact> | null;
  attachmentPicker: ByondFlag;
  syndimaticPicker?: 'compose' | 'avatar' | null;
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
  serverUtcOffset: string;
};

const CameraSettings = ({ open, onOpenChange }: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) => {
  const { act, data } = useBackend<CameraData>();
  const { frameWidth, frameHeight, maxFrameSize, capturing } = data;
  const container = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) {
      return;
    }
    const closeOutside = (event: MouseEvent) => {
      if (!container.current?.contains(event.target as Node)) {
        onOpenChange(false);
      }
    };
    document.addEventListener('click', closeOutside, true);
    return () => document.removeEventListener('click', closeOutside, true);
  }, [open, onOpenChange]);

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
        onClick={() => onOpenChange(!open)}
      />
      {open && (
        <Box
          role="dialog"
          aria-label="Размер кадра"
          position="absolute"
          left={0}
          bottom="calc(100% + 0.35rem)"
          width="20rem"
          style={{ zIndex: 10, boxShadow: '0 0.25rem 0.75rem #0008' }}>
          <Section title="Размер кадра">
            <LabeledList>
              {dimensions.map(({ label, action, value }) => (
                <LabeledList.Item key={action} label={label}>
                  <Box nowrap>
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
                  </Box>
                </LabeledList.Item>
              ))}
            </LabeledList>
          </Section>
        </Box>
      )}
    </div>
  );
};

const ViewfinderMap = ({ id, frameWidth, frameHeight }: {
  id: string;
  frameWidth: number;
  frameHeight: number;
}) => {
  const { act } = useBackend<CameraData>();
  const [onResize] = useState(() => () => act('mount_viewfinder', { id }));

  return (
    <ByondUi
      onResize={onResize}
      style={{
        width: `min(100cqw, calc(100cqh * ${frameWidth / frameHeight}))`,
        aspectRatio: `${frameWidth} / ${frameHeight}`,
      }}
      params={{
        id,
        type: 'map',
        zoom: 0,
        letterbox: true,
        'background-color': '#101216',
        'is-disabled': true,
      }}
    />
  );
};

const Viewfinder = () => {
  const { act, data } = useBackend<CameraData>();
  const { flash, viewfinder, viewfinderMap, frameWidth, frameHeight, capturing, localCount } = data;
  const [settingsOpen, setSettingsOpen] = useState(false);
  const aiming = viewfinder === 'aiming';
  const blocked = viewfinder === 'blocked';

  return (
    <Stack fill vertical>
      <Stack.Item grow>
        <Box
          height="100%"
          backgroundColor={blocked || aiming ? '#101216' : '#555b62'}
          style={{
            containerType: 'size',
            minHeight: '17rem',
            border: '1px solid rgba(255, 255, 255, 0.16)',
            display: 'grid',
            placeItems: 'center',
          }}>
          {aiming && viewfinderMap && !settingsOpen ? (
            <ViewfinderMap
              key={viewfinderMap}
              id={viewfinderMap}
              frameWidth={frameWidth}
              frameHeight={frameHeight}
            />
          ) : (
            <Box textAlign="center" textColor="#eee" mx={2}>
              {!blocked && <Icon name={aiming ? 'crosshairs' : 'camera'} size={4} />}
              {blocked && (
                <Box>Для съёмки держите ПДА в руке и выйдите на открытое место.</Box>
              )}
            </Box>
          )}
        </Box>
      </Stack.Item>
      {aiming && (
        <Stack.Item textAlign="center" color="label">
          Наведите курсор и щёлкните.
        </Stack.Item>
      )}
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
            <CameraSettings open={settingsOpen} onOpenChange={setSettingsOpen} />
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
              onClick={() => act('shutter', {
                timeZone: typeof Intl === 'undefined'
                  ? null
                  : Intl.DateTimeFormat().resolvedOptions().timeZone,
              })}>
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
        <PhotoGallery>
          {gallery.map(({ id, name, thumbnail, thumbnailUrl, uploaded }) => (
            <PhotoTile
              key={id}
              label={name}
              thumbnail={thumbnail}
              thumbnailUrl={thumbnailUrl}
              badge={!!uploaded && <Icon name="check" color="blue" />}
              onClick={() => act('select', { id })}
            />
          ))}
        </PhotoGallery>
      ) : (
        <NoticeBox>
          {tab === 'local' ? 'На ПДА пока нет фотографий.' : 'В облаке пока нет фотографий.'}
        </NoticeBox>
      )}
      <PhotoGalleryPagination page={page} pages={pages} onPage={(page) => act('page', { page })} />
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

const formatCaptureTime = (time: number, timeZone: string) =>
  new Date(time).toLocaleString('ru-RU', {
    timeZone,
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).replace(',', '');

const PhotoCaptureTime = ({ photo }: { photo: SelectedPhoto }) => {
  const { data } = useBackend<CameraData>();
  // Первые 48 бит UUIDv7 хранят время создания в миллисекундах.
  const uuidTime = /^([0-9a-f]{8})-([0-9a-f]{4})-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.exec(photo.id);
  const capturedAt = uuidTime ? parseInt(uuidTime[1] + uuidTime[2], 16) : NaN;
  let clientTime: string | undefined;
  if (photo.captureTimeZone && Number.isFinite(capturedAt)) {
    try {
      clientTime = formatCaptureTime(capturedAt, photo.captureTimeZone);
    } catch {
      // Часовой пояс мог быть записан в другой версии WebView.
    }
  }

  if (data.tab === 'cloud') {
    let captureTime = clientTime || photo.serverCaptureTime;
    if (!captureTime && Number.isFinite(capturedAt)) {
      // Для старых снимков восстанавливаем дату по UUID.
      const offset = /^([+-])(\d{2})(\d{2})$/.exec(data.serverUtcOffset);
      const minutes = offset ? Number(offset[2]) * 60 + Number(offset[3]) : 0;
      const sign = offset?.[1] === '-' ? -1 : 1;
      captureTime = formatCaptureTime(capturedAt + sign * minutes * 60_000, 'UTC');
    }
    return captureTime && (
      <Box mt={1}>
        <LabeledList>
          <LabeledList.Item label="Дата съёмки">{captureTime}</LabeledList.Item>
        </LabeledList>
      </Box>
    );
  }

  return (
    <Box mt={1}>
      <LabeledList>
        {!!photo.stationCaptureTime && (
          <LabeledList.Item label="По станции">{photo.stationCaptureTime}</LabeledList.Item>
        )}
        {!!clientTime && <LabeledList.Item label="По местному времени">{clientTime}</LabeledList.Item>}
      </LabeledList>
    </Box>
  );
};

const SharePhoto = ({ photo }: { photo: SelectedPhoto }) => {
  const { act, data } = useBackend<CameraData>();
  const [search, setSearch] = useState('');
  const query = search.trim().toLowerCase();
  const contacts = Object.values(data.shareContacts ?? {}).filter(({ name, job }) =>
    `${name} ${job}`.toLowerCase().includes(query),
  );

  return (
    <Section
      title={photo.name}
      buttons={<Button icon="arrow-left" onClick={() => act('cancel_share')}>Назад</Button>}>
      <Stack vertical>
        <Stack.Item>
          <Input
            fluid
            placeholder="Найти получателя"
            value={search}
            onInput={(_, value) => setSearch(value)}
          />
        </Stack.Item>
        {contacts.length === 0 && (
          <Stack.Item>
            <NoticeBox>Получатели не найдены.</NoticeBox>
          </Stack.Item>
        )}
        {contacts.map(({ ref, name, job }) => (
          <Stack.Item key={ref}>
            <Button
              fluid
              ellipsis
              icon="comment"
              content={`${name} · ${job}`}
              onClick={() => act('share_photo', { id: photo.id, tab: data.tab, recipient: ref })}
            />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const PhotoDetails = ({ photo }: { photo: SelectedPhoto }) => {
  const { act, data } = useBackend<CameraData>();
  if (data.printOpen) {
    return <PrintPhoto photo={photo} />;
  }
  if (data.shareContacts) {
    return <SharePhoto photo={photo} />;
  }

  return (
    <>
      <Section
        title={photo.name}
        buttons={data.syndimaticPicker || data.attachmentPicker ? (
          <>
            <Button icon="arrow-left" tooltip="К списку фотографий" onClick={() => act('back')} />
            <Button
              icon={data.syndimaticPicker ? 'check' : 'paperclip'}
              onClick={() => act(data.syndimaticPicker ? 'select_syndimatic_photo' : 'attach_photo', { id: photo.id, tab: data.tab })}>
              {data.syndimaticPicker ? 'Выбрать' : 'Прикрепить'}
            </Button>
          </>
        ) : !data.editMode && (
          <>
            <Button icon="arrow-left" tooltip="К списку фотографий" onClick={() => act('back')} />
            {data.tab === 'local' && (
              <Button
                icon={photo.uploaded ? 'check' : 'cloud-upload-alt'}
                iconColor={photo.uploaded ? 'blue' : undefined}
                disabled={!!photo.uploaded}
                tooltip={photo.uploaded ? 'Загружено в облако' : 'Сохранить в облаке'}
                onClick={() => act('upload')}
              />
            )}
            <Button icon="pen" tooltip="Редактировать" onClick={() => act('edit')} />
            <Button.Confirm
              icon="trash"
              confirmIcon="trash"
              tooltip={data.tab === 'local' ? 'Удалить с ПДА' : 'Удалить из облака'}
              confirmContent="Удалить?"
              onClick={() => act('delete', { id: photo.id, tab: data.tab })}
            />
            <Button icon="share" tooltip="Поделиться" aria-label="Поделиться" onClick={() => act('request_share')} />
            <Button icon="print" tooltip="Печать" onClick={() => act('request_print')} />
          </>
        )}>
        <PhotoPreview {...photo} />
        {!data.editMode && (
          <>
            {!!photo.description && <Box mt={1} style={{ overflowWrap: 'anywhere' }}>{photo.description}</Box>}
            {!!photo.caption && <Box mt={1} italic style={{ overflowWrap: 'anywhere' }}>{photo.caption}</Box>}
          </>
        )}
        <PhotoCaptureTime photo={photo} />
      </Section>
      {!!data.editMode && <EditPhoto key={photo.id} photo={photo} />}
    </>
  );
};

export const NtosCamera = () => {
  const { act, data } = useBackend<CameraData>();
  const { tab, photo } = data;

  return (
    <NtosWindow title="Камера" width={550} height={800}>
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
                {data.syndimaticPicker ? (
                  <Button icon="arrow-left" onClick={() => act('cancel_syndimatic_picker')}>В Syndimatic</Button>
                ) : data.attachmentPicker ? (
                  <Button icon="arrow-left" onClick={() => act('cancel_attachment')}>В чат</Button>
                ) : (
                  <Button icon="camera" onClick={() => act('tab', { tab: 'camera' })}>Камера</Button>
                )}
              </Stack.Item>
            </Stack>
            {photo ? <PhotoDetails photo={photo} /> : <GalleryGrid />}
          </>
        )}
      </NtosWindow.Content>
    </NtosWindow>
  );
};
