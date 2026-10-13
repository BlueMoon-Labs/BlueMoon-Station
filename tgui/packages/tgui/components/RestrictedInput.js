import { KEY_ENTER, KEY_ESCAPE } from 'common/keycodes';
import { clamp } from 'common/math';
import { classes } from 'common/react';
import { Component, createRef } from 'react';

import { Box } from './Box';

const DEFAULT_MIN = 0;
const DEFAULT_MAX = 10000;

/**
 * Takes a string input and parses a number from it (floats supported).
 * If none: Minimum is set.
 * Else: Clamps it to the given range.
 * Comma is accepted as a decimal separator (RU locale) and normalized
 * to a dot. A leading minus is preserved so negative ranges keep working.
 */
const getClampedNumber = (value, minValue, maxValue) => {
  const minimum = minValue ?? DEFAULT_MIN;
  const maximum = maxValue ?? DEFAULT_MAX;
  if (value === null || value === undefined || !String(value).length) {
    return String(minimum);
  }
  const normalized = String(value).replace(/,/g, '.').trim();
  let parsedValue;
  if (/^-?(\d+\.?\d*|\.\d+)$/.test(normalized)) {
    parsedValue = parseFloat(normalized);
  } else {
    // Tolerant fallback for pasted garbage ("12abc34"): extract the first
    // number-like chunk instead of dropping the separators entirely.
    // NOTE: parseInt(value.replace(/\D/g, '')) used to live here — it stripped
    // "." / "," / "-" so "0.1" became 1, "7.7" became 77 and "-1" became 1.
    const match = normalized.match(/-?\d*\.?\d+/);
    parsedValue = match ? parseFloat(match[0]) : NaN;
  }
  if (isNaN(parsedValue)) {
    return String(minimum);
  } else {
    return String(clamp(parsedValue, minimum, maximum));
  }
};

export class RestrictedInput extends Component {
  constructor() {
    super();
    this.inputRef = createRef();
    this.state = {
      editing: false,
    };
    // Commit (clamp + onChange) happens on blur or Enter, never per
    // keystroke: React fires onChange on every input, so clamping there
    // would fight the user while typing (the upstream #80490 bug class).
    this.handleBlur = (e) => {
      const { maxValue, minValue, onChange } = this.props;
      const { editing } = this.state;
      if (editing) {
        this.setEditing(false);
      }
      e.target.value = getClampedNumber(e.target.value, minValue, maxValue);
      if (e.target.value !== this.focusedValue && onChange) {
        onChange(e, +e.target.value);
      }
    };
    this.handleFocus = (e) => {
      const { editing } = this.state;
      this.focusedValue = e.target.value;
      if (!editing) {
        this.setEditing(true);
      }
    };
    this.handleInput = (e) => {
      const { editing } = this.state;
      const { onInput } = this.props;
      if (!editing) {
        this.setEditing(true);
      }
      if (onInput) {
        const raw = String(e.target.value).replace(/,/g, '.');
        const parsed = raw.trim().length ? +raw : NaN;
        onInput(e, parsed);
      }
    };
    this.handleKeyDown = (e) => {
      const { maxValue, minValue, onChange, onEnter } = this.props;
      if (e.key === KEY_ENTER) {
        const safeNum = getClampedNumber(e.target.value, minValue, maxValue);
        this.setEditing(false);
        e.target.value = safeNum;
        // Remember the committed value so the follow-up blur handler
        // does not fire a duplicate onChange.
        this.focusedValue = safeNum;
        if (onChange) {
          onChange(e, +safeNum);
        }
        if (onEnter) {
          onEnter(e, +safeNum);
        }
        e.target.blur();
        return;
      }
      if (e.key === KEY_ESCAPE) {
        if (this.props.onEscape) {
          this.props.onEscape(e);
          return;
        }
        this.setEditing(false);
        e.target.value = this.props.value;
        e.target.blur();
        return;
      }
    };
  }

  componentDidMount() {
    const { maxValue, minValue } = this.props;
    const nextValue = this.props.value?.toString();
    const input = this.inputRef.current;
    if (input) {
      input.value = getClampedNumber(nextValue, minValue, maxValue);
    }
    if (this.props.autoFocus || this.props.autoSelect) {
      this.setState({ editing: true }, () => {
        requestAnimationFrame(() => {
          const input = this.inputRef.current;
          if (!input) return;
          input.focus();
          if (this.props.autoSelect) {
            input.select();
            // Re-select when external forces (BYOND window manager) reset selection
            const reselect = () => {
              if (document.activeElement === input
                  && input.selectionStart === input.selectionEnd
                  && input.value.length > 0) {
                input.select();
              }
            };
            const cleanup = () => {
              document.removeEventListener('selectionchange', reselect);
              input.removeEventListener('mousedown', cleanup);
              input.removeEventListener('keydown', cleanup);
            };
            document.addEventListener('selectionchange', reselect);
            input.addEventListener('mousedown', cleanup, { once: true });
            input.addEventListener('keydown', cleanup, { once: true });
            setTimeout(cleanup, 1000);
          }
        });
      });
    }
  }

  shouldComponentUpdate(nextProps, nextState) {
    if (this.state.editing && nextState.editing) {
      return false;
    }
    return true;
  }

  componentDidUpdate(prevProps, _) {
    const { maxValue, minValue } = this.props;
    const { editing } = this.state;
    const prevValue = prevProps.value?.toString();
    const nextValue = this.props.value?.toString();
    const input = this.inputRef.current;
    if (input && !editing) {
      if (nextValue !== prevValue && nextValue !== input.value) {
        input.value = getClampedNumber(nextValue, minValue, maxValue);
      }
    }
  }

  setEditing(editing) {
    this.setState({ editing });
  }

  render() {
    const { props } = this;
    const {
      autoFocus,
      autoSelect,
      maxValue,
      minValue,
      onChange,
      onEnter,
      onEscape,
      onInput,
      value,
      ...boxProps
    } = props;
    const { className, fluid, monospace, ...rest } = boxProps;
    return (
      <Box
        className={classes([
          'Input',
          fluid && 'Input--fluid',
          monospace && 'Input--monospace',
          className,
        ])}
        {...rest}>
        <div className="Input__baseline">.</div>
        <input
          className="Input__input"
          onInput={this.handleInput}
          onFocus={this.handleFocus}
          onBlur={this.handleBlur}
          onKeyDown={this.handleKeyDown}
          ref={this.inputRef}
          type="text"
          inputMode="decimal"
        />
      </Box>
    );
  }
}
