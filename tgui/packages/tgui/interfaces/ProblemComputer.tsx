import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Flex, Icon, Input, NoticeBox, ProgressBar, Section, Stack } from '../components';
import { Window } from '../layouts';

// Types
type ProblemComputerData = {
  screen: string;
  currentGame: string | null;
  difficulty: string | null;
  rewardType: string | null;
  charges: number;
  maxCharges: number;
  lastResult: string | null;
  lastPoints: number;
  lastMessage: string;
  gameData: GameData | null;
};

type GameData = {
  question?: string;
  gridSize?: number;
  pairs?: WirePair[];
  sequence?: number[];
  hint?: string;
};

type WirePair = {
  color: string;
  id: number;
  start: { x: number; y: number };
  end: { x: number; y: number };
};

// Game Definitions
const GAMES = [
  {
    id: 'math',
    name: 'Математика',
    icon: 'calculator',
    description: 'Решайте математические задачи разной сложности',
    color: '#3498db',
  },
  {
    id: 'wires',
    name: 'Провода',
    icon: 'plug',
    description: 'Соедините пары контактов одного цвета',
    color: '#e74c3c',
  },
  {
    id: 'signal',
    name: 'Дешифровка',
    icon: 'wave-square',
    description: 'Найдите следующее число в последовательности',
    color: '#9b59b6',
  },
];

const DIFFICULTIES = [
  { id: 'Easy', name: 'Лёгкая', color: 'green', icon: 'star' },
  { id: 'Medium', name: 'Средняя', color: 'orange', icon: 'star-half-alt' },
  { id: 'Hard', name: 'Сложная', color: 'red', icon: 'fire' },
];

// Wire color mapping to CSS
const WIRE_CSS_COLORS: Record<string, string> = {
  red: '#e74c3c',
  blue: '#3498db',
  green: '#2ecc71',
  yellow: '#f1c40f',
  purple: '#9b59b6',
  orange: '#e67e22',
  cyan: '#1abc9c',
};

// Shuffle helper
function shuffleArray<T>(arr: T[]): T[] {
  const result = [...arr];
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
  }
  return result;
}

