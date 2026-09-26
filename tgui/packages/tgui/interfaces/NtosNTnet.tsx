import {
  CSSProperties,
  ReactNode,
  useCallback,
  useEffect,
  useRef,
  useState,
} from 'react';

import { useBackend } from '../backend';
import { Box, Icon } from '../components';
import { NtosWindow } from '../layouts';

type Palette = {
  accent: string;
  chrome: string;
  deep: string;
  line: string;
  text: string;
  muted: string;
  disabled: string;
  surface: string;
  canvas: string;
  secure: string;
  danger: string;
  notice: string;
  noticeText: string;
};

const PALETTES: Record<string, Palette> = {
  dark: {
    accent: '#4a9eff',
    chrome: '#1b1e24',
    deep: '#101217',
    line: '#33394a',
    text: '#e6e9ef',
    muted: '#8b93a3',
    disabled: '#4d5361',
    surface: '#1c1f26',
    canvas: '#15171c',
    secure: '#57c785',
    danger: '#ff8080',
    notice: '#3a2f1c',
    noticeText: '#f0c674',
  },
  light: {
    accent: '#1a73e8',
    chrome: '#dfe3ea',
    deep: '#c3cad4',
    line: '#aab3c0',
    text: '#1f2328',
    muted: '#5f6672',
    disabled: '#a7aebb',
    surface: '#ffffff',
    canvas: '#f2f3f5',
    secure: '#1e8e3e',
    danger: '#c5221f',
    notice: '#fdf3d8',
    noticeText: '#7a5b12',
  },
};

const FRAME_ADDRESS =
  /^https:\/\/[a-z0-9.-]{4,64}\/i\/[a-f0-9]{32}\/[a-z0-9][a-z0-9-]{0,62}$/;
