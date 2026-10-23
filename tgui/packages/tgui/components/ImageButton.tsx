import { Placement } from '@popperjs/core';
import { BooleanLike, classes } from 'common/react';
import { KeyboardEvent, MouseEvent, ReactNode } from 'react';

import { Box, BoxProps } from './Box';
import { Icon } from './Icon';
import { Tooltip } from './Tooltip';

type ImageButtonProps = BoxProps & {
  asset?: string[];
  assetSize?: number;
  base64?: string;
  buttons?: ReactNode;
  buttonsAlt?: ReactNode;
  disabled?: BooleanLike;
  fluid?: boolean;
  imageSize?: number;
  imageSrc?: string;
  onClick?: (event: MouseEvent | KeyboardEvent) => void;
  onRightClick?: (event: MouseEvent) => void;
  tooltip?: ReactNode;
  tooltipPosition?: Placement;
};

// Карточка Nova: отдельная область выдачи и независимые элементы управления.
export const ImageButton = (props: ImageButtonProps) => {
  const {
    asset,
    assetSize = 32,
    base64,
    buttons,
    buttonsAlt,
    children,
    className,
    disabled,
    fluid,
    imageSize = 64,
    imageSrc,
    onClick,
    onRightClick,
    tooltip,
    tooltipPosition,
    ...rest
  } = props;
  let content = (
    <div
      className="ImageButton__container"
      role="button"
      aria-disabled={!!disabled}
      tabIndex={disabled ? undefined : 0}
      style={{ width: fluid ? 'auto' : `calc(${imageSize}px + 0.5em + 2px)` }}
      onClick={(event) => !disabled && onClick?.(event)}
      onContextMenu={(event) => {
        event.preventDefault();
        if (!disabled) {
          onRightClick?.(event);
        }
      }}
      onKeyDown={(event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          if (!disabled) {
            onClick?.(event);
          }
        }
      }}>
      <div
        className="ImageButton__image"
        style={{ width: imageSize, height: imageSize }}>
        {base64 || imageSrc ? (
          <img
            src={base64 ? `data:image/png;base64,${base64}` : imageSrc}
            width={imageSize}
            height={imageSize}
            alt=""
          />
        ) : asset ? (
          <span
            className={classes(asset)}
            style={{
              display: 'block',
              imageRendering: 'pixelated',
              transform: `scale(${imageSize / assetSize})`,
              transformOrigin: 'top left',
            }}
          />
        ) : (
          <Icon name="question" style={{ fontSize: imageSize }} />
        )}
      </div>
      {!!children && <div className="ImageButton__content">{children}</div>}
    </div>
  );
  if (tooltip) {
    content = (
      <Tooltip content={tooltip} position={tooltipPosition}>
        {content}
      </Tooltip>
    );
  }
  return (
    <Box
      className={classes([
        'ImageButton',
        fluid && 'ImageButton--fluid',
        disabled && 'ImageButton--disabled',
        className,
      ])}
      {...rest}>
      {content}
      {!!buttons && <div className="ImageButton__buttons">{buttons}</div>}
      {!!buttonsAlt && (
        <div className="ImageButton__buttons ImageButton__buttons--alt">
          {buttonsAlt}
        </div>
      )}
    </Box>
  );
};
