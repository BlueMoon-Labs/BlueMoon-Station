import { Component, createRef } from 'inferno';

export class PixelArtImage extends Component {
  constructor(props) {
    super(props);
    this.containerRef = createRef();
    this.canvasRef = createRef();
    this.image = new Image();
    this.resizeRaf = null;
    this.recomputeSize = this.recomputeSize.bind(this);
    this.handleImageLoad = this.handleImageLoad.bind(this);
    this.handleWindowResize = this.handleWindowResize.bind(this);
  }

  componentDidMount() {
    this.image.onload = this.handleImageLoad;
    this.image.src = this.props.src;
    window.addEventListener('resize', this.handleWindowResize);
    // Defer to let flex layout settle before measuring container width
    this.resizeRaf = requestAnimationFrame(() => {
      this.resizeRaf = null;
      this.recomputeSize();
    });
  }

  componentDidUpdate(prevProps) {
    if (prevProps.src !== this.props.src) {
      this.image.src = this.props.src;
    }
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.handleWindowResize);
    this.image.onload = null;
    if (this.resizeRaf !== null) {
      cancelAnimationFrame(this.resizeRaf);
      this.resizeRaf = null;
    }
  }

  handleImageLoad() {
    this.recomputeSize();
  }

  handleWindowResize() {
    if (this.resizeRaf !== null) {
      return;
    }
    this.resizeRaf = requestAnimationFrame(() => {
      this.resizeRaf = null;
      this.recomputeSize();
    });
  }

  recomputeSize() {
    const container = this.containerRef.current;
    const canvas = this.canvasRef.current;
    if (!container || !canvas) {
      return;
    }

    const naturalWidth = this.image.naturalWidth;
    const naturalHeight = this.image.naturalHeight;
    if (!naturalWidth || !naturalHeight) {
      return;
    }

    // Reset canvas size so the container can shrink freely in flex layout
    canvas.style.width = '0';
    canvas.style.height = '0';

    let displayWidth = Math.floor(container.clientWidth);
    if (!displayWidth) {
      return;
    }

    const fit = this.props.fit || 'width';
    const maxWidth = this.props.maxWidth;
    if (maxWidth) {
      displayWidth = Math.min(displayWidth, maxWidth);
    }

    if (fit === 'contain') {
      let maxHeight = this.props.maxHeight;
      if (!maxHeight) {
        maxHeight = Math.floor(container.clientHeight);
      }
      if (maxHeight > 0) {
        const widthByHeight = Math.floor(maxHeight * naturalWidth / naturalHeight);
        displayWidth = Math.min(displayWidth, widthByHeight);
      }
    }

    if (displayWidth >= naturalWidth) {
      displayWidth = naturalWidth * Math.max(1, Math.floor(displayWidth / naturalWidth));
    }

    displayWidth = Math.max(1, Math.round(displayWidth));
    const displayHeight = Math.max(1, Math.round(displayWidth * naturalHeight / naturalWidth));
    const dpr = window.devicePixelRatio || 1;

    canvas.style.width = `${displayWidth}px`;
    canvas.style.height = `${displayHeight}px`;
    canvas.width = Math.max(1, Math.round(displayWidth * dpr));
    canvas.height = Math.max(1, Math.round(displayHeight * dpr));

    const ctx = canvas.getContext('2d');
    if (!ctx) {
      return;
    }

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.imageSmoothingEnabled = false;
    ctx.clearRect(0, 0, displayWidth, displayHeight);
    ctx.drawImage(this.image, 0, 0, displayWidth, displayHeight);
  }

  render() {
    const { className, style, containerStyle } = this.props;
    return (
      <div
        ref={this.containerRef}
        style={{
          width: '100%',
          textAlign: 'center',
          overflow: 'hidden',
          ...containerStyle,
        }}>
        <canvas
          ref={this.canvasRef}
          className={className}
          style={{
            display: 'inline-block',
            maxWidth: '100%',
            imageRendering: 'pixelated',
            ...style,
          }} />
      </div>
    );
  }
}