const FRAME_SITE = /^[a-f0-9]{32}$/;
const FRAME_SLUG = /^[a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?$/;
const FRAME_SANDBOX = 'allow-scripts';
const FRAME_POLICY_VERSION = 3;
const SANDBOX_MIRROR = 'https://sandbox-ru.wiki-ss13.space';
const framePolicy = (url: string) =>
  [
    "default-src 'none'",
    "script-src 'unsafe-inline'",
    "style-src 'unsafe-inline'",
    'img-src https: data:',
    'media-src https:',
    "font-src data:",
    `connect-src ${url.slice(0, url.indexOf('/', 'https://'.length))} ${SANDBOX_MIRROR}`,
    "form-action 'none'",
    "frame-src 'none'",
    "child-src 'none'",
    "worker-src 'none'",
    "object-src 'none'",
    "base-uri 'none'",
    'sandbox allow-scripts',
  ].join('; ');
const PROBE_TIMEOUT = 700;
const LAG_TICK = 1000;
const LAG_LIMIT = 4000;
const CSP_PROBE =
  '<meta http-equiv="Content-Security-Policy" content="script-src \'none\'">' +
  '<script>parent.postMessage("ntnet-probe-csp","*")</script>';
const SANDBOX_PROBE =
  '<script>parent.postMessage("ntnet-probe-sandbox","*")</script>';

let rendererCheck: Promise<boolean> | null = null;

const escapes = (): Promise<boolean> =>
  new Promise((resolve) => {
    let settled = false;
    const frames: HTMLIFrameElement[] = [];
    const finish = (leaked: boolean) => {
      if (settled) {
        return;
      }
      settled = true;
      window.removeEventListener('message', listener);
      window.clearTimeout(timer);
      for (const frame of frames) {
        frame.remove();
      }
      resolve(leaked);
    };
    const listener = (event: MessageEvent) => {
      if (
        event.data === 'ntnet-probe-csp' ||
        event.data === 'ntnet-probe-sandbox'
      ) {
        finish(true);
      }
    };
    const timer = window.setTimeout(() => finish(false), PROBE_TIMEOUT);
    window.addEventListener('message', listener);
    try {
      const probes: [string, string | null][] = [
        [CSP_PROBE, null],
        [SANDBOX_PROBE, ''],
      ];
      for (const [markup, sandbox] of probes) {
        const frame = document.createElement('iframe');
        frame.style.display = 'none';
        if (sandbox !== null) {
          frame.setAttribute('sandbox', sandbox);
        }
        frame.srcdoc = markup;
        document.body.appendChild(frame);
        frames.push(frame);
      }
    } catch {
      finish(true);
    }
  });

const rendererAllows = (): Promise<boolean> => {
  if (!rendererCheck) {
    rendererCheck = (async () => {
      const frame = document.createElement('iframe');
      if (!('sandbox' in frame) || !('srcdoc' in frame)) {
        return false;
      }
      return !(await escapes());
    })().catch(() => false);
  }
  return rendererCheck;
};

const navigationRequest = (value: any) => {
  if (!value || typeof value !== 'object') {
    return null;
  }
  const { ntnet, site, slug } = value;
  if (
    ntnet !== 'navigate' ||
    typeof site !== 'string' ||
    typeof slug !== 'string' ||
    !FRAME_SITE.test(site) ||
    !FRAME_SLUG.test(slug)
  ) {
    return null;
  }
  return { siteId: site, slug };
};

const tokenRequest = (value: any) =>
  value && typeof value === 'object' && value.ntnet === 'token'
    ? { renew: value.renew === true }
    : null;

type SitePage = {
  slug: string;
  title: string;
};

type Site = {
  id: string;
  domain: string;
  title: string;
  version: string;
  icon?: string;
  pages: SitePage[];
};

type Page = {
  site_id: string;
  slug: string;
  version: string;
  title: string;
  frame: string | null;
  text: string;
};

type Found = {
  site_id: string;
  slug: string;
  title: string;
  snippet: string;
};

type Tab = {
  id: number;
  title: string;
  active: boolean;
};

type Data = {
  tabs: Tab[];
  can_open_tab: boolean;
  available: boolean;
  loading: boolean;
  failed?: boolean;
  viewer?: {
    token: string | null;
    error: string | null;
    answer: number | null;
  };
  catalog: Site[];
  site: Site | null;
  page: Page | null;
  view: string;
  address: string;
  has_back: boolean;
  has_forward: boolean;
  theme: string;
  search: {
    query: string | null;
    results: Found[];
    pending: boolean;
    error: string | null;
  };
  login: {
    code: string | null;
    pending: boolean;
    retry_seconds: number;
    error: string | null;
  };
};

const palette = (data: Data) => PALETTES[data.theme] || PALETTES.dark;

type FieldProps = {
  value: string;
  placeholder: string;
  height: string;
  fontSize: string;
  color: string;
  onEnter: (value: string) => void;
};

const Field = (props: FieldProps) => {
  const { value, placeholder, height, fontSize, color, onEnter } = props;
  const input = useRef<HTMLInputElement | null>(null);
  useEffect(() => {
    if (input.current && document.activeElement !== input.current) {
      input.current.value = value;
    }
  }, [value]);
  return (
    <input
      ref={input}
      defaultValue={value}
      placeholder={placeholder}
      maxLength={120}
      onKeyDown={(event) => {
        if (event.key === 'Enter') {
          onEnter(event.currentTarget.value);
          event.currentTarget.blur();
        }
      }}
      style={{
        flex: '1',
        minWidth: '0',
        width: 'auto',
        height: height,
        background: 'transparent',
        border: '0',
        outline: 'none',
        padding: '0',
        color: color,
        fontFamily: 'inherit',
        fontSize: fontSize,
      }}
    />
  );
};

type ToolButtonProps = {
  icon: string;
  t: Palette;
  disabled?: boolean;
  onClick: () => void;
};

const ToolButton = (props: ToolButtonProps) => {
  const { icon, disabled, t, onClick } = props;
  return (
    <Box
      onClick={() => !disabled && onClick()}
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: '0',
        width: '26px',
        height: '26px',
        borderRadius: '13px',
        cursor: disabled ? 'default' : 'pointer',
        color: disabled ? t.disabled : t.text,
      }}
    >
      <Icon name={icon} style={{ fontSize: '0.9rem' }} />
    </Box>
  );
};

const Avatar = (props: { site: Site; size: string; t: Palette }) => {
  const { site, size, t } = props;
  if (site.icon) {
    return (
      <img
        src={site.icon}
        alt=""
        width={size}
        height={size}
        style={{ borderRadius: '50%', objectFit: 'cover' }}
      />
    );
  }
  return (
    <Box
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        flexShrink: '0',
        width: size,
        height: size,
        borderRadius: '50%',
        background: t.accent,
        color: t.deep,
        fontSize: '1.3rem',
        fontWeight: 'bold',
      }}
    >
      {site.domain.slice(0, 1).toUpperCase()}
    </Box>
  );
};

const Pill = (props: {
  icon: string;
  text: string;
  t: Palette;
  onClick: () => void;
}) => {
  const { icon, text, t, onClick } = props;
  return (
    <Box
      onClick={onClick}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        padding: '8px 16px',
        borderRadius: '18px',
        background: t.surface,
        border: '1px solid ' + t.line,
        color: t.text,
        cursor: 'pointer',
      }}
    >
      <Icon name={icon} style={{ color: t.muted }} />
      {text}
    </Box>
  );
};

const TabStrip = () => {
  const { act, data } = useBackend<Data>();
  const { tabs, can_open_tab } = data;
  const t = palette(data);
  return (
    <Box
      style={{
        display: 'flex',
        alignItems: 'flex-end',
        gap: '2px',
        padding: '6px 8px 0',
        background: t.deep,
      }}
    >
      {tabs.map((tab) => (
        <Box
          key={tab.id}
          onClick={() => act('tab_select', { id: tab.id })}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            maxWidth: '200px',
            padding: '6px 12px',
            borderRadius: '8px 8px 0 0',
            background: tab.active ? t.chrome : 'transparent',
            color: tab.active ? t.text : t.muted,
            cursor: 'pointer',
          }}
        >
          <Icon
            name="globe"
            style={{
              color: tab.active ? t.accent : t.muted,
              fontSize: '0.8rem',
            }}
          />
          <Box
            style={{
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
              fontSize: '0.85rem',
            }}
          >
            {tab.title}
          </Box>
          {tabs.length > 1 && (
            <Box
              onClick={() => act('tab_close', { id: tab.id })}
              style={{ color: t.muted, fontSize: '0.7rem' }}
            >
              <Icon name="times" />
            </Box>
          )}
        </Box>
      ))}
      {can_open_tab && (
        <Box
          onClick={() => act('tab_open')}
          style={{
            padding: '4px 10px 6px',
            cursor: 'pointer',
            color: t.muted,
            fontSize: '1.1rem',
          }}
        >
          <Icon name="plus" />
        </Box>
      )}
    </Box>
  );
};

const Toolbar = () => {
  const { act, data } = useBackend<Data>();
  const { address, has_back, has_forward, site, theme } = data;
  const t = palette(data);
  return (
    <Box
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '5px',
        padding: '6px 8px',
        background: t.chrome,
      }}
    >
      <ToolButton
        icon="arrow-left"
        t={t}
        disabled={!has_back}
        onClick={() => act('back')}
      />
      <ToolButton
        icon="arrow-right"
        t={t}
        disabled={!has_forward}
        onClick={() => act('forward')}
      />
      <ToolButton icon="sync" t={t} onClick={() => act('refresh')} />
      <ToolButton icon="home" t={t} onClick={() => act('home')} />
      <Box
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          flex: '1',
          minWidth: '0',
          height: '28px',
          padding: '0 12px',
          background: t.deep,
          border: '1px solid ' + t.line,
          borderRadius: '14px',
        }}
      >
        <Icon
          name={site ? 'lock' : 'globe'}
          style={{
            color: site ? t.secure : t.muted,
            fontSize: '0.8rem',
          }}
        />
        <Field
          value={address}
          height="26px"
          fontSize="1rem"
          color={t.text}
          placeholder="Введите адрес .bm или поисковый запрос"
          onEnter={(value) => act('go', { query: value })}
        />
      </Box>
      <ToolButton
        icon="list"
        t={t}
        onClick={() => act('view', { name: 'catalog' })}
      />
      <ToolButton
        icon="plus-square"
        t={t}
        onClick={() => act('view', { name: 'create' })}
      />
      <ToolButton
        icon={theme === 'light' ? 'moon-o' : 'sun-o'}
        t={t}
        onClick={() => act('theme')}
      />
    </Box>
  );
};

