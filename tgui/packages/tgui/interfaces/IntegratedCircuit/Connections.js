import { Component } from 'react';

import { classes } from '../../../common/react';
import { CSS_COLORS } from '../../constants';
import { SVG_CURVE_INTENSITY } from './constants';

const isColorClass = (str) => typeof str === 'string' && CSS_COLORS.includes(str);

const isHexStrokeColor = (str) =>
  typeof str === 'string' && /^#[0-9A-Fa-f]{6}$/.test(str);

export function buildWirePath(from, to) {
  if (!to || !from) {
    return '';
  }
  let path = `M ${from.x} ${from.y}`;
  path += `C ${from.x + SVG_CURVE_INTENSITY}, ${from.y},`;
  path += `${to.x - SVG_CURVE_INTENSITY}, ${to.y},`;
  path += `${to.x}, ${to.y}`;
  return path;
}

export function wireConnectionKey(conn, index) {
  if (conn.isPreview) {
    return `preview-${index}`;
  }
  if (conn.outRef && conn.inRef) {
    return `${conn.outRef}|${conn.inRef}`;
  }
  return `idx-${index}`;
}

/**
 * Два SVG: base — линии; overlay — широкий hit-test для hover по проводам (только
 * там, где нет ноды сверху). Вынесено в отдельный класс с shouldComponentUpdate,
 * чтобы на каждый кадр панорамы/драга нод НЕ пересоздавались сотни <path> —
 * обновляем только когда массив `connections` (пересобирается родителем с мемоизацией)
 * или `pulseKeys` реально изменились. Ноды (children) рендерятся родителем отдельно.
 */
class WireCanvas extends Component {
  constructor(props) {
    super(props);
    this.state = { hoveredKey: null };
    this.handleClearHover = this.handleClearHover.bind(this);
    this.handleOverlayWireMouseEnter = this.handleOverlayWireMouseEnter.bind(this);
  }

  shouldComponentUpdate(nextProps, nextState) {
    return (
      this.props.connections !== nextProps.connections
      || this.props.pulseKeys !== nextProps.pulseKeys
      || this.state.hoveredKey !== nextState.hoveredKey
    );
  }

  handleClearHover() {
    this.setState({ hoveredKey: null });
  }

  handleOverlayWireMouseEnter(ev) {
    const key = ev.currentTarget.getAttribute('data-wire-key');
    if (key !== null) {
      this.setState({ hoveredKey: key });
    }
  }

  render() {
    const { connections, svgRef, pulseKeys } = this.props;
    const { hoveredKey } = this.state;

    const renderPathD = (val) => {
      const from = val.from;
      const to = val.to;
      if (!to || !from) {
        return null;
      }
      return buildWirePath(from, to);
    };

    return (
      <>
        <svg
          ref={svgRef}
          className="IntegratedCircuit__connections IntegratedCircuit__connections--base"
          width="100%"
          height="100%"
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            zIndex: 0,
            overflow: 'visible',
            pointerEvents: 'none',
          }}>
          {connections.map((val, index) => {
            const d = renderPathD(val);
            if (!d) {
              return null;
            }
            const key = wireConnectionKey(val, index);
            const color = val.color || 'blue';
            const hexStroke = isHexStrokeColor(color);
            const pulsing = !val.isPreview && !!pulseKeys
              && !!val.outRef && !!val.inRef
              && pulseKeys.has(`${val.outRef}\u0000${val.inRef}`);
            const hot = pulsing || hoveredKey === key;
            return (
              <path
                className={classes([
                  'IntegratedCircuit__wire',
                  !hexStroke && isColorClass(color) && `color-stroke-${color}`,
                  hot && 'IntegratedCircuit__wire--hot',
                  pulsing && 'IntegratedCircuit__wire--pulse',
                ])}
                key={`b-${key}`}
                d={d}
                fill="transparent"
                stroke={hexStroke ? color : undefined}
                strokeWidth="2"
                vectorEffect="non-scaling-stroke"
              />
            );
          })}
        </svg>
        <svg
          className="IntegratedCircuit__connections IntegratedCircuit__connections--overlay"
          width="100%"
          height="100%"
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            zIndex: 0,
            overflow: 'visible',
            pointerEvents: 'none',
          }}
          onMouseLeave={this.handleClearHover}>
          {connections.map((val, index) => {
            const d = renderPathD(val);
            if (!d || val.isPreview) {
              return null;
            }
            const key = wireConnectionKey(val, index);
            return (
              <path
                key={`o-${key}`}
                data-wire-key={key}
                d={d}
                fill="none"
                stroke="rgba(255,255,255,0.001)"
                strokeWidth="14"
                vectorEffect="non-scaling-stroke"
                style={{ pointerEvents: 'stroke', cursor: 'crosshair' }}
                onMouseEnter={this.handleOverlayWireMouseEnter}
              />
            );
          })}
        </svg>
      </>
    );
  }
}

export const Connections = (props) => {
  const {
    connections,
    svgRef,
    pulseKeys,
    children,
  } = props;

  return (
    <>
      <WireCanvas
        connections={connections}
        pulseKeys={pulseKeys}
        svgRef={svgRef}
      />
      {children}
    </>
  );
};