/**
 * @file
 * Search bar for the chat panel.
 * Rendered outside the scrollable area so it stays visible.
 */

import { Component } from 'inferno';
import { Button, Input } from 'tgui/components';

import { chatRenderer } from './renderer';

const debounce = (fn, delay) => {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), delay);
  };
};

export class ChatSearchBar extends Component {
  constructor() {
    super();
    this.state = {
      query: '',
      total: 0,
      current: -1,
    };
    this._handleKeyDown = e => {
      if (e.key === 'Escape') {
        this.props.onClose();
      }
    };
    this._debouncedSearch = debounce(query => {
      const result = chatRenderer.searchMessages(query);
      this.setState({
        total: result.total,
        current: result.current,
      });
    }, 300);
  }

  componentDidMount() {
    document.addEventListener('keydown', this._handleKeyDown);
  }

  componentWillUnmount() {
    document.removeEventListener('keydown', this._handleKeyDown);
    chatRenderer.clearSearch();
  }

  _onInput(value) {
    this.setState({ query: value });
    this._debouncedSearch(value);
  }

  _next() {
    const result = chatRenderer.searchNext();
    this.setState({ total: result.total, current: result.current });
  }

  _prev() {
    const result = chatRenderer.searchPrev();
    this.setState({ total: result.total, current: result.current });
  }

  render() {
    const { query, total, current } = this.state;
    return (
      <div className="Chat__searchBar">
        <Input
          autoFocus
          placeholder={'Поиск...'}
          value={query}
          onInput={(e, value) => this._onInput(value)}
          onKeyDown={e => {
            if (e.key === 'Enter') {
              if (e.shiftKey) {
                this._prev();
              }
              else {
                this._next();
              }
            }
          }}
        />
        <span className="Chat__searchCount">
          {total > 0
            ? (current + 1) + ' / ' + total
            : '—'}
        </span>
        <Button
          icon="arrow-up"
          tooltip={'Назад (Shift+Enter)'}
          onClick={() => this._prev()}
        />
        <Button
          icon="arrow-down"
          tooltip={'Дальше (Enter)'}
          onClick={() => this._next()}
        />
        <Button
          icon="times"
          tooltip={'Закрыть (Esc)'}
          onClick={() => this.props.onClose()}
        />
      </div>
    );
  }
}
