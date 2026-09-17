import { classes } from 'common/react';
import { Component, createRef } from 'react';

import { Icon } from './Icon';

/**
 * Button that displays an image (base64 data URL) on the left.
 * Used by the cargo catalog to show previews of purchasable items.
 */
export class ImageButton extends Component {
  constructor() {
    super();
    this.buttonRef = createRef();
  }

  handleClick = (event) => {
    const { disabled, onClick } = this.props;
    if (disabled || !onClick) {
      return;
    }
    event.preventDefault();
    onClick(event);
  };

  render() {
    const {
      buttonsAlt,
      children,
      className,
      color,
      disabled,
      fluid,
      img,
      imageSize = 32,
      onClick,
      ...rest
    } = this.props;

    return (
      <div
        className={classes([
          'ImageButton',
          fluid && 'ImageButton--fluid',
          disabled && 'ImageButton--disabled',
          color && 'ImageButton--color--' + color,
          className,
        ])}
        onClick={this.handleClick}
        role={onClick ? 'button' : undefined}
        style={{
          ...rest.style,
        }}
      >
        <div
          className="ImageButton__image"
          style={{ width: imageSize + 'px', height: imageSize + 'px' }}
        >
          {img ? (
            <img alt="" src={img} />
          ) : (
            <Icon className="ImageButton__placeholder" name="box" />
          )}
        </div>
        <div className="ImageButton__content">{children}</div>
        {!!buttonsAlt && (
          <div className="ImageButton__buttons" onClick={(e) => e.stopPropagation()}>
            {buttonsAlt}
          </div>
        )}
      </div>
    );
  }
}