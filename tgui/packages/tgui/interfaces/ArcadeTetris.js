import { Component, createRef } from 'inferno';

import { useBackend } from '../backend';
import { Box, Button, Section, Stack } from '../components';
import { Window } from '../layouts';

// ---- Constants ----
const COLS = 10;
const ROWS = 20;
const CELL = 22; // px per cell
const PREVIEW_CELL = 16;

// Tetromino shapes (each rotation is a list of [row, col] offsets)
const SHAPES = {
  I: { color: '#00f0f0', cells: [[0, 0], [0, 1], [0, 2], [0, 3]] },
  O: { color: '#f0f000', cells: [[0, 0], [0, 1], [1, 0], [1, 1]] },
  T: { color: '#a000f0', cells: [[0, 0], [0, 1], [0, 2], [1, 1]] },
  S: { color: '#00f000', cells: [[0, 1], [0, 2], [1, 0], [1, 1]] },
  Z: { color: '#f00000', cells: [[0, 0], [0, 1], [1, 1], [1, 2]] },
  J: { color: '#0000f0', cells: [[0, 0], [1, 0], [1, 1], [1, 2]] },
  L: { color: '#f0a000', cells: [[0, 2], [1, 0], [1, 1], [1, 2]] },
};

const PIECE_NAMES = Object.keys(SHAPES);

// Delays per level (ms)
const DELAYS = [828, 620, 464, 348, 260, 196, 148, 112, 84, 64, 48, 36, 27];

// Rotate cells 90 degrees clockwise around center
const rotateCells = (cells) => {
  const cx = cells.reduce((s, c) => s + c[0], 0) / cells.length;
  const cy = cells.reduce((s, c) => s + c[1], 0) / cells.length;
  return cells.map(([r, c]) => {
    const nr = Math.round(cx + (c - cy));
    const nc = Math.round(cy - (r - cx));
    return [nr, nc];
  });
};

// ---- Tetris Game Engine (class component for imperative game loop) ----
class TetrisGame extends Component {
  constructor(props) {
    super(props);
    this.canvasRef = createRef();
    this.previewRef = createRef();
    this.state = {
      score: 0,
      level: 1,
      lines: 0,
      gameOver: false,
      paused: false,
      started: false,
    };
    this.board = [];
    this.colors = [];
    this.current = null;
    this.currentColor = null;
    this.currentCells = [];
    this.pos = { r: 0, c: 0 };
    this.nextPiece = null;
    this.timer = null;
    this._keyHandler = this._keyHandler.bind(this);
  }

  componentDidMount() {
    document.addEventListener('keydown', this._keyHandler);
  }

  componentWillUnmount() {
    document.removeEventListener('keydown', this._keyHandler);
    if (this.timer) clearTimeout(this.timer);
  }

  // Отправляет звуковой эффект на сервер
  sfx(type) {
    const { act } = this.props;
    act('sfx', { type });
  }

  _keyHandler(e) {
    if (!this.state.started || this.state.gameOver || this.state.paused) return;
    switch (e.keyCode) {
      case 37: // left
        if (this.move(0, -1)) this.sfx('move');
        e.preventDefault();
        break;
      case 39: // right
        if (this.move(0, 1)) this.sfx('move');
        e.preventDefault();
        break;
      case 40: // down (soft drop)
        this.move(1, 0);
        e.preventDefault();
        break;
      case 38: // up (rotate)
        this.rotate();
        e.preventDefault();
        break;
      case 32: // space (hard drop)
        this.hardDrop();
        e.preventDefault();
        break;
    }
  }

  initBoard() {
    this.board = Array.from({ length: ROWS }, () => Array(COLS).fill(0));
    this.colors = Array.from({ length: ROWS }, () => Array(COLS).fill(null));
  }

  newGame() {
    if (this.timer) clearTimeout(this.timer);
    this.initBoard();
    this.nextPiece = PIECE_NAMES[Math.floor(Math.random() * 7)];
    this.setState({ score: 0, level: 1, lines: 0, gameOver: false, paused: false, started: true }, () => {
      this.spawnPiece();
      this.drawPreview();
      this.tick();
      // Запускаем фоновую музыку
      const { act } = this.props;
      act('music_start');
    });
  }

