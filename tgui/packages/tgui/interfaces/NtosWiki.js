import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Icon, Input, NoticeBox } from '../components';
import { NtosWindow } from '../layouts';
import { WIKI_CATEGORIES } from './wikiData';

const JOB_FA_MAP = {
  captain: 'crown',
  headofpersonnel: 'users',
  headofsecurity: 'shield-halved',
  chiefengineer: 'screwdriver-wrench',
  chiefmedicalofficer: 'user-doctor',
  researchdirector: 'microscope',
  quartermaster: 'boxes-stacked',
  nanotrasenrepresentative: 'scale-balanced',
  blueshield: 'shield',
  bridgeofficer: 'tower-broadcast',
  warden: 'vault',
  detective: 'magnifying-glass',
  securityofficer: 'shield-halved',
  peacekeeper: 'handshake',
  brigphysician: 'briefcase-medical',
  internalaffairsagent: 'gavel',
  stationengineer: 'helmet-safety',
  atmospherictechnician: 'wind',
  scientist: 'flask-vial',
  roboticist: 'robot',
  cook: 'utensils',
  chef: 'utensils',
  bartender: 'martini-glass',
  botanist: 'leaf',
  janitor: 'broom',
  clown: 'face-laugh',
  mime: 'face-meh',
  chaplain: 'cross',
  curator: 'book',
  cargotechnician: 'dolly',
  shaftminer: 'person-digging',
  medicaldoctor: 'stethoscope',
  chemist: 'pills',
  psychologist: 'brain',
  paramedic: 'truck-medical',
  geneticist: 'dna',
  virologist: 'virus',
  assistant: 'user',
};

const getJobFa = (jobIcon) => JOB_FA_MAP[jobIcon] || 'user';

