import { useLayoutEffect, useRef, useState } from 'react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { StationMap } from './common/StationMap';

export const StationMinimap = () => {
  const { data } = useBackend();
  return (
    <Window title="Карта станции" width={800} height={600}>
      <Window.Content>
        <StationMap
          maps={data.maps}
          initialZ={data.z}
          renderMarkers={floor => (
            <StationAreaTooltip key={floor.z} areas={floor.areas} />
          )} />
      </Window.Content>
    </Window>
  );
};

const StationAreaTooltip = ({ areas }) => {
  const pixels = useRef(null);
  const tooltip = useRef(null);
  const cursorAnchor = useRef(null);
  const [areaName, setAreaName] = useState('');
  const visible = !!areaName;
  const updateTooltipPosition = () => {
    const anchor = cursorAnchor.current;
    const element = tooltip.current;
    if (!anchor || !element) {
      return;
    }
    const overlay = anchor.parentElement;
    const viewport = overlay.closest('.StationMap__viewport');
    if (!viewport) {
      return;
    }
    const cursorRect = anchor.getBoundingClientRect();
    const tooltipRect = element.getBoundingClientRect();
    const bounds = viewport.getBoundingClientRect();
    const scale = overlay.getBoundingClientRect().width / overlay.clientWidth;
    const padding = 4 * scale;
    // Подсказка и якорь находятся под одним CSS zoom; в пиксели элемента переводим только отступ.
    const preferredLeft = cursorRect.left + 12 * scale;
    const left = Math.max(bounds.left + padding, Math.min(
      preferredLeft + tooltipRect.width > bounds.right - padding
        ? cursorRect.left - tooltipRect.width - 12 * scale : preferredLeft,
      bounds.right - tooltipRect.width - padding,
    ));
    const top = Math.max(bounds.top + padding, Math.min(
      cursorRect.top - tooltipRect.height / 2, bounds.bottom - tooltipRect.height - padding,
    ));
    element.style.left = `${(left - cursorRect.left) / scale}px`;
    element.style.top = `${(top - cursorRect.top) / scale}px`;
  };
  useLayoutEffect(updateTooltipPosition, [areaName]);
  if (!areas) {
    return null;
  }
  return (
    <div
      className="StationMinimap__areaOverlay"
      onMouseLeave={() => setAreaName('')}
      onPointerDown={() => setAreaName('')}
      onWheel={() => setAreaName('')}
      onMouseMove={e => {
        const image = pixels.current;
        const target = e.currentTarget;
        if (!image || e.buttons) {
          setAreaName('');
          return;
        }
        // Доли от экранных размеров сохраняют положение якоря при любом CSS zoom.
        const rect = target.getBoundingClientRect();
        const relativeX = (e.clientX - rect.left) / rect.width;
        const relativeY = (e.clientY - rect.top) / rect.height;
        const x = Math.floor(relativeX * image.width);
        const y = Math.floor(relativeY * image.height);
        if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
          setAreaName('');
          return;
        }
        const index = (y * image.width + x) * 4;
        const color = '#' + Array.from(image.data.subarray(index, index + 3))
          .map(channel => channel.toString(16).padStart(2, '0'))
          .join('');
        cursorAnchor.current.style.left = `${relativeX * 100}%`;
        cursorAnchor.current.style.top = `${relativeY * 100}%`;
        setAreaName(areas.names[color] || '');
        updateTooltipPosition();
      }}>
      <div ref={cursorAnchor} className="StationMinimap__cursorAnchor">
        {visible && (
          <div ref={tooltip} className="Tooltip StationMinimap__areaTooltip" role="tooltip">
            {areaName}
          </div>
        )}
      </div>
      <img
        hidden
        src={areas.image}
        alt=""
        onLoad={e => {
          const image = e.currentTarget;
          const canvas = document.createElement('canvas');
          canvas.width = image.naturalWidth;
          canvas.height = image.naturalHeight;
          const context = canvas.getContext('2d');
          if (!context) {
            return;
          }
          context.drawImage(image, 0, 0);
          pixels.current = context.getImageData(0, 0, canvas.width, canvas.height);
        }} />
    </div>
  );
};