const HomePage = () => {
  const { act, data } = useBackend<Data>();
  const { catalog } = data;
  const t = palette(data);
  return (
    <Box
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        padding: '60px 24px 32px',
      }}
    >
      <Box
        style={{
          fontSize: '3.4rem',
          fontWeight: 'bold',
          lineHeight: '1',
        }}
      >
        NT
        <Box as="span" style={{ color: t.accent }}>
          net
        </Box>
      </Box>
      <Box mt={0.5} style={{ color: t.muted, letterSpacing: '2px' }}>
        СЕТЬ СТАНЦИОННЫХ САЙТОВ
      </Box>
      <Box
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '10px',
          width: '100%',
          maxWidth: '520px',
          height: '42px',
          margin: '28px 0 0',
          padding: '0 18px',
          background: t.surface,
          border: '1px solid ' + t.line,
          borderRadius: '21px',
        }}
      >
        <Icon name="search" style={{ color: t.muted }} />
        <Field
          value=""
          height="40px"
          fontSize="1.1rem"
          color={t.text}
          placeholder="Поиск в NTnet"
          onEnter={(value) => act('go', { query: value })}
        />
      </Box>
      <Box mt={2} style={{ display: 'flex', gap: '10px' }}>
        <Pill
          icon="list"
          text="Список сайтов"
          t={t}
          onClick={() => act('view', { name: 'catalog' })}
        />
        <Pill
          icon="plus"
          text="Создать сайт"
          t={t}
          onClick={() => act('view', { name: 'create' })}
        />
      </Box>
      {catalog.length ? (
        <Box
          style={{
            display: 'flex',
            flexWrap: 'wrap',
            justifyContent: 'center',
            gap: '12px',
            maxWidth: '640px',
            marginTop: '32px',
          }}
        >
          {catalog.slice(0, 8).map((site) => (
            <Box
              key={site.id}
              onClick={() =>
                act('open', { site_id: site.id, slug: site.pages[0].slug })
              }
              style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '8px',
                width: '96px',
                padding: '10px 4px',
                borderRadius: '10px',
                cursor: 'pointer',
                background: t.surface,
              }}
            >
              <Avatar site={site} size="40px" t={t} />
              <Box
                style={{
                  width: '100%',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                  textAlign: 'center',
                  fontSize: '0.75rem',
                  color: t.muted,
                }}
              >
                {site.domain}
              </Box>
            </Box>
          ))}
        </Box>
      ) : null}
    </Box>
  );
};

const CatalogPage = () => {
  const { act, data } = useBackend<Data>();
  const { catalog } = data;
  const t = palette(data);
  return (
    <Box style={{ padding: '24px' }}>
      <Box mb={2} style={{ fontSize: '1.4rem', fontWeight: 'bold' }}>
        Список сайтов
      </Box>
      {(catalog.length &&
        catalog.map((site) => (
          <Box
            key={site.id}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              padding: '12px 14px',
              marginBottom: '8px',
              borderRadius: '10px',
              background: t.surface,
            }}
          >
            <Avatar site={site} size="36px" t={t} />
            <Box style={{ flex: '1', minWidth: '0' }}>
              <Box style={{ fontWeight: 'bold' }}>{site.title}</Box>
              <Box style={{ color: t.muted, fontSize: '0.85rem' }}>
                {site.domain}
              </Box>
            </Box>
            {site.pages.map((page) => (
              <Box
                key={page.slug}
                onClick={() =>
                  act('open', { site_id: site.id, slug: page.slug })
                }
                style={{
                  padding: '6px 12px',
                  borderRadius: '14px',
                  background: t.chrome,
                  color: t.accent,
                  cursor: 'pointer',
                  fontSize: '0.85rem',
                }}
              >
                {page.title}
              </Box>
            ))}
          </Box>
        ))) || <Box style={{ color: t.muted }}>Каталог пуст.</Box>}
    </Box>
  );
};

const CreatePage = () => {
  const { act, data } = useBackend<Data>();
  const { login } = data;
  const t = palette(data);
  return (
    <Box
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        padding: '60px 24px',
      }}
    >
      <Box style={{ fontSize: '1.6rem', fontWeight: 'bold' }}>
        Создать сайт
      </Box>
      <Box
        mt={1}
        style={{
          color: t.muted,
          maxWidth: '440px',
          textAlign: 'center',
        }}
      >
        Сайты собираются во внешнем редакторе. Возьмите одноразовый код,
        откройте редактор на любом устройстве и введите его.
      </Box>
      {(login.code && (
        <Box
          mt={3}
          style={{
            padding: '18px 28px',
            borderRadius: '12px',
            background: t.surface,
            border: '1px solid ' + t.line,
            textAlign: 'center',
          }}
        >
          <Box
            style={{
              fontSize: '2rem',
              fontWeight: 'bold',
              letterSpacing: '2px',
            }}
          >
            {login.code}
          </Box>
          <Box mt={1} style={{ color: t.muted }}>
            Действует 15 минут. Никому не передавайте.
          </Box>
        </Box>
      )) || (
        <Box mt={3}>
          <Pill
            icon="key"
            t={t}
            text={login.pending ? 'Запрос…' : 'Получить код'}
            onClick={() =>
              !login.pending && !login.retry_seconds && act('login')
            }
          />
        </Box>
      )}
      {login.retry_seconds > 0 && (
        <Box mt={1} style={{ color: t.muted }}>
          Следующая попытка через {login.retry_seconds} с
        </Box>
      )}
      {login.error && (
        <Box mt={1} style={{ color: t.danger }}>
          {login.error}
        </Box>
      )}
    </Box>
  );
};

const plural = (count: number, one: string, few: string, many: string) => {
  const tail = count % 100;
  if (tail > 10 && tail < 20) {
    return many;
  }
  switch (count % 10) {
    case 1:
      return one;
    case 2:
    case 3:
    case 4:
      return few;
    default:
      return many;
  }
};

const highlight = (snippet: string, query: string, t: Palette) => {
  const stems = query
    .toLowerCase()
    .split(/\s+/)
    .filter((word) => word.length > 1)
    .map((word) =>
      word.length > 6
        ? word.slice(0, -2)
        : word.length > 4
          ? word.slice(0, -1)
          : word,
    );
  const lowered = snippet.toLowerCase();
  const marks = new Array(snippet.length).fill(false);
  for (const stem of stems) {
    let at = lowered.indexOf(stem);
    while (at >= 0) {
      marks.fill(true, at, at + stem.length);
      at = lowered.indexOf(stem, at + stem.length);
    }
  }
  const parts: ReactNode[] = [];
  let start = 0;
  for (let index = 1; index <= snippet.length; index++) {
    if (index === snippet.length || marks[index] !== marks[start]) {
      const text = snippet.slice(start, index);
      parts.push(
        marks[start] ? (
          <b key={start} style={{ color: t.text }}>
            {text}
          </b>
        ) : (
          <Box as="span" key={start}>
            {text}
          </Box>
        ),
      );
      start = index;
    }
  }
  return parts;
};

const SearchPage = () => {
  const { act, data } = useBackend<Data>();
  const { catalog, search } = data;
  const t = palette(data);
  const query = search.query || '';
  if (search.pending) {
    return (
      <Box style={{ padding: '40px', textAlign: 'center', color: t.muted }}>
        <Icon name="spinner" spin mr={1} />
        Ищем «{query}» в NTnet…
      </Box>
    );
  }
  return (
    <Box style={{ padding: '18px 24px 40px', maxWidth: '760px' }}>
      <Box style={{ color: t.muted, fontSize: '0.8rem' }}>
        {search.results.length
          ? `Найдено ${search.results.length} ${plural(search.results.length, 'страница', 'страницы', 'страниц')} по запросу «${query}»`
          : `По запросу «${query}» ничего не найдено`}
      </Box>
      {search.results.map((entry) => {
        const site = catalog.find((known) => known.id === entry.site_id);
        if (!site) {
          return null;
        }
        const first = site.pages[0].slug === entry.slug;
        return (
          <Box key={entry.site_id + '/' + entry.slug} mt={2.5}>
            <Box
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                color: t.muted,
                fontSize: '0.8rem',
              }}
            >
              <Avatar site={site} size="16px" t={t} />
              {site.domain}
              {first ? null : ` › ${entry.title}`}
            </Box>
            <Box
              onClick={() =>
                act('open', { site_id: entry.site_id, slug: entry.slug })
              }
              style={{
                marginTop: '2px',
                color: t.accent,
                fontSize: '1.25rem',
                cursor: 'pointer',
                textDecoration: 'underline',
              }}
            >
              {first ? site.title : entry.title}
            </Box>
            <Box mt={0.5} style={{ color: t.muted, lineHeight: '1.5' }}>
              {highlight(entry.snippet, query, t)}
            </Box>
          </Box>
        );
      })}
      {search.results.length ? null : (
        <Box mt={2} style={{ color: t.muted, lineHeight: '1.6' }}>
          Попробуйте другие слова или откройте{' '}
          <Box
            as="span"
            onClick={() => act('view', { name: 'catalog' })}
            style={{ color: t.accent, cursor: 'pointer' }}
          >
            список сайтов
          </Box>
          .
        </Box>
      )}
    </Box>
  );
};

const PageText = (props: { text: string; t: Palette }) => {
  const { text, t } = props;
  if (!text) {
    return <Box style={{ padding: '24px', color: t.muted }}>Страница пуста.</Box>;
  }
  return <Box style={{ padding: '24px', whiteSpace: 'pre-wrap' }}>{text}</Box>;
};

type FrameProps = {
  url: string;
  title: string;
  t: Palette;
  fallback: any;
  onNavigate: (siteId: string, slug: string) => void;
};

const PageFrame = (props: FrameProps) => {
  const { url, title, t, fallback, onNavigate } = props;
  const { act, data } = useBackend<Data>();
  const [allowed, setAllowed] = useState<boolean | null>(null);
  const [stopped, setStopped] = useState(false);
  const [loaded, setLoaded] = useState(false);
  const frame = useRef<HTMLIFrameElement | null>(null);
  const wantsToken = useRef(false);
  const askedAnswer = useRef<number | null>(null);
  const viewer = useRef(data.viewer);
  viewer.current = data.viewer;
  const deliverToken = () => {
    const target = frame.current?.contentWindow;
    const current = viewer.current;
    if (!wantsToken.current || !target || !current) {
      return;
    }
    if ((current.answer || null) === askedAnswer.current) {
      return;
    }
    if (current.token) {
      target.postMessage({ ntnet: 'token', token: current.token }, '*');
    } else {
      const error = current.error || 'Не удалось получить доступ к базе сайта.';
      target.postMessage({ ntnet: 'token', error }, '*');
    }
    wantsToken.current = false;
  };
  useEffect(deliverToken, [data.viewer?.answer]);
  useEffect(() => {
    let alive = true;
    const receive = (event: MessageEvent) => {
      if (!frame.current || event.source !== frame.current.contentWindow) {
        return;
      }
      const asked = tokenRequest(event.data);
      if (asked) {
        const token = viewer.current?.token;
        if (!asked.renew && token) {
          frame.current.contentWindow?.postMessage(
            { ntnet: 'token', token },
            '*'
          );
          return;
        }
        wantsToken.current = true;
        askedAnswer.current = viewer.current?.answer || null;
        if (asked.renew) {
          act('token', { renew: 1 });
        } else {
          act('token');
        }
        return;
      }
      const request = navigationRequest(event.data);
      if (request) {
        onNavigate(request.siteId, request.slug);
      }
    };
    window.addEventListener('message', receive);
    rendererAllows().then((result) => {
      if (alive) {
        setAllowed(result);
      }
    });
    return () => {
      alive = false;
      window.removeEventListener('message', receive);
    };
  }, [onNavigate, act]);
  useEffect(() => {
    if (allowed !== true) {
      return;
    }
    let lastTick = Date.now();
    const timer = window.setInterval(() => {
      const now = Date.now();
      const lag = now - lastTick - LAG_TICK;
      lastTick = now;
      if (lag > LAG_LIMIT) {
        window.clearInterval(timer);
        setStopped(true);
      }
    }, LAG_TICK);
    return () => window.clearInterval(timer);
  }, [allowed]);
  const attach = useCallback(
    (node: HTMLIFrameElement | null) => {
      frame.current = node;
      if (!node || node.dataset.ntnetLoaded === url) {
        return;
      }
      node.dataset.ntnetLoaded = url;
      node.setAttribute('sandbox', FRAME_SANDBOX);
      node.setAttribute('csp', framePolicy(url));
      node.setAttribute('referrerpolicy', 'no-referrer');
      node.setAttribute('allow', '');
      node.setAttribute('src', `${url}?csp=${FRAME_POLICY_VERSION}`);
    },
    [url],
  );
  if (allowed === null) {
    return <Box style={{ padding: '24px', color: t.muted }}>Загрузка…</Box>;
  }
  if (allowed === false || stopped) {
    return (
      <Box>
        <Box style={{ padding: '12px 24px 0', color: t.muted }}>
          {stopped
            ? 'Страница подвесила клиент и была остановлена.'
            : 'Этот клиент не умеет показывать страницы целиком.'}
        </Box>
        {fallback}
      </Box>
    );
  }
  return (
    <Box style={{ position: 'relative', height: '100%' }}>
      <iframe
        title={title}
        ref={attach}
        onLoad={() => setLoaded(true)}
        style={{
          width: '100%',
          height: '100%',
          border: 'none',
          background: '#ffffff',
        }}
      />
      {!loaded && (
        <Box
          style={{
            position: 'absolute',
            top: '0',
            left: '0',
            right: '0',
            padding: '24px',
            color: '#5c6b77',
          }}
        >
          <Icon name="spinner" spin mr={1} />
          Загрузка страницы…
        </Box>
      )}
    </Box>
  );
};

export const NtosNTnet = () => {
  const { act, data } = useBackend<Data>();
  const { available, loading, site, page, view, search } = data;
  const t = palette(data);
  const frame = page && FRAME_ADDRESS.test(page.frame || '') ? page.frame : null;
  const title = (page && page.title) || (site && site.title) || 'NTnet';
  const navigate = useCallback(
    (siteId: string, slug: string) => act('open', { site_id: siteId, slug }),
    [act],
  );
  const notice: CSSProperties = {
    padding: '8px 24px',
    background: t.notice,
    fontSize: '0.85rem',
  };
  return (
    <NtosWindow width={900} height={700} resizable>
      <NtosWindow.Content>
        <Box
          style={{
            display: 'flex',
            flexDirection: 'column',
            height: '100%',
            background: t.canvas,
            color: t.text,
          }}
        >
          <TabStrip />
          <Toolbar />
          {!available && (
            <Box style={{ ...notice, color: t.noticeText }}>
              NTnet недоступен. Показано сохранённое.
            </Box>
          )}
          {search.error && (
            <Box style={{ ...notice, color: t.danger }}>{search.error}</Box>
          )}
          <Box style={{ flex: '1', minHeight: '0', overflow: 'auto' }}>
            {(loading && (
              <Box style={{ padding: '24px', color: t.muted }}>
                <Icon name="spinner" spin mr={1} />
                Загрузка…
              </Box>
            )) ||
              (site &&
                ((page &&
                  ((frame && (
                    <PageFrame
                      key={frame}
                      url={frame}
                      title={title}
                      t={t}
                      fallback={<PageText text={page.text} t={t} />}
                      onNavigate={navigate}
                    />
                  )) || <PageText text={page.text} t={t} />)) || (
                  <Box style={{ padding: '24px', color: t.muted }}>
                    Страница не открылась.{' '}
                    <Box
                      as="span"
                      onClick={() => act('refresh')}
                      style={{
                        color: t.accent,
                        cursor: 'pointer',
                        textDecoration: 'underline',
                      }}
                    >
                      Повторить
                    </Box>
                  </Box>
                ))) ||
              (search.query && <SearchPage />) ||
              (view === 'catalog' && <CatalogPage />) ||
              (view === 'create' && <CreatePage />) || <HomePage />}
          </Box>
        </Box>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
