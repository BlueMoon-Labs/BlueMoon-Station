import { type RefObject, useEffect, useLayoutEffect, useRef, useState } from 'react';

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
  avatar?: PhotoMedia | null;
  thumbnail?: string | null;
  thumbnailUrl?: string | null;
};

type Comment = {
  id: string;
  authorId: string;
  author: string;
  avatar?: PhotoMedia | null;
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
  view: 'feed' | 'gallery' | 'profile' | 'post' | 'compose' | 'avatar' | 'blocks';
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
  feedIds?: string[];
  feedLimit: number;
  feedHasMore: ByondFlag;
  [key: `feedPhoto:${string}`]: PhotoMedia | null | undefined;
  [key: `feedPost:${string}`]: (Post & { liked: ByondFlag }) | undefined;
  post?: Post;
  liked?: ByondFlag;
  commentsOpen?: ByondFlag;
  comments?: Comment[];
  commentSerial: number;
  commentSort: 'oldest' | 'newest' | 'popular';
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
const commentSortOptions = [
  { value: 'oldest', displayText: 'Сначала старые' },
  { value: 'newest', displayText: 'Сначала новые' },
  { value: 'popular', displayText: 'По лайкам' },
];

const ProfileAvatar = ({ avatar, size }: { avatar?: PhotoMedia | null; size: number }) => (
  <Box
    aria-hidden="true"
    width={size}
    height={size}
    textAlign="center"
    style={{ borderRadius: '50%', overflow: 'hidden', display: 'grid', placeItems: 'center' }}
  >
    {avatar ? <PhotoPreview {...avatar} /> : <Icon name="user-circle" size={size - 0.25} />}
  </Box>
);

const AuthorButton = ({ id, name, avatar, size = 4 }: {
  id: string;
  name: string;
  avatar?: PhotoMedia | null;
  size?: number;
}) => {
  const { act } = useBackend<SyndimaticData>();
  return (
    <Button
      compact
      color="transparent"
      style={{ backgroundColor: 'transparent', color: 'inherit' }}
      role="button"
      onClick={() => act('profile', { id })}
    >
      <Stack align="center">
        <Stack.Item>
          <ProfileAvatar avatar={avatar} size={size} />
        </Stack.Item>
        <Stack.Item bold style={{ overflowWrap: 'anywhere' }}>{name}</Stack.Item>
      </Stack>
    </Button>
  );
};

const PostLikeButton = ({ id, likes, liked }: { id: string; likes: number; liked?: ByondFlag }) => {
  const { act, data } = useBackend<SyndimaticData>();
  return (
    <Button
      icon="heart"
      selected={!!liked}
      disabled={!data.canWrite}
      role="button"
      aria-label={liked ? 'Убрать отметку «Нравится»' : 'Поставить отметку «Нравится»'}
      aria-pressed={!!liked}
      aria-disabled={!data.canWrite}
      onClick={() => act('like', { id, liked: liked ? 0 : 1 })}
    >
      Нравится · {likes}
    </Button>
  );
};

const useFeedTrigger = (
  scrollRef: RefObject<HTMLDivElement | null>,
  enabled: boolean,
  action: 'feed_photo' | 'feed_more',
  value: string | number,
) => {
  const { act } = useBackend<SyndimaticData>();
  const targetRef = useRef<HTMLDivElement>(null);
  const requestRef = useRef<(() => void) | null>(null);
  useEffect(() => {
    const target = targetRef.current;
    if (!enabled || !target) {
      return;
    }
    let pendingUntil = 0;
    const request = () => {
      const now = performance.now();
      if (now < pendingUntil) {
        return;
      }
      pendingUntil = now + 2000;
      act(action, action === 'feed_photo' ? { id: value } : { limit: value });
    };
    requestRef.current = request;
    const observer = new IntersectionObserver((entries) => {
      if (entries.some((entry) => entry.isIntersecting)) {
        request();
      }
    }, { root: scrollRef.current, rootMargin: '160px 0px' });
    observer.observe(target);
    return () => {
      observer.disconnect();
      requestRef.current = null;
    };
  }, [act, scrollRef, enabled, action, value]);
  return { targetRef, request: () => requestRef.current?.() };
};

const FeedPost = ({ post, scrollRef }: {
  post: Post & { liked: ByondFlag };
  scrollRef: RefObject<HTMLDivElement | null>;
}) => {
  const { act, data } = useBackend<SyndimaticData>();
  const { id, author, authorId, avatar, caption, comments, likes, liked } = post;
  const media = data[`feedPhoto:${id}`];
  const { targetRef: photoRef, request: loadPhoto } = useFeedTrigger(scrollRef, media === undefined, 'feed_photo', id);

  return (
    <Box as="article" data-feed-post={id} mb={1} p={0.75} backgroundColor="rgba(0, 0, 0, 0.22)"
      style={{ border: '1px solid #ffffff24', borderRadius: '0.35rem' }}>
      <div ref={photoRef} style={{ margin: '0.5rem 0' }}>
        {media === undefined ? (
          <Box
            backgroundColor="#111"
            style={{ aspectRatio: '1 / 1', display: 'grid', placeItems: 'center' }}
          >
            <Button icon="image" onClick={loadPhoto}>Загрузить фото</Button>
          </Box>
        ) : (
          <PhotoPreview {...media} />
        )}
      </div>
      <AuthorButton id={authorId} name={author} avatar={avatar} />
      {!!caption && <Box mt={0.5} style={multiline}>{caption}</Box>}
      <Stack align="center" wrap="wrap" mt={0.5}>
        <Stack.Item><PostLikeButton id={id} likes={likes} liked={liked} /></Stack.Item>
        <Stack.Item>
          <Button icon="comment" role="button" onClick={() => act('open_post', { id, comments: 1 })}>
            Комментарии · {comments}
          </Button>
        </Stack.Item>
      </Stack>
    </Box>
  );
};

const PostFeed = ({ scrollRef }: { scrollRef: RefObject<HTMLDivElement | null> }) => {
  const { data } = useBackend<SyndimaticData>();
  const { feedHasMore, feedLimit, feedIds } = data;
  const { targetRef: moreRef, request: loadMore } = useFeedTrigger(scrollRef, !!feedHasMore, 'feed_more', feedLimit);

  if (!feedIds?.length) {
    return <NoticeBox>В ленте пока нет публикаций.</NoticeBox>;
  }
  return (
    <>
      {feedIds.map((id) => {
        const post = data[`feedPost:${id}`];
        return post ? <FeedPost key={id} post={post} scrollRef={scrollRef} /> : null;
      })}
      {!!feedHasMore && (
        <div ref={moreRef}>
          <Button fluid icon="chevron-down" onClick={loadMore}>Загрузить ещё</Button>
        </div>
      )}
    </>
  );
};

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
        {posts.map(({ id, author, avatar, caption, thumbnail, thumbnailUrl, likes, comments }) => (
          <PhotoTile
            key={id}
            label={`${author}${caption ? ` · ${caption}` : ''} · Нравится: ${likes}, комментарии: ${comments}`}
            thumbnail={thumbnail}
            thumbnailUrl={thumbnailUrl}
            onClick={() => act('open_post', { id })}
            footer={
              <Stack align="center">
                {view === 'gallery' && (
                  <Stack.Item shrink={0}><ProfileAvatar avatar={avatar} size={3} /></Stack.Item>
                )}
                <Stack.Item grow minWidth={0}>
                  {view === 'gallery' && <Box bold style={ellipsis}>{author}</Box>}
                  <Stack>
                    <Stack.Item><Icon name="heart" /> {likes}</Stack.Item>
                    <Stack.Item><Icon name="comment" /> {comments}</Stack.Item>
                  </Stack>
                </Stack.Item>
              </Stack>
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
  const { canWrite, comments, commentSerial, commentSort, commentBlocked, commentsDisabled, isAdmin, page, pages } = data;
  return (
    <Section title="Комментарии" data-syndimatic-comments>
      <Box mb={1}>
        <select
          aria-label="Порядок комментариев"
          value={commentSort}
          onChange={(event) => act('sort_comments', { id, order: event.target.value })}
          style={{ font: 'inherit', colorScheme: 'dark' }}
        >
          {commentSortOptions.map(({ value, displayText }) => (
            <option key={value} value={value}>{displayText}</option>
          ))}
        </select>
      </Box>
      {commentsDisabled ? (
        <NoticeBox>Автор закрыл комментарии к публикации.</NoticeBox>
      ) : commentBlocked ? (
        <NoticeBox>Вам заблокировано комментирование.</NoticeBox>
      ) : !!canWrite && <CommentForm key={`${id}:${commentSerial}`} id={id} />}
      {comments?.length ? (
        <Stack vertical mt={1}>
          {comments.map(({ id: commentId, author, authorId, avatar, text, likes, dislikes, vote, ownComment }) => (
            <Stack.Item key={commentId}>
              <Stack align="center">
                <Stack.Item>
                  <AuthorButton id={authorId} name={author} avatar={avatar} size={3} />
                </Stack.Item>
                {!!isAdmin && (
                  <Stack.Item>
                    <Button.Confirm
                      icon="trash"
                      color="bad"
                      tooltip={`${adminAction} — удалить комментарий`}
                      role="button"
                      aria-label="Удалить комментарий"
                      confirmContent="Удалить?"
                      onClick={() => act('delete_comment', { id, comment: commentId })}
                    />
                  </Stack.Item>
                )}
              </Stack>
              <Box ml={0.5} style={multiline}>{text}</Box>
              <Box mt={0.25}>
                {[
                  { value: 1, count: likes, icon: 'thumbs-up', color: 'good', label: 'Лайк комментарию' },
                  { value: -1, count: dislikes, icon: 'thumbs-down', color: 'bad', label: 'Дизлайк комментарию' },
                ].map(({ value, count, icon, color, label }) => (
                  <button
                    key={value}
                    type="button"
                    aria-label={label}
                    aria-pressed={vote === value}
                    disabled={!canWrite || !!ownComment}
                    title={ownComment ? 'Это ваш комментарий' : label}
                    onClick={() => act('vote_comment', { id, comment: commentId, vote: vote === value ? 0 : value })}
                    style={{
                      color: 'inherit',
                      font: 'inherit',
                      border: 0,
                      background: 'transparent',
                      opacity: !canWrite || ownComment ? 0.6 : 1,
                      cursor: !canWrite || ownComment ? 'default' : 'pointer',
                      padding: '0.15rem 0.5rem',
                    }}
                  >
                    <Icon name={icon} color={vote === value ? color : undefined} mr={0.4} />
                    {count}
                  </button>
                ))}
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
  const { commentsOpen, commentsDisabled, isAdmin, ownPost, liked, media } = data;
  const { id, authorId, author, avatar, caption, likes, comments } = post;
  return (
    <>
      <Section>
        <Box mb={0.5} textAlign="right">
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
        </Box>
        <Box mx="auto" style={{ maxWidth: '22rem' }}>
          <PhotoPreview {...media} />
        </Box>
        <AuthorButton id={authorId} name={author} avatar={avatar} />
        {!!caption && <Box my={1} style={multiline}>{caption}</Box>}
        <Stack mt={1}>
          <Stack.Item>
            <PostLikeButton id={id} likes={likes} liked={liked} />
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
  const optionsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) {
      return;
    }
    const dismissOutside = (event: PointerEvent) => {
      if (!optionsRef.current?.contains(event.target as Node)) {
        setOpen(false);
      }
    };
    const dismissOnEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        setOpen(false);
      }
    };
    document.addEventListener('pointerdown', dismissOutside);
    document.addEventListener('keydown', dismissOnEscape);
    return () => {
      document.removeEventListener('pointerdown', dismissOutside);
      document.removeEventListener('keydown', dismissOnEscape);
    };
  }, [open]);

  if (!data.canSetNotifications) {
    return null;
  }
  return (
    <div ref={optionsRef} style={{ display: 'inline-block', marginRight: '0.2rem' }}>
      <Button
        icon={data.notifications ? 'bell' : 'bell-slash'}
        tooltip={data.notifications ? 'Уведомления включены' : 'Уведомления выключены'}
        role="button"
        aria-label="Настроить уведомления о новых публикациях"
        aria-expanded={open}
        onClick={() => setOpen(!open)}
      />
      {open && (
        <Box
          role="group"
          aria-label="Уведомления"
          position="absolute"
          right={0.75}
          top="100%"
          width="16rem"
          maxWidth="calc(100% - 1.5rem)"
          p={0.5}
          backgroundColor="#1c2531"
          style={{ boxSizing: 'border-box', zIndex: 5, borderRadius: '0.35rem', boxShadow: '0 0.25rem 0.75rem #0008' }}
        >
          {[
            { enabled: 1, permanent: 0, label: 'Включить на эту смену' },
            { enabled: 0, permanent: 0, label: 'Выключить на эту смену' },
            { enabled: 1, permanent: 1, label: 'Включить постоянно' },
            { enabled: 0, permanent: 1, label: 'Выключить постоянно' },
          ].map(({ enabled, permanent, label }) => (
            <Button
              key={label}
              fluid
              role="button"
              style={{ whiteSpace: 'normal' }}
              onClick={() => {
                act('notifications', { enabled, permanent });
                setOpen(false);
              }}
            >
              {label}
            </Button>
          ))}
        </Box>
      )}
    </div>
  );
};

export const NtosSyndimatic = () => {
  const { act, data } = useBackend<SyndimaticData>();
  const { blocks, canWrite, draftId, isAdmin, myProfile, ownProfile, post, profile, publishBlocked, view } = data;
  const scrollRef = useRef<HTMLDivElement>(null);
  const feedPosition = useRef({ id: '', offset: 0, scrollTop: 0 });
  const viewedPostId = view === 'post' ? post?.id : undefined;

  const rememberFeedPosition = () => {
    const content = scrollRef.current;
    if (view !== 'feed' || !content) {
      return;
    }
    const viewport = content.getBoundingClientRect();
    for (const card of content.querySelectorAll<HTMLElement>('[data-feed-post]')) {
      const rect = card.getBoundingClientRect();
      if (rect.bottom > viewport.top && rect.top < viewport.bottom) {
        const scale = viewport.width / content.offsetWidth || 1;
        feedPosition.current = {
          id: card.dataset.feedPost || '',
          offset: (viewport.top - rect.top) / scale,
          scrollTop: content.scrollTop,
        };
        return;
      }
    }
    feedPosition.current = { id: '', offset: 0, scrollTop: content.scrollTop };
  };

  useLayoutEffect(() => {
    const content = scrollRef.current;
    if (content) {
      if (view === 'feed') {
        const { id, offset, scrollTop } = feedPosition.current;
        const card = id && content.querySelector(`[data-feed-post="${CSS.escape(id)}"]`);
        const viewport = content.getBoundingClientRect();
        const scale = viewport.width / content.offsetWidth || 1;
        content.scrollTop = card
          ? content.scrollTop + (card.getBoundingClientRect().top - viewport.top) / scale + offset
          : scrollTop;
      } else {
        content.scrollTop = 0;
      }
      if (view === 'post') {
        content.querySelector('[data-syndimatic-comments]')?.scrollIntoView({ block: 'start' });
      }
    }
  }, [view, viewedPostId]);

  return (
    <NtosWindow title="Syndimatic" width={550} height={620}>
      <NtosWindow.Content fitted>
        <Stack
          vertical
          fill
          onClickCapture={rememberFeedPosition}
          onKeyDownCapture={(event) => {
            if (event.key === 'Enter' || event.key === ' ') {
              rememberFeedPosition();
            }
          }}
        >
          <Stack.Item position="relative" px={0.75} pt={0.75} pb={0.5}>
            <Stack wrap="wrap" align="center">
              <Stack.Item grow>
                <Button
                  icon="stream"
                  selected={view === 'feed'}
                  role="button"
                  aria-pressed={view === 'feed'}
                  onClick={() => act('feed')}
                >
                  Лента
                </Button>
                <Button
                  icon="images"
                  selected={view === 'gallery'}
                  role="button"
                  aria-pressed={view === 'gallery'}
                  onClick={() => act('gallery')}
                >
                  Галерея
                </Button>
                <Button
                  icon="user"
                  selected={view === 'profile' && !!ownProfile}
                  role="button"
                  aria-pressed={view === 'profile' && !!ownProfile}
                  aria-disabled={!myProfile}
                  disabled={!myProfile}
                  tooltip={!myProfile ? 'Профиль появится после первой публикации или комментария.' : undefined}
                  onClick={() => act('profile')}
                >
                  Мой профиль
                </Button>
              </Stack.Item>
              <Stack.Item>
                {!!isAdmin && (
                  <Button
                    icon="ban"
                    color="bad"
                    role="button"
                    aria-label="Блокировки"
                    tooltip={`${adminAction} — открыть список блокировок`}
                    onClick={() => act('blocks')}
                  />
                )}
                <NotificationOptions />
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
          </Stack.Item>
          <Stack.Item grow minHeight={0}>
            <Section
              fill
              scrollable
              scrollableRef={scrollRef}
            >
              {view === 'feed' && <PostFeed scrollRef={scrollRef} />}
              {view === 'gallery' && <PostGallery />}
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
            </Section>
          </Stack.Item>
        </Stack>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
