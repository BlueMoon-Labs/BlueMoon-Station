import { act, fireEvent, render } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../../backend';
import { debugReducer } from '../../debug';
import { CombatPanel, IncomingAttacks } from './CombatPanel';
import { CombatState, CombatTarget, CombatTurn, IncomingProgram } from './types';

const enemy: CombatTarget = {
  ref: 'ice-1', name: 'ICE-SENTRY', kind: 'ice', hostile: true,
  integrity: 120, max_integrity: 120, stunned: false,
  node: 'LAN:0002', node_name: 'Сервер', unavailable_reason: null,
};

const strike = {
  id: 'strike', uid: 'file-strike', name: 'strike.exe', desc: 'Удар по процессу',
  size: 2, role: 'attack', power: 18, cooldown: 2, consumable: false,
  needs_target: true, icon: 'bolt', ready_in: 0,
};

const setup = (combatOverrides: Partial<CombatState> = {}, locked = 0) => {
  const topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  const combat: CombatState = {
    node: null, node_name: null, self: null,
    targets: [enemy], programs: [strike], incoming: [],
    ...combatOverrides,
  };
  store.dispatch(backendUpdate({
    config: { interface: 'NetrunTerminal' },
    data: { combat, locked, breach: null },
  }));
  return { topic, store, combat };
};

const uses = (topic) => topic.mock.calls
  .filter((call) => call[0]?.type === 'act/program_use')
  .map((call) => JSON.parse(call[0].payload));

const ownTurn: CombatTurn = {
  round: 2, actor_ref: 'self', actor_name: 'Вы', your_turn: true,
  ap: 2, max_ap: 3, remaining: 12, decision_seconds: 12, can_pass: true,
  participants: [
    { ref: 'self', name: 'Вы', current: true, ap: 2, max_ap: 3 },
    { ref: enemy.ref, name: enemy.name, current: false, ap: 3, max_ap: 3 },
  ],
};

