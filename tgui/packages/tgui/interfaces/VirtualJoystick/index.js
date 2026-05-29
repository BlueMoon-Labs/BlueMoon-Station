import { Component } from 'inferno';
import { useBackend } from 'tgui/backend';
import { Box } from 'tgui/components';
import { Window } from 'tgui/layouts';
import './VirtualJoystick.scss';

const TRAIL_MAX_AGE = 250;
const TRAIL_SAMPLE_MS = 50;
const ACT_INTERVAL_MS = 50;
const TRAIL_MIN_SPEED = 0.25;

export class VirtualJoystick extends Component {
  constructor(props) {
    super(props);
    this.state = { knobX: 0, knobY: 0 };

    this.trailPoints = [];
    this._animating = false;
    this._dragActive = false;
    this._lastTrailTime = 0;
    this._lastMoveTime = 0;
    this._lastActTime = 0;
    this._lastTrailPos = { x: 0, y: 0 };

    this.canvasElement = null;
    this.containerRef = { current: null };
    this.ctxRef = {};
    this.trailTimeoutRef = {};

    this._mouseMoveHandler = null;
    this._mouseUpHandler = null;

    this._pendingKnobX = 0;
    this._pendingKnobY = 0;
    this._rafId = null;

    this._resizeObserver = null;
    this._canvasSize = { width: 0, height: 0 };
    this._setCanvasDimensions = (container) => {
      const rect = container.getBoundingClientRect();
      const w = Math.round(rect.width);
      const h = Math.round(rect.height);
      if (w !== this._canvasSize.width || h !== this._canvasSize.height) {
        this._canvasSize.width = w;
        this._canvasSize.height = h;
        const canvas = this.canvasElement;
        if (canvas) {
          canvas.width = w;
          canvas.height = h;
        }
      }
    };
  }

  componentDidMount() {
    if (!this.canvasElement) {
      this.canvasElement = document.createElement('canvas');
      this.canvasElement.style.position = 'absolute';
      this.canvasElement.style.pointerEvents = 'none';
      this.canvasElement.style.width = '100%';
      this.canvasElement.style.height = '100%';
      if (this.containerRef.current) {
        this.containerRef.current.appendChild(this.canvasElement);
        this.ctxRef.current = this.canvasElement.getContext('2d');
      }
    }

    if (this.containerRef.current) {
      this._setCanvasDimensions(this.containerRef.current);
      this._resizeObserver = new ResizeObserver(() => {
        if (this.containerRef.current) {
          this._setCanvasDimensions(this.containerRef.current);
        }
      });
      this._resizeObserver.observe(this.containerRef.current);
    }
  }

  componentWillUnmount() {
    if (this._resizeObserver) {
      this._resizeObserver.disconnect();
      this._resizeObserver = null;
    }
    if (this._rafId) cancelAnimationFrame(this._rafId);
    if (this.trailTimeoutRef.current) {
      cancelAnimationFrame(this.trailTimeoutRef.current);
      this.trailTimeoutRef.current = null;
    }
    if (this._mouseMoveHandler) {
      window.removeEventListener('mousemove', this._mouseMoveHandler);
      this._mouseMoveHandler = null;
    }
    if (this._mouseUpHandler) {
      window.removeEventListener('mouseup', this._mouseUpHandler);
      this._mouseUpHandler = null;
    }
    if (this.canvasElement) {
      this.canvasElement.remove();
      this.canvasElement = null;
    }
  }

  _queueKnobUpdate(normX, normY) {
    this._pendingKnobX = normX;
    this._pendingKnobY = normY;
    if (this._rafId === null) {
      this._rafId = requestAnimationFrame(() => {
        this._rafId = null;
        this.setState({ knobX: this._pendingKnobX, knobY: this._pendingKnobY });
      });
    }
  }

  updatePosition(clientX, clientY) {
    const container = this.containerRef.current;
    if (!container) return;

    const rect = container.getBoundingClientRect();
    const centerX = rect.left + rect.width / 2;
    const centerY = rect.top + rect.height / 2;

    let dx = clientX - centerX;
    let dy = centerY - clientY;

    const maxDist = Math.min(rect.width, rect.height) * 0.4;
    if (maxDist <= 0) {
      return;
    }
    const dist = Math.sqrt(dx * dx + dy * dy);
    if (dist > maxDist) {
      dx = dx / dist * maxDist;
      dy = dy / dist * maxDist;
    }

    const normX = dx / maxDist;
    const normY = dy / maxDist;

    const now = Date.now();
    if (now - this._lastTrailTime >= TRAIL_SAMPLE_MS) {
      this._lastTrailTime = now;
      const speed = Math.hypot(normX - this._lastTrailPos.x, normY - this._lastTrailPos.y);
      this._lastTrailPos = { x: normX, y: normY };
      this.trailPoints.push({ x: normX, y: normY, time: now, speed: speed });
    }

    this._queueKnobUpdate(normX, normY);

    if (now - this._lastActTime >= ACT_INTERVAL_MS) {
      this._lastActTime = now;
      const { act } = useBackend(this.context);
      act('update_position', { x: +normX.toFixed(2), y: +normY.toFixed(2) });
    }

    if (!this._animating) {
      this._animating = true;
      this.trailTimeoutRef.current = requestAnimationFrame(() => this.animateTrail());
    }
  }

  handleMouseDown(e) {
    e.preventDefault();
    this._dragActive = true;
    this.updatePosition(e.clientX, e.clientY);

    this._mouseMoveHandler = (e) => {
      const now = Date.now();
      if (now - this._lastMoveTime < 16) return;
      this._lastMoveTime = now;
      this.updatePosition(e.clientX, e.clientY);
    };
    this._mouseUpHandler = () => {
      this._dragActive = false;
      this.setState({ knobX: 0, knobY: 0 });
      this._pendingKnobX = 0;
      this._pendingKnobY = 0;
      this._lastTrailPos = { x: 0, y: 0 };
      const { act } = useBackend(this.context);
      act('update_position', { x: 0, y: 0 });
      window.removeEventListener('mousemove', this._mouseMoveHandler);
      window.removeEventListener('mouseup', this._mouseUpHandler);
      this._mouseMoveHandler = null;
      this._mouseUpHandler = null;
    };

    window.addEventListener('mousemove', this._mouseMoveHandler);
    window.addEventListener('mouseup', this._mouseUpHandler);
  }

  animateTrail() {
    const ctx = this.ctxRef.current;
    const container = this.containerRef.current;
    if (!ctx || !container) {
      this._animating = false;
      return;
    }

    const width = this._canvasSize.width;
    const height = this._canvasSize.height;
    ctx.clearRect(0, 0, width, height);

    const now = Date.now();
    this.trailPoints = this.trailPoints.filter(p => now - p.time < TRAIL_MAX_AGE);
    const points = this.trailPoints;

    if (points.length === 0) {
      this._animating = false;
      return;
    }

    const minDim = Math.min(width, height);
    const minRadius = 0.1 * minDim;
    const maxRadius = 0.15 * minDim;

    for (const p of points) {
      if (p.speed < TRAIL_MIN_SPEED) continue;

      const age = (now - p.time) / TRAIL_MAX_AGE;
      const opacity = 1 - age;
      const radius = minRadius + (maxRadius - minRadius) * age;
      const x = (p.x * 40 + 50) / 100 * width;
      const y = (50 - p.y * 40) / 100 * height;

      ctx.beginPath();
      ctx.arc(x, y, radius, 0, 2 * Math.PI);
      ctx.strokeStyle = `rgba(0, 229, 255, ${opacity})`;
      ctx.lineWidth = 1.5;
      ctx.stroke();
    }

    if (points.length > 0 || this._dragActive) {
      this.trailTimeoutRef.current = requestAnimationFrame(() => this.animateTrail());
    } else {
      this._animating = false;
    }
  }

  render() {
    const { knobX, knobY } = this.state;
    const maxPercentRadius = 40;
    const knobLeft = 50 + knobX * maxPercentRadius - 10;
    const knobTop = 50 - knobY * maxPercentRadius - 10;

    return (
      <Window canClose={false} width={180} height={210}>
        <Window.Content>
          <Box className="VirtualJoystick">
            <div
              className="joystick-container"
              ref={el => { this.containerRef.current = el; }}
              onMouseDown={(e) => this.handleMouseDown(e)}
            >
              <div
                className="knob"
                style={{
                  left: `${knobLeft}%`,
                  top: `${knobTop}%`,
                }}
              />
            </div>
          </Box>
        </Window.Content>
      </Window>
    );
  }
}
