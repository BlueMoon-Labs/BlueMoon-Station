/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { BooleanLike, classes } from 'common/react';
import { createElement, CSSProperties, memo, ReactNode } from 'react';

import { CSS_COLORS } from '../constants';

export interface BoxProps {
  [key: string]: any;
  as?: string;
  className?: string | BooleanLike;
  children?: ReactNode;
  position?: string | BooleanLike;
  overflow?: string | BooleanLike;
  overflowX?: string | BooleanLike;
  overflowY?: string | BooleanLike;
  top?: string | BooleanLike;
  bottom?: string | BooleanLike;
  left?: string | BooleanLike;
  right?: string | BooleanLike;
  width?: string | BooleanLike;
  minWidth?: string | BooleanLike;
  maxWidth?: string | BooleanLike;
  height?: string | BooleanLike;
  minHeight?: string | BooleanLike;
  maxHeight?: string | BooleanLike;
  fontSize?: string | BooleanLike;
  fontFamily?: string;
  lineHeight?: string | BooleanLike;
  opacity?: number;
  textAlign?: string | BooleanLike;
  verticalAlign?: string | BooleanLike;
  inline?: BooleanLike;
  bold?: BooleanLike;
  italic?: BooleanLike;
  nowrap?: BooleanLike;
  preserveWhitespace?: BooleanLike;
  m?: string | BooleanLike;
  mx?: string | BooleanLike;
  my?: string | BooleanLike;
  mt?: string | BooleanLike;
  mb?: string | BooleanLike;
  ml?: string | BooleanLike;
  mr?: string | BooleanLike;
  p?: string | BooleanLike;
  px?: string | BooleanLike;
  py?: string | BooleanLike;
  pt?: string | BooleanLike;
  pb?: string | BooleanLike;
  pl?: string | BooleanLike;
  pr?: string | BooleanLike;
  color?: string | BooleanLike;
  textColor?: string | BooleanLike;
  backgroundColor?: string | BooleanLike;
  fillPositionedParent?: boolean;
}

/**
 * Coverts our rem-like spacing unit into a CSS unit.
 */
export const unit = (value: unknown): string | undefined => {
  if (typeof value === 'string') {
    // Transparently convert pixels into rem units
    if (value.endsWith('px')) {
      return parseFloat(value) / 12 + 'rem';
    }
    return value;
  }
  if (typeof value === 'number') {
    return value + 'rem';
  }
};

/**
 * Same as `unit`, but half the size for integers numbers.
 */
export const halfUnit = (value: unknown): string | undefined => {
  if (typeof value === 'string') {
    return unit(value);
  }
  if (typeof value === 'number') {
    return unit(value * 0.5);
  }
};

const isColorCode = (str: unknown) => !isColorClass(str);

const isColorClass = (str: unknown): boolean => {
  if (typeof str === 'string') {
    return CSS_COLORS.includes(str);
  }
};

const mapRawPropTo = attrName => (style, value) => {
  if (typeof value === 'number' || typeof value === 'string') {
    style[attrName] = value;
  }
};

const mapUnitPropTo = (attrName, unit) => (style, value) => {
  if (typeof value === 'number' || typeof value === 'string') {
    style[attrName] = unit(value);
  }
};

const mapBooleanPropTo = (attrName, attrValue) => (style, value) => {
  if (value) {
    style[attrName] = attrValue;
  }
};

const mapDirectionalUnitPropTo = (attrName, unit, dirs) => (style, value) => {
  if (typeof value === 'number' || typeof value === 'string') {
    for (let i = 0; i < dirs.length; i++) {
      style[attrName + dirs[i]] = unit(value);
    }
  }
};

const mapColorPropTo = attrName => (style, value) => {
  if (isColorCode(value)) {
    style[attrName] = value;
  }
};

const styleMapperByPropName = {
  // Direct mapping
  position: mapRawPropTo('position'),
  overflow: mapRawPropTo('overflow'),
  overflowX: mapRawPropTo('overflowX'),
  overflowY: mapRawPropTo('overflowY'),
  top: mapUnitPropTo('top', unit),
  bottom: mapUnitPropTo('bottom', unit),
  left: mapUnitPropTo('left', unit),
  right: mapUnitPropTo('right', unit),
  width: mapUnitPropTo('width', unit),
  minWidth: mapUnitPropTo('minWidth', unit),
  maxWidth: mapUnitPropTo('maxWidth', unit),
  height: mapUnitPropTo('height', unit),
  minHeight: mapUnitPropTo('minHeight', unit),
  maxHeight: mapUnitPropTo('maxHeight', unit),
  fontSize: mapUnitPropTo('fontSize', unit),
  fontFamily: mapRawPropTo('fontFamily'),
  lineHeight: (style, value) => {
    if (typeof value === 'number') {
      style['lineHeight'] = value;
    }
    else if (typeof value === 'string') {
      style['lineHeight'] = unit(value);
    }
  },
  opacity: mapRawPropTo('opacity'),
  textAlign: mapRawPropTo('textAlign'),
  verticalAlign: mapRawPropTo('verticalAlign'),
  // Boolean props
  inline: mapBooleanPropTo('display', 'inline-block'),
  bold: mapBooleanPropTo('fontWeight', 'bold'),
  italic: mapBooleanPropTo('fontStyle', 'italic'),
  nowrap: mapBooleanPropTo('whiteSpace', 'nowrap'),
  preserveWhitespace: mapBooleanPropTo('whiteSpace', 'pre-wrap'),
  // Margins
  m: mapDirectionalUnitPropTo('margin', halfUnit, [
    'Top', 'Bottom', 'Left', 'Right',
  ]),
  mx: mapDirectionalUnitPropTo('margin', halfUnit, [
    'Left', 'Right',
  ]),
  my: mapDirectionalUnitPropTo('margin', halfUnit, [
    'Top', 'Bottom',
  ]),
  mt: mapUnitPropTo('marginTop', halfUnit),
  mb: mapUnitPropTo('marginBottom', halfUnit),
  ml: mapUnitPropTo('marginLeft', halfUnit),
  mr: mapUnitPropTo('marginRight', halfUnit),
  // Paddings
  p: mapDirectionalUnitPropTo('padding', halfUnit, [
    'Top', 'Bottom', 'Left', 'Right',
  ]),
  px: mapDirectionalUnitPropTo('padding', halfUnit, [
    'Left', 'Right',
  ]),
  py: mapDirectionalUnitPropTo('padding', halfUnit, [
    'Top', 'Bottom',
  ]),
  pt: mapUnitPropTo('paddingTop', halfUnit),
  pb: mapUnitPropTo('paddingBottom', halfUnit),
  pl: mapUnitPropTo('paddingLeft', halfUnit),
  pr: mapUnitPropTo('paddingRight', halfUnit),
  // Color props
  color: mapColorPropTo('color'),
  textColor: mapColorPropTo('color'),
  backgroundColor: mapColorPropTo('backgroundColor'),
  // Utility props
  fillPositionedParent: (style, value) => {
    if (value) {
      style['position'] = 'absolute';
      style['top'] = 0;
      style['bottom'] = 0;
      style['left'] = 0;
      style['right'] = 0;
    }
  },
};

export const computeBoxProps = (props: BoxProps) => {
  const computedProps: Record<string, any> = {};
  const computedStyles: CSSProperties = {};
  // Compute props
  for (let propName of Object.keys(props)) {
    if (propName === 'style') {
      continue;
    }
    const propValue = props[propName];
    const mapPropToStyle = styleMapperByPropName[propName];
    if (mapPropToStyle) {
      mapPropToStyle(computedStyles, propValue);
    }
    else {
      computedProps[propName] = propValue;
    }
  }
  const style = {
    ...computedStyles,
    ...props.style,
  };
  if (Object.keys(style).length > 0) {
    computedProps.style = style;
  }
  return computedProps;
};

export const computeBoxClassName = (props: BoxProps) => {
  const color = props.textColor || props.color;
  const backgroundColor = props.backgroundColor;
  return classes([
    isColorClass(color) && 'color-' + color,
    isColorClass(backgroundColor) && 'color-bg-' + backgroundColor,
  ]);
};

const BoxInner = (props: BoxProps) => {
  const {
    as = 'div',
    className,
    children,
    ...rest
  } = props;
  // Render props
  if (typeof children === 'function') {
    return (children as (props: Record<string, any>) => ReactNode)(
      computeBoxProps(props),
    );
  }
  const computedClassName = typeof className === 'string'
    ? className + ' ' + computeBoxClassName(rest)
    : computeBoxClassName(rest);
  const computedProps = computeBoxProps(rest);
  // Render a wrapper element
  return createElement(as, {
    ...computedProps,
    className: computedClassName,
  }, children);
};

export const Box = memo(BoxInner);
