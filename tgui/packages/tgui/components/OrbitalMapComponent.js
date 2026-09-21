/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { Component } from 'react';

import { DraggableClickableControl } from './DraggableClickableControl';

const DEFAULT_UPDATE_RATE = 5;

export class OrbitalMapComponent extends Component {
  constructor(props) {
    super(props);
    this.xControl = null;
    this.yControl = null;
    this.state = {
      xOffset: props.valueX ?? 0,
      yOffset: props.valueY ?? 0,
    };
  }

  static getDerivedStateFromProps(props, state) {
    if (props.isTracking) {
      const xOffset = props.dynamicXOffset;
      const yOffset = props.dynamicYOffset;
      if (xOffset !== state.xOffset || yOffset !== state.yOffset) {
        return { xOffset, yOffset };
      }
      return null;
    }
    if (props.valueX !== state.xOffset || props.valueY !== state.yOffset) {
      return { xOffset: props.valueX, yOffset: props.valueY };
    }
    return null;
  }

  handleDrag = (e, valueX, valueY) => {
    this.setState({
      xOffset: valueX,
      yOffset: valueY,
    });
    if (this.props.onDrag) {
      this.props.onDrag(e, valueX, valueY);
    }
  };

  handleClick = (e, valueX, valueY) => {
    if (this.props.onClick) {
      this.props.onClick(e, valueX, valueY);
    }
  };

  handleDragStart = e => {
    if (this.xControl) {
      this.xControl.handleDragStart(e);
    }
    if (this.yControl) {
      this.yControl.handleDragStart(e);
    }
  };

  render() {
    const {
      children,
      step,
      stepPixelSize,
      updateRate = DEFAULT_UPDATE_RATE,
    } = this.props;
    const {
      xOffset,
      yOffset,
    } = this.state;
    const dragProps = {
      step: step,
      stepPixelSize: stepPixelSize,
      updateRate: updateRate,
    };
    return (
      <DraggableClickableControl
        {...dragProps}
        value={xOffset}
        dragMatrix={[-1, 0]}
        onDrag={(e, value) => this.handleDrag(e, value, yOffset)}
        onClick={(e, value) => this.handleClick(e, value, yOffset)}>
        {control => {
          this.xControl = control;
          return (
            <DraggableClickableControl
              {...dragProps}
              value={yOffset}
              dragMatrix={[0, -1]}
              onDrag={(e, value) => this.handleDrag(e, xOffset, value)}
              onClick={(e, value) => this.handleClick(e, xOffset, value)}>
              {controlY => {
                this.yControl = controlY;
                return children({
                  xOffset,
                  yOffset,
                  handleDragStart: this.handleDragStart,
                });
              }}
            </DraggableClickableControl>
          );
        }}
      </DraggableClickableControl>
    );
  }
}

OrbitalMapComponent.defaultProps = {
  valueX: 0,
  valueY: 0,
  isTracking: false,
  dynamicXOffset: 0,
  dynamicYOffset: 0,
};