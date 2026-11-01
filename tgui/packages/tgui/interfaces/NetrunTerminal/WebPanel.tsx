import { Box, Button, Icon, Section } from '../../components';
import { NetrunData, THEME, WebState } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

/** Мост «сайты NTnet в терминале»: каталог сайтов и чтение страниц (только чтение) */
export const WebPanel = (props: { web: WebState }) => {
  const { act } = useBackend<NetrunData>([]);
  const { web } = props;

  if (!web.available) {
    return (
      <Section title="NTnet — сайты">
        <Box color={THEME.muted} p={1}>
          Индекс сайтов недоступен. Нужна связь с NTnet; подождите обновления каталога.
        </Box>
      </Section>
    );
  }

  if (web.site) {
    return (
      <Section
        title={web.site.domain}
        scrollable
        style={{ minHeight: '100%', overflowY: 'auto' }}
        buttons={
          <Button icon="arrow-left" content="Назад" onClick={() => act('web_back')} />
        }
      >
        {!web.page ? (
          <PageList web={web} />
        ) : (
          <PageView web={web} />
        )}
      </Section>
    );
  }

  return (
    <Section title="NTnet — сайты" scrollable style={{ minHeight: '100%', overflowY: 'auto' }}>
      {web.sites.length === 0 && (
        <Box color={THEME.muted}>В индексе нет опубликованных сайтов.</Box>
      )}
      {web.sites.map((site) => (
        <Box
          key={site.id}
          p={1}
          mb={0.5}
          style={{ background: THEME.bg, border: `1px solid ${THEME.line}`, cursor: 'pointer' }}
          onClick={() => act('web_site', { id: site.id })}
        >
          <Icon name="globe" mr={1} color={THEME.accent} />
          <Box inline bold>
            {site.domain}
          </Box>
          <Box color={THEME.muted} fontSize="11px">
            {site.title}
          </Box>
        </Box>
      ))}
    </Section>
  );
};

const PageList = (props: { web: WebState }) => {
  const { act } = useBackend<NetrunData>([]);
  const { web } = props;
  return (
    <>
      <Box color={THEME.muted} mb={1}>
        {web.site!.title}
      </Box>
      {web.site!.pages.map((page) => (
        <Button
          key={page.slug}
          fluid
          icon="file-lines"
          content={page.title}
          mb={0.5}
          onClick={() => act('web_page', { slug: page.slug })}
        />
      ))}
    </>
  );
};

const PageView = (props: { web: WebState }) => {
  const { act } = useBackend<NetrunData>([]);
  const { page } = props.web;
  return (
    <Box>
      <Button icon="list" content="К страницам сайта" mb={1} onClick={() => act('web_back')} />
      <Box bold mb={1} color={THEME.accent}>
        {page!.title}
      </Box>
      {!!page!.loading && <Box color={THEME.muted}>Загрузка страницы…</Box>}
      {!!page!.failed && <Box color={THEME.bad}>Не удалось загрузить страницу.</Box>}
      {!!page!.text && (
        <Box
          style={{
            whiteSpace: 'pre-wrap',
            fontFamily: 'monospace',
            fontSize: '12px',
            lineHeight: 1.4,
          }}
        >
          {page!.text}
        </Box>
      )}
    </Box>
  );
};
