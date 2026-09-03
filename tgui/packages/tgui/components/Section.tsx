/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { canRender, classes } from 'common/react';
import { Component, createRef, ReactNode, RefObject } from 'react';

import { addScrollableNode, removeScrollableNode } from '../events';
import { BoxProps, computeBoxClassName, computeBoxProps } from './Box';

interface SectionProps extends BoxProps {
  className?: string;
  title?: string;
  buttons?: ReactNode;
  fill?: boolean;
  fitted?: boolean;
  scrollable?: boolean;
  /** @deprecated Please use `scrollable` property */
  overflowY?: any;
}

export class Section extends Component<SectionProps> {
  scrollableRef: RefObject<HTMLDivElement>;
  scrollable: boolean;

  constructor(props) {
    super(props);
    this.scrollableRef = props.scrollableRef || createRef();
    this.scrollable = props.scrollable;
  }

  componentDidMount() {
    if (this.scrollable) {
      addScrollableNode(this.scrollableRef.current as HTMLElement);
    }
  }

  componentWillUnmount() {
    if (this.scrollable) {
      removeScrollableNode(this.scrollableRef.current as HTMLElement);
    }
  }

  render() {
    const {
      className,
      title,
      buttons,
      fill,
      fitted,
      scrollable,
      children,
      // Not DOM props: consume them here so they don't leak to the div.
      scrollableRef,
      onScroll,
      ...rest
    } = this.props as SectionProps & {
      scrollableRef?: RefObject<HTMLDivElement>;
      onScroll?: (ev: Event) => void;
    };
    const hasTitle = canRender(title) || canRender(buttons);
    return (
      <div
        className={classes([
          'Section',
          fill && 'Section--fill',
          fitted && 'Section--fitted',
          scrollable && 'Section--scrollable',
          className,
          computeBoxClassName(rest),
        ])}
        {...computeBoxProps(rest)}>
        {hasTitle && (
          <div className="Section__title">
            <span className="Section__titleText">
              {title}
            </span>
            <div className="Section__buttons">
              {buttons}
            </div>
          </div>
        )}
        <div className="Section__rest">
          <div
            ref={this.scrollableRef}
            // Scroll events do not bubble: the handler must sit on the
            // element that actually scrolls, which is Section__content.
            onScroll={onScroll as any}
            className="Section__content">
            {children}
          </div>
        </div>
      </div>
    );
  }
}