// ============================================
// Main Component
// ============================================
export const ProblemComputer = (props) => {
  const { data } = useBackend<ProblemComputerData>();
  const { screen } = data;

  return (
    <Window width={580} height={640} title="Problem Computer">
      <Window.Content scrollable>
        <Stack vertical fill>
          <Stack.Item>
            <ChargeBar />
          </Stack.Item>
          <Stack.Item grow>
            {screen === 'menu' && <MenuScreen />}
            {screen === 'game' && <GameScreen />}
            {screen === 'result' && <ResultScreen />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

// ============================================
// Charge Bar
// ============================================
const ChargeBar = (props) => {
  const { data } = useBackend<ProblemComputerData>();
  const { charges, maxCharges, rewardType } = data;

  return (
    <Section>
      <Stack align="center">
        <Stack.Item grow>
          <ProgressBar
            value={charges}
            maxValue={maxCharges}
            color={charges > 0 ? 'good' : 'bad'}>
            <Box inline>
              <Icon name="bolt" mr={1} />
              Задачи: {charges} / {maxCharges}
            </Box>
          </ProgressBar>
        </Stack.Item>
        {rewardType && (
          <Stack.Item ml={1}>
            <Box
              inline
              px={1}
              py={0.5}
              backgroundColor={rewardType === 'Science' ? '#8e44ad' : '#d35400'}
              color="white"
              style={{ borderRadius: '4px' }}>
              <Icon
                name={rewardType === 'Science' ? 'flask' : 'boxes'}
                mr={1}
              />
              {rewardType === 'Science' ? 'Наука' : 'Карго'}
            </Box>
          </Stack.Item>
        )}
      </Stack>
    </Section>
  );
};

// Menu Screen
const MenuScreen = (props) => {
  const { act } = useBackend<ProblemComputerData>();
  const [selectedGame, setSelectedGame] = useState<string | null>(null);

  return (
    <Section title="Выберите мини-игру" fill>
      <Stack vertical>
        <Stack.Item>
          <Flex wrap="wrap" justify="center">
            {GAMES.map((game) => (
              <Flex.Item key={game.id} basis="46%" m={0.5}>
                <Button
                  fluid
                  selected={selectedGame === game.id}
                  onClick={() => setSelectedGame(game.id)}
                  style={{
                    'border': selectedGame === game.id
                      ? '2px solid ' + game.color
                      : '2px solid rgba(255,255,255,0.1)',
                    borderRadius: '8px',
                    'padding': '10px',
                    textAlign: 'center',
                    minHeight: '90px',
                    backgroundColor: selectedGame === game.id
                      ? game.color + '33'
                      : 'rgba(255,255,255,0.05)',
                  }}>
                  <Stack vertical align="center">
                    <Stack.Item>
                      <Icon name={game.icon} size={2} color={game.color} />
                    </Stack.Item>
                    <Stack.Item mt={0.5}>
                      <Box bold fontSize={1.05}>{game.name}</Box>
                    </Stack.Item>
                    <Stack.Item>
                      <Box color="label" fontSize={0.8}>
                        {game.description}
                      </Box>
                    </Stack.Item>
                  </Stack>
                </Button>
              </Flex.Item>
            ))}
          </Flex>
        </Stack.Item>
        {selectedGame && (
          <Stack.Item mt={1}>
            <Section title="Выберите сложность">
              <Flex justify="center">
                {DIFFICULTIES.map((diff) => (
                  <Flex.Item key={diff.id} mx={0.5}>
                    <Button
                      icon={diff.icon}
                      color={diff.color}
                      content={diff.name}
                      style={{
                        'padding': '8px 16px',
                        fontSize: '13px',
                        borderRadius: '6px',
                      }}
                      onClick={() =>
                        act('select_game', {
                          game: selectedGame,
                          difficulty: diff.id,
                        })
                      }
                    />
                  </Flex.Item>
                ))}
              </Flex>
            </Section>
          </Stack.Item>
        )}
      </Stack>
    </Section>
  );
};

// Game Screen
const GameScreen = (props) => {
  const { data, act } = useBackend<ProblemComputerData>();
  const { currentGame } = data;
  const diffLabel = data.difficulty === 'Easy'
    ? 'Лёгкая' : data.difficulty === 'Medium'
      ? 'Средняя' : 'Сложная';

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Button
          icon="arrow-left"
          content="Назад в меню"
          onClick={() => act('back_to_menu')}
        />
        <Box inline ml={1} bold>
          {GAMES.find((g) => g.id === currentGame)?.name || 'Игра'}
          {' — '}
          {diffLabel}
        </Box>
      </Stack.Item>
      <Stack.Item grow>
        {currentGame === 'math' && <MathGame />}
        {currentGame === 'wires' && <WireGame />}
        {currentGame === 'signal' && <SignalGame />}
      </Stack.Item>
    </Stack>
  );
};

// Math Game
const MathGame = (props) => {
  const { data, act } = useBackend<ProblemComputerData>();
  const [answer, setAnswer] = useState('');
  const gameData = data.gameData;

  if (!gameData) return <NoticeBox>Загрузка...</NoticeBox>;

  return (
    <Section
      title="Математическая задача"
      fill
      buttons={
        <Box inline color="label">
          <Icon name="calculator" mr={1} />
          Введите числовой ответ
        </Box>
      }>
      <Stack vertical align="center" justify="center" fill>
        <Stack.Item>
          <Box
            textAlign="center"
            fontSize={1.3}
            p={2}
            m={1}
            backgroundColor="rgba(0,0,0,0.3)"
            style={{
              borderRadius: '8px',
              'border': '1px solid rgba(52,152,219,0.5)',
            }}>
            {gameData.question}
          </Box>
        </Stack.Item>
        <Stack.Item mt={2}>
          <Stack align="center">
            <Stack.Item>
              <Input
                placeholder="Ваш ответ..."
                value={answer}
                onChange={(_, val) => setAnswer(val)}
                onEnter={() => {
                  act('submit_answer', { answer: answer });
                  setAnswer('');
                }}
                style={{
                  fontSize: '18px',
                  'width': '200px',
                  textAlign: 'center',
                }}
              />
            </Stack.Item>
            <Stack.Item ml={1}>
              <Button
                icon="check"
                color="good"
                content="Ответить"
                onClick={() => {
                  act('submit_answer', { answer: answer });
                  setAnswer('');
                }}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

let _wireCache: { key: string; left: number[]; right: number[] } | null = null;

// Wire Connect
const WireGame = (props) => {
  const { data, act } = useBackend<ProblemComputerData>();
  const gameData = data.gameData;

  const [connections, setConnections] = useState<Record<number, boolean>>({});
  const [selectedSide, setSelectedSide] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<number | null>(null);

  if (!gameData || !gameData.pairs || !Array.isArray(gameData.pairs)) {
    return <NoticeBox>Загрузка...</NoticeBox>;
  }

  const pairs = gameData.pairs;
  const pairsKey = pairs.map((p) => p.id + ':' + p.color).join('|');

  if (!_wireCache || _wireCache.key !== pairsKey) {
    const ids = pairs.map((p) => p.id);
    _wireCache = { key: pairsKey, left: shuffleArray(ids), right: shuffleArray(ids) };
  }
  const leftOrder = _wireCache.left;
  const rightOrder = _wireCache.right;

  const totalConnected = Object.keys(connections).length;
  const allConnected = totalConnected === pairs.length;

  const tryConnect = (side: string, pairId: number) => {
    if (connections[pairId]) return;
    if (selectedSide === null || selectedId === null) {
      setSelectedSide(side);
      setSelectedId(pairId);
      return;
    }
    // Clicking the same side — just re-select
    if (selectedSide === side) {
      setSelectedSide(side);
      setSelectedId(pairId);
      return;
    }
    // Different sides — check if same pair
    if (selectedId === pairId) {
      const newConn = { ...connections };
      newConn[pairId] = true;
      setConnections(newConn);
    }
    setSelectedSide(null);
    setSelectedId(null);
  };

  const handleSubmit = () => {
    const connList = pairs
      .filter((p) => connections[p.id])
      .map((p) => ({ id: p.id }));
    act('submit_answer', { connections: connList });
    setConnections({});
    setSelectedSide(null);
    setSelectedId(null);
    _wireCache = null;
  };

  const handleReset = () => {
    setConnections({});
    setSelectedSide(null);
    setSelectedId(null);
  };

  const nodeH = 40;
  const gap = 6;
  const pairById = (id: number) => pairs.find((p) => p.id === id);

  const renderNode = (
    id: number,
    side: string,
    align: string,
  ) => {
    const pair = pairById(id);
    if (!pair) return null;
    const connected = connections[id];
    const active = selectedSide === side && selectedId === id;
    const clr = WIRE_CSS_COLORS[pair.color] || '#888';
    return (
      <Box
        key={side + id}
        onClick={() => tryConnect(side, id)}
        mb={gap + 'px'}
        style={{
          'width': '110px',
          'height': nodeH + 'px',
          borderRadius: side === 'L' ? '6px 0 0 6px' : '0 6px 6px 0',
          'background': connected ? clr + '55' : active ? clr + 'CC' : clr + '44',
          'border': active ? '2px solid #fff' : '2px solid ' + clr,
          'cursor': connected ? 'default' : 'pointer',
          textAlign: align,
          lineHeight: nodeH + 'px',
          'padding': '0 10px',
          boxShadow: active ? '0 0 8px ' + clr : 'none',
        }}>
        {connected && <Icon name="check" color="white" />}
        <Box
          inline
          ml={connected ? '6px' : '0'}
          style={{
            'width': '14px',
            'height': '14px',
            borderRadius: '50%',
            'background': clr,
            'display': 'inline-block',
            verticalAlign: 'middle',
          }}
        />
      </Box>
    );
  };

  return (
    <Section
      title="Соедините провода"
      fill
      buttons={
        <Box inline color="label">
          Соединено: {totalConnected}/{pairs.length}
        </Box>
      }>
      <Stack vertical align="center" fill>
        <Stack.Item>
          <Box color="label" textAlign="center" mb={1}>
            Нажмите контакт слева, затем контакт того же цвета справа
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Flex justify="center">
            {/* Left column */}
            <Flex.Item>
              {leftOrder.map((id) => renderNode(id, 'L', 'right'))}
            </Flex.Item>
            {/* Center SVG lines */}
            <Flex.Item>
              <Box style={{
                'position': 'relative',
                'width': '60px',
                'height': pairs.length * (nodeH + gap) + 'px',
              }}>
                <svg
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%',
                  }}>
                  {pairs
                    .filter((p) => connections[p.id])
                    .map((p) => {
                      const li = leftOrder.indexOf(p.id);
                      const ri = rightOrder.indexOf(p.id);
                      const y1 = li * (nodeH + gap) + nodeH / 2;
                      const y2 = ri * (nodeH + gap) + nodeH / 2;
                      const c = WIRE_CSS_COLORS[p.color] || '#fff';
                      return (
                        <line
                          key={'ln' + p.id}
                          x1={0} y1={y1}
                          x2={60} y2={y2}
                          stroke={c}
                          strokeWidth="3"
                          opacity="0.9"
                        />
                      );
                    })}
                </svg>
              </Box>
            </Flex.Item>
            {/* Right column */}
            <Flex.Item>
              {rightOrder.map((id) => renderNode(id, 'R', 'left'))}
            </Flex.Item>
          </Flex>
        </Stack.Item>
        <Stack.Item mt={1}>
          <Button
            icon="check-double"
            color={allConnected ? 'good' : 'default'}
            disabled={!allConnected}
            content="Подтвердить"
            onClick={handleSubmit}
          />
          <Button
            icon="undo"
            color="caution"
            content="Сброс"
            ml={1}
            onClick={handleReset}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// Signal Decode Game
const SignalGame = (props) => {
  const { data, act } = useBackend<ProblemComputerData>();
  const gameData = data.gameData;
  const [answer, setAnswer] = useState('');

  if (!gameData || !gameData.sequence) {
    return <NoticeBox>Загрузка...</NoticeBox>;
  }

  const sequence = gameData.sequence;
  const hint = gameData.hint;

  return (
    <Section
      title="Дешифровка сигнала"
      fill
      buttons={
        <Box inline color="label">
          <Icon name="wave-square" mr={1} />
          Найдите закономерность
        </Box>
      }>
      <Stack vertical align="center" justify="center" fill>
        <Stack.Item>
          <Box color="label" textAlign="center" mb={1}>
            Найдите следующее число в последовательности:
          </Box>
        </Stack.Item>

        {/* Sequence Display */}
        <Stack.Item>
          <Flex justify="center" align="center" wrap="wrap">
            {sequence.map((num, i) => (
              <Flex.Item key={i}>
                <Flex align="center">
                  <Flex.Item>
                    <Box
                      inline
                      textAlign="center"
                      bold
                      style={{
                        minWidth: '50px',
                        'height': '50px',
                        lineHeight: '50px',
                        borderRadius: '8px',
                        fontSize: '20px',
                        backgroundColor: 'rgba(155,89,182,0.3)',
                        'border': '2px solid rgba(155,89,182,0.6)',
                        'padding': '0 8px',
                      }}>
                      {num}
                    </Box>
                  </Flex.Item>
                  {i < sequence.length - 1 && (
                    <Flex.Item mx={0.3}>
                      <Icon name="arrow-right" color="label" />
                    </Flex.Item>
                  )}
                </Flex>
              </Flex.Item>
            ))}
            {/* Question mark */}
            <Flex.Item>
              <Flex align="center">
                <Flex.Item mx={0.3}>
                  <Icon name="arrow-right" color="label" />
                </Flex.Item>
                <Flex.Item>
                  <Box
                    inline
                    textAlign="center"
                    bold
                    style={{
                      minWidth: '50px',
                      'height': '50px',
                      lineHeight: '50px',
                      borderRadius: '8px',
                      fontSize: '24px',
                      backgroundColor: 'rgba(231,76,60,0.3)',
                      'border': '2px dashed rgba(231,76,60,0.6)',
                      'padding': '0 8px',
                    }}>
                    ?
                  </Box>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </Stack.Item>

        {/* Hint */}
        {hint && (
          <Stack.Item mt={1}>
            <Box
              textAlign="center"
              color="label"
              italic
              style={{
                'padding': '6px 12px',
                backgroundColor: 'rgba(255,255,255,0.05)',
                borderRadius: '4px',
              }}>
              <Icon name="lightbulb" mr={1} />
              Подсказка: {hint}
            </Box>
          </Stack.Item>
        )}

        {/* Input */}
        <Stack.Item mt={2}>
          <Stack align="center">
            <Stack.Item>
              <Input
                placeholder="Ваш ответ..."
                value={answer}
                onChange={(_, val) => setAnswer(val)}
                onEnter={() => {
                  act('submit_answer', { answer: answer });
                  setAnswer('');
                }}
                style={{
                  fontSize: '18px',
                  'width': '200px',
                  textAlign: 'center',
                }}
              />
            </Stack.Item>
            <Stack.Item ml={1}>
              <Button
                icon="check"
                color="good"
                content="Ответить"
                style={{ fontSize: '14px', 'padding': '6px 16px' }}
                onClick={() => {
                  act('submit_answer', { answer: answer });
                  setAnswer('');
                }}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

// Result Screen
const ResultScreen = (props) => {
  const { data, act } = useBackend<ProblemComputerData>();
  const { lastResult, lastPoints, lastMessage } = data;
  const isCorrect = lastResult === 'correct';

  return (
    <Section fill>
      <Stack vertical align="center" justify="center" fill>
        <Stack.Item>
          <Icon
            name={isCorrect ? 'check-circle' : 'times-circle'}
            size={5}
            color={isCorrect ? 'good' : 'bad'}
          />
        </Stack.Item>
        <Stack.Item mt={1}>
          <Box
            bold
            fontSize={1.8}
            textAlign="center"
            color={isCorrect ? 'good' : 'bad'}>
            {isCorrect ? 'Верно!' : 'Неверно!'}
          </Box>
        </Stack.Item>
        <Stack.Item mt={1}>
          <Box
            textAlign="center"
            fontSize={1.1}
            p={1}
            style={{
              backgroundColor: isCorrect
                ? 'rgba(46,204,113,0.15)'
                : 'rgba(231,76,60,0.15)',
              borderRadius: '8px',
              'border': isCorrect
                ? '1px solid rgba(46,204,113,0.4)'
                : '1px solid rgba(231,76,60,0.4)',
              maxWidth: '400px',
            }}>
            {lastMessage}
          </Box>
        </Stack.Item>
        <Stack.Item mt={1}>
          <Box textAlign="center" bold fontSize={1.3}>
            {isCorrect ? '+' : '-'}{lastPoints} очков
          </Box>
        </Stack.Item>
        <Stack.Item mt={2}>
          <Button
            icon="redo"
            color="good"
            content="Играть ещё"
            style={{ fontSize: '14px', 'padding': '8px 20px' }}
            onClick={() => act('play_again')}
          />
          <Button
            icon="home"
            content="В меню"
            ml={1}
            style={{ fontSize: '14px', 'padding': '8px 20px' }}
            onClick={() => act('back_to_menu')}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};
