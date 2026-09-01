import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, ProgressBar, Stack } from '../components';
import { Window } from '../layouts';

// Strip HTML tags from DM battle messages
const stripHtml = (str) => String(str).replace(/<[^>]*>/g, '').trim();

// Passive ability info
const PASSIVE_INFO = {
  short_temper: { emoji: '😡', label: 'Вспыльчивый' },
  poisonous: { emoji: '☠️', label: 'Ядовитый' },
  smart: { emoji: '🧠', label: 'Умный' },
  shotgun: { emoji: '🔫', label: 'Дробовик' },
  magical: { emoji: '✨', label: 'Магический' },
  chonker: { emoji: '🐄', label: 'Толстяк' },
};

export const ArcadeBattle = (props) => {
  const { act, data } = useBackend();
  const [showIntro, setShowIntro] = useState(true);

  const {
    enemy_name = 'Space Villain',
    enemy_hp = 100,
    enemy_max_hp = 100,
    enemy_mp = 40,
    player_hp = 85,
    player_max_hp = 85,
    player_mp = 20,
    battle_log = [],
    gameover = false,
    blocked = false,
    finishing_move = false,
    emagged = false,
    bomb_cooldown = 19,
    enemy_passive = {},
    chosen_weapon = '',
  } = data;

  // ═══════════════════════════════════════════
  //  INTRO SCREEN
  // ═══════════════════════════════════════════
  if (showIntro) {
    return (
      <Window width={480} height={560} title="Космический Злодей 2000">
        <Window.Content>
          <div className="ArcadeBattle__intro">
            <div className="ArcadeBattle__intro-title">
              ⚔️ КОСМИЧЕСКИЙ ЗЛОДЕЙ 2000 ⚔️
            </div>
            <div className="ArcadeBattle__intro-villain">👾</div>
            <div className="ArcadeBattle__intro-tips">
              <div className="ArcadeBattle__intro-tip">
                🗡️ <b>Лёгкая атака</b> — слабая, но без затрат МП
              </div>
              <div className="ArcadeBattle__intro-tip">
                🛡️ <b>Защита</b> — получить МП, снизить урон
              </div>
              <div className="ArcadeBattle__intro-tip">
                ⚡ <b>Контратака</b> — отразить атаку врага (10 МП)
              </div>
              <div className="ArcadeBattle__intro-tip">
                💥 <b>Мощная атака</b> — двойной урон (20 МП)
              </div>
            </div>
            <div className="ArcadeBattle__intro-hint">
              У каждого врага есть пассивные способности с секретными комбо!
              <br />
              Осмотрите автомат, чтобы найти подсказки...
            </div>
            <Button
              className="ArcadeBattle__start-btn"
              onClick={() => setShowIntro(false)}
              fontSize="18px"
              color="green"
              bold>
              ▶ ИГРАТЬ
            </Button>
          </div>
        </Window.Content>
      </Window>
    );
  }

  // ═══════════════════════════════════════════
  //  GAME SCREEN
  // ═══════════════════════════════════════════
  const alivePassives = Object.keys(enemy_passive || {});
  const enemyHpPct = Math.max(0, enemy_hp) / Math.max(1, enemy_max_hp);
  const playerHpPct = Math.max(0, player_hp) / Math.max(1, player_max_hp);

  return (
    <Window
      width={480}
      height={560}
      title={emagged ? 'ПЕРЕБОМБИ КУБИНЦА ПИТА' : 'Космический Злодей 2000'}>
      <Window.Content>
        <div
          className={
            'ArcadeBattle' + (emagged ? ' ArcadeBattle--emagged' : '')
          }>
          {/* ── ENEMY PANEL ── */}
          <div className="ArcadeBattle__enemy">
            <div className="ArcadeBattle__enemy-header">
              <span className="ArcadeBattle__enemy-icon">
                {emagged ? '💣' : '👾'}
              </span>
              <span className="ArcadeBattle__enemy-name">{enemy_name}</span>
              {!!chosen_weapon && (
                <span className="ArcadeBattle__enemy-weapon">
                  ⚔ {chosen_weapon}
                </span>
              )}
            </div>
            <div className="ArcadeBattle__bar-row">
              <span className="ArcadeBattle__bar-label">HP</span>
              <ProgressBar
                value={enemyHpPct}
                ranges={{
                  good: [-Infinity, 0.3],
                  average: [0.3, 0.7],
                  bad: [0.7, Infinity],
                }}>
                {Math.max(0, enemy_hp)} / {enemy_max_hp}
              </ProgressBar>
            </div>
            <div className="ArcadeBattle__bar-row">
              <span className="ArcadeBattle__bar-label">MP</span>
              <Box inline color="cyan" bold>
                {enemy_mp}
              </Box>
            </div>

            {/* Passive badges */}
            {alivePassives.length > 0 && (
              <div className="ArcadeBattle__passives">
                {alivePassives.map((p) => {
                  const info = PASSIVE_INFO[p] || { emoji: '❓', label: p };
                  return (
                    <span key={p} className="ArcadeBattle__passive-badge">
                      {info.emoji} {info.label}
                    </span>
                  );
                })}
              </div>
            )}

            {/* Bomb timer (emag mode) */}
            {!!emagged && (
              <div
                className={
                  'ArcadeBattle__bomb' +
                  (bomb_cooldown <= 5 ? ' ArcadeBattle__bomb--critical' : '')
                }>
                💣 БОМБА: {bomb_cooldown} ходов
              </div>
            )}
          </div>

          {/* ── BATTLE LOG ── */}
          <div className="ArcadeBattle__log">
            <div className="ArcadeBattle__log-title">⚔️ Журнал боя</div>
            <div className="ArcadeBattle__log-content">
              {battle_log.length === 0 ? (
                <div className="ArcadeBattle__log-entry ArcadeBattle__log-entry--info">
                  Победители не употребляют космонаркотики
                </div>
              ) : (
                battle_log.map((msg, i) => (
                  <div key={i} className="ArcadeBattle__log-entry">
                    {'▸ ' + stripHtml(msg)}
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Finishing move alert */}
          {!!finishing_move && !gameover && (
            <div className="ArcadeBattle__finishing">
              ⚡ СЛАБОЕ МЕСТО ОБНАЖЕНО! Следующая атака = 100× урон! ⚡
            </div>
          )}

          {/* ── PLAYER STATS ── */}
          <div className="ArcadeBattle__player">
            <Stack>
              <Stack.Item grow>
                <div className="ArcadeBattle__bar-row">
                  <span className="ArcadeBattle__bar-label">❤️</span>
                  <ProgressBar
                    value={playerHpPct}
                    ranges={{
                      bad: [-Infinity, 0.3],
                      average: [0.3, 0.7],
                      good: [0.7, Infinity],
                    }}>
                    {Math.max(0, player_hp)} / {player_max_hp}
                  </ProgressBar>
                </div>
              </Stack.Item>
              <Stack.Item>
                <div className="ArcadeBattle__bar-row">
                  <span className="ArcadeBattle__bar-label">🔮</span>
                  <Box inline color="cyan" bold fontSize="14px">
                    {player_mp} MP
                  </Box>
                </div>
              </Stack.Item>
            </Stack>
          </div>

          {/* ── ACTION BUTTONS ── */}
          <div className="ArcadeBattle__actions">
            {gameover ? (
              <Button
                className="ArcadeBattle__btn ArcadeBattle__btn--newgame"
                onClick={() => act('newgame')}
                fluid
                textAlign="center"
                fontSize="16px"
                bold>
                🔄 Новая игра
              </Button>
            ) : (
              <div className="ArcadeBattle__btn-grid">
                <Button
                  className="ArcadeBattle__btn ArcadeBattle__btn--attack"
                  onClick={() => act('attack')}
                  disabled={blocked}
                  fluid
                  textAlign="center">
                  🗡️ Атака
                </Button>
                <Button
                  className="ArcadeBattle__btn ArcadeBattle__btn--defend"
                  onClick={() => act('defend')}
                  disabled={blocked}
                  fluid
                  textAlign="center">
                  🛡️ Защита
                </Button>
                <Button
                  className="ArcadeBattle__btn ArcadeBattle__btn--counter"
                  onClick={() => act('counter_attack')}
                  disabled={blocked}
                  fluid
                  textAlign="center">
                  ⚡ Контратака (10)
                </Button>
                <Button
                  className="ArcadeBattle__btn ArcadeBattle__btn--power"
                  onClick={() => act('power_attack')}
                  disabled={blocked}
                  fluid
                  textAlign="center">
                  💥 Мощная (20)
                </Button>
              </div>
            )}
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