  spawnPiece() {
    const name = this.nextPiece;
    this.nextPiece = PIECE_NAMES[Math.floor(Math.random() * 7)];
    const shape = SHAPES[name];
    this.currentColor = shape.color;
    this.currentCells = shape.cells.map(([r, c]) => [r, c]);
    this.pos = { r: 0, c: Math.floor((COLS - 3) / 2) };
    if (!this.isValid(this.currentCells, this.pos)) {
      this.setState({ gameOver: true });
      this.lockPiece();
      this.draw();
      this.drawPreview();
      // Game over — останавливаем музыку, играем звук, отправляем счёт
      const { act } = this.props;
      act('music_stop');
      this.sfx('game_over');
      act('submitScore', { score: this.state.score });
    }
  }

  isValid(cells, pos) {
    for (const [r, c] of cells) {
      const nr = r + pos.r;
      const nc = c + pos.c;
      if (nr < 0 || nr >= ROWS || nc < 0 || nc >= COLS) return false;
      if (this.board[nr][nc]) return false;
    }
    return true;
  }

  move(dr, dc) {
    const newPos = { r: this.pos.r + dr, c: this.pos.c + dc };
    if (this.isValid(this.currentCells, newPos)) {
      this.pos = newPos;
      this.draw();
      return true;
    }
    return false;
  }

  rotate() {
    const rotated = rotateCells(this.currentCells);
    if (this.isValid(rotated, this.pos)) {
      this.currentCells = rotated;
      this.draw();
      this.sfx('rotate');
      return;
    }
    // Wall kick: try shifting left/right
    for (const dc of [-1, 1, -2, 2]) {
      const kickPos = { r: this.pos.r, c: this.pos.c + dc };
      if (this.isValid(rotated, kickPos)) {
        this.currentCells = rotated;
        this.pos = kickPos;
        this.draw();
        this.sfx('rotate');
        return;
      }
    }
  }

  hardDrop() {
    while (this.move(1, 0)) { /* keep dropping */ }
    this.lockPiece();
    this.clearLines();
    this.draw();
    this.sfx('drop');
    this.spawnPiece();
    this.drawPreview();
  }

  lockPiece() {
    for (const [r, c] of this.currentCells) {
      const nr = r + this.pos.r;
      const nc = c + this.pos.c;
      if (nr >= 0 && nr < ROWS && nc >= 0 && nc < COLS) {
        this.board[nr][nc] = 1;
        this.colors[nr][nc] = this.currentColor;
      }
    }
  }

  clearLines() {
    let cleared = 0;
    for (let r = ROWS - 1; r >= 0; r--) {
      if (this.board[r].every(cell => cell === 1)) {
        this.board.splice(r, 1);
        this.colors.splice(r, 1);
        this.board.unshift(Array(COLS).fill(0));
        this.colors.unshift(Array(COLS).fill(null));
        cleared++;
        r++; // recheck row
      }
    }
    if (cleared > 0) {
      const points = [0, 100, 300, 500, 800];
      this.setState((prevState) => {
        const score = prevState.score + 20 + (points[cleared] || 800) * prevState.level;
        const lines = prevState.lines + cleared;
        const level = Math.min(12, Math.max(prevState.level, Math.floor(lines / 10) + 1));
        // Звук повышения уровня
        if (level > prevState.level) {
          this.sfx('level_up');
        }
        return { score, lines, level };
      });
      // Звук очистки линий (тетрис = 4 линии)
      if (cleared >= 4) {
        this.sfx('tetris');
      } else {
        this.sfx('line_clear');
      }
    } else {
      this.setState((prevState) => ({ score: prevState.score + 20 }));
    }
  }

