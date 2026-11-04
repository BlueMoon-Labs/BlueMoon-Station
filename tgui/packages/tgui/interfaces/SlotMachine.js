import { useState } from 'react';

import { useBackend } from '../backend';
import { AnimatedNumber, Box, Button, Divider, Section, Stack } from '../components';
import { Window } from '../layouts';

// Emoji symbols for the slot machine reels
const SYMBOL_MAP = {
  'seven': { emoji: '💰', label: 'Money' },
  'cherry': { emoji: '🍒', label: 'Cherry' },
  'banana': { emoji: '🍌', label: 'Banana' },
  'strawberry': { emoji: '🍓', label: 'Strawberry' },
  'grape': { emoji: '🍇', label: 'Grape' },
  'diamond': { emoji: '💎', label: 'Diamond' },
  'star': { emoji: '⭐', label: 'Star' },
  'watermelon': { emoji: '🍉', label: 'Watermelon' },
  'wild': { emoji: '🃏', label: 'Wild' },
  'scatter': { emoji: '💫', label: 'Scatter' },
};

const ALL_SYMBOLS = Object.keys(SYMBOL_MAP);

const BET_OPTIONS = [5, 10, 25, 50, 100];
const AUTO_SPIN_OPTIONS = [5, 10, 25];
const DEPOSIT_OPTIONS = [50, 100, 500];

// How many paylines each bet unlocks
const BET_LINES = {
  5: 1,
  10: 2,
  25: 3,
  50: 3,
  100: 3,
};

// Payline patterns: row index (0-based) for each column
// Must match DM definitions
const PAYLINE_DEFS = [
  [1, 1, 1, 1, 1], // Line 1: middle
  [0, 0, 0, 0, 0], // Line 2: top
  [2, 2, 2, 2, 2], // Line 3: bottom
  [0, 1, 2, 1, 0], // Line 4: V-shape
  [2, 1, 0, 1, 2], // Line 5: inverted V
];

const PAYLINE_COLORS = [
  '#ffd700', // gold - middle
  '#ff4444', // red - top
  '#4488ff', // blue - bottom
  '#00ff88', // green - V
  '#ff6eff', // pink - inverted V
];

const getSymbolDisplay = (symbolKey) => {
  const sym = SYMBOL_MAP[symbolKey];
  return sym ? sym.emoji : '❓';
};

const getResultIcon = (type) => {
  switch (type) {
    case 'jackpot': return '🎉';
    case 'win': return '✅';
    case 'small': return '🎁';
    case 'bonus': return '⚡';
    default: return '❌';
  }
};

