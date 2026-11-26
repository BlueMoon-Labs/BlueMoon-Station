import type { ReactNode } from 'react';

import { Box, Button, Icon, Stack } from '../../components';

export const PhotoGallery = ({
  children,
  columns = 4,
}: {
  children: ReactNode;
  columns?: number;
}) => (
  <Box
    style={{
      display: 'grid',
      gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))`,
      gap: '0.5rem',
    }}
  >
    {children}
  </Box>
);

export const PhotoTile = ({
  label,
  thumbnail,
  thumbnailUrl,
  badge,
  footer,
  onClick,
}: {
  label: string;
  thumbnail?: string | null;
  thumbnailUrl?: string | null;
  badge?: ReactNode;
  footer?: ReactNode;
  onClick: () => void;
}) => (
  <button
    type="button"
    title={label}
    aria-label={label}
    onClick={onClick}
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
  >
    {thumbnail || (thumbnailUrl && !/\.(webm|mp4)([?#]|$)/i.test(thumbnailUrl)) ? (
      <img
        src={thumbnail ? `data:image/png;base64,${thumbnail}` : thumbnailUrl ?? undefined}
        alt=""
        referrerPolicy="no-referrer"
        style={{
          width: '100%',
          height: '100%',
          objectFit: 'cover',
          imageRendering: thumbnail ? 'pixelated' : 'auto',
        }}
      />
    ) : (
      <Icon name="image" size={1.75} />
    )}
    {badge && (
      <Box
        position="absolute"
        top={0.25}
        right={0.25}
        px={0.25}
        backgroundColor="#000b"
        style={{ borderRadius: '0.2rem' }}
      >
        {badge}
      </Box>
    )}
    {footer && (
      <Box
        position="absolute"
        bottom={0}
        left={0}
        width="100%"
        px={0.5}
        py={0.35}
        backgroundColor="#000c"
        textColor="#fff"
        textAlign="left"
      >
        {footer}
      </Box>
    )}
  </button>
);

export const PhotoGalleryPagination = ({
  page,
  pages,
  onPage,
}: {
  page: number;
  pages: number;
  onPage: (page: number) => void;
}) =>
  pages > 1 && (
    <Stack justify="center" align="center" mt={1}>
      <Stack.Item>
        <Button
          icon="chevron-left"
          tooltip="Предыдущая страница"
          aria-label="Предыдущая страница"
          disabled={page <= 1}
          onClick={() => onPage(page - 1)}
        />
      </Stack.Item>
      <Stack.Item>
        {page} / {pages}
      </Stack.Item>
      <Stack.Item>
        <Button
          icon="chevron-right"
          tooltip="Следующая страница"
          aria-label="Следующая страница"
          disabled={page >= pages}
          onClick={() => onPage(page + 1)}
        />
      </Stack.Item>
    </Stack>
  );
