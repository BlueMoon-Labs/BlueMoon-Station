import { Component } from 'inferno';
import { useBackend } from '../backend';
import { Button } from '../components';
import { NtosWindow } from '../layouts';

const SNAKE_DIR_UP = 1;
const SNAKE_DIR_DOWN = 2;
const SNAKE_DIR_LEFT = 3;
const SNAKE_DIR_RIGHT = 4;

class SnakeGame extends Component {
  constructor(props) {
    super(props);
    this._keyHandler = this._keyHandler.bind(this);
  }

  componentDidMount() {
    document.addEventListener('keydown', this._keyHandler);
  }

  componentWillUnmount() {
    document.removeEventListener('keydown', this._keyHandler);
  }

  _keyHandler(e) {
    const { act, game_active, paused } = this.props;
    const key = e.key;

    if (key === 'Enter' && !game_active) {
      act('start');
      e.preventDefault();
      return;
    }

    if (key === ' ' && game_active) {
      act('pause');
      e.preventDefault();
      return;
    }

    if (!game_active || paused) {
      return;
    }

    switch (key) {
      case 'ArrowUp':
      case 'w':
      case 'W':
        act('dir', { dir: SNAKE_DIR_UP });
        e.preventDefault();
        break;
      case 'ArrowDown':
      case 's':
      case 'S':
        act('dir', { dir: SNAKE_DIR_DOWN });
        e.preventDefault();
        break;
      case 'ArrowLeft':
      case 'a':
      case 'A':
        act('dir', { dir: SNAKE_DIR_LEFT });
        e.preventDefault();
        break;
      case 'ArrowRight':
      case 'd':
      case 'D':
        act('dir', { dir: SNAKE_DIR_RIGHT });
        e.preventDefault();
        break;
    }
  }

  render() {
    const {
      act,
      game_active = false,
      paused = false,
      score = 0,
      high_score = 0,
      death_reason = '',
      grid_w = 20,
      grid_h = 15,
      body = [],
      food = {},
    } = this.props;

    const bodySet = new Set();
    body.forEach((seg) => bodySet.add(seg.x + ',' + seg.y));
    const headSeg = body.length > 0 ? body[body.length - 1] : null;
    const headKey = headSeg ? headSeg.x + ',' + headSeg.y : null;

    const rows = [];
    for (let y = 1; y <= grid_h; y++) {
      const cells = [];
      for (let x = 1; x <= grid_w; x++) {
        const key = x + ',' + y;
        let cls = 'NtosSnake__cell';
        if (key === headKey) {
          cls += ' NtosSnake__cell--head';
        } else if (bodySet.has(key)) {
          cls += ' NtosSnake__cell--body';
        } else if (food && food.x === x && food.y === y) {
          cls += ' NtosSnake__cell--food';
        }
        cells.push(<div key={key} className={cls} />);
      }
      rows.push(
        <div key={'row' + y} className="NtosSnake__row">
          {cells}
        </div>
      );
    }

    return (
      <div className="NtosSnake">
        <div className="NtosSnake__header">
          <span className="NtosSnake__title">
            {'🐍 Змейка'}
          </span>
          <span className="NtosSnake__score">
            {'Счёт: '}
            <b>{score}</b>
            {high_score > 0 && (
              <span className="NtosSnake__highscore">
                {' | Рекорд: ' + high_score}
              </span>
            )}
          </span>
        </div>

        <div className="NtosSnake__field-wrap">
          <div className="NtosSnake__field">
            {rows}
          </div>

          {!!game_active && !!paused && (
            <div className="NtosSnake__overlay">
              <div className="NtosSnake__overlay-text">{'⏸ ПАУЗА'}</div>
            </div>
          )}

          {!game_active && !!death_reason && (
            <div className="NtosSnake__overlay NtosSnake__overlay--dead">
              <div className="NtosSnake__overlay-text">{'💀 ИГРА ОКОНЧЕНА'}</div>
              <div className="NtosSnake__overlay-reason">{death_reason}</div>
              <div className="NtosSnake__overlay-score">{'Счёт: ' + score}</div>
            </div>
          )}

          {!game_active && !death_reason && (
            <div className="NtosSnake__overlay">
              <div className="NtosSnake__overlay-text">{'🐍 ЗМЕЙКА'}</div>
              <div className="NtosSnake__overlay-reason">
                {'Нажмите Enter чтобы начать'}
              </div>
            </div>
          )}
        </div>

        <div className="NtosSnake__controls">
          <div className="NtosSnake__action-btns">
            {!game_active ? (
              <Button
                className="NtosSnake__btn-start"
                onClick={() => act('start')}
                color="green"
                bold
                fluid>
                {death_reason ? '▶ Заново' : '▶ Старт'}
              </Button>
            ) : (
              <Button
                className="NtosSnake__btn-pause"
                onClick={() => act('pause')}
                color={paused ? 'green' : 'yellow'}
                fluid>
                {paused ? '▶ Продолжить' : '⏸ Пауза'}
              </Button>
            )}
          </div>
        </div>
      </div>
    );
  }
}

export const NtosSnake = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    game_active = false,
    paused = false,
    score = 0,
    high_score = 0,
    death_reason = '',
    grid_w = 20,
    grid_h = 15,
    body = [],
    food = {},
  } = data;

  return (
    <NtosWindow width={480} height={560}>
      <NtosWindow.Content>
        <SnakeGame
          act={act}
          game_active={game_active}
          paused={paused}
          score={score}
          high_score={high_score}
          death_reason={death_reason}
          grid_w={grid_w}
          grid_h={grid_h}
          body={body}
          food={food}
        />
      </NtosWindow.Content>
    </NtosWindow>
  );
};
