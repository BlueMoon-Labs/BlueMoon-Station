/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { clamp } from 'common/math';
import { Component, createRef } from 'react';

const DEFAULT_UPDATE_RATE = 400;

/**
 * Reduces screen offset to a single number based on the matrix provided.
 */
const getScalarScreenOffset = (e, matrix) => {
  // DPI fix: screenX/screenY are in physical pixels; divide by DPR to normalize
  // drag sensitivity so stepPixelSize behaves consistently at any DPI.
  const dpr = window.devicePixelRatio ?? 1;
  return (e.screenX * matrix[0] + e.screenY * matrix[1]) / dpr;
};

export class DraggableClickableControl extends Component {
  constructor(props) {
    super(props);
    this.inputRef = createRef();
    this.state = {
      value: props.value,
      dragging: false,
      internalValue: null,
      origin: null,
    };

    this.handleDragStart = e => {
      const {
        value,
        dragMatrix,
      } = this.props;
      document.body.style['pointer-events'] = 'none';
      this.setState({
        dragging: false,
        origin: getScalarScreenOffset(e, dragMatrix),
        value,
        internalValue: value,
      });
      this.timer = setTimeout(() => {
        this.setState({
          dragging: true,
        });
      }, 250);
      this.dragInterval = setInterval(() => {
        const { dragging, value } = this.state;
        const { onDrag } = this.props;
        if (dragging && onDrag) {
          onDrag(e, value);
        }
      }, this.props.updateRate || DEFAULT_UPDATE_RATE);
      document.addEventListener('mousemove', this.handleDragMove);
      document.addEventListener('mouseup', this.handleDragEnd);
    };

    this.handleDragMove = e => {
      const {
        minValue,
        maxValue,
        step,
        stepPixelSize,
        dragMatrix,
      } = this.props;
      this.setState(prevState => {
        const state = { ...prevState };
        const offset = getScalarScreenOffset(e, dragMatrix) - state.origin;
        if (prevState.dragging) {
          const stepOffset = Number.isFinite(minValue)
            ? minValue % step
            : 0;
          // Translate mouse movement to value
          // Give it some headroom (by increasing clamp range by 1 step)
          state.internalValue = clamp(
            state.internalValue
              + offset * step / stepPixelSize,
            minValue - step,
            maxValue + step);
          // Clamp the final value
          state.value = clamp(
            state.internalValue
              - state.internalValue % step
              + stepOffset,
            minValue,
            maxValue);
          state.origin = getScalarScreenOffset(e, dragMatrix);
        }
        else if (Math.abs(offset) > 4) {
          state.dragging = true;
        }
        return state;
      });
    };

    this.handleDragEnd = e => {
      const {
        onChange,
        onDrag,
        onClick,
      } = this.props;
      const {
        dragging,
        value,
      } = this.state;
      document.body.style['pointer-events'] = 'auto';
      clearTimeout(this.timer);
      clearInterval(this.dragInterval);
      document.removeEventListener('mousemove', this.handleDragMove);
      document.removeEventListener('mouseup', this.handleDragEnd);
      this.setState({
        dragging: false,
        origin: null,
      });
      if (dragging) {
        if (onChange) {
          onChange(e, value);
        }
        if (onDrag) {
          onDrag(e, value);
        }
      }
      else if (onClick) {
        onClick(e, value);
      }
    };
  }

  render() {
    const {
      dragging,
      value,
    } = this.state;
    const {
      children,
    } = this.props;
    const inputElement = (
      <input
        ref={this.inputRef}
        className="NumberInput__input"
        style={{ display: 'none' }} />
    );
    return children({
      dragging,
      value,
      inputElement,
      handleDragStart: this.handleDragStart,
    });
  }
}

DraggableClickableControl.defaultProps = {
  minValue: -Infinity,
  maxValue: +Infinity,
  step: 1,
  stepPixelSize: 1,
  dragMatrix: [1, 0],
};