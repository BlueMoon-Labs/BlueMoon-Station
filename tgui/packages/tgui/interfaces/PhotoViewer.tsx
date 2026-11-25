import { useBackend } from '../backend';
import { Box, NoticeBox, Section } from '../components';
import { Window } from '../layouts';

export type PhotoMedia = {
  image?: string;
  url?: string;
};

type PhotoViewerData = PhotoMedia & {
  photoName: string;
  description?: string;
  caption?: string;
};

const mediaStyle = {
  display: 'block',
  width: '100%',
  height: '100%',
  objectFit: 'contain',
} as const;

export const PhotoPreview = ({ image, url }: PhotoMedia) => {
  if (!url && !image) {
    return <NoticeBox>На фотографии ничего нет.</NoticeBox>;
  }

  return (
    <Box
      mx="auto"
      backgroundColor="#111"
      style={{ aspectRatio: '1 / 1', maxHeight: '100%' }}>
      {url && /\.(webm|mp4)([?#]|$)/i.test(url) ? (
        <video autoPlay loop muted playsInline src={url} style={mediaStyle} />
      ) : (
        <img
          alt="Фотография"
          referrerPolicy="no-referrer"
          src={url || `data:image/png;base64,${image}`}
          style={{
            ...mediaStyle,
            imageRendering: url ? 'auto' : 'pixelated',
          }} />
      )}
    </Box>
  );
};

export const PhotoViewer = () => {
  const { data } = useBackend<PhotoViewerData>();
  const { caption, description, photoName } = data;

  return (
    <Window width={500} height={580} title={photoName || 'Фотография'}>
      <Window.Content scrollable>
        <PhotoPreview {...data} />
        {!!description && (
          <Section title="Описание" mt={1}>
            <Box style={{ whiteSpace: 'pre-wrap', overflowWrap: 'anywhere' }}>
              {description}
            </Box>
          </Section>
        )}
        {!!caption && (
          <Section title="На обратной стороне" mt={1}>
            <Box style={{ whiteSpace: 'pre-wrap', overflowWrap: 'anywhere' }}>
              {caption}
            </Box>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
