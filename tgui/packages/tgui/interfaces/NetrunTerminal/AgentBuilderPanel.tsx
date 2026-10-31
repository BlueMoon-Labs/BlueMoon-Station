import { useState } from 'react';

import { Box, Button } from '../../components';
import { EntityAvatar } from './EntityAvatar';
import { NETRUN_THEMES } from './themes';
import { AgentBehavior, AgentBuilder, NetrunData, THEME } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

/** A private template produces an independent executable package, ready to launch from Files. */
export const AgentBuilderPanel = ({ builder }: { builder: AgentBuilder }) => {
  const { act, data } = useBackend<NetrunData>(['storage', 'shard']);
  const [open, setOpen] = useState(false);
  const [name, setName] = useState(builder.name);
  const [avatar, setAvatar] = useState(builder.avatars[0]?.id || 'cipher');
  const [accent, setAccent] = useState(builder.accents[0]?.id || 'cyan');
  const [tagline, setTagline] = useState('');
  const [theme, setTheme] = useState(builder.themes.includes('ion') ? 'ion' : builder.themes[0]);
  const [order, setOrder] = useState(builder.orders[0]?.id || 'guard');
  const [behavior, setBehavior] = useState<AgentBehavior>(builder.behavior || {
    strategy: 'profile', aggression: 100, caution: 30, cooperation: true,
  });
  const [includeDefaults, setIncludeDefaults] = useState(true);
  const [selected, setSelected] = useState<string[]>([]);
  const [selectedModules, setSelectedModules] = useState<string[]>([]);
  const [toShard, setToShard] = useState(false);
  // Removed media/programs disappear from the request as soon as a new payload arrives.
  const programs = builder.programs.filter((program) => selected.includes(program.uid));
  const modules = (builder.modules || []).filter((module) => selectedModules.includes(module.uid));
  const used = (includeDefaults ? builder.defaults.reduce((sum, program) => sum + program.size, 0) : 0)
    + programs.reduce((sum, program) => sum + program.size, 0) + modules.reduce((sum, module) => sum + module.size, 0);
  const size = builder.base_size + used;
  const onShard = toShard && !!data.shard;
  const destination = onShard ? data.shard : data.storage;
  const remaining = destination ? destination.capacity - destination.used : 0;
  const overfull = used > builder.capacity || size > remaining;
  const valid = !!name.trim() && !overfull && modules.every((module) => module.allowed)
    && Number.isFinite(behavior.aggression) && behavior.aggression >= 0 && behavior.aggression <= 100
    && Number.isFinite(behavior.caution) && behavior.caution >= 0 && behavior.caution <= 100
    && modules.length <= (builder.max_modules ?? 4) && programs.length <= (builder.max_programs ?? 8);
  const create = () => {
    if (!valid) { return; }
    act('agent_create', { uid: builder.template_uid, name: name.trim(), avatar, accent, tagline, theme, order,
      behavior, include_defaults: includeDefaults, program_uids: programs.map((program) => program.uid), module_uids: modules.map((module) => module.uid), to_shard: onShard });
  };
  return (<Box mt={1} data-net-agent-builder={builder.profile}>
    <Button compact icon="robot" content={builder.template_uid ? 'Собрать своего агента' : 'Создать агента с нуля'} selected={open} onClick={() => setOpen(!open)} />
    {open && <form className="netrun-agent-form" aria-label="Конструктор агента" onSubmit={(event) => { event.preventDefault(); create(); }}>
      <Box bold>{builder.name}</Box>
      <Box color={THEME.muted} fontSize="11px">{builder.description}</Box>
      <label className="netrun-field">Имя агента<input value={name} maxLength={42} onChange={(event) => setName(event.target.value)} /></label>
      <div className="netrun-agent-form__row">
        <EntityAvatar avatar={avatar} accent={accent} size={38} />
        <label className="netrun-field">Аватар<select value={avatar} onChange={(event) => setAvatar(event.target.value)}>
          {builder.avatars.map((choice) => <option key={choice.id} value={choice.id}>{choice.name}</option>)}
                                              </select>
        </label>
        <label className="netrun-field">Цвет<select value={accent} onChange={(event) => setAccent(event.target.value)}>
          {builder.accents.map((choice) => <option key={choice.id} value={choice.id}>{choice.name}</option>)}
                                            </select>
        </label>
      </div>
      <label className="netrun-field">Подпись<input value={tagline} maxLength={80} onChange={(event) => setTagline(event.target.value)} /></label>
      <label className="netrun-field">Оформление<select value={theme} onChange={(event) => setTheme(event.target.value)}>
        {builder.themes.map((id) => <option key={id} value={id}>{NETRUN_THEMES[id]?.name || id}</option>)}
                                                </select>
      </label>
      <label className="netrun-field">Начальная задача<select value={order} onChange={(event) => setOrder(event.target.value)}>
        {builder.orders.map((choice) => <option key={choice.id} value={choice.id}>{choice.name}</option>)}
                                                      </select>
      </label>
      <fieldset style={{ border: `1px solid ${THEME.line}`, margin: '0 0 6px', padding: '6px' }}>
        <legend>Паттерн поведения</legend>
        <label className="netrun-field">Стратегия<select value={behavior.strategy}
          onChange={(event) => setBehavior({ ...behavior, strategy: event.target.value as AgentBehavior['strategy'] })}>
          <option value="profile">Поведение профиля</option>
          <option value="guard">Охранять пост</option>
          <option value="patrol">Патрулировать доступную сеть</option>
          <option value="scavenge">Искать и собирать обломки</option>
                                                 </select>
        </label>
        <label className="netrun-field">Агрессия<input type="number" min={0} max={100} value={behavior.aggression}
          onChange={(event) => setBehavior({ ...behavior, aggression: Number(event.target.value) })} />
        </label>
        <label className="netrun-field">Осторожность<input type="number" min={0} max={100} value={behavior.caution}
          onChange={(event) => setBehavior({ ...behavior, caution: Number(event.target.value) })} />
        </label>
        <label><input type="checkbox" checked={!!behavior.cooperation}
          onChange={(event) => setBehavior({ ...behavior, cooperation: event.target.checked })} /> Помогать союзникам
        </label>
        <Box color={THEME.muted} fontSize="11px">Поведение профиля следует начальной задаче; другая стратегия задаёт постоянный паттерн. Агрессия определяет готовность атаковать сильных противников, осторожность — порог отступления. Программы и права доступа нужны для выполнения действий.</Box>
      </fieldset>
      <fieldset style={{ border: `1px solid ${THEME.line}`, margin: 0, padding: '6px' }}>
        <legend>Программы · память {used}/{builder.capacity}</legend>
        <label style={{ display: 'block' }}><input type="checkbox" checked={includeDefaults} onChange={(event) => setIncludeDefaults(event.target.checked)} /> Штатный набор</label>
        {!!includeDefaults && <Box ml={2} color={THEME.muted} fontSize="11px">
          {builder.defaults.map((program) => `${program.name} (${program.size})`).join(' · ') || 'Нет штатных программ'}
                              </Box>}
        {builder.programs.map((program) => (<label key={program.uid} style={{ display: 'block' }}>
          <input type="checkbox" checked={selected.includes(program.uid)}
            disabled={!selected.includes(program.uid) && programs.length >= (builder.max_programs ?? 8)}
            onChange={(event) => setSelected(event.target.checked ? [...selected, program.uid] : selected.filter((uid) => uid !== program.uid))} />
          {' '}{program.name} · {program.size}
                                            </label>))}
        {!builder.programs.length && <Box color={THEME.muted} fontSize="11px">Дополнительные программы можно выбрать из памяти или шарда.</Box>}
      </fieldset>
      {!!builder.modules?.length && <fieldset style={{ border: `1px solid ${THEME.line}`, margin: '6px 0 0', padding: '6px' }}>
        <legend>Модули агента · {modules.length}/{builder.max_modules ?? 4}</legend>
        <Box color={THEME.muted} fontSize="11px" mb={0.5}>Модули добавляют возможности агента и занимают его память.</Box>
        {builder.modules.map((module) => (<div key={module.uid} style={{ marginTop: '5px' }}>
          <label><input type="checkbox" checked={selectedModules.includes(module.uid)}
            disabled={!selectedModules.includes(module.uid) && (!module.allowed || modules.length >= (builder.max_modules ?? 4))}
            onChange={(event) => {
              if (event.target.checked && (!module.allowed || modules.length >= (builder.max_modules ?? 4))) { return; }
              setSelectedModules(event.target.checked ? [...selectedModules, module.uid] : selectedModules.filter((uid) => uid !== module.uid));
            }} />
            {' '}{module.name} · {module.size}
          </label>
          <Box color={THEME.muted} fontSize="11px" ml={2}>{module.desc}</Box>
          {!!module.requirements.length && <Box color={THEME.muted} fontSize="10px" ml={2}>Нужно: {module.requirements.join(', ')}</Box>}
          {!module.allowed && !!module.reason && <Box color={THEME.warn} fontSize="11px" ml={2}>{module.reason}</Box>}
                                          </div>))}
                                    </fieldset>}
      <label className="netrun-field">Сохранить агента<select value={onShard ? 'shard' : 'local'} onChange={(event) => setToShard(event.target.value === 'shard')}>
        <option value="local">Локальная память</option>
        {!!data.shard && <option value="shard">{data.shard.name}</option>}
                                                      </select>
      </label>
      <Box color={overfull ? THEME.warn : THEME.muted} fontSize="11px">
        {used > builder.capacity ? 'Программы не помещаются в память агента.'
          : size > remaining ? `Недостаточно места: нужно ${size}, свободно ${remaining}.`
            : `Файл займёт ${size}; свободно ${remaining}.`}
      </Box>
      <Box color={THEME.muted} fontSize="11px">После создания выберите новый файл и запустите агента. Шаблон и выбранные программы сохраняются.</Box>
      <Button compact icon="check" content="Создать агента" disabled={!valid} onClick={create} />
             </form>}
          </Box>);
};