  tick() {
    if (this.state.gameOver || this.state.paused) return;
    if (!this.move(1, 0)) {
      this.lockPiece();
      this.clearLines();
      this.draw();
      if (!this.state.gameOver) {
        this.spawnPiece();
        this.drawPreview();
      }
    }
    const delay = DELAYS[Math.min(this.state.level, DELAYS.length - 1)] || 27;
    this.timer = setTimeout(() => this.tick(), delay);
  }

  togglePause() {
    if (this.state.gameOver) return;
    this.setState((prevState) => ({ paused: !prevState.paused }), () => {
      if (!this.state.paused) {
        this.tick();
        const { act } = this.props;
        act('music_start');
      } else {
        const { act } = this.props;
        act('music_stop');
      }
    });
  }

  // ---- Canvas Drawing ----
  draw() {
    const canvas = this.canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    // Background
    ctx.fillStyle = '#1a1a2e';
    ctx.fillRect(0, 0, COLS * CELL, ROWS * CELL);

    // Grid lines
    ctx.strokeStyle = '#2a2a4a';
    ctx.lineWidth = 0.5;
    for (let r = 0; r <= ROWS; r++) {
      ctx.beginPath();
      ctx.moveTo(0, r * CELL);
      ctx.lineTo(COLS * CELL, r * CELL);
      ctx.stroke();
    }
    for (let c = 0; c <= COLS; c++) {
      ctx.beginPath();
      ctx.moveTo(c * CELL, 0);
      ctx.lineTo(c * CELL, ROWS * CELL);
      ctx.stroke();
    }

    // Locked blocks
    for (let r = 0; r < ROWS; r++) {
      for (let c = 0; c < COLS; c++) {
        if (this.board[r][c]) {
          this.drawBlock(ctx, c, r, this.colors[r][c], CELL);
        }
      }
    }

    // Ghost piece
    if (!this.state.gameOver && this.currentCells) {
      let ghostPos = { ...this.pos };
      while (this.isValid(this.currentCells, { r: ghostPos.r + 1, c: ghostPos.c })) {
        ghostPos.r++;
      }
      if (ghostPos.r !== this.pos.r) {
        ctx.globalAlpha = 0.25;
        for (const [r, c] of this.currentCells) {
          this.drawBlock(ctx, c + ghostPos.c, r + ghostPos.r, this.currentColor, CELL);
        }
        ctx.globalAlpha = 1.0;
      }
    }

    // Current piece
    if (!this.state.gameOver && this.currentCells) {
      for (const [r, c] of this.currentCells) {
        const nr = r + this.pos.r;
        const nc = c + this.pos.c;
        if (nr >= 0) {
          this.drawBlock(ctx, nc, nr, this.currentColor, CELL);
        }
      }
    }
  }

  drawBlock(ctx, x, y, color, size) {
    const px = x * size;
    const py = y * size;
    const pad = 1;
    ctx.fillStyle = color;
    ctx.fillRect(px + pad, py + pad, size - pad * 2, size - pad * 2);
    // Highlight
    ctx.fillStyle = 'rgba(255,255,255,0.2)';
    ctx.fillRect(px + pad, py + pad, size - pad * 2, 3);
    ctx.fillRect(px + pad, py + pad, 3, size - pad * 2);
    // Shadow
    ctx.fillStyle = 'rgba(0,0,0,0.3)';
    ctx.fillRect(px + pad, py + size - pad - 3, size - pad * 2, 3);
    ctx.fillRect(px + size - pad - 3, py + pad, 3, size - pad * 2);
  }

  drawPreview() {
    const canvas = this.previewRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#1a1a2e';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    if (!this.nextPiece) return;
    const shape = SHAPES[this.nextPiece];
    const cells = shape.cells;
    // Center in preview
    const minR = Math.min(...cells.map(c => c[0]));
    const maxR = Math.max(...cells.map(c => c[0]));
    const minC = Math.min(...cells.map(c => c[1]));
    const maxC = Math.max(...cells.map(c => c[1]));
    const h = maxR - minR + 1;
    const w = maxC - minC + 1;
    const offX = Math.floor((canvas.width - w * PREVIEW_CELL) / 2);
    const offY = Math.floor((canvas.height - h * PREVIEW_CELL) / 2);
    for (const [r, c] of cells) {
      const px = offX + (c - minC) * PREVIEW_CELL;
      const py = offY + (r - minR) * PREVIEW_CELL;
      ctx.fillStyle = shape.color;
      ctx.fillRect(px + 1, py + 1, PREVIEW_CELL - 2, PREVIEW_CELL - 2);
      ctx.fillStyle = 'rgba(255,255,255,0.2)';
      ctx.fillRect(px + 1, py + 1, PREVIEW_CELL - 2, 2);
    }
  }

