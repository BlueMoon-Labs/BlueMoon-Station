/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

const RENDER_MODE_DEFAULT = 'default';
const RENDER_MODE_PLANET = 'planet';
const RENDER_MODE_BEACON = 'beacon';
const RENDER_MODE_SHUTTLE = 'shuttle';
const RENDER_MODE_PROJECTILE = 'projectile';

const PLANET_COLOR = '#C4704F';
const BEACON_COLOR = '#00E0C8';
const SHUTTLE_COLOR = '#00FF00';
const DEFAULT_COLOR = '#FFFFFF';
const PROJECTILE_COLOR = '#C0C0C0';
const TARGET_COLOR = '#FFD700';
const INTERDICTION_COLOR = '#CE1935';
const GRID_COLOR = '#4665DE';

export const OrbitalMapSvg = (props) => {
  const {
    children,
    map_objects = [],
    ourObject = null,
    scaledXOffset = 0,
    scaledYOffset = 0,
    lockedZoomScale = 1,
    zoomScale = 1,
    interdiction_range = 150,
    shuttleTargetX = 0,
    shuttleTargetY = 0,
    dragStartEvent = null,
  } = props;

  const toScreen = (x, y) => ({
    x: x * zoomScale + scaledXOffset,
    y: y * zoomScale + scaledYOffset,
  });

  //WHITE-STEEL PORT: направление вектора скорости совпадает с направлением
  //движения на карте (без инверсии по Y, как в списке карт белого стиля).
  const velocityVector = (vx, vy) => {
    const magnitude = Math.hypot(vx, vy);
    if (!magnitude) {
      return { x: 0, y: 0 };
    }
    const length = Math.min(magnitude, 50) * zoomScale;
    return {
      x: (vx / magnitude) * length,
      y: (vy / magnitude) * length,
    };
  };

  const makeText = (x, y, text, color) => (
    <text
      x={x}
      y={y}
      fill={color}
      fontSize={Math.min(40 * lockedZoomScale, 14)}
      textAnchor="middle">
      {text}
    </text>
  );

  const drawObject = (mapObject) => {
    const position = toScreen(mapObject.position_x, mapObject.position_y);
    const radius = Math.max(mapObject.radius * zoomScale, 4);
    switch (mapObject.render_mode) {
      case RENDER_MODE_PLANET:
        return (
          <>
            <circle
              cx={position.x}
              cy={position.y}
              r={radius}
              fill={PLANET_COLOR}
              opacity="0.8" />
            {makeText(
              position.x,
              position.y + radius + 12,
              mapObject.name,
              '#FFFFFF')}
          </>
        );
      case RENDER_MODE_BEACON:
        return (
          <>
            <circle
              cx={position.x}
              cy={position.y}
              r={radius * 2}
              fill="none"
              stroke={BEACON_COLOR}
              strokeWidth="2"
              strokeDasharray="6 6" />
            <rect
              x={position.x - 6 * zoomScale}
              y={position.y - 6 * zoomScale}
              width={12 * zoomScale}
              height={12 * zoomScale}
              fill={BEACON_COLOR}
              transform={`rotate(45 ${position.x} ${position.y})`} />
            {makeText(
              position.x,
              position.y - radius * 2 - 12,
              mapObject.name,
              '#FFFFFF')}
          </>
        );
      case RENDER_MODE_SHUTTLE:
      {
        const heading = velocityVector(
          mapObject.velocity_x,
          mapObject.velocity_y);
        return (
          <>
            <line
              x1={position.x}
              y1={position.y}
              x2={position.x + heading.x}
              y2={position.y + heading.y}
              stroke={SHUTTLE_COLOR}
              strokeWidth="3" />
            <rect
              x={position.x - 10 * zoomScale}
              y={position.y - 10 * zoomScale}
              width={20 * zoomScale}
              height={20 * zoomScale}
              fill={SHUTTLE_COLOR} />
            {makeText(
              position.x,
              position.y - 22 * zoomScale,
              mapObject.name,
              '#FFFFFF')}
          </>
        );
      }
      case RENDER_MODE_PROJECTILE:
      {
        const heading = velocityVector(
          mapObject.velocity_x,
          mapObject.velocity_y);
        return (
          <line
            x1={position.x}
            y1={position.y}
            x2={position.x + heading.x}
            y2={position.y + heading.y}
            stroke={PROJECTILE_COLOR}
            strokeWidth="2" />
        );
      }
      default:
      {
        const heading = velocityVector(
          mapObject.velocity_x,
          mapObject.velocity_y);
        return (
          <>
            <circle
              cx={position.x}
              cy={position.y}
              r={radius}
              fill="rgba(0,0,0,0)"
              stroke={DEFAULT_COLOR}
              strokeWidth="2" />
            <line
              x1={position.x}
              y1={position.y}
              x2={position.x + heading.x}
              y2={position.y + heading.y}
              stroke={DEFAULT_COLOR}
              strokeWidth="2" />
            {makeText(
              position.x,
              position.y - radius - 12,
              mapObject.name,
              '#FFFFFF')}
          </>
        );
      }
    }
  };

  const drawOurShip = () => {
    if (!ourObject) {
      return null;
    }
    const position = toScreen(ourObject.position_x, ourObject.position_y);
    return (
      <circle
        cx={position.x}
        cy={position.y}
        r={30 * zoomScale}
        fill="none"
        stroke="#FFFFFF"
        strokeWidth="1.5"
        strokeDasharray="4 4" />
    );
  };

  let interdictionCircle = null;
  if (ourObject) {
    const position = toScreen(ourObject.position_x, ourObject.position_y);
    interdictionCircle = (
      <circle
        cx={position.x}
        cy={position.y}
        r={interdiction_range * zoomScale}
        fill="none"
        stroke={INTERDICTION_COLOR}
        strokeWidth="2"
        opacity="0.7" />
    );
  }

  let targetMarker = null;
  if (shuttleTargetX !== 0 || shuttleTargetY !== 0) {
    const target = toScreen(shuttleTargetX, shuttleTargetY);
    const start = ourObject
      ? toScreen(ourObject.position_x, ourObject.position_y)
      : { x: 0, y: 0 };
    targetMarker = (
      <>
        <line
          x1={start.x}
          y1={start.y}
          x2={target.x}
          y2={target.y}
          stroke={TARGET_COLOR}
          strokeWidth="1.5"
          strokeDasharray="8 4"
          opacity="0.6" />
        <circle
          cx={target.x}
          cy={target.y}
          r={18 * zoomScale}
          fill="none"
          stroke={TARGET_COLOR}
          strokeWidth="1.5"
          strokeDasharray="10 6" />
        <line
          x1={target.x - 24 * zoomScale}
          y1={target.y}
          x2={target.x + 24 * zoomScale}
          y2={target.y}
          stroke={TARGET_COLOR}
          strokeWidth="2" />
        <line
          x1={target.x}
          y1={target.y - 24 * zoomScale}
          x2={target.x}
          y2={target.y + 24 * zoomScale}
          stroke={TARGET_COLOR}
          strokeWidth="2" />
      </>
    );
  }

  const svgComponent = (
    <svg
      position="absolute"
      width="100%"
      height="100%"
      viewBox="-250 -250 500 500"
      overflowY="hidden"
      onMouseDown={dragStartEvent}>
      <defs>
        <pattern
          id="orbitalMapGrid"
          width={100 * lockedZoomScale}
          height={100 * lockedZoomScale}
          patternUnits="userSpaceOnUse"
          x={scaledXOffset}
          y={scaledYOffset}>
          <rect
            width={100 * lockedZoomScale}
            height={100 * lockedZoomScale}
            fill="url(#orbitalMapSmallGrid)" />
          <path
            fill="none"
            stroke={GRID_COLOR}
            strokeWidth="1"
            d={`M ${100 * lockedZoomScale} 0 L 0 0 0 ${100 * lockedZoomScale}`} />
        </pattern>
        <pattern
          id="orbitalMapSmallGrid"
          width={50 * lockedZoomScale}
          height={50 * lockedZoomScale}
          patternUnits="userSpaceOnUse">
          <rect
            width={50 * lockedZoomScale}
            height={50 * lockedZoomScale}
            fill="#2B2E3B" />
          <path
            fill="none"
            stroke={GRID_COLOR}
            strokeWidth="0.5"
            d={`M ${50 * lockedZoomScale} 0 L 0 0 0 ${50 * lockedZoomScale}`} />
        </pattern>
      </defs>
      <rect
        x="-50%"
        y="-50%"
        width="100%"
        height="100%"
        fill="url(#orbitalMapGrid)" />
      {interdictionCircle}
      {targetMarker}
      {map_objects.map(drawObject)}
      {drawOurShip()}
    </svg>
  );

  return children({
    svgComponent,
  });
};
