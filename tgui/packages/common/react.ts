/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { isValidElement } from 'react';

/**
 * Helper for conditionally adding/removing classes in React
 */
export const classes = (classNames: (string | BooleanLike)[]) => {
  let className = '';
  for (let i = 0; i < classNames.length; i++) {
    const part = classNames[i];
    if (typeof part === 'string') {
      className += part + ' ';
    }
  }
  return className;
};

/**
 * Normalizes children prop, so that it is always an array of VDom
 * elements.
 */
export const normalizeChildren = <T>(children: T | T[]) => {
  if (Array.isArray(children)) {
    return children.flat().filter(value => value) as T[];
  }
  if (typeof children === 'object') {
    return [children];
  }
  return [];
};

/**
 * Returns true if a ref can be attached directly to the given child
 * element. DOM elements and function components are fine (React 19
 * passes ref through as a regular prop); class components would give
 * us a component instance instead of a DOM node.
 */
export const canDirectlyRef = (child: unknown): boolean => {
  if (!isValidElement(child)) {
    return false;
  }
  const type = child.type as any;
  if (typeof type === 'string') {
    return true;
  }
  if (typeof type === 'function') {
    return !type.prototype?.isReactComponent;
  }
  // memo() and similar wrappers
  if (typeof type === 'object' && type !== null) {
    return true;
  }
  return false;
};

/**
 * Shallowly checks if two objects are different.
 * Credit: https://github.com/developit/preact-compat
 */
export const shallowDiffers = (a: object, b: object) => {
  let i;
  for (i in a) {
    if (!(i in b)) {
      return true;
    }
  }
  for (i in b) {
    if (a[i] !== b[i]) {
      return true;
    }
  }
  return false;
};

/**
 * A helper to determine whether the object is renderable by React.
 */
export const canRender = (value: unknown) => {
  return value !== undefined
    && value !== null
    && typeof value !== 'boolean';
};

/**
 * A common case in tgui, when you pass a value conditionally, these are
 * the types that can fall through the condition.
 */
export type BooleanLike = number | boolean | null | undefined;