  render() {
    const { score, level, lines, gameOver, paused, started } = this.state;

    return (
      <Stack fill>
        {/* Game board */}
        <Stack.Item>
          <Box className="ArcadeTetris__board-wrap">
            <canvas
              ref={this.canvasRef}
              width={COLS * CELL}
              height={ROWS * CELL}
              className="ArcadeTetris__canvas"
            />
            {gameOver && (
              <Box className="ArcadeTetris__overlay">
                <Box fontSize="20px" bold color="bad">
                  {'ИГРА ОКОНЧЕНА'}
                </Box>
                <Box mt={1} color="label">
                  {'Счёт: ' + score}
                </Box>
              </Box>
            )}
            {paused && (
              <Box className="ArcadeTetris__overlay">
                <Box fontSize="18px" bold color="average">
                  {'⏸ ПАУЗА'}
                </Box>
              </Box>
            )}
          </Box>
        </Stack.Item>

        {/* Side panel */}
        <Stack.Item grow>
          <Stack vertical fill className="ArcadeTetris__side">
            {/* Preview */}
            <Stack.Item>
              <Section title="Следующая">
                <Box textAlign="center">
                  <canvas
                    ref={this.previewRef}
                    width={80}
                    height={50}
                    className="ArcadeTetris__preview"
                  />
                </Box>
              </Section>
            </Stack.Item>

            {/* Статистика */}
            <Stack.Item>
              <Section title="Статистика">
                <Box className="ArcadeTetris__stat">
                  <Box color="label">{'Счёт'}</Box>
                  <Box bold fontSize="16px">{score}</Box>
                </Box>
                <Box className="ArcadeTetris__stat">
                  <Box color="label">{'Уровень'}</Box>
                  <Box bold fontSize="16px">{level}</Box>
                </Box>
                <Box className="ArcadeTetris__stat">
                  <Box color="label">{'Линии'}</Box>
                  <Box bold fontSize="16px">{lines}</Box>
                </Box>
              </Section>
            </Stack.Item>

            {/* Управление */}
            <Stack.Item>
              <Section title="Управление">
                <Stack vertical>
                  <Stack.Item>
                    <Button
                      fluid
                      icon="play"
                      color="good"
                      onClick={() => this.newGame()}>
                      {started ? 'Новая игра' : 'Старт'}
                    </Button>
                  </Stack.Item>
                  {started && !gameOver && (
                    <Stack.Item>
                      <Button
                        fluid
                        icon={paused ? 'play' : 'pause'}
                        color="caution"
                        onClick={() => this.togglePause()}>
                        {paused ? 'Продолжить' : 'Пауза'}
                      </Button>
                    </Stack.Item>
                  )}
                </Stack>
              </Section>
            </Stack.Item>

            {/* Подсказки */}
            <Stack.Item mt={1}>
              <Box color="label" fontSize="11px">
                <Box>{'← → Движение'}</Box>
                <Box>{'↑ Поворот'}</Box>
                <Box>{'↓ Мягкий сброс'}</Box>
                <Box>{'Пробел Жёсткий сброс'}</Box>
              </Box>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    );
  }
}

// ---- Main export ----
export const ArcadeTetris = (props, context) => {
  const { act } = useBackend(context);

  return (
    <Window title="T.E.T.R.I.S." width={400} height={520}>
      <Window.Content className="ArcadeTetris">
        <TetrisGame act={act} />
      </Window.Content>
    </Window>
  );
};
