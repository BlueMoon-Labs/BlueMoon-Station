import { useState } from 'react';

import { useBackend } from '../backend';
import { Button } from '../components';
import { NtosWindow } from '../layouts';

// Цвета цифр (классический Сапёр)
const NUM_COLORS = {
  1: '#4444ff',
  2: '#008200',
  3: '#ff0000',
  4: '#000084',
  5: '#840000',
  6: '#008284',
  7: '#840084',
  8: '#757575',
};

export const NtosMinesweeper = (props) => {
  const { act, data } = useBackend();
  const {
    game_active = false,
    game_won = false,
    grid_w = 9,
    grid_h = 9,
    mine_count = 10,
    flags_placed = 0,
    difficulty = 'easy',
    elapsed = 0,
    grid = [],
  } = data;

  const [flagMode, setFlagMode] = useState(false);
  const hasGame = grid.length > 0;

  const minutes = Math.floor(elapsed / 60);
  const seconds = elapsed % 60;
  const timeStr =
    String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');

  // Размер окна по сложности
  const winW = Math.max(380, grid_w * 32 + 80);
  const winH = Math.max(480, grid_h * 32 + 240);

  // Рендерим строки поля
  const fieldRows = [];
  if (hasGame) {
    for (let yi = 0; yi < grid.length; yi++) {
      const row = grid[yi];
      const cells = [];
      for (let xi = 0; xi < row.length; xi++) {
        const cell = row[xi];
        const x = xi + 1;
        const y = yi + 1;
        const key = x + ',' + y;

        if (cell === 'H') {
          cells.push(
            <div
              key={key}
              className="NtosMinesweeper__cell NtosMinesweeper__cell--hidden"
              onClick={() =>
                flagMode
                  ? act('flag', { x: x, y: y })
                  : act('reveal', { x: x, y: y })
              }
              onContextMenu={(e) => {
                e.preventDefault();
                act('flag', { x: x, y: y });
              }}
            />
          );
        } else if (cell === 'F') {
          cells.push(
            <div
              key={key}
              className="NtosMinesweeper__cell NtosMinesweeper__cell--flagged"
              onClick={() => flagMode ? act('flag', { x: x, y: y }) : null}
              onContextMenu={(e) => {
                e.preventDefault();
                act('flag', { x: x, y: y });
              }}>
              {'🚩'}
            </div>
          );
        } else if (cell === -1) {
          cells.push(
            <div
              key={key}
              className="NtosMinesweeper__cell NtosMinesweeper__cell--mine">
              {'💣'}
            </div>
          );
        } else {
          cells.push(
            <div
              key={key}
              className="NtosMinesweeper__cell NtosMinesweeper__cell--revealed"
              onClick={() => act('chord', { x: x, y: y })}>
              {cell > 0 ? (
                <span className={'NtosMinesweeper__num NtosMinesweeper__num--n' + cell}>
                  {cell}
                </span>
              ) : (
                ''
              )}
            </div>
          );
        }
      }
      fieldRows.push(
        <div key={'row' + yi} className="NtosMinesweeper__row">
          {cells}
        </div>
      );
    }
  }

  return (
    <NtosWindow width={winW} height={winH}>
      <NtosWindow.Content>
        <div className="NtosMinesweeper">
          {/* Toolbar */}
          <div className="NtosMinesweeper__toolbar">
            <div className="NtosMinesweeper__mines-counter">
              {'💣 ' + (mine_count - flags_placed)}
            </div>
            <div className="NtosMinesweeper__face">
              {!hasGame
                ? '🙂'
                : game_won
                  ? '😎'
                  : !game_active
                    ? '💀'
                    : '🙂'}
            </div>
            <div className="NtosMinesweeper__timer">
              {'⏱ ' + timeStr}
            </div>
          </div>

          {/* Переключатель режима */}
          {!!game_active && (
            <Button
              onClick={() => setFlagMode(!flagMode)}
              color={flagMode ? 'orange' : ''}
              bold
              fluid
              textAlign="center">
              {flagMode
                ? '🚩 Режим: ФЛАЖОК (ЛКМ ставит флажки)'
                : '⛏ Режим: КОПАНИЕ (ЛКМ открывает клетки)'}
            </Button>
          )}

          {/* Меню / результат */}
          {(!hasGame || !game_active) && (
            <div className="NtosMinesweeper__menu">
              {!game_active && hasGame && (
                <div
                  className={
                    'NtosMinesweeper__result' +
                    (game_won
                      ? ' NtosMinesweeper__result--win'
                      : ' NtosMinesweeper__result--lose')
                  }>
                  {game_won
                    ? '🎉 Победа! Время: ' + timeStr
                    : '💥 Подорвались!'}
                </div>
              )}
              <div className="NtosMinesweeper__diff-btns">
                <Button
                  onClick={() => act('start', { difficulty: 'easy' })}
                  color={difficulty === 'easy' ? 'green' : ''}
                  bold>
                  {'😊 Лёгкий (9×9)'}
                </Button>
                <Button
                  onClick={() => act('start', { difficulty: 'medium' })}
                  color={difficulty === 'medium' ? 'yellow' : ''}
                  bold>
                  {'😐 Средний (16×16)'}
                </Button>
                <Button
                  onClick={() => act('start', { difficulty: 'hard' })}
                  color={difficulty === 'hard' ? 'red' : ''}
                  bold>
                  {'💀 Сложный (20×14)'}
                </Button>
              </div>
            </div>
          )}

          {/* Поле */}
          {hasGame && (
            <div className="NtosMinesweeper__field-wrap">
              <div className="NtosMinesweeper__field">{fieldRows}</div>
            </div>
          )}

          {/* Подсказка */}
          <div className="NtosMinesweeper__hint">
            {'ЛКМ — открыть | ПКМ — флажок | Кнопка — переключить режим'}
          </div>
        </div>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