describe('Netrun combat contacts', () => {
  let actionTime = Date.now();
  beforeEach(() => {
    actionTime += 1000;
    jest.spyOn(Date, 'now').mockReturnValue(actionTime);
  });
  afterEach(() => jest.restoreAllMocks());

  test('BLACK ICE has a distinct combat identity and warns about neural harm', () => {
    setup({ targets: [{ ...enemy, name: 'BLACK ICE', ice_kind: 'black' }] });
    const panel = render(<CombatPanel />);
    expect(panel.getByRole('img', { name: 'BLACK ICE · нелегальный' }).querySelector('.fa-skull-crossbones')).toBeTruthy();
    expect(panel.getByText(/нейрообратная связь может повредить телу/)).toBeTruthy();
  });

  test('combat bot identity uses its role glyph and the delivered private faction color and name', () => {
    setup({ targets: [{ ...enemy, kind: 'bot', bot_kind: 'hacker', faction: 'owner:console-42',
      faction_name: 'Агенты Лиса', faction_color: '#12ab34' }] });
    const panel = render(<CombatPanel />);
    const avatar = panel.getByRole('img', { name: 'Бот: Агент-взломщик' });
    expect(avatar.getAttribute('data-bot-glyph')).toBe('cipher');
    expect(avatar.style.color).toBe('rgb(18, 171, 52)');
    expect(panel.getByText('Агент-взломщик · Агенты Лиса')).toBeTruthy();
  });

  test('incoming countdown is shown once in reserved session status, not repeated inside combat', () => {
    const { store, combat } = setup({
      incoming: [{ source: 'ICE-SENTRY', name: 'strike.exe', role: 'attack',
        power: 16, remaining: 2.3, source_ref: enemy.ref }],
      self: { integrity: 74, max_integrity: 100, stunned: false },
    });
    const panel = render(<CombatPanel />);
    expect(panel.queryByText(/ICE-SENTRY готовит strike.exe/)).toBeNull();
    const self = panel.getByText('Вы');
    expect(self).toBeTruthy();
    act(() => store.dispatch(backendUpdate({ data: { combat: {
      ...combat, incoming: [{ ...combat.incoming![0], remaining: 1.2 }],
    } } })));
    panel.rerender(<CombatPanel />);
    expect(panel.queryByText(/ICE-SENTRY готовит strike.exe/)).toBeNull();
    expect(panel.getByText('Вы')).toBeTruthy();
  });

  test('a remote contact shows its actual node and uses the real source ref', () => {
    const { topic } = setup();
    const panel = render(<CombatPanel />);
    expect(panel.getByText('Ответный бой')).toBeTruthy();
    expect(panel.getByText('Сервер LAN:0002')).toBeTruthy();
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: 'file-strike', target: 'ice-1' }]);
  });

  test('a lawful guard requires deliberate selection before it can be attacked', () => {
    const { topic } = setup({ targets: [{ ...enemy, hostile: false }] });
    const panel = render(<CombatPanel />);
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toHaveLength(0);
    fireEvent.click(panel.getByText('ICE-SENTRY'));
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: 'file-strike', target: 'ice-1' }]);
  });

  test('retains an opponent when its announced program enters cooldown', () => {
    const { topic, store, combat } = setup({
      incoming: [{ source: enemy.name, source_ref: enemy.ref, name: 'trace.exe', role: 'trace', power: 6, remaining: 3 }],
    });
    const panel = render(<CombatPanel />);
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat, incoming: [],
      targets: [{ ...enemy, programs: [{ name: 'trace.exe', desc: '', role: 'trace', power: 6, cooldown: 5, windup: 3, ready_in: 5 }] }],
    } } })));
    panel.rerender(<CombatPanel />);
    expect(panel.getByText('ICE-SENTRY')).toBeTruthy();
    expect(panel.getByText('trace.exe: перезарядка 5 с')).toBeTruthy();
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: 'file-strike', target: 'ice-1' }]);
  });

  test('replaces removed selection with the next usable hostile source', () => {
    const { topic, store, combat } = setup();
    const panel = render(<CombatPanel />);
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat,
      targets: [{ ...enemy, ref: 'ice-2', name: 'ICE-HUNTER' }],
    } } })));
    panel.rerender(<CombatPanel />);
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: 'file-strike', target: 'ice-2' }]);
  });

  test('route loss disables a reply and restoration reselects the same opponent', () => {
    const { topic, store, combat } = setup();
    const panel = render(<CombatPanel />);
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat,
      targets: [{ ...enemy, unavailable_reason: 'Нет маршрута к противнику.' }],
    } } })));
    panel.rerender(<CombatPanel />);
    expect(panel.getByText('Нет маршрута к противнику.')).toBeTruthy();
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toHaveLength(0);
    act(() => store.dispatch(backendUpdate({ data: { combat } })));
    panel.rerender(<CombatPanel />);
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: 'file-strike', target: 'ice-1' }]);
  });

  test('a remote console cannot use entity-only support programs', () => {
    const { topic } = setup({ programs: [{ ...strike, uid: 'file-barrier', name: 'barrier.exe',
      role: 'shield', needs_target: false, unavailable_reason: 'Нужна собственная сущность в сети.',
    }] });
    const panel = render(<CombatPanel />);
    expect(panel.getByText('Нужна собственная сущность в сети.')).toBeTruthy();
    fireEvent.click(panel.getByText('barrier'));
    expect(uses(topic)).toHaveLength(0);
  });

  test('a finished contact removes the selected ref and blocks further use', () => {
    const { topic, store, combat } = setup();
    const panel = render(<CombatPanel />);
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat, targets: [] } } })));
    panel.rerender(<CombatPanel />);
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toHaveLength(0);
    expect(panel.queryByText('ICE-SENTRY')).toBeNull();
  });

  test.each(['entity', 'bot'] as const)('an entity host can explicitly pursue a selected %s', (kind) => {
    const target = { ...enemy, ref: 'runner', name: 'RUNNER', kind };
    const { topic } = setup({ pursuit_available: true, node: target.node, targets: [target] });
    const panel = render(<CombatPanel />);
    fireEvent.click(panel.getByText('Преследовать'));
    const calls = topic.mock.calls.filter(([message]) => message.type === 'act/pursue');
    expect(calls).toHaveLength(1);
    expect(JSON.parse(calls[0][0].payload)).toEqual({ ref: 'runner' });
    expect(uses(topic)).toHaveLength(0); // Capturing a target never starts a manual attack.
  });

  test.each(['ice', 'fortress'] as const)('pursuit controls are not offered for %s', (kind) => {
    setup({ pursuit_available: true, targets: [{ ...enemy, kind }] });
    const panel = render(<CombatPanel />);
    expect(panel.queryByText('Преследовать')).toBeNull();
  });

  test('a pursuit keeps its captured ref across missing and remote snapshots without enabling attacks', () => {
    const runner: CombatTarget = { ...enemy, ref: 'runner', name: 'RUNNER', kind: 'entity', node: 'HERE' };
    const pursuit = { target_ref: runner.ref, name: runner.name, node: 'HERE', following: true, status: 'Цель рядом.' };
    const { topic, store, combat } = setup({ node: 'HERE', pursuit_available: true, targets: [runner], pursuit });
    const panel = render(<CombatPanel />);
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat,
      targets: [enemy], pursuit: { ...pursuit, node: 'NEXT', status: 'Идём к следующему узлу.' },
    } } })));
    expect(panel.getByText('Захвачена цель: RUNNER')).toBeTruthy();
    expect(panel.getByText('Идём к следующему узлу.')).toBeTruthy();
    fireEvent.click(panel.getByText('ICE-SENTRY'));
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toHaveLength(0); // A new hostile contact must not steal the captured selection.
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat,
      targets: [{ ...runner, node: 'NEXT' }], pursuit: { ...pursuit, node: 'NEXT' },
    } } })));
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toHaveLength(0); // A visible remote entity is still outside the current node.
    act(() => store.dispatch(backendUpdate({ data: { combat } })));
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: 'file-strike', target: runner.ref }]);
    fireEvent.click(panel.getByText('Остановить преследование'));
    expect(topic.mock.calls.some(([message]) => message.type === 'act/pursuit_stop')).toBe(true);
  });

  test('pursuit requires an available entity host and respects a locked terminal', () => {
    const runner: CombatTarget = { ...enemy, kind: 'bot' };
    const { topic, store, combat } = setup({ targets: [runner], pursuit_available: false }, 3);
    const panel = render(<CombatPanel />);
    expect(panel.queryByText('Преследовать')).toBeNull();
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat, pursuit_available: true } } })));
    fireEvent.click(panel.getByText('Преследовать'));
    expect(topic.mock.calls.some(([message]) => message.type === 'act/pursue')).toBe(false);
  });

  test('trace warnings preserve their source identity while the puzzle is open', () => {
    setup({ incoming: [{ source: enemy.name, source_ref: enemy.ref, source_node: enemy.node,
      name: 'trace.exe', role: 'trace', power: 6, remaining: 3 }] });
    const open = jest.fn();
    const panel = render(<IncomingAttacks onCombat={open} />);
    expect(panel.getByRole('alert').textContent).toContain('ICE-SENTRY готовит trace.exe');
    fireEvent.click(panel.getByText('Открыть бой'));
    expect(open).toHaveBeenCalledTimes(1);
  });

  test('shared launch recovery blocks attack and support until the server releases it', () => {
    const { topic, store, combat } = setup({
      action_ready_in: 0.5,
      programs: [strike, { ...strike, uid: 'file-barrier', name: 'barrier.exe', role: 'shield', needs_target: false }],
    });
    const panel = render(<CombatPanel />);
    expect(panel.getByRole('status').textContent).toContain('Общая пауза запуска: ещё 0.5 с.');
    fireEvent.click(panel.getByText('strike'));
    fireEvent.click(panel.getByText('barrier'));
    expect(uses(topic)).toHaveLength(0);

    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat, action_ready_in: 0 } } })));
    expect(panel.queryByRole('status')).toBeNull();
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: 'file-strike', target: 'ice-1' }]);
  });

  test('a program keeps its own cooldown after shared recovery expires', () => {
    const { topic, store, combat } = setup({ action_ready_in: 0.1, programs: [{ ...strike, ready_in: 2 }] });
    const panel = render(<CombatPanel />);
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat, action_ready_in: 0 } } })));
    expect(panel.getByText('Перезарядка: ещё 2 с.')).toBeTruthy();
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toHaveLength(0);
  });

  test('cooldown and changing target casts preserve the same action tiles and their order', () => {
    const { store, combat } = setup({ programs: [strike,
      { ...strike, uid: 'shield', name: 'barrier.exe', needs_target: false }] });
    const panel = render(<CombatPanel />);
    const tiles = Array.from(panel.container.querySelectorAll('[data-net-program]'));
    const status = panel.container.querySelector('.netrun-combat-action-status');
    const cast = panel.container.querySelector('.netrun-target-cast');
    act(() => store.dispatch(backendUpdate({ data: { combat: {
      ...combat, action_ready_in: 0.5,
      programs: combat.programs.map((program) => ({ ...program, ready_in: 20 })),
      targets: [{ ...enemy, casting: { name: 'Очень длинное название программы', role: 'attack', power: 20, remaining: 3 } }],
    } } })));
    expect(Array.from(panel.container.querySelectorAll('[data-net-program]'))).toEqual(tiles);
    tiles.forEach((tile) => expect(panel.container.contains(tile)).toBe(true));
    expect(panel.container.querySelector('.netrun-combat-action-status')).toBe(status);
    expect(panel.container.querySelector('.netrun-target-cast')).toBe(cast);
    act(() => store.dispatch(backendUpdate({ data: { combat } })));
    expect(panel.container.querySelector('[data-net-program="file-strike"]')).toBe(tiles[0]);
    expect(panel.container.querySelector('.netrun-combat-action-status')).toBe(status);
    expect(panel.queryByRole('status')).toBeNull();
  });

  test('a hidden summary preserves full actions and deliberate selection, while an active null clears them', () => {
    const lawful = { ...enemy, ref: 'guard', name: 'GUARD', hostile: false };
    const { store, combat, topic } = setup({ targets: [enemy, lawful] });
    const panel = render(<CombatPanel />);
    fireEvent.click(panel.getByText('GUARD'));
    const tile = panel.container.querySelector('[data-net-program="file-strike"]');
    act(() => store.dispatch(backendUpdate({ data: { workspace_view: 'files', combat: { incoming: [] } } })));
    expect(panel.container.querySelector('[data-net-program="file-strike"]')).toBe(tile);
    act(() => store.dispatch(backendUpdate({ data: { workspace_view: 'combat', combat } })));
    expect(panel.container.querySelector('[data-net-program="file-strike"]')).toBe(tile);
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: strike.uid, target: lawful.ref }]);
    act(() => store.dispatch(backendUpdate({ data: { workspace_view: 'combat', combat: null } })));
    expect(panel.queryByText('strike')).toBeNull();
    expect(panel.queryByText('GUARD')).toBeNull();
    expect(panel.getByText(/Нет боевого контакта/)).toBeTruthy();
  });

  test('turn AP and cooldowns admit only affordable ready programs, and passing sends one explicit action', () => {
    const { topic } = setup({ turn: ownTurn, programs: [
      { ...strike, ap_cost: 2, ready_in: 30, ready_turns: 0, cooldown_turns: 3, shield_turns: 2, stun_turns: 1 },
      { ...strike, uid: 'expensive', name: 'overload.exe', ap_cost: 3 },
      { ...strike, uid: 'cooling', name: 'blackout.exe', ap_cost: 1, ready_turns: 1 },
    ] });
    const panel = render(<CombatPanel />);
    expect(panel.getByText('Ваш ход')).toBeTruthy();
    expect(panel.getByText('Раунд 2')).toBeTruthy();
    expect(panel.getByRole('meter', { name: 'Очки действия текущего хода' }).getAttribute('aria-valuenow')).toBe('2');
    const strikeTile = panel.container.querySelector('[data-net-program="file-strike"]')!;
    fireEvent.mouseEnter(strikeTile);
    const facts = document.querySelector('[role="tooltip"] dl')!;
    expect(facts.textContent).toContain('Перезарядка3 ход.');
    expect(facts.textContent).toContain('Длительность щита2 ход.');
    expect(facts.textContent).toContain('Оглушение1 ход.');
    fireEvent.mouseLeave(strikeTile);
    fireEvent.click(panel.getByText('overload'));
    fireEvent.click(panel.getByText('blackout'));
    expect(uses(topic)).toHaveLength(0);
    expect(panel.getByText('Нужно 3 ОД, осталось 2.')).toBeTruthy();
    expect(panel.getByText('Перезарядка: ещё 1 ход.')).toBeTruthy();
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: strike.uid, target: enemy.ref }]);
    fireEvent.click(panel.getByText('Завершить ход'));
    const passes = topic.mock.calls.filter(([message]) => message.type === 'act/combat_pass');
    expect(passes).toHaveLength(1);
    expect(JSON.parse(passes[0][0].payload)).toEqual({});
  });

  test('another actor blocks actions and pass until the server publishes the own turn', () => {
    const { topic, combat, store } = setup({ turn: { ...ownTurn, your_turn: false, can_pass: false, actor_ref: enemy.ref, actor_name: enemy.name } });
    const panel = render(<CombatPanel />);
    expect(panel.getByText('Ход: ICE-SENTRY')).toBeTruthy();
    fireEvent.click(panel.getByText('strike'));
    fireEvent.click(panel.getByText('Завершить ход'));
    expect(topic).not.toHaveBeenCalled();
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat, turn: ownTurn } } })));
    expect(panel.getByText('Ваш ход')).toBeTruthy();
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: strike.uid, target: enemy.ref }]);
  });

  test('enemy turn cooldown and AP stay distinct from an already pending attack in seconds', () => {
    setup({ turn: ownTurn, targets: [{ ...enemy,
      casting: { name: 'trace.exe', role: 'trace', power: 6, remaining: 0.8 },
      programs: [{ name: 'trace.exe', desc: 'Трассировка', role: 'trace', power: 6,
        cooldown: 5, windup: 0.8, ready_in: 0, ap_cost: 2, ready_turns: 2, cooldown_turns: 3 }],
    }] });
    const panel = render(<CombatPanel />);
    expect(panel.getByText('Готовит trace.exe: 0.8 с')).toBeTruthy();
    expect(panel.getByText('trace.exe: перезарядка 2 ход. · 2 ОД').title).toContain('перезарядка 3 ход.');
  });

  test.each([
    [true, 0, 'Вы оглушены: дождитесь окончания оглушения.'],
    [false, 3, 'Терминал заблокирован: ещё 3 с.'],
  ])('disabled programs explain stun=%s and lock=%s', (stunned, locked, reason) => {
    const { topic } = setup({ self: { integrity: 100, max_integrity: 100, stunned } }, locked);
    const panel = render(<CombatPanel />);
    expect(panel.getByRole('status').textContent).toContain(reason);
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toHaveLength(0);
  });

  test.each([
    ['attack', 16, '16 урона до щита', 'Включите щит, оглушите ICE или выйдите из узла.'],
    ['stun', 25, '2.5 с оглушения', 'Оглушите ICE или выйдите из узла.'],
    ['trace', 6, '+6% трассировки', 'Прервите взлом или оглушите ICE.'],
  ])('compact warning shows the effect and counterplay for %s', (role, power, effect, advice) => {
    setup({ incoming: [{ source: enemy.name, name: `${role}.exe`, role, power, remaining: 1.2 }] });
    const open = jest.fn();
    const panel = render(<IncomingAttacks compact onCombat={open} />);
    expect(panel.getByRole('alert').textContent).toContain(`${effect} · через 1.2 с`);
    expect(panel.getByText(advice)).toBeTruthy();
    expect(open).not.toHaveBeenCalled();
    if (role === 'stun') {
      expect(panel.getByRole('alert').textContent).not.toContain('щит');
    }
    fireEvent.click(panel.getByText('Открыть бой'));
    expect(open).toHaveBeenCalledTimes(1);
  });

  test('compact warning leads with the soonest impact and retains every threat in its tooltip', () => {
    const incoming: IncomingProgram[] = [
      { source: 'ICE-SENTRY', name: 'trace.exe', role: 'trace', power: 6, remaining: 3 },
      { source: 'ICE-HUNTER', name: 'blackout.exe', role: 'stun', power: 20, remaining: 0.7 },
    ];
    setup({ incoming });
    const panel = render(<IncomingAttacks compact onCombat={() => {}} />);
    const alert = panel.getByRole('alert');
    expect(alert.textContent).toContain('2 с оглушения · через 0.7 с · ICE-HUNTER готовит blackout.exe · угроз: 2');
    expect(alert.textContent).not.toContain('ICE-SENTRY');
    const tooltip = alert.querySelector('[title]')!.getAttribute('title');
    expect(tooltip).toContain('ICE-SENTRY готовит trace.exe · +6% трассировки');
    expect(tooltip).toContain('Щит не защищает от оглушения.');
  });

  test('enemy-turn warnings show skipped turns and reserve program counterplay for the own turn in both formats', () => {
    const { topic, store, combat } = setup({ turn: { ...ownTurn, actor_ref: enemy.ref, actor_name: enemy.name, your_turn: false, can_pass: false }, incoming: [
      { source: enemy.name, name: 'blackout.exe', role: 'stun', power: 20, stun_turns: 2, remaining: 0.7 },
      { source: enemy.name, name: 'strike.exe', role: 'attack', power: 16, remaining: 1.2 },
      { source: enemy.name, name: 'trace.exe', role: 'trace', power: 6, remaining: 1.5 },
    ] });
    const panel = render(<IncomingAttacks onCombat={() => {}} />);
    for (const compact of [false, true]) {
      panel.rerender(<IncomingAttacks compact={compact} onCombat={() => {}} />);
      const warning = panel.getByRole('alert');
      const guidance = warning.textContent + (warning.querySelector('[title]')?.getAttribute('title') || '');
      expect(warning.textContent).toContain('пропуск 2 ходов');
      expect(guidance).not.toContain('с оглушения');
      expect(guidance).toContain('Щит подготовьте в свой ход; отступление стоит 1 ОД.');
      expect(guidance).toContain('Подавление ICE подготовьте в свой ход.');
      expect(guidance).toContain('Прервите взлом, чтобы сорвать трассировку; подавление ICE доступно в свой ход.');
      expect(guidance).not.toMatch(/Оглушите ICE|Включите щит|выйдите из узла/);
    }
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat,
      incoming: [{ ...combat.incoming![0], stun_turns: undefined }],
    } } })));
    expect(panel.getByRole('alert').textContent).toContain('пропуск 1 хода');
    expect(topic).not.toHaveBeenCalled();
  });

  test('detailed warnings distinguish damage, stun and trace effects', () => {
    setup({ incoming: [
      { source: enemy.name, name: 'strike.exe', role: 'attack', power: 14, remaining: 2 },
      { source: enemy.name, name: 'blackout.exe', role: 'stun', power: 30, remaining: 1 },
      { source: enemy.name, name: 'trace.exe', role: 'trace', power: 6, remaining: 3 },
    ] });
    const panel = render(<IncomingAttacks onCombat={() => {}} />);
    const alert = panel.getByRole('alert');
    expect(alert.textContent).toContain('strike.exe · 14 урона до щита');
    expect(alert.textContent).toContain('blackout.exe · 3 с оглушения');
    expect(alert.textContent).toContain('trace.exe · +6% трассировки');
    expect(alert.textContent).toContain('Щит не защищает от оглушения.');
    expect(alert.textContent).toContain('Щит не скрывает трассировку.');
  });

  test('a stun-only warning never recommends damage protection', () => {
    setup({ incoming: [{ source: enemy.name, name: 'blackout.exe', role: 'stun', power: 20, remaining: 1 }] });
    const panel = render(<IncomingAttacks onCombat={() => {}} />);
    const alert = panel.getByRole('alert');
    expect(alert.textContent).toContain('Оглушите ICE или выйдите из узла');
    expect(alert.textContent).not.toContain('Щит снижает урон');
  });
});