export const NtosWiki = (props) => {
  useBackend();

  const [activeCategoryId, setActiveCategoryId] = useState(WIKI_CATEGORIES[0].id);
  const [expandedSections, setExpandedSections] = useState({});
  const [selectedArticleId, setSelectedArticleId] = useState(null);
  const [searchText, setSearchText] = useState('');
  const [history, setHistory] = useState([]);
  const [sidebarWidth, setSidebarWidth] = useState(280);
  const [isResizing, setIsResizing] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const sidebarRef = useRef(null);
  const contentRef = useRef(null);
  const containerRef = useRef(null);
  const [isPda, setIsPda] = useState(false);

  const hasAutoCollapsed = useRef(false);
  useEffect(() => {
    let raf = null;
    const check = () => {
      const w = containerRef.current ? containerRef.current.clientWidth : window.innerWidth;
      const nextIsPda = w < 700 && w !== 0;
      setIsPda((prev) => (prev !== nextIsPda ? nextIsPda : prev));
      if (nextIsPda) {
        setSidebarWidth((prev) => (prev > 260 ? 220 : prev));
        if (!hasAutoCollapsed.current) {
          hasAutoCollapsed.current = true;
          setSidebarCollapsed(true);
        }
      } else {
        hasAutoCollapsed.current = false;
        setSidebarCollapsed(false);
      }
    };
    const debouncedCheck = () => {
      if (raf) cancelAnimationFrame(raf);
      raf = requestAnimationFrame(check);
    };
    check();
    let ro = null;
    if (window.ResizeObserver && containerRef.current) {
      ro = new ResizeObserver(debouncedCheck);
      ro.observe(containerRef.current);
    }
    window.addEventListener('resize', debouncedCheck);
    const t = setTimeout(check, 150);
    return () => {
      window.removeEventListener('resize', debouncedCheck);
      if (ro) ro.disconnect();
      if (raf) cancelAnimationFrame(raf);
      clearTimeout(t);
    };
  }, []);

  const activeCategory = useMemo(
    () => WIKI_CATEGORIES.find((c) => c.id === activeCategoryId) || WIKI_CATEGORIES[0],
    [activeCategoryId],
  );

  const allArticles = useMemo(() => {
    const out = [];
    (WIKI_CATEGORIES || []).forEach((cat) => {
      if (!cat || !cat.sections) return;
      (cat.sections || []).forEach((sec) => {
        if (!sec || !sec.articles) return;
        (sec.articles || []).forEach((art) => {
          if (!art) return;
          out.push({ ...art, categoryId: cat.id, categoryTitle: cat.title, sectionId: sec.id, sectionTitle: sec.title, sectionIcon: sec.icon, catColor: cat.color, catIcon: cat.icon });
        });
      });
    });
    return out;
  }, []);

  const filteredArticles = useMemo(() => {
    if (!searchText) return [];
    const q = searchText.toLowerCase();
    return allArticles.filter(
      (a) => a.title.toLowerCase().includes(q) || a.id.toLowerCase().includes(q) || (a.content && a.content.toLowerCase().includes(q)),
    ).slice(0, 20);
  }, [searchText, allArticles]);

  const selectedArticle = useMemo(() => {
    if (!selectedArticleId) return null;
    return allArticles.find((a) => a.id === selectedArticleId) || null;
  }, [selectedArticleId, allArticles]);

  const navigateToArticle = (articleId) => {
    const art = allArticles.find((a) => a.id === articleId);
    if (!art) return;
    if (selectedArticleId) setHistory((h) => [...h, selectedArticleId]);
    setSelectedArticleId(articleId);
    setActiveCategoryId(art.categoryId);
    setExpandedSections((prev) => ({ ...prev, [art.sectionId]: true }));
    if (contentRef.current) contentRef.current.scrollTop = 0;
    if (isPda) setSidebarCollapsed(true);
  };

  const goBack = () => {
    if (history.length === 0) {
      setSelectedArticleId(null);
      return;
    }
    const prev = history[history.length - 1];
    setHistory((h) => h.slice(0, -1));
    setSelectedArticleId(prev);
    const art = allArticles.find((a) => a.id === prev);
    if (art) setActiveCategoryId(art.categoryId);
    if (contentRef.current) contentRef.current.scrollTop = 0;
  };

  const toggleSection = (sectionId) => {
    setExpandedSections((prev) => ({ ...prev, [sectionId]: !prev[sectionId] }));
  };

  const startResizing = useCallback((e) => {
    setIsResizing(true);
    e.preventDefault();
  }, []);

  const stopResizing = useCallback(() => {
    setIsResizing(false);
  }, []);

  const resize = useCallback(
    (e) => {
      if (isResizing && containerRef.current) {
        const rect = containerRef.current.getBoundingClientRect();
        const newWidth = e.clientX - rect.left;
        if (newWidth >= 200 && newWidth <= 420) {
          setSidebarWidth(newWidth);
        }
      }
    },
    [isResizing],
  );

  const resizeTouch = useCallback(
    (e) => {
      if (isResizing && containerRef.current && e.touches[0]) {
        const rect = containerRef.current.getBoundingClientRect();
        const newWidth = e.touches[0].clientX - rect.left;
        if (newWidth >= 200 && newWidth <= 420) setSidebarWidth(newWidth);
      }
    },
    [isResizing],
  );

  useEffect(() => {
    if (isResizing) {
      window.addEventListener('mousemove', resize);
      window.addEventListener('mouseup', stopResizing);
      window.addEventListener('touchmove', resizeTouch);
      window.addEventListener('touchend', stopResizing);
      return () => {
        window.removeEventListener('mousemove', resize);
        window.removeEventListener('mouseup', stopResizing);
        window.removeEventListener('touchmove', resizeTouch);
        window.removeEventListener('touchend', stopResizing);
      };
    }
  }, [isResizing, resize, stopResizing, resizeTouch]);

  const handleContentClick = (e) => {
    const target = e.target.closest('a.wiki-link');
    if (target && target.dataset.article) {
      e.preventDefault();
      navigateToArticle(target.dataset.article);
    }
  };

  const defaultArticle = useMemo(() => {
    if (selectedArticle) return selectedArticle;
    const cat = activeCategory;
    if (cat.sections[0]?.articles[0]) {
      const art = cat.sections[0].articles[0];
      return { ...art, categoryId: cat.id, categoryTitle: cat.title, sectionTitle: cat.sections[0].title, catColor: cat.color, catIcon: cat.icon };
    }
    return null;
  }, [selectedArticle, activeCategory]);

  const displayedArticle = selectedArticle || defaultArticle;

  useEffect(() => {
    if (contentRef.current) contentRef.current.scrollTop = 0;
  }, [displayedArticle?.id]);

  const wikiStyles = `
    .wiki-table { width: 100%; border-collapse: collapse; margin: 8px 0; font-size: 12px; display: table; box-sizing: border-box; }
    .wiki-table th { background: rgba(255,255,255,0.08); padding: 6px 8px; text-align: left; border: 1px solid rgba(255,255,255,0.12); white-space: nowrap; }
    .wiki-table td { padding: 5px 8px; border: 1px solid rgba(255,255,255,0.08); word-break: break-word; }
    .wiki-table.compact td, .wiki-table.compact th { padding: 4px 6px; font-size: 11px; }
    .wiki-table.small { font-size: 11px; }
    .wiki-table.severity .severity-1 { background: rgba(39,174,96,0.08); }
    .wiki-table.severity .severity-2 { background: rgba(241,196,15,0.08); }
    .wiki-table.severity .severity-3 { background: rgba(230,126,34,0.12); }
    .wiki-table.severity .severity-4 { background: rgba(231,76,60,0.12); }
    .wiki-table.severity .severity-5 { background: rgba(142,68,173,0.15); }
    .wiki-notice { padding: 8px 12px; border-radius: 6px; margin: 10px 0; font-size: 12px; border-left: 4px solid; }
    .wiki-notice.info { background: rgba(52,152,219,0.1); border-color: #3498db; }
    .wiki-notice.warning { background: rgba(243,156,18,0.1); border-color: #f39c12; }
    .wiki-notice.danger { background: rgba(231,76,60,0.1); border-color: #e74c3c; }
    .wiki-notice.success { background: rgba(39,174,96,0.1); border-color: #27ae60; }
    .wiki-code { background: rgba(255,255,255,0.06); padding: 6px 10px; border-radius: 4px; font-family: monospace; font-size: 12px; display: block; margin: 8px 0; overflow-x: auto; }
    .badge { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 10px; font-weight: bold; margin-left: 8px; vertical-align: middle; }
    .badge.z1 { background: #27ae60; color: white; }
    .badge.z2 { background: #f1c40f; color: #1a1a1a; }
    .badge.z3 { background: #e67e22; color: white; }
    .badge.z4 { background: #e74c3c; color: white; }
    .badge.z5 { background: #8e44ad; color: white; }
    .hint { font-size: 11px; color: rgba(255,255,255,0.45); font-style: italic; margin-top: 4px; }
    .wiki-content h2 { font-size: 18px; margin: 0 0 10px 0; padding-bottom: 6px; border-bottom: 1px solid rgba(255,255,255,0.08); }
    .wiki-content h3 { font-size: 14px; margin: 14px 0 6px 0; color: #3498db; }
    .wiki-content h4 { font-size: 12px; margin: 10px 0 4px 0; color: rgba(255,255,255,0.85); text-transform: uppercase; letter-spacing: 0.5px; }
    .wiki-content p { margin: 6px 0; line-height: 1.5; font-size: 12.5px; }
    .wiki-content ul, .wiki-content ol { margin: 6px 0 6px 18px; font-size: 12.5px; line-height: 1.5; }
    .wiki-content a.wiki-link { color: #3498db; text-decoration: underline; cursor: pointer; }
    .wiki-content a.wiki-link:hover { color: #5dade2; }
    .wiki-content { overflow-wrap: anywhere; word-break: break-word; isolation: isolate; }
    .wiki-content table { max-width: 100%; box-sizing: border-box; }
    .wiki-table-wrapper { overflow-x: auto; overflow-y: hidden; -webkit-overflow-scrolling: touch; max-width: 100%; border-radius: 4px; display: block; }
    .wiki-table-wrapper .wiki-table { min-width: 480px; }
    @media (max-width: 700px) { .wiki-table-wrapper .wiki-table { min-width: 520px; } }
    .wiki-sidebar-item { padding: 4px 8px; border-radius: 4px; cursor: pointer; display: flex; align-items: center; gap: 8px; font-size: 12px; }
    .wiki-sidebar-item:hover { background: rgba(255,255,255,0.06); }
    .wiki-sidebar-item.selected { background: rgba(52,152,219,0.15); color: #5dade2; border-left: 3px solid #3498db; }
    .wiki-sidebar-section { margin-bottom: 2px; }
    .wiki-sidebar-header { padding: 6px 8px; font-weight: bold; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; color: rgba(255,255,255,0.6); display: flex; align-items: center; justify-content: space-between; cursor: pointer; border-radius: 4px; }
    .wiki-sidebar-header:hover { background: rgba(255,255,255,0.04); }
    .wiki-category-pill { padding: 4px 10px; border-radius: 12px; font-size: 11px; font-weight: bold; cursor: pointer; border: 1px solid; display: inline-flex; align-items: center; gap: 6px; white-space: nowrap; flex-shrink: 0; }
    .wiki-category-pill.active { color: white; }
    .wiki-search-result { padding: 6px 10px; border-radius: 4px; cursor: pointer; border: 1px solid transparent; }
    .wiki-search-result:hover { background: rgba(255,255,255,0.06); border-color: rgba(255,255,255,0.08); }
    .wiki-resizer { width: 6px; cursor: col-resize; background: rgba(255,255,255,0.04); border-left: 1px solid rgba(255,255,255,0.06); border-right: 1px solid rgba(255,255,255,0.06); display: flex; align-items: center; justify-content: center; flex-shrink: 0; user-select: none; touch-action: none; }
    .wiki-resizer:hover, .wiki-resizer.dragging { background: rgba(52,152,219,0.15); border-color: rgba(52,152,219,0.3); }
    .wiki-resizer::after { content: ''; width: 2px; height: 24px; background: rgba(255,255,255,0.15); border-radius: 1px; }
    .wiki-nrp-block { margin: 12px 0; border-radius: 6px; overflow: hidden; border: 1px solid rgba(255,255,255,0.08); }
    .wiki-nrp-block-header { padding: 6px 10px; font-weight: bold; font-size: 12px; display: flex; align-items: center; gap: 8px; }
    .wiki-nrp-block-header.oblig { background: rgba(231,76,60,0.12); border-bottom: 1px solid rgba(231,76,60,0.2); color: #e74c3c; }
    .wiki-nrp-block-header.right { background: rgba(46,204,113,0.10); border-bottom: 1px solid rgba(46,204,113,0.2); color: #27ae60; }
    .wiki-nrp-block-header.forbid { background: rgba(52,73,94,0.4); border-bottom: 1px solid rgba(255,255,255,0.08); color: #95a5a6; }
    .wiki-nrp-block ul { margin: 0; padding: 8px 12px 8px 28px; background: rgba(255,255,255,0.02); }
    .wiki-nrp-block li { margin: 4px 0; }
    .wiki-sidebar { scrollbar-width: thin; scrollbar-color: rgba(255,255,255,0.14) transparent; overscroll-behavior: contain; }
    .wiki-sidebar::-webkit-scrollbar { width: 6px; }
    .wiki-sidebar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.12); border-radius: 3px; }
    .wiki-sidebar::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.20); }
    .wiki-sidebar::-webkit-scrollbar-track { background: transparent; }
    .wiki-content-scroll { scrollbar-width: thin; scrollbar-color: rgba(255,255,255,0.12) transparent; overscroll-behavior: contain; -webkit-overflow-scrolling: touch; }
    .wiki-content-scroll::-webkit-scrollbar { width: 6px; }
    .wiki-content-scroll::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.10); border-radius: 3px; }
    .wiki-category-bar { scrollbar-width: thin; scrollbar-color: rgba(255,255,255,0.10) transparent; -webkit-overflow-scrolling: touch; overscroll-behavior-x: contain; }
    .wiki-category-bar::-webkit-scrollbar { height: 4px; }
    .wiki-category-bar::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.14); border-radius: 2px; }
    @media (max-width: 700px) {
      .wiki-content h2 { font-size: 16px; }
      .wiki-content p, .wiki-content ul, .wiki-content ol { font-size: 12px; }
      .wiki-table { font-size: 11px; }
    }
  `;

  return (
    <NtosWindow width={920} height={640} theme="ntos">
      <style>{wikiStyles}</style>
      <NtosWindow.Content>
        <Box
          ref={containerRef}
          style={{
            display: 'flex',
            flexDirection: 'column',
            height: '100%',
            minHeight: 0,
            overflow: 'hidden',
          }}
        >
          <Box
            style={{
              padding: '8px 10px',
              background: 'rgba(255,255,255,0.03)',
              borderBottom: '1px solid rgba(255,255,255,0.06)',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              flexShrink: 0,
              flexWrap: 'wrap',
            }}
          >
            <Box style={{ display: 'flex', alignItems: 'center', gap: '8px', flexShrink: 0 }}>
              {isPda && (
                <Button
                  icon={sidebarCollapsed ? 'bars' : 'times'}
                  color="transparent"
                  tooltip={sidebarCollapsed ? 'Показать оглавление' : 'Скрыть оглавление'}
                  onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
                />
              )}
              <Icon name="book-open" size={1.2} color="#3498db" />
              <Box inline bold style={{ fontSize: '13px', whiteSpace: 'nowrap' }}>
                Википедия Nanotrasen
              </Box>
              <Box inline style={{ fontSize: '10px', color: 'rgba(255,255,255,0.45)', display: isPda ? 'none' : 'inline' }}>
                КЗ • НРП • Гайды
              </Box>
            </Box>
            <Box
              style={{
                marginLeft: isPda ? '0' : 'auto',
                display: 'flex',
                gap: '6px',
                alignItems: 'center',
                flex: isPda ? '1 1 100%' : '0 1 auto',
                width: isPda ? '100%' : 'auto',
                marginTop: isPda ? '6px' : '0',
              }}
            >
              <Input
                placeholder="Поиск... (102, саботаж, СМО)"
                fluid={isPda}
                width={isPda ? undefined : '240px'}
                value={searchText}
                onInput={(e, v) => setSearchText(v)}
                style={isPda ? { flex: 1 } : {}}
              />
              {!!searchText && (
                <Button icon="times" color="transparent" onClick={() => setSearchText('')} tooltip="Очистить" />
              )}
              {!!(history.length || selectedArticleId) && (
                <Button icon="arrow-left" onClick={goBack} tooltip="Назад">
                  {isPda ? '' : 'Назад'}
                </Button>
              )}
            </Box>
          </Box>

          <Box
            className="wiki-category-bar"
            style={{
              padding: '7px 10px',
              display: 'flex',
              gap: '6px',
              flexWrap: 'nowrap',
              overflowX: 'auto',
              overflowY: 'hidden',
              borderBottom: '1px solid rgba(255,255,255,0.04)',
              flexShrink: 0,
              alignItems: 'center',
            }}
          >
            {(WIKI_CATEGORIES || []).filter(Boolean).map((cat) => (
              <Box
                key={cat.id}
                className={`wiki-category-pill ${activeCategoryId === cat.id ? 'active' : ''}`}
                style={{
                  background: activeCategoryId === cat.id ? cat.color : 'transparent',
                  borderColor: cat.color,
                  color: activeCategoryId === cat.id ? 'white' : cat.color,
                }}
                onClick={() => {
                  setActiveCategoryId(cat.id);
                  setSelectedArticleId(null);
                  setHistory([]);
                  if (contentRef.current) contentRef.current.scrollTop = 0;
                  if (isPda) setSidebarCollapsed(true);
                }}
              >
                <Icon name={cat.icon} />
                {cat.title}
                <Box inline style={{ opacity: 0.7, fontSize: '10px' }}>
                  ({(cat.sections || []).filter(Boolean).reduce((a, s) => a + (s.articles || []).filter(Boolean).length, 0)})
                </Box>
              </Box>
            ))}
          </Box>

          <Box
            style={{
              display: 'flex',
              flex: 1,
              minHeight: 0,
              overflow: 'hidden',
              position: 'relative',
            }}
          >
            {(!isPda || !sidebarCollapsed) && (
              <Box
                ref={sidebarRef}
                className="wiki-sidebar"
                style={{
                  width: isPda ? '100%' : sidebarWidth + 'px',
                  minWidth: isPda ? '0' : '200px',
                  maxWidth: isPda ? '100%' : '420px',
                  background: isPda ? '#1e1e24' : 'rgba(0,0,0,0.15)',
                  overflowY: 'auto',
                  overflowX: 'hidden',
                  flexShrink: 0,
                  borderRight: isPda ? '1px solid rgba(255,255,255,0.08)' : '1px solid rgba(255,255,255,0.06)',
                  position: isPda ? 'absolute' : 'relative',
                  left: 0,
                  top: 0,
                  bottom: 0,
                  zIndex: isPda ? 5 : 1,
                  display: 'flex',
                  flexDirection: 'column',
                }}
              >
                {searchText ? (
                  <Box style={{ padding: '8px' }}>
                    <Box style={{ fontSize: '11px', color: 'rgba(255,255,255,0.5)', marginBottom: '6px', padding: '0 4px' }}>
                      Результаты: {filteredArticles.length}
                    </Box>
                    {filteredArticles.length === 0 && (
                      <NoticeBox info>Ничего не найдено по запросу &quot;{searchText}&quot;</NoticeBox>
                    )}
                    {filteredArticles.map((art) => (
                      <Box
                        key={art.id}
                        className={`wiki-search-result ${selectedArticleId === art.id ? 'selected' : ''}`}
                        style={{
                          background: selectedArticleId === art.id ? 'rgba(52,152,219,0.12)' : 'transparent',
                          borderColor: selectedArticleId === art.id ? 'rgba(52,152,219,0.3)' : 'transparent',
                          marginBottom: '4px',
                        }}
                        onClick={() => navigateToArticle(art.id)}
                      >
                        <Box style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                          <Icon name={art.icon || art.sectionIcon || art.catIcon} color={art.catColor} />
                          <Box inline bold style={{ fontSize: '12px' }}>
                            {art.title}
                          </Box>
                          {art.jobIcon && (
                            <Icon
                              name={getJobFa(art.jobIcon)}
                              size={0.9}
                              style={{ marginLeft: 'auto', opacity: 0.6 }}
                              title={art.jobIcon}
                            />
                          )}
                        </Box>
                        <Box style={{ fontSize: '10px', color: 'rgba(255,255,255,0.45)', marginTop: '2px' }}>
                          {art.categoryTitle} › {art.sectionTitle}
                        </Box>
                      </Box>
                    ))}
                  </Box>
                ) : (
                  <Box style={{ padding: '6px 0', flex: 1 }}>
                    <Box style={{ padding: '6px 12px', fontSize: '11px', color: 'rgba(255,255,255,0.4)' }}>{activeCategory.desc}</Box>
                    {(activeCategory.sections || []).filter(Boolean).map((section) => {
                      const isExpanded = expandedSections[section.id] !== false;
                      return (
                        <Box key={section.id} className="wiki-sidebar-section">
                          <Box className="wiki-sidebar-header" onClick={() => toggleSection(section.id)}>
                            <Box style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                              <Icon name={section.icon} color={activeCategory.color} />
                              {section.title}
                              {section.jobIcon && (
                                <Icon name={getJobFa(section.jobIcon)} size={0.85} style={{ opacity: 0.5 }} />
                              )}
                              <Box inline style={{ fontSize: '10px', opacity: 0.5 }}>
                                {(section.articles || []).filter(Boolean).length}
                              </Box>
                            </Box>
                            <Icon name={isExpanded ? 'chevron-down' : 'chevron-right'} size={0.8} style={{ opacity: 0.4 }} />
                          </Box>
                          {isExpanded && (
                            <Box>
                              {(section.articles || []).filter(Boolean).map((art) => (
                                <Box
                                  key={art.id}
                                  className={`wiki-sidebar-item ${displayedArticle?.id === art.id ? 'selected' : ''}`}
                                  onClick={() => navigateToArticle(art.id)}
                                  style={{ margin: '1px 6px', paddingLeft: displayedArticle?.id === art.id ? '5px' : '8px' }}
                                >
                                  <Icon
                                    name={art.icon || section.icon}
                                    size={0.9}
                                    style={{ opacity: displayedArticle?.id === art.id ? 1 : 0.6, color: displayedArticle?.id === art.id ? '#5dade2' : undefined }}
                                  />
                                  <Box inline style={{ flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                    {art.title}
                                  </Box>
                                  {art.jobIcon && (
                                    <Box
                                      style={{
                                        width: '16px',
                                        height: '16px',
                                        borderRadius: '3px',
                                        background: 'rgba(255,255,255,0.06)',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        flexShrink: 0,
                                      }}
                                      title={art.jobIcon}
                                    >
                                      <Icon name={getJobFa(art.jobIcon)} size={0.7} style={{ opacity: 0.8 }} />
                                    </Box>
                                  )}
                                  {art.color && (
                                    <Box
                                      style={{
                                        width: '6px',
                                        height: '6px',
                                        borderRadius: '50%',
                                        background: art.color,
                                        flexShrink: 0,
                                      }}
                                    />
                                  )}
                                </Box>
                              ))}
                            </Box>
                          )}
                        </Box>
                      );
                    })}
                  </Box>
                )}
                {isPda && (
                  <Box style={{ padding: '8px', borderTop: '1px solid rgba(255,255,255,0.06)', flexShrink: 0 }}>
                    <Button fluid icon="times" content="Закрыть оглавление" onClick={() => setSidebarCollapsed(true)} />
                  </Box>
                )}
              </Box>
            )}

            {!isPda && (
              <Box
                className={`wiki-resizer ${isResizing ? 'dragging' : ''}`}
                onMouseDown={startResizing}
                onTouchStart={startResizing}
                title="Перетащите для изменения ширины (200–420px)"
              />
            )}

            <Box
              ref={contentRef}
              className="wiki-content-scroll"
              style={{
                flex: 1,
                minWidth: 0,
                minHeight: 0,
                overflowY: 'auto',
                overflowX: 'hidden',
                background: 'rgba(255,255,255,0.01)',
                position: 'relative',
              }}
            >
              {displayedArticle ? (
                <Box style={{ padding: isPda ? '12px 14px' : '16px 20px', maxWidth: '100%' }}>
                  <Box
                    style={{
                      fontSize: '11px',
                      color: 'rgba(255,255,255,0.4)',
                      marginBottom: '10px',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '6px',
                      flexWrap: 'wrap',
                    }}
                  >
                    <Icon name={activeCategory.icon} color={activeCategory.color} size={0.9} />
                    {activeCategory.title}
                    <Icon name="chevron-right" size={0.7} style={{ opacity: 0.3 }} />
                    {displayedArticle.sectionTitle || displayedArticle.sectionId}
                    <Icon name="chevron-right" size={0.7} style={{ opacity: 0.3 }} />
                    <Box inline style={{ color: 'rgba(255,255,255,0.7)' }}>
                      {displayedArticle.title}
                    </Box>
                    {displayedArticle.jobIcon && (
                      <Box
                        inline
                        style={{
                          marginLeft: '6px',
                          background: 'rgba(255,255,255,0.06)',
                          padding: '2px 6px',
                          borderRadius: '10px',
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '4px',
                        }}
                      >
                        <Icon name={getJobFa(displayedArticle.jobIcon)} size={0.8} />
                        <span style={{ fontSize: '10px' }}>{displayedArticle.jobIcon}</span>
                      </Box>
                    )}
                  </Box>

                  {displayedArticle.raw ? (
                    <Box
                      className="wiki-content"
                      style={{
                        background: 'rgba(255,255,255,0.02)',
                        border: '1px solid rgba(255,255,255,0.06)',
                        borderRadius: '8px',
                        padding: '16px',
                        whiteSpace: 'pre-wrap',
                        wordBreak: 'break-word',
                        overflowWrap: 'anywhere',
                        fontSize: '12.5px',
                        lineHeight: '1.6',
                        overflowX: 'auto',
                      }}
                    >
                      {displayedArticle.content}
                    </Box>
                  ) : (
                    <Box
                      className="wiki-content"
                      style={{
                        background: 'rgba(255,255,255,0.02)',
                        border: '1px solid rgba(255,255,255,0.06)',
                        borderRadius: '8px',
                        padding: '14px',
                        overflow: 'hidden',
                      }}
                      onClick={handleContentClick}
                    >
                      <Box
                        style={{ maxWidth: '100%', overflowX: 'hidden' }}
                        dangerouslySetInnerHTML={{
                          __html: displayedArticle.content
                            .replace(/<table/g, '<div class="wiki-table-wrapper"><table')
                            .replace(/<\/table>/g, '</table></div>'),
                        }}
                      />
                    </Box>
                  )}

                  <Box style={{ marginTop: '12px', display: 'flex', gap: '6px', flexWrap: 'wrap', alignItems: 'center' }}>
                    <Box inline style={{ fontSize: '11px', color: 'rgba(255,255,255,0.4)', marginRight: '6px', lineHeight: '22px' }}>
                      Связанные:
                    </Box>
                    {allArticles
                      .filter((a) => a.categoryId === displayedArticle.categoryId && a.id !== displayedArticle.id)
                      .slice(0, 4)
                      .map((rel) => (
                        <Button key={rel.id} compact color="transparent" icon={rel.icon} onClick={() => navigateToArticle(rel.id)}>
                          {rel.title.replace(/^\d+\s*—\s*/, '').slice(0, 18)}
                        </Button>
                      ))}
                  </Box>

                  <Box
                    style={{
                      marginTop: '16px',
                      padding: '10px',
                      background: 'rgba(52,152,219,0.06)',
                      borderRadius: '6px',
                      border: '1px solid rgba(52,152,219,0.12)',
                    }}
                  >
                    <Box style={{ fontSize: '11px', color: 'rgba(255,255,255,0.6)', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Icon name="info-circle" color="#3498db" />
                      Информация из корпоративной базы данных Nanotrasen. Последнее обновление: 26.12.2565 (НРП) / 30.05.2565 (КЗ). При расхождении с бумажными копиями — приоритет у электронной версии.
                    </Box>
                  </Box>
                </Box>
              ) : (
                <Box style={{ padding: '40px', textAlign: 'center', color: 'rgba(255,255,255,0.4)' }}>
                  <Icon name="book-open" size={3} style={{ opacity: 0.15, marginBottom: '12px' }} />
                  <Box>Выберите статью в боковой панели</Box>
                  {isPda && (
                    <Button mt={2} icon="bars" content="Открыть оглавление" onClick={() => setSidebarCollapsed(false)} />
                  )}
                </Box>
              )}
            </Box>

            {isPda && !sidebarCollapsed && (
              <Box
                style={{
                  position: 'absolute',
                  inset: 0,
                  background: 'rgba(0,0,0,0.55)',
                  zIndex: 4,
                }}
                onClick={() => setSidebarCollapsed(true)}
              />
            )}
          </Box>

          <Box
            style={{
              padding: '6px 10px',
              borderTop: '1px solid rgba(255,255,255,0.06)',
              display: 'flex',
              gap: '12px',
              fontSize: '10px',
              color: 'rgba(255,255,255,0.35)',
              alignItems: 'center',
              flexShrink: 0,
              flexWrap: 'wrap',
            }}
          >
            <Box inline>
              <Icon name="search" /> Поиск: номер статьи (напр. 102) или слово
            </Box>
            <Box inline style={{ display: isPda ? 'none' : 'flex', gap: '8px', alignItems: 'center' }}>
              <Icon name="mouse-pointer" /> Клик по ссылке в тексте — переход
            </Box>
            {!isPda && (
              <Box inline style={{ marginLeft: 'auto', opacity: 0.6 }}>
                Ширина панели: {sidebarWidth}px — тяните за разделитель
              </Box>
            )}
            {isPda && (
              <Box inline style={{ marginLeft: 'auto' }}>
                <Icon name="arrows-up-down" /> Скролл — свайпом
              </Box>
            )}
          </Box>
        </Box>
      </NtosWindow.Content>
    </NtosWindow>
  );
};