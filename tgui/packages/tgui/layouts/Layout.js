/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { classes } from 'common/react';

import { computeBoxClassName, computeBoxProps } from '../components/Box';
import { addScrollableNode, removeScrollableNode } from '../events';

export const Layout = props => {
  const {
    className,
    theme = 'nanotrasen',
    children,
    ...rest
  } = props;
  return (
    <div className={'theme-' + theme}>
      <div
        className={classes([
          'Layout',
          className,
          computeBoxClassName(rest),
        ])}
        {...computeBoxProps(rest)}>
        {children}
      </div>
    </div>
  );
};

// Stable identity ref callback, so React runs it once per mount,
// not on every render. Returns a cleanup (React 19 ref cleanup API).
const trackScrollableNode = node => {
  if (!node) {
    return;
  }
  addScrollableNode(node);
  return () => removeScrollableNode(node);
};

const LayoutContent = props => {
  const {
    className,
    scrollable,
    children,
    ...rest
  } = props;
  return (
    <div
      ref={trackScrollableNode}
      className={classes([
        'Layout__content',
        scrollable && 'Layout__content--scrollable',
        className,
        computeBoxClassName(rest),
      ])}
      {...computeBoxProps(rest)}>
      {children}
    </div>
  );
};

Layout.Content = LayoutContent;
