import { Component, createRef } from 'inferno';

import { computeBoxProps } from "./Box";
import { Button } from "./Button";
import { ProgressBar } from "./ProgressBar";
import { Stack } from "./Stack";

const ZOOM_MIN_VAL = 0.5;
const ZOOM_MAX_VAL = 1.5;

const ZOOM_INCREMENT = 0.1;

/** Snap to discrete steps; repeated +/- avoids float drift (e.g. 0.9999999999999997). */
const ZOOM_STEP_COUNT = Math.round((ZOOM_MAX_VAL - ZOOM_MIN_VAL) / ZOOM_INCREMENT);

const snapZoom = (value) => {
  const step = Math.round((value - ZOOM_MIN_VAL) / ZOOM_INCREMENT);
  const clamped = Math.max(0, Math.min(ZOOM_STEP_COUNT, step));
  return ZOOM_MIN_VAL + clamped * ZOOM_INCREMENT;
};

export class InfinitePlane extends Component {
  constructor() {
    super();

    this.planeRootRef = createRef();

    this.state = {
      mouseDown: false,

      left: 0,
      top: 0,

      lastLeft: 0,
      lastTop: 0,

      zoom: 1,
    };

    this.handleMouseDown = this.handleMouseDown.bind(this);
    this.handleMouseMove = this.handleMouseMove.bind(this);
    this.handleZoomIncrease = this.handleZoomIncrease.bind(this);
    this.handleZoomDecrease = this.handleZoomDecrease.bind(this);
    this.onMouseUp = this.onMouseUp.bind(this);

    this.doOffsetMouse = this.doOffsetMouse.bind(this);
    this.onPlaneWheel = this.onPlaneWheel.bind(this);
  }

  componentDidMount() {
    window.addEventListener("mouseup", this.onMouseUp);

    window.addEventListener("mousedown", this.doOffsetMouse);
    window.addEventListener("mousemove", this.doOffsetMouse);
    window.addEventListener("mouseup", this.doOffsetMouse);

    const root = this.planeRootRef.current;
    if (root) {
      root.addEventListener('wheel', this.onPlaneWheel, { passive: false, capture: true });
    }
  }

  componentWillUnmount() {
    window.removeEventListener("mouseup", this.onMouseUp);

    window.removeEventListener("mousedown", this.doOffsetMouse);
    window.removeEventListener("mousemove", this.doOffsetMouse);
    window.removeEventListener("mouseup", this.doOffsetMouse);

    const root = this.planeRootRef.current;
    if (root) {
      root.removeEventListener('wheel', this.onPlaneWheel, { capture: true });
    }
  }

  doOffsetMouse(event) {
    const zoom = snapZoom(this.state.zoom);
    event.screenZoomX = event.screenX * Math.pow(zoom, -1);
    event.screenZoomY = event.screenY * Math.pow(zoom, -1);
  }

  handleMouseDown(event) {
    // Shift+ЛКМ: вставка чипа IE по клику (не начинать панораму поля)
    if (this.props.onShiftPlaneMouseDown && event.shiftKey) {
      this.props.onShiftPlaneMouseDown(event);
      event.preventDefault();
      event.stopPropagation();
      return;
    }
    this.setState((state) => {
      return {
        mouseDown: true,
        lastLeft: event.clientX - state.left,
        lastTop: event.clientY - state.top,
      };
    });
  }

  onMouseUp() {
    this.setState({
      mouseDown: false,
    });
  }

  onPlaneWheel(event) {
    if (event.deltaY === 0) {
      return;
    }
    event.preventDefault();
    event.stopPropagation();
    const { onZoomChange } = this.props;
    const zoom = snapZoom(this.state.zoom);
    const next = event.deltaY < 0
      ? snapZoom(Math.min(zoom + ZOOM_INCREMENT, ZOOM_MAX_VAL))
      : snapZoom(Math.max(zoom - ZOOM_INCREMENT, ZOOM_MIN_VAL));
    if (next === zoom) {
      return;
    }
    this.setState({ zoom: next });
    if (onZoomChange) {
      onZoomChange(next);
    }
  }

  handleZoomIncrease(event) {
    const { onZoomChange } = this.props;
    const zoom = snapZoom(this.state.zoom);
    const newZoomValue = snapZoom(Math.min(zoom + ZOOM_INCREMENT, ZOOM_MAX_VAL));
    if (newZoomValue === zoom) {
      return;
    }
    this.setState({
      zoom: newZoomValue,
    });
    if (onZoomChange) {
      onZoomChange(newZoomValue);
    }
  }

  handleZoomDecrease(event) {
    const { onZoomChange } = this.props;
    const zoom = snapZoom(this.state.zoom);
    const newZoomValue = snapZoom(Math.max(zoom - ZOOM_INCREMENT, ZOOM_MIN_VAL));
    if (newZoomValue === zoom) {
      return;
    }
    this.setState({
      zoom: newZoomValue,
    });

    if (onZoomChange) {
      onZoomChange(newZoomValue);
    }
  }

  handleMouseMove(event) {
    const {
      onBackgroundMoved,
      initialLeft = 0,
      initialTop = 0,
    } = this.props;
    if (this.state.mouseDown) {
      let newX, newY;
      this.setState((state) => {
        newX = event.clientX - state.lastLeft;
        newY = event.clientY - state.lastTop;
        return {
          left: newX,
          top: newY,
        };
      });
      if (onBackgroundMoved) {
        onBackgroundMoved(newX+initialLeft, newY+initialTop);
      }
    }
  }

  componentDidUpdate(prevProps) {
    /// Когда сервер присылает новый якорь панорамы или запрошен сброс к origin,
    /// обнуляем локальный drag-offset. Иначе left/top суммируются с initial* — поле «прыгает».
    if (this.state.mouseDown) {
      return;
    }
    const anchorChanged =
      prevProps.initialLeft !== this.props.initialLeft
      || prevProps.initialTop !== this.props.initialTop;
    const panReset =
      prevProps.resetPanNonce !== this.props.resetPanNonce;

    if (anchorChanged || panReset) {
      this.setState({
        left: 0,
        top: 0,
      });
    }
  }

  render() {
    const {
      children,
      backgroundImage,
      imageWidth,
      initialLeft = 0,
      initialTop = 0,
      resetPanNonce = 0,
      ...rest
    } = this.props;
    const {
      left,
      top,
      zoom: rawZoom,
    } = this.state;
    const zoom = snapZoom(rawZoom);

    const finalLeft = initialLeft + left;
    const finalTop = initialTop + top;

    return (
      <div
        ref={this.planeRootRef}
        {...computeBoxProps({
          ...rest,
          style: {
            ...rest.style,
            overflow: "hidden",
            position: "relative",
          },
        })}
      >
        {/* absolute (not fixed): must stay inside the plane host; fixed used viewport and broke layout at HiDPI / non-1:1 scale */}
        <div
          onMouseDown={this.handleMouseDown}
          onMouseMove={this.handleMouseMove}
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundImage: `url("${backgroundImage}")`,
            backgroundPosition: `${finalLeft}px ${finalTop}px`,
            backgroundRepeat: 'repeat',
            backgroundSize: `${zoom * imageWidth}px`,
          }}
        />
        <div
          onMouseDown={this.handleMouseDown}
          onMouseMove={this.handleMouseMove}
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            transform: `translate(${finalLeft}px, ${finalTop}px) scale(${zoom})`,
            transformOrigin: 'top left',
          }}
        >
          {children}
        </div>

        <Stack
          position="absolute"
          width="100%"
        >
          <Stack.Item>
            <Button
              icon="minus"
              onClick={this.handleZoomDecrease}
            />
          </Stack.Item>
          <Stack.Item grow={1}>
            <ProgressBar
              minValue={ZOOM_MIN_VAL}
              value={zoom}
              maxValue={ZOOM_MAX_VAL}
            >
              {`${Math.round(zoom * 100) / 100}x`}
            </ProgressBar>
          </Stack.Item>
          <Stack.Item>
            <Button
              icon="plus"
              onClick={this.handleZoomIncrease}
            />
          </Stack.Item>
        </Stack>
      </div>
    );
  }
}