const SlotReel = (props) => {
  const { symbols, spinning, reelIndex, stopped } = props;
  return (
    <div className={
      'SlotMachine__reel'
      + (spinning && !stopped ? ' SlotMachine__reel--spinning' : '')
    }>
      <div className="SlotMachine__reel-window">
        {spinning && !stopped ? (
          <div
            className="SlotMachine__reel-strip"
            style={{
              animationDelay: (reelIndex * 0.15) + 's',
            }}>
            {ALL_SYMBOLS.concat(ALL_SYMBOLS).concat(ALL_SYMBOLS).map((sym, i) => (
              <div className="SlotMachine__reel-symbol" key={i}>
                {getSymbolDisplay(sym)}
              </div>
            ))}
          </div>
        ) : (
          <div className="SlotMachine__reel-strip SlotMachine__reel-strip--stopped">
            {symbols.map((sym, i) => (
              <div
                className={
                  'SlotMachine__reel-symbol'
                  + (i === 1 ? ' SlotMachine__reel-symbol--highlight' : '')
                }
                key={i}>
                {getSymbolDisplay(sym)}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

// Confetti overlay for big wins
const ConfettiOverlay = () => (
  <div className="SlotMachine__confetti">
    {Array.from({ length: 30 }).map((_, i) => (
      <div
        key={i}
        className="SlotMachine__confetti-piece"
        style={{
          'left': (((i * 37) % 100)) + '%',
          animationDelay: ((i * 0.13) % 2) + 's',
          animationDuration: (1.5 + (i % 3) * 0.5) + 's',
          'background': ['#ffd700', '#ff6eff', '#00ff88', '#ff4444', '#4488ff'][i % 5],
        }}
      />
    ))}
  </div>
);

export const SlotMachine = (props) => {
  const { act, data } = useBackend();
  const [showIntro, setShowIntro] = useState(true);
  const {
    money,
    plays,
    jackpots,
    balance,
    working,
    bet_amount,
    reels,
    result_message,
    result_type,
    prize_bank,
    house_edge,
    jackpot_share,
    bank_share,
    deposit_max,
    prize_big,
    prize_small,
    jackpot_sevens,
    bonus_multiplier,
    bonus_active,
    win_streak,
    session_winnings,
    auto_spin,
    auto_spin_remaining,
    free_spins_remaining,
    loss_streak,
    spin_history,
    gamble_available,
    gamble_amount,
    near_miss,
    near_miss_message,
    show_confetti,
    active_lines,
    winning_line,
  } = data;

  // Intro splash screen
  if (showIntro) {
    return (
      <Window
        width={540}
        height={680}
        theme="ntos">
        <Window.Content>
          <div
            className="SlotMachine__intro"
            onClick={() => setShowIntro(false)}>
            <div className="SlotMachine__intro-machine">🎰</div>
            <div className="SlotMachine__intro-title">SLOT MACHINE</div>
            <div className="SlotMachine__intro-subtitle">
              Игровой автомат
            </div>
            <div className="SlotMachine__intro-symbols">
              🍒 🍌 🍓 🍇 💎 ⭐ 🍉 💰 🃏 💫
            </div>
            <div className="SlotMachine__intro-click">
              ▶ Нажмите, чтобы играть ◀
            </div>
          </div>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window
      width={540}
      height={680}
      theme="ntos">
      <Window.Content overflow="auto">
        {/* Confetti overlay for big wins */}
        {!!show_confetti && !working && <ConfettiOverlay />}

        <Stack vertical fill>
          {/* Header with jackpot display */}
          <Stack.Item>
            <div className="SlotMachine__header">
              <div className="SlotMachine__header-text">
                ★ ДЖЕКПОТ ★
              </div>
              <div className="SlotMachine__header-amount">
                💰 {money} кр.
              </div>
            </div>
            <Box textAlign="center" fontSize="11px" color="label">
              Банк выигрышей: {prize_bank} кр. С каждой ставки {house_edge}%
              забирает NT, {jackpot_share}% идёт в джекпот, {bank_share}% - в
              банк. Выигрыш не больше банка.
            </Box>
          </Stack.Item>

          {/* Bonus indicator */}
          {!!bonus_active && !working && (
            <Stack.Item>
              <div className="SlotMachine__bonus-banner">
                ⚡ БОНУС x{bonus_multiplier}! ⚡
              </div>
            </Stack.Item>
          )}

          {/* Win streak indicator */}
          {win_streak >= 2 && (
            <Stack.Item>
              <div className="SlotMachine__streak-banner">
                🔥 Серия побед: {win_streak}!
              </div>
            </Stack.Item>
          )}

          {/* Reels */}
          <Stack.Item>
            <Section>
              <div className="SlotMachine__machine">
                <div className="SlotMachine__reels-container">
                  {/* Payline indicators (left side) */}
                  <div className="SlotMachine__payline-labels">
                    {PAYLINE_DEFS.slice(0, active_lines || 1).map((_, idx) => (
                      <div
                        key={idx}
                        className={
                          'SlotMachine__payline-label'
                          + (winning_line === (idx + 1) && !working
                            ? ' SlotMachine__payline-label--winning' : '')
                        }
                        style={{ 'color': PAYLINE_COLORS[idx] }}>
                        L{idx + 1}
                      </div>
                    ))}
                  </div>
                  <div className="SlotMachine__reels">
                    {reels && reels.map((reel, i) => (
                      <SlotReel
                        key={i}
                        symbols={reel.symbols}
                        spinning={working}
                        stopped={reel.stopped}
                        reelIndex={i}
                      />
                    ))}
                  </div>
                  {/* Payline overlay when not spinning */}
                  {!working && !!winning_line && (
                    <div className="SlotMachine__payline-overlay">
                      {PAYLINE_DEFS[winning_line - 1] && (
                        <svg
                          className="SlotMachine__payline-svg"
                          viewBox="0 0 340 150"
                          preserveAspectRatio="none">
                          <polyline
                            points={
                              PAYLINE_DEFS[winning_line - 1]
                                .map((row, col) =>
                                  ((col * 66) + 33) + ',' + ((row * 50) + 25)
                                )
                                .join(' ')
                            }
                            stroke={PAYLINE_COLORS[winning_line - 1]}
                            strokeWidth="3"
                            fill="none"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            opacity="0.8"
                          />
                        </svg>
                      )}
                    </div>
                  )}
                  <div className="SlotMachine__payline" />
                </div>

                {/* Result message */}
                {result_message && !working && (
                  <div className={
                    'SlotMachine__result SlotMachine__result--' + (result_type || 'lose')
                  }>
                    {result_message}
                  </div>
                )}
              </div>
            </Section>
          </Stack.Item>

          {/* Near-miss indicator */}
          {!!near_miss && !working && (
            <Stack.Item>
              <div className="SlotMachine__near-miss">
                😱 {near_miss_message}
              </div>
            </Stack.Item>
          )}

          {/* Free spins indicator */}
          {free_spins_remaining > 0 && (
            <Stack.Item>
              <div style={{
                textAlign: 'center',
                'padding': '6px',
                'background': 'rgba(0,200,0,0.15)',
                'border': '1px solid rgba(0,200,0,0.4)',
                borderRadius: '4px',
                'color': '#4f4',
                fontWeight: 'bold',
                fontSize: '14px',
              }}>
                🎰 Бесплатных вращений: {free_spins_remaining}
              </div>
            </Stack.Item>
          )}

          {/* Hot machine indicator */}
          {loss_streak >= 5 && !working && (
            <Stack.Item>
              <div style={{
                textAlign: 'center',
                'padding': '4px',
                'background': 'rgba(255,100,0,0.15)',
                'border': '1px solid rgba(255,100,0,0.4)',
                borderRadius: '4px',
                'color': '#fa3',
                fontSize: '12px',
              }}>
                🔥 Автомат разогрет: {loss_streak} проигрышей подряд, шанс бонуса выше!
              </div>
            </Stack.Item>
          )}

          {/* Gamble (Double or Nothing) */}
          {!!gamble_available && !working && (
            <Stack.Item>
              <Section
                title={'🎲 Удвоить ' + gamble_amount + ' кр.?'}
                className="SlotMachine__gamble">
                <Stack align="center" justify="center">
                  <Stack.Item grow>
                    <Button
                      fluid
                      bold
                      textAlign="center"
                      fontSize="14px"
                      color="red"
                      className="SlotMachine__gamble-btn--red"
                      onClick={() => act('gamble', { choice: 'red' })}>
                      ♥ КРАСНОЕ
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Box bold textAlign="center" px="8px" color="label">
                      или
                    </Box>
                  </Stack.Item>
                  <Stack.Item grow>
                    <Button
                      fluid
                      bold
                      textAlign="center"
                      fontSize="14px"
                      className="SlotMachine__gamble-btn--black"
                      onClick={() => act('gamble', { choice: 'black' })}>
                      ♠ ЧЁРНОЕ
                    </Button>
                  </Stack.Item>
                  <Stack.Item>
                    <Box px="4px" />
                  </Stack.Item>
                  <Stack.Item grow>
                    <Button
                      fluid
                      bold
                      textAlign="center"
                      color="green"
                      onClick={() => act('collect')}>
                      💰 Забрать
                    </Button>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          )}

          {/* Bet Selection */}
          <Stack.Item>
            <Section title="Ставка">
              <Stack align="center">
                {BET_OPTIONS.map((amount) => (
                  <Stack.Item key={amount} grow>
                    <Button
                      fluid
                      bold
                      textAlign="center"
                      selected={bet_amount === amount}
                      disabled={working}
                      color={bet_amount === amount ? 'green' : 'default'}
                      onClick={() => act('set_bet', { amount })}>
                      {amount} кр.
                      <br />
                      <span style={{ fontSize: '9px', 'opacity': 0.7 }}>
                        линий: {BET_LINES[amount] || 1}
                      </span>
                    </Button>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>

          {/* Controls */}
          <Stack.Item>
            <Section>
              <Stack>
                {/* Balance */}
                <Stack.Item grow basis={0}>
                  <Box color="label" fontSize="11px">Баланс</Box>
                  <Box fontSize="16px" bold color="good">
                    💵 <AnimatedNumber value={balance} /> кр.
                  </Box>
                  {session_winnings !== 0 && (
                    <Box
                      fontSize="11px"
                      color={session_winnings > 0 ? 'good' : 'bad'}>
                      За сессию: {session_winnings > 0 ? '+' : ''}{session_winnings} кр.
                    </Box>
                  )}
                  <Box color="label" fontSize="10px" mt="4px">
                    С карты (до {deposit_max} кр.):
                  </Box>
                  <Stack>
                    {DEPOSIT_OPTIONS.map((amount) => (
                      <Stack.Item key={amount}>
                        <Button
                          disabled={working}
                          tooltip={'Внести ' + amount + ' кр. с ID-карты'}
                          onClick={() => act('card_deposit', { amount })}>
                          {amount}
                        </Button>
                      </Stack.Item>
                    ))}
                  </Stack>
                </Stack.Item>

                {/* Spin Button */}
                <Stack.Item grow basis={0}>
                  <Stack vertical align="center">
                    <Stack.Item>
                      <Button
                        fluid
                        bold
                        textAlign="center"
                        icon={working ? 'spinner' : 'play'}
                        disabled={working || balance < bet_amount}
                        color={working ? 'grey' : 'green'}
                        fontSize="18px"
                        className="SlotMachine__spin-button"
                        onClick={() => act('spin')}>
                        {working
                          ? (auto_spin ? 'АВТО...' : 'КРУТИТСЯ...')
                          : (free_spins_remaining > 0
                            ? ('🎰 БЕСПЛАТНО!')
                            : ('КРУТИТЬ ' + bet_amount + ' кр.'))}
                      </Button>
                    </Stack.Item>
                    <Stack.Item>
                      <Stack>
                        {auto_spin ? (
                          <Stack.Item grow>
                            <Button
                              fluid
                              textAlign="center"
                              icon="stop"
                              color="bad"
                              onClick={() => act('stop_auto')}>
                              Стоп ({auto_spin_remaining})
                            </Button>
                          </Stack.Item>
                        ) : (
                          AUTO_SPIN_OPTIONS.map((count) => (
                            <Stack.Item key={count}>
                              <Button
                                icon="redo"
                                disabled={working || balance < bet_amount}
                                tooltip={'Автовращение ' + count + ' раз'}
                                onClick={() => act('auto_spin', { count })}>
                                x{count}
                              </Button>
                            </Stack.Item>
                          ))
                        )}
                      </Stack>
                    </Stack.Item>
                    {balance > 0 && !working && !auto_spin && (
                      <Stack.Item>
                        <Button
                          fluid
                          textAlign="center"
                          icon="eject"
                          color="caution"
                          onClick={() => act('refund')}>
                          Забрать деньги
                        </Button>
                      </Stack.Item>
                    )}
                  </Stack>
                </Stack.Item>

                {/* Stats */}
                <Stack.Item grow basis={0}>
                  <Box color="label" fontSize="11px" textAlign="right">
                    Статистика
                  </Box>
                  <Box fontSize="11px" textAlign="right">
                    🎲 Вращений: {plays}
                  </Box>
                  <Box fontSize="11px" textAlign="right">
                    🏆 Джекпотов: {jackpots}
                  </Box>
                  {win_streak > 0 && (
                    <Box fontSize="11px" textAlign="right" color="good">
                      🔥 Серия: {win_streak}
                    </Box>
                  )}
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          {/* Spin History */}
          {spin_history && spin_history.length > 0 && (
            <Stack.Item>
              <Section title="Последние вращения">
                <Stack>
                  {spin_history.slice().reverse().map((entry, i) => (
                    <Stack.Item key={i} grow basis={0}>
                      <div className={
                        'SlotMachine__history-item SlotMachine__history-item--'
                        + (entry.result || 'lose')
                      }>
                        <div className="SlotMachine__history-icon">
                          {getResultIcon(entry.result)}
                        </div>
                        <div className="SlotMachine__history-amount">
                          {entry.won > 0 ? ('+' + entry.won) : entry.bet}
                        </div>
                      </div>
                    </Stack.Item>
                  ))}
                </Stack>
              </Section>
            </Stack.Item>
          )}

          {/* Paytable */}
          <Stack.Item>
            <Section title="Выигрыши">
              <Stack fill>
                <Stack.Item grow basis={0}>
                  <Box className="SlotMachine__paytable-row">
                    <span className="SlotMachine__paytable-symbols">
                      {jackpot_sevens}× 💰/🃏 в центре
                    </span>
                    <span className="SlotMachine__paytable-prize SlotMachine__paytable-prize--jackpot">
                      ДЖЕКПОТ
                    </span>
                  </Box>
                  <Box className="SlotMachine__paytable-row">
                    <span className="SlotMachine__paytable-symbols">
                      5 в линию
                    </span>
                    <span className="SlotMachine__paytable-prize">
                      {prize_big} кр.
                    </span>
                  </Box>
                  <Box className="SlotMachine__paytable-row">
                    <span className="SlotMachine__paytable-symbols">
                      4 в линию
                    </span>
                    <span className="SlotMachine__paytable-prize">
                      {prize_small} кр.
                    </span>
                  </Box>
                  <Box className="SlotMachine__paytable-row">
                    <span className="SlotMachine__paytable-symbols">
                      3 в линию
                    </span>
                    <span className="SlotMachine__paytable-prize">
                      1-3 бесплатных
                    </span>
                  </Box>
                </Stack.Item>
                <Stack.Item grow basis={0}>
                  <Box className="SlotMachine__paytable-row">
                    <span className="SlotMachine__paytable-symbols">
                      🃏 Джокер
                    </span>
                    <span className="SlotMachine__paytable-prize SlotMachine__paytable-prize--wild">
                      = любой символ
                    </span>
                  </Box>
                  <Box className="SlotMachine__paytable-row">
                    <span className="SlotMachine__paytable-symbols">
                      💫 Скаттер ×3+
                    </span>
                    <span className="SlotMachine__paytable-prize SlotMachine__paytable-prize--bonus">
                      Выплата за каждый
                    </span>
                  </Box>
                  <Divider />
                  <Box className="SlotMachine__paytable-row">
                    <span className="SlotMachine__paytable-symbols">
                      ⚡ Бонус
                    </span>
                    <span className="SlotMachine__paytable-prize SlotMachine__paytable-prize--bonus">
                      x2-x5
                    </span>
                  </Box>
                  <Box fontSize="10px" color="label" mt="2px">
                    2+ одинаковых - шанс бонуса
                  </Box>
                  <Divider />
                  <Box fontSize="10px" color="label">
                    <b>Линии:</b> 5 кр.=1 | 10 кр.=2 | 25 кр.+=3
                  </Box>
                  <Box fontSize="9px" color="label">
                    <span style={{ 'color': '#ffd700' }}>L1</span> центр{' '}
                    <span style={{ 'color': '#ff4444' }}>L2</span> верх{' '}
                    <span style={{ 'color': '#4488ff' }}>L3</span> низ{' '}
                    <span style={{ 'color': '#00ff88' }}>L4</span> V{' '}
                    <span style={{ 'color': '#ff6eff' }}>L5</span> ^
                  </Box>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
