import { memo, useEffect, useRef, useState } from 'react';

import { Box, Button, Icon } from '../../components';
import { Meter } from './CombatPanel';
import { EntityAvatar, PERSONA_ACCENTS, PERSONA_AVATAR_OPTIONS } from './EntityAvatar';
import { BotAvatar, botKindLabel } from './EntityContacts';
import { isTransferableFile } from './filePermissions';
import { NETRUN_THEMES } from './themes';
import { AgentBehavior, AgentState, CombatProgram, NetFile, NetrunData, SelectedNode, THEME } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

type Order = (order: string, options?: object) => void;
const DETAIL_ORDERS = new Set(['command', 'persona', 'upload', 'download', 'behavior']);
const ACCENT_NAMES: Record<string, string> = { cyan: 'Лёд', mint: 'Мята', amber: 'Янтарь', rose: 'Роза', violet: 'Ирис', silver: 'Серебро' };
const PROGRAM_ROLES: Record<string, string> = { attack: 'атака', stun: 'подавление', shield: 'щит', repair: 'ремонт', purge: 'очистка' };
const programReadiness = (program: CombatProgram) => program.unavailable_reason
  || ((program.ready_turns ?? 0) > 0 ? `Восстановление через ${program.ready_turns} ход.`
    : program.ready_in > 0 ? `Восстановление ${Math.ceil(program.ready_in)} с` : 'Готова');

const AgentPersona = ({ agent, order }: { agent: AgentState; order: Order }) => {
  const [name, setName] = useState(agent.name);
  const [avatar, setAvatar] = useState(agent.persona?.avatar || 'cipher');
  const [accent, setAccent] = useState(agent.persona?.accent || 'cyan');
  const [tagline, setTagline] = useState(agent.persona?.tagline || '');
  const [theme, setTheme] = useState(agent.persona?.theme || 'ion');
  return (<form className="netrun-agent-form" aria-label={`Личность агента ${agent.name}`}
    onSubmit={(event) => { event.preventDefault(); if (name.trim()) { order('persona', { name: name.trim(), avatar, accent, tagline, theme }); } }}>
    <label className="netrun-field">Имя<input value={name} maxLength={42} onChange={(event) => setName(event.target.value)} /></label>
    <div className="netrun-agent-form__row">
      <EntityAvatar avatar={avatar} accent={accent} size={38} />
      <label className="netrun-field">Аватар<select value={avatar} onChange={(event) => setAvatar(event.target.value)}>
        {(agent.persona?.options?.avatars || PERSONA_AVATAR_OPTIONS).map((option) => <option key={option.id} value={option.id}>{option.name}</option>)}
                                            </select>
      </label>
      <label className="netrun-field">Цвет<select value={accent} onChange={(event) => setAccent(event.target.value)}>
        {Object.keys(PERSONA_ACCENTS).map((id) => <option key={id} value={id}>{ACCENT_NAMES[id] || id}</option>)}
                                          </select>
      </label>
    </div>
    <label className="netrun-field">Подпись<input value={tagline} maxLength={80} onChange={(event) => setTagline(event.target.value)} /></label>
    <label className="netrun-field">Оформление<select value={theme} onChange={(event) => setTheme(event.target.value)}>
      {Object.entries(NETRUN_THEMES).map(([id, choice]) => <option key={id} value={id}>{choice.name}</option>)}
                                              </select>
    </label>
    <Button compact icon="check" content="Сохранить личность" disabled={!name.trim()}
      onClick={() => name.trim() && order('persona', { name: name.trim(), avatar, accent, tagline, theme })} />
          </form>);
};

const AgentBehaviorSettings = ({ agent, behavior, order }: { agent: AgentState; behavior: AgentBehavior; order: Order }) => {
  const [strategy, setStrategy] = useState(behavior.strategy);
  const [aggression, setAggression] = useState(behavior.aggression);
  const [caution, setCaution] = useState(behavior.caution);
  const [cooperation, setCooperation] = useState(behavior.cooperation);
  // Ordinary status patches preserve an unsent draft. Actual policy changes
  // reconcile the controls without recreating the card or its open details.
  useEffect(() => {
    setStrategy(behavior.strategy);
    setAggression(behavior.aggression);
    setCaution(behavior.caution);
    setCooperation(behavior.cooperation);
  }, [behavior.strategy, behavior.aggression, behavior.caution, behavior.cooperation]);
  const save = () => order('behavior', { strategy, aggression, caution, cooperation });
  return (
    <details className="netrun-agent-details"><summary><Icon name="sliders" /> Поведение</summary>
      <form className="netrun-agent-form" aria-label={`Поведение агента ${agent.name}`}
        onSubmit={(event) => { event.preventDefault(); save(); }}>
        <label className="netrun-field">Стратегия<select aria-label={`Стратегия агента ${agent.name}`} value={strategy}
          onChange={(event) => setStrategy(event.target.value as AgentBehavior['strategy'])}>
          <option value="profile">По профилю</option>
          <option value="patrol">Патруль</option>
          <option value="scavenge">Сбор трофеев</option>
          <option value="guard">Охрана узла</option>
                                                 </select>
        </label>
        <label className="netrun-field">Агрессия · {aggression}%<input type="range" min={0} max={100} step={1} value={aggression}
          aria-label={`Агрессия агента ${agent.name}`} onChange={(event) => setAggression(Number(event.target.value))} />
        </label>
        <label className="netrun-field">Осторожность · {caution}%<input type="range" min={0} max={100} step={1} value={caution}
          aria-label={`Осторожность агента ${agent.name}`} onChange={(event) => setCaution(Number(event.target.value))} />
        </label>
        <label><input type="checkbox" checked={cooperation} onChange={(event) => setCooperation(event.target.checked)} /> Помогать союзникам</label>
        <Button compact icon="check" content="Применить поведение" onClick={save} />
      </form>
    </details>
  );
};

const AgentCard = (props: { agent: AgentState; selected: SelectedNode | null; files: NetFile[]; act: (action: string, payload?: object) => void }) => {
  const { agent, selected, act, files } = props;
  const [editing, setEditing] = useState(false);
  const [command, setCommand] = useState('');
  const [upload, setUpload] = useState('');
  const hasOrder = (id: string) => agent.orders.some((entry) => entry.id === id && entry.enabled !== false);
  const order: Order = (id, options = {}) => act('agent_order', { ref: agent.ref, order: id, ...options });
  const commands = selected?.commands || [];
  const chosen = commands.find((entry) => entry.id === command);
  const selectedFile = files.find((file) => file.uid === upload);
  return (
    <Box p={1} mb={0.5} data-net-agent={agent.bot_kind}
      style={{ background: THEME.bg, border: `1px solid ${THEME.line}`, borderRadius: '6px' }}>
      <Box bold>
        {agent.persona ? <EntityAvatar avatar={agent.persona.avatar} accent={agent.persona.accent} size={28} />
          : <BotAvatar kind={agent.bot_kind} faction="owner" size={24} />}
        {agent.name}
        <Box inline ml={1} fontSize="11px" color={THEME.muted}>{botKindLabel(agent.bot_kind)}</Box>
      </Box>
      {!!agent.persona?.tagline && <Box className="netrun-contact-tagline">{agent.persona.tagline}</Box>}
      <Box fontSize="11px" color={THEME.muted}>
        {agent.node ? `${agent.node_name || ''} ${agent.node}` : 'вне сети'} · {agent.state}
      </Box>
      {!!agent.goal && <Box fontSize="11px">Задача: {agent.goal}</Box>}
      <Meter value={agent.integrity} max={agent.max_integrity} label={`Целостность ${agent.name}`} height={4}
        style={{ margin: '4px 0' }} />
      <Box fontSize="10px" color={THEME.muted}>
        Целостность {agent.integrity}/{agent.max_integrity} · память {agent.storage.used}/{agent.storage.capacity}
      </Box>
      {agent.storage.capacity > 0 && agent.storage.used >= agent.storage.capacity && (
        <Box color={THEME.warn} fontSize="11px">Память заполнена: заберите файлы или отзовите агента с добычей.</Box>
      )}
      <Box mt={0.5} style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
        {agent.orders.filter((entry) => !DETAIL_ORDERS.has(entry.id)).map((entry) => {
          const blocked = entry.enabled === false || (entry.needs_node && !selected);
          return (
            <Button key={entry.id} compact content={entry.name} disabled={blocked}
              color={entry.id === 'terminate' ? 'bad' : undefined}
              tooltip={entry.reason || (blocked ? 'Сначала выберите узел на карте.' : undefined)}
              onClick={() => order(entry.id, { address: entry.needs_node ? selected?.address : undefined })} />
          );
        })}
        {hasOrder('persona') && <Button compact icon="fingerprint" content="Личность" selected={editing} onClick={() => setEditing(!editing)} />}
      </Box>
      {editing && hasOrder('persona') && <AgentPersona agent={agent} order={order} />}
      {hasOrder('behavior') && agent.behavior && <AgentBehaviorSettings agent={agent} behavior={agent.behavior} order={order} />}
      {!!agent.goals?.length && <details className="netrun-agent-details"><summary><Icon name="bullseye" /> План агента · {agent.goals.length}</summary>
        <ol>{agent.goals.map((goal) => (<li key={goal.id} aria-current={goal.selected ? 'step' : undefined}>
          <strong>{goal.name}</strong>{goal.selected && <span className="netrun-agent-active-goal"> · сейчас</span>}
          <Box color={THEME.muted} fontSize="11px">{goal.desc}</Box>
                                        </li>))}
        </ol>
                                </details>}
      {agent.programs && <details className="netrun-agent-details"><summary><Icon name="microchip" /> Программы · {agent.programs.length}</summary>
        {agent.programs.length ? agent.programs.map((program) => (<Box key={program.uid || program.id} className="netrun-agent-program">
          <Box bold>{program.name}<Box inline ml={1} color={THEME.muted} fontSize="10px">
            {PROGRAM_ROLES[program.role] || program.role} · мощность {program.power}{program.ap_cost !== undefined ? ` · ${program.ap_cost} ОД` : ''}
                                  </Box>
          </Box>
          <Box color={THEME.muted} fontSize="11px">{program.desc}</Box>
          <Box color={program.unavailable_reason || program.ready_in > 0 || (program.ready_turns ?? 0) > 0 ? THEME.warn : THEME.good} fontSize="10px"
            title={programReadiness(program)} style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {programReadiness(program)}
          </Box>
                                                                  </Box>)) : <Box color={THEME.muted} fontSize="11px">Боевых программ нет. Загрузите файл из локальной памяти.</Box>}
                         </details>}
      {(agent.files || hasOrder('upload')) && <details className="netrun-agent-details"><summary><Icon name="hard-drive" /> Память · {agent.storage.used}/{agent.storage.capacity}</summary>
        {(agent.files || []).map((file) => (<div key={file.uid} className="netrun-agent-file">
          <span title={file.preview || undefined}>{file.name}<small>{file.kind} · {file.size}</small></span>
          {hasOrder('download') && <Button compact icon="download" aria-label={`Забрать ${file.name} у ${agent.name}`}
            disabled={!isTransferableFile(file)}
            tooltip={isTransferableFile(file) ? 'Переместить исходный файл из памяти агента в вашу память.' : 'Этот файл нельзя перенести из текущего сеанса.'}
            onClick={() => order('download', { uid: file.uid })} />}
                                            </div>))}
        {!agent.files?.length && <Box color={THEME.muted} fontSize="11px">Память агента пуста.</Box>}
        {hasOrder('upload') && <div className="netrun-agent-form__row">
          <label className="netrun-field">Локальный файл<select value={selectedFile?.uid || ''} onChange={(event) => setUpload(event.target.value)}>
            <option value="">Выберите файл…</option>
            {files.map((file) => <option key={file.uid} value={file.uid}>{file.name} · {file.size}</option>)}
                                                        </select>
          </label>
          <Button compact icon="upload" content="Загрузить" disabled={!selectedFile || selectedFile.size > agent.storage.capacity - agent.storage.used}
            tooltip={selectedFile && selectedFile.size > agent.storage.capacity - agent.storage.used ? 'В памяти агента недостаточно места.' : 'Переместить исходный файл по сети в память агента.'}
            onClick={() => selectedFile && order('upload', { uid: selectedFile.uid })} />
                               </div>}
                                              </details>}
      {hasOrder('command') && <details className="netrun-agent-details"><summary><Icon name="terminal" /> Команда устройству</summary>
        <Box fontSize="11px" color={THEME.muted}>{selected ? `Цель: ${selected.name || selected.address}` : 'Выберите устройство на карте.'} Команда выполняется с доступами агента.</Box>
        <div className="netrun-agent-form__row">
          <label className="netrun-field">Запрос<select aria-label={`Команда агента ${agent.name}`} value={chosen?.id || ''}
            disabled={!selected} onChange={(event) => setCommand(event.target.value)}>
            <option value="">Выберите команду…</option>
            {commands.map((entry) => <option key={entry.id} value={entry.id}>{entry.name}</option>)}
                                                </select>
          </label>
          <Button compact icon="paper-plane" content="Поручить" disabled={!selected || !chosen} tooltip={chosen?.desc}
            onClick={() => selected && chosen && order('command', { address: selected.address, command: chosen.id })} />
        </div>
                              </details>}
    </Box>
  );
};

/** Agents launched from `.bot` files by this console. */
const AgentsPanelView = () => {
  const { act, data } = useBackend<NetrunData>(['workspace_view', 'agents', 'selected', 'storage']);
  const confirmed = useRef<AgentState[]>([]);
  if (!data.workspace_view || data.workspace_view === 'agents') { confirmed.current = data.agents || []; }
  const agents = data.workspace_view && data.workspace_view !== 'agents' ? confirmed.current : data.agents || [];
  if (!agents.length) {
    return <Box mt={1} color={THEME.muted}>Запущенных агентов пока нет. Выберите шаблон ниже, чтобы создать или запустить агента.</Box>;
  }
  return (
    <Box mt={2} data-net-agents>
      <Box bold mb={0.5} color={THEME.text}>Активные агенты ({agents.length})</Box>
      <div className="netrun-agent-grid">{agents.map((agent) => (
        <AgentCard key={agent.ref} agent={agent} selected={data.selected ?? null} files={(data.storage?.files || []).filter(isTransferableFile)} act={act} />
      ))}
      </div>
    </Box>
  );
};

export const AgentsPanel = memo(AgentsPanelView);
