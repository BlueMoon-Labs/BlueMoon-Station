import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Icon, NoticeBox, Section, Stack, TextArea } from '../components';
import { NtosWindow } from '../layouts';
import { PhotoGallery, PhotoGalleryPagination, PhotoTile } from './common/PhotoGallery';
import { type PhotoMedia, PhotoPreview } from './PhotoViewer';

type ByondFlag = boolean | 0 | 1;

type Post = {
  id: string;
  authorId: string;
  author: string;
  caption: string;
  likes: number;
  comments: number;
  thumbnail?: string | null;
  thumbnailUrl?: string | null;
};

type Comment = {
  id: string;
  authorId: string;
  author: string;
  text: string;
  likes: number;
  dislikes: number;
  vote: -1 | 0 | 1;
  ownComment: ByondFlag;
};

type Profile = {
  name: string;
  description: string;
  avatar?: PhotoMedia | null;
};

type SyndimaticData = {
  view: 'feed' | 'profile' | 'post' | 'compose' | 'avatar' | 'blocks';
  canWrite: ByondFlag;
  canSetNotifications: ByondFlag;
  notifications: ByondFlag;
  isAdmin: ByondFlag;
  ownPost?: ByondFlag;
  publishBlocked: ByondFlag;
  commentBlocked: ByondFlag;
  commentsDisabled?: ByondFlag;
  profileId?: string;
  profilePublishBlocked?: ByondFlag;
  profileCommentBlocked?: ByondFlag;
  blocks?: { id: string; name: string }[];
  myProfile: ByondFlag;
  captionLimit: number;
  descriptionLimit: number;
  posts?: Post[];
  post?: Post;
  liked?: ByondFlag;
  commentsOpen?: ByondFlag;
  comments?: Comment[];
  commentSerial: number;
  profile?: Profile;
  ownProfile?: ByondFlag;
  editingProfile?: ByondFlag;
  media?: PhotoMedia;
  draftId?: string;
  page: number;
  pages: number;
};

const multiline = { overflowWrap: 'anywhere', whiteSpace: 'pre-wrap' } as const;
const ellipsis = { overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' } as const;
const adminAction = 'Административное действие';

const PostGallery = () => {
  const { act, data } = useBackend<SyndimaticData>();
  const { page, pages, posts, view } = data;
  if (!posts?.length) {
    return (
      <NoticeBox>
        {view === 'profile' ? 'У персонажа пока нет публикаций.' : 'В ленте пока нет публикаций.'}
      </NoticeBox>
    );
  }
  return (
    <>
      <PhotoGallery columns={3}>
        {posts.map(({ id, author, caption, thumbnail, thumbnailUrl, likes, comments }) => (
          <PhotoTile
            key={id}
            label={`${author}${caption ? ` · ${caption}` : ''} · Нравится: ${likes}, комментарии: ${comments}`}
            thumbnail={thumbnail}
            thumbnailUrl={thumbnailUrl}
            onClick={() => act('open_post', { id })}
            footer={
              <>
                {view === 'feed' && <Box bold style={ellipsis}>{author}</Box>}
                <Stack>
                  <Stack.Item><Icon name="heart" /> {likes}</Stack.Item>
                  <Stack.Item><Icon name="comment" /> {comments}</Stack.Item>
                </Stack>
              </>
            }
          />
        ))}
      </PhotoGallery>
      <PhotoGalleryPagination page={page} pages={pages} onPage={(page) => act('page', { page })} />
    </>
  );
};

const CommentForm = ({ id }: { id: string }) => {
  const { act, data } = useBackend<SyndimaticData>();
  const [text, setText] = useState('');
  return (
    <Stack vertical>
      <Stack.Item>
        <TextArea
          dontUseTabForIndent
          fluid
          height={4}
          value={text}
          maxLength={data.captionLimit}
          placeholder="Ваш комментарий"
          onInput={(_, value) => setText(value)}
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          icon="paper-plane"
          disabled={!text.trim()}
          onClick={() => act('comment', { id, text, commentSerial: data.commentSerial })}
        >
          Отправить
        </Button>
      </Stack.Item>
    </Stack>
  );
};

const Comments = ({ id }: { id: string }) => {
  const { act, data } = useBackend<SyndimaticData>();
  const { canWrite, comments, commentSerial, commentBlocked, commentsDisabled, isAdmin, page, pages } = data;
  return (
    <Section title="Комментарии">
      {commentsDisabled ? (
        <NoticeBox>Автор закрыл комментарии к публикации.</NoticeBox>
      ) : commentBlocked ? (
        <NoticeBox>Вам заблокировано комментирование.</NoticeBox>
      ) : !!canWrite && <CommentForm key={`${id}:${commentSerial}`} id={id} />}
      {comments?.length ? (
        <Stack vertical mt={1}>
          {comments.map(({ id: commentId, author, authorId, text, likes, dislikes, vote, ownComment }) => (
            <Stack.Item key={commentId}>
              <Button
                compact
                transparent
                icon="user"
                content={author}
                onClick={() => act('profile', { id: authorId })}
              />
              {!!isAdmin && (
                <Button.Confirm
                  icon="trash"
                  color="bad"
                  tooltip={`${adminAction} — удалить комментарий`}
                  role="button"
                  aria-label="Удалить комментарий"
                  confirmContent="Удалить?"
                  onClick={() => act('delete_comment', { id, comment: commentId })}
                />
              )}
              <Box ml={0.5} style={multiline}>{text}</Box>
              <Box mt={0.25}>
                <Button
                  compact
                  icon="thumbs-up"
                  content={likes}
                  role="button"
                  aria-label="Лайк комментарию"
                  aria-pressed={vote === 1}
                  aria-disabled={!canWrite || !!ownComment}
                  selected={vote === 1}
                  disabled={!canWrite || !!ownComment}
                  tooltip={ownComment ? 'Это ваш комментарий' : 'Лайк'}
                  onClick={() => act('vote_comment', { id, comment: commentId, vote: vote === 1 ? 0 : 1 })}
                />
                <Button
                  compact
                  icon="thumbs-down"
                  content={dislikes}
                  role="button"
                  aria-label="Дизлайк комментарию"
                  aria-pressed={vote === -1}
                  aria-disabled={!canWrite || !!ownComment}
                  selected={vote === -1}
                  disabled={!canWrite || !!ownComment}
                  tooltip={ownComment ? 'Это ваш комментарий' : 'Дизлайк'}
                  onClick={() => act('vote_comment', { id, comment: commentId, vote: vote === -1 ? 0 : -1 })}
                />
              </Box>
            </Stack.Item>
          ))}
        </Stack>
      ) : (
        <Box mt={1} color="label">Комментариев пока нет.</Box>
      )}
      <PhotoGalleryPagination page={page} pages={pages} onPage={(page) => act('page', { page })} />
    </Section>
  );
};

const PostPage = ({ post }: { post: Post }) => {
  const { act, data } = useBackend<SyndimaticData>();
  const { canWrite, commentsOpen, commentsDisabled, isAdmin, ownPost, liked, media } = data;
  const { id, authorId, author, caption, likes, comments } = post;
  return (
    <>
      <Section
        title={
          <Button transparent icon="user" content={author} onClick={() => act('profile', { id: authorId })} />
        }
        buttons={(
          <>
            {(!!ownPost || !!isAdmin) && (
              <Button.Confirm
                icon="trash"
                color={isAdmin ? 'bad' : undefined}
                tooltip={isAdmin ? `${adminAction} — удалить публикацию` : 'Удалить публикацию'}
                role="button"
                aria-label="Удалить публикацию"
                confirmContent="Удалить?"
                onClick={() => act('delete_post', { id })}
              />
            )}
            <Button icon="arrow-left" onClick={() => act('back')}>Назад</Button>
          </>
        )}
      >
        <Box mx="auto" style={{ maxWidth: '22rem' }}>
          <PhotoPreview {...media} />
        </Box>
        {!!caption && <Box my={1} style={multiline}>{caption}</Box>}
        <Stack mt={1}>
          <Stack.Item>
            <Button
              icon="heart"
              selected={!!liked}
              disabled={!canWrite}
              role="button"
              aria-label={liked ? 'Убрать отметку «Нравится»' : 'Поставить отметку «Нравится»'}
              aria-pressed={!!liked}
              aria-disabled={!canWrite}
              onClick={() => act('like', { id, liked: liked ? 0 : 1 })}
            >
              Нравится · {likes}
            </Button>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="comment"
              selected={!!commentsOpen}
              role="button"
              aria-expanded={!!commentsOpen}
              onClick={() => act('show_comments', { id })}
            >
              Комментарии · {comments}
            </Button>
          </Stack.Item>
          {!!ownPost && (
            <Stack.Item>
              <Button
                icon={commentsDisabled ? 'unlock' : 'lock'}
                onClick={() => act('set_comments', { id, disabled: commentsDisabled ? 0 : 1 })}
              >
                {commentsDisabled ? 'Открыть комментарии' : 'Закрыть комментарии'}
              </Button>
            </Stack.Item>
          )}
        </Stack>
      </Section>
      {!!commentsOpen && <Comments id={id} />}
    </>
  );
};

const EditProfile = ({ profile }: { profile: Profile }) => {
  const { act, data } = useBackend<SyndimaticData>();
  const [description, setDescription] = useState(profile.description);
  return (
    <Section title="Описание профиля">
      <TextArea
        dontUseTabForIndent
        fluid
        height={5}
        value={description}
        maxLength={data.descriptionLimit}
        placeholder="Описание"
        onInput={(_, value) => setDescription(value)}
      />
      <Box mt={1}>
        <Button icon="check" color="good" onClick={() => act('save_profile', { description })}>
          Сохранить
        </Button>
        <Button onClick={() => act('back')}>Отмена</Button>
      </Box>
    </Section>
  );
};

const ProfilePage = ({ profile }: { profile: Profile }) => {
  const { act, data } = useBackend<SyndimaticData>();
  const { ownProfile, canWrite, editingProfile, isAdmin, profileId,
    profilePublishBlocked, profileCommentBlocked } = data;
  return (
    <>
      <Section>
        <Stack align="center">
          <Stack.Item width={6}>
            {profile.avatar ? (
              <PhotoPreview {...profile.avatar} />
            ) : (
              <Box textAlign="center" color="label">
                <Icon name="user-circle" size={4} />
              </Box>
            )}
          </Stack.Item>
          <Stack.Item grow>
            <Box bold fontSize={1.25} style={multiline}>{profile.name}</Box>
            {!!profile.description && <Box mt={0.5} style={multiline}>{profile.description}</Box>}
            {!!ownProfile && !!canWrite && !editingProfile && (
              <Box mt={1}>
                <Button icon="image" onClick={() => act('pick_avatar')}>Сменить фото</Button>
                <Button icon="pen" onClick={() => act('edit_profile')}>Изменить описание</Button>
              </Box>
            )}
          </Stack.Item>
        </Stack>
      </Section>
      {!!isAdmin && (
        <Section title="Модерация профиля">
          {[
            { kind: 'publish', blocked: profilePublishBlocked, label: 'публикации' },
            { kind: 'comment', blocked: profileCommentBlocked, label: 'комментарии' },
          ].map(({ kind, blocked, label }) => (
            <Button.Confirm
              key={kind}
              icon={blocked ? 'unlock' : 'ban'}
              color="bad"
              tooltip={`${adminAction} — ${blocked ? 'разрешить' : 'заблокировать'} ${label}`}
              content={`${blocked ? 'Разрешить' : 'Заблокировать'} ${label}`}
              confirmContent="Подтвердить"
              onClick={() => act('set_block', { id: profileId, kind, blocked: blocked ? 0 : 1 })}
            />
          ))}
        </Section>
      )}
      {editingProfile ? (
        <EditProfile profile={profile} />
      ) : (
        <Section title="Публикации">
          {profilePublishBlocked ? <NoticeBox>Профиль заблокирован.</NoticeBox> : <PostGallery />}
        </Section>
      )}
    </>
  );
};

const PhotoDraft = ({ id, avatar }: { id: string; avatar: boolean }) => {
  const { act, data } = useBackend<SyndimaticData>();
  const [caption, setCaption] = useState('');
  return (
    <Section
      title={avatar ? 'Фото профиля' : 'Новая публикация'}
      buttons={<Button icon="times" onClick={() => act('back')}>Отмена</Button>}
    >
      <Box mx="auto" mb={1} style={{ maxWidth: avatar ? '12rem' : '20rem' }}>
        <PhotoPreview {...data.media} />
      </Box>
      {!avatar && (
        <TextArea
          dontUseTabForIndent
          fluid
          height={4}
          maxLength={data.captionLimit}
          placeholder="Подпись к фотографии"
          value={caption}
          onInput={(_, value) => setCaption(value)}
        />
      )}
      <Box mt={1}>
        {avatar ? (
          <Button icon="check" color="good" onClick={() => act('save_avatar', { id })}>
            Сохранить фото
          </Button>
        ) : (
          <Button
            icon="paper-plane"
            color="good"
            disabled={!!data.publishBlocked}
            tooltip={data.publishBlocked ? 'Вам заблокировано создание публикаций.' : undefined}
            onClick={() => act('publish', { id, caption })}
          >
            Опубликовать
          </Button>
        )}
      </Box>
    </Section>
  );
};

const NotificationOptions = () => {
  const { act, data } = useBackend<SyndimaticData>();
  const [open, setOpen] = useState(false);
  if (!data.canSetNotifications) {
    return null;
  }
  return (
    <Section
      buttons={(
        <Button
          icon={data.notifications ? 'bell' : 'bell-slash'}
          tooltip="Настроить уведомления о новых публикациях"
          role="button"
          aria-expanded={open}
          onClick={() => setOpen(!open)}
        >
          {data.notifications ? 'Включены' : 'Выключены'}
        </Button>
      )}
      title="Уведомления"
    >
      {open && (
        <>
          {[
            { enabled: 1, permanent: 0, label: 'Включить на эту смену' },
            { enabled: 0, permanent: 0, label: 'Выключить на эту смену' },
            { enabled: 1, permanent: 1, label: 'Включить постоянно' },
            { enabled: 0, permanent: 1, label: 'Выключить постоянно' },
          ].map(({ enabled, permanent, label }) => (
            <Button
              key={label}
              onClick={() => {
                act('notifications', { enabled, permanent });
                setOpen(false);
              }}
            >
              {label}
            </Button>
          ))}
        </>
      )}
    </Section>
  );
};

export const NtosSyndimatic = () => {
  const { act, data } = useBackend<SyndimaticData>();
  const { blocks, canWrite, draftId, isAdmin, myProfile, ownProfile, post, profile, publishBlocked, view } = data;

  return (
    <NtosWindow title="Syndimatic" width={550} height={620}>
      <NtosWindow.Content scrollable>
        <Stack mb={1}>
          <Stack.Item>
            <Button icon="images" selected={view === 'feed'} onClick={() => act('feed')}>
              Лента
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              icon="user"
              selected={view === 'profile' && !!ownProfile}
              disabled={!myProfile}
              tooltip={!myProfile ? 'Профиль появится после первой публикации или комментария.' : undefined}
              onClick={() => act('profile')}
            >
              Мой профиль
            </Button>
          </Stack.Item>
          {!!isAdmin && (
            <Stack.Item>
              <Button
                icon="ban"
                color="bad"
                tooltip={`${adminAction} — открыть список блокировок`}
                onClick={() => act('blocks')}
              >
                Блокировки
              </Button>
            </Stack.Item>
          )}
          <Stack.Item>
            <Button
              icon="plus"
              color="good"
              disabled={!canWrite || !!publishBlocked}
              tooltip={publishBlocked ? 'Вам заблокировано создание публикаций.' : undefined}
              onClick={() => act('pick_post')}
            >
              Новый пост
            </Button>
          </Stack.Item>
        </Stack>
        {view === 'feed' && (
          <>
            <NotificationOptions />
            <PostGallery />
          </>
        )}
        {view === 'blocks' && !!isAdmin && (
          <Section title="Заблокированные профили">
            {blocks?.length ? blocks.map(({ id, name }) => (
              <Button
                key={id}
                icon="user"
                color="bad"
                content={name}
                tooltip={`${adminAction} — открыть заблокированный профиль`}
                onClick={() => act('profile', { id })}
              />
            )) : <NoticeBox>Активных блокировок нет.</NoticeBox>}
          </Section>
        )}
        {view === 'profile' && profile && <ProfilePage profile={profile} />}
        {view === 'post' && post && <PostPage key={post.id} post={post} />}
        {(view === 'compose' || view === 'avatar') && draftId && (
          <PhotoDraft key={draftId} id={draftId} avatar={view === 'avatar'} />
        )}
      </NtosWindow.Content>
    </NtosWindow>
  );
};
