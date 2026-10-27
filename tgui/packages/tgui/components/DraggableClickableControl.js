/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { clamp } from 'common/math';
import { Component, createRef } from 'react';

const DEFAULT_UPDATE_RATE = 400;

// Shared drag session bookkeeping so that pointer events over the document
// body are only locked while at least one control is actively dragging, even
// when several instances start and end their sessions at the same time.
let dragSessionCount = 0;
let originalPointerEvents = '';

const beginDragPointerLock = () => {
  if (dragSessionCount === 0) {
    originalPointerEvents = document.body.style.pointerEvents;
    document.body.style.pointerEvents = 'none';
  }
  dragSessionCount += 1;
};

const endDragPointerLock = () => {
  if (dragSessionCount > 0) {
    dragSessionCount -= 1;
  }
  if (dragSessionCount === 0) {
    document.body.style.pointerEvents = originalPointerEvents;
  }
};

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
    this.disposed = true;
    this.state = {
      value: props.value,
      dragging: false,
      internalValue: null,
      origin: null,
    };

    this.handleWindowBlur = () => {
      this.disposeSession();
    };
    window.addEventListener('blur', this.handleWindowBlur);

    this.handleDragStart = e => {
      const {
        value,
        dragMatrix,
      } = this.props;
      this.disposed = false;
      beginDragPointerLock();
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
      // Guard against non-finite or non-positive pixel size (e.g. a zoom
      // scale that collapsed to 0 or Infinity) before dividing.
      const safeStepPixelSize = Number.isFinite(stepPixelSize)
        && stepPixelSize > 0
        ? stepPixelSize
        : 1;
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
              + offset * step / safeStepPixelSize,
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
      if (this.disposed) {
        return;
      }
      const {
        onChange,
        onDrag,
        onClick,
      } = this.props;
      const {
        dragging,
        value,
      } = this.state;
      this.disposeSession();
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

    // Idempotent drag session teardown, shared by mouseup, window blur and
    // unmount so no listeners or timers survive a cancelled/interrupted drag.
    this.disposeSession = () => {
      if (this.disposed) {
        return;
      }
      this.disposed = true;
      endDragPointerLock();
      clearTimeout(this.timer);
      clearInterval(this.dragInterval);
      this.timer = null;
      this.dragInterval = null;
      document.removeEventListener('mousemove', this.handleDragMove);
      document.removeEventListener('mouseup', this.handleDragEnd);
      this.setState({
        dragging: false,
        origin: null,
      });
    };
  }

  componentWillUnmount() {
    window.removeEventListener('blur', this.handleWindowBlur);
    this.disposeSession();
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