test('the decision clock runs locally only in the active workspace and never restarts on an AP update', () => {
  jest.useFakeTimers({ doNotFake: ['performance'] });
  let now = 0;
  const clock = jest.spyOn(performance, 'now').mockImplementation(() => now);
  const { store, combat, topic } = setup({ turn: ownTurn });
  const panel = render(<CombatPanel />);
  const advance = (milliseconds: number) => act(() => { now += milliseconds; jest.advanceTimersByTime(milliseconds); });
  try {
    expect(panel.getByLabelText('Осталось 12 с')).toBeTruthy();
    expect(jest.getTimerCount()).toBe(1);
    advance(2000);
    expect(panel.getByLabelText('Осталось 10 с')).toBeTruthy();
    act(() => store.dispatch(backendUpdate({ data: { combat: { ...combat, turn: { ...ownTurn, ap: 1 } } } })));
    expect(panel.getByLabelText('Осталось 10 с')).toBeTruthy();
    act(() => store.dispatch(backendUpdate({ data: { workspace_view: 'files', combat: null } })));
    expect(jest.getTimerCount()).toBe(0);
    advance(2000);
    act(() => store.dispatch(backendUpdate({ data: { workspace_view: 'combat', combat: { ...combat, turn: { ...ownTurn, remaining: 8 } } } })));
    expect(panel.getByLabelText('Осталось 8 с')).toBeTruthy();
    advance(8000);
    expect(panel.getByLabelText('Осталось 0 с')).toBeTruthy();
    expect(jest.getTimerCount()).toBe(0);
    expect(topic).not.toHaveBeenCalled();
  } finally {
    panel.unmount();
    clock.mockRestore();
    jest.useRealTimers();
  }
});

test('combat actions carry their exact server decision identity', () => {
  const { topic } = setup({ turn: { ...ownTurn, id: 'encounter-1:3' } });
  const panel = render(<CombatPanel />);
  fireEvent.click(panel.getByText('strike'));
  expect(uses(topic)).toEqual([{ uid: 'file-strike', target: enemy.ref, turn_id: 'encounter-1:3' }]);
  fireEvent.click(panel.getByText('Завершить ход'));
  const pass = topic.mock.calls.find((call) => call[0]?.type === 'act/combat_pass');
  expect(JSON.parse(pass![0].payload)).toEqual({ turn_id: 'encounter-1:3' });
});

test('spectators explicitly join the current decision instead of launching an off-turn attack', () => {
  const { topic, store, combat } = setup({ turn: {
    ...ownTurn, id: 'encounter-2:1', your_turn: false, can_pass: false,
    participating: false, can_join: true,
  } });
  const panel = render(<CombatPanel />);
  expect(panel.queryByText('Завершить ход')).toBeNull();
  fireEvent.click(panel.getByText('strike'));
  expect(uses(topic)).toHaveLength(0);
  fireEvent.click(panel.getByText('Вступить в бой'));
  const join = topic.mock.calls.find((call) => call[0]?.type === 'act/combat_join');
  expect(JSON.parse(join![0].payload)).toEqual({ turn_id: 'encounter-2:1' });
  act(() => store.dispatch(backendUpdate({ data: { combat: {
    ...combat, turn: { ...combat.turn!, participating: true, can_join: false },
  } } })));
  expect(panel.queryByText('Вступить в бой')).toBeNull();
  expect(panel.getByText('Завершить ход')).toBeTruthy();
});

test('local expiry locks actions and a recreated encounter resets the same actor and round clock', () => {
  jest.useFakeTimers({ doNotFake: ['performance'] });
  let now = 0;
  const clock = jest.spyOn(performance, 'now').mockImplementation(() => now);
  const { store, combat, topic } = setup({ turn: { ...ownTurn, id: 'encounter-3:1' } });
  const panel = render(<CombatPanel />);
  try {
    act(() => { now = 12000; jest.advanceTimersByTime(12000); });
    expect(panel.getByLabelText('Осталось 0 с')).toBeTruthy();
    expect(panel.getAllByText('Время на решение истекло. Ожидается следующий ход.').length).toBeGreaterThan(0);
    fireEvent.click(panel.getByText('strike'));
    fireEvent.click(panel.getByText('Завершить ход'));
    expect(topic).not.toHaveBeenCalled();
    expect(jest.getTimerCount()).toBe(0);
    act(() => store.dispatch(backendUpdate({ data: { combat: {
      ...combat, turn: { ...ownTurn, id: 'encounter-4:1' },
    } } })));
    expect(panel.getByLabelText('Осталось 12 с')).toBeTruthy();
    expect(panel.queryByText('Время на решение истекло. Ожидается следующий ход.')).toBeNull();
    expect(jest.getTimerCount()).toBe(1);
    fireEvent.click(panel.getByText('strike'));
    expect(uses(topic)).toEqual([{ uid: 'file-strike', target: enemy.ref, turn_id: 'encounter-4:1' }]);
  } finally {
    panel.unmount();
    clock.mockRestore();
    jest.useRealTimers();
  }
});


test('a spectator joins the encounter without a target even after the displayed NPC decision expires', () => {
  const { topic, store, combat } = setup({ targets: [], turn: {
    ...ownTurn, id: 'encounter-6:14', join_id: 'encounter-6', remaining: 0,
    your_turn: false, can_pass: false, participating: false, can_join: true,
  } });
  const panel = render(<CombatPanel />);
  expect(panel.getByText('Цель: не выбрана')).toBeTruthy();
  fireEvent.click(panel.getByText('Вступить в бой'));
  const joins = () => topic.mock.calls.filter((call) => call[0]?.type === 'act/combat_join');
  expect(joins()).toHaveLength(1);
  expect(JSON.parse(joins()[0][0].payload)).toEqual({ turn_id: 'encounter-6' });
  expect(uses(topic)).toHaveLength(0);
  act(() => store.dispatch(backendUpdate({ data: { combat: {
    ...combat, turn: { ...combat.turn!, id: 'encounter-6:15', can_join: false },
  } } })));
  fireEvent.click(panel.getByText('Вступить в бой'));
  expect(joins()).toHaveLength(1);
});

test('a newly locked spectator cannot use a previously enabled join card', () => {
  const { topic } = setup({ turn: {
    ...ownTurn, id: 'encounter-7:1', join_id: 'encounter-7',
    your_turn: false, can_pass: false, participating: false, can_join: true,
  } }, 30);
  const panel = render(<CombatPanel />);
  fireEvent.click(panel.getByText('Вступить в бой'));
  expect(topic).not.toHaveBeenCalled();
});
