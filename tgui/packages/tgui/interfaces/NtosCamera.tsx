import { useEffect, useState } from 'react';

import { useBackend } from '../backend';
import {
  Box,
  Button,
  Icon,
  Input,
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
  uploaded?: ByondFlag;
};

type SelectedPhoto = GalleryPhoto & PhotoMedia & {
  description: string;
  caption: string;
};

type CameraData = {
  tab: CameraTab;
  flash: ByondFlag;
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
  printCompleted: ByondFlag;
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
            gridTemplateColumns: 'repeat(auto-fit, minmax(8rem, 1fr))',
            gap: '0.5rem',
          }}>
          {gallery.map(({ id, name, uploaded }) => (
            <Button
              key={id}
              fluid
              height="6rem"
              lineHeight="normal"
              textAlign="center"
              tooltip={name}
              style={{
                display: 'grid',
                placeContent: 'center',
                minWidth: 0,
                overflowWrap: 'anywhere',
                whiteSpace: 'normal',
              }}
              onClick={() => act('select', { id })}>
              <Box mb={0.5}>
                <Icon name="image" size={1.75} />
              </Box>
              <Box>
                {name}
                {!!uploaded && <Icon name="check" color="blue" ml={0.5} />}
              </Box>
            </Button>
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
              disabled={page <= 1}
              onClick={() => act('page', { page: page - 1 })}
            />
          </Stack.Item>
          <Stack.Item>{page} / {pages}</Stack.Item>
          <Stack.Item>
            <Button
              icon="chevron-right"
              tooltip="Следующая страница"
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

  return <ProgressBar value={percent} maxValue={100} />;
};

const PrintPhoto = ({ photo }: { photo: SelectedPhoto }) => {
  const { act, data } = useBackend<CameraData>();
  const { printJob, printCompleted, printDuration, printMessage, printerNearby, printerError } = data;

  return (
    <Section title={photo.name}>
      {printMessage && <NoticeBox>{printMessage}</NoticeBox>}
      {printJob ? (
        <PrintProgress key={printJob} duration={printDuration} />
      ) : (
        <>
          {!!printCompleted && <ProgressBar value={100} maxValue={100} color="good" />}
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
        {printJob ? 'Отменить печать' : 'Назад к фотографии'}
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
