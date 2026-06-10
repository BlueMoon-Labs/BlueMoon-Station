/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { BooleanLike, classes } from 'common/react';

import { Box, BoxProps, unit } from './Box';

export interface FlexProps extends BoxProps {
  direction?: string | BooleanLike;
  wrap?: string | BooleanLike;
  align?: string | BooleanLike;
  justify?: string | BooleanLike;
  inline?: BooleanLike;
}

export const computeFlexProps = (props: FlexProps) => {
  const {
    className,
    direction,
    wrap,
    align,
    justify,
    inline,
    ...rest
  } = props;
  return {
    className: classes([
      'Flex',
      inline && 'Flex--inline',
      className,
    ]),
    ...rest,
    // camelCase keys are required: React appends 'px' to numeric values
    // of unknown (kebab-case) properties, producing invalid CSS.
    style: {
      ...rest.style,
      flexDirection: direction,
      flexWrap: wrap === true ? 'wrap' : wrap,
      alignItems: align,
      justifyContent: justify,
    },
  };
};

export const Flex = props => (
  <Box {...computeFlexProps(props)} />
);

export interface FlexItemProps extends BoxProps {
  grow?: number;
  order?: number;
  shrink?: number;
  basis?: string | BooleanLike;
  align?: string | BooleanLike;
}

export const computeFlexItemProps = (props: FlexItemProps) => {
  const {
    className,
    style,
    grow,
    order,
    shrink,
    basis = props.width,
    align,
    ...rest
  } = props;
  return {
    className: classes([
      'Flex__item',
      className,
    ]),
    ...rest,
    style: {
      ...style,
      flexGrow: grow !== undefined ? Number(grow) : undefined,
      flexShrink: shrink !== undefined ? Number(shrink) : undefined,
      flexBasis: unit(basis),
      order: order,
      alignSelf: align,
    },
  };
};

const FlexItem = props => (
  <Box {...computeFlexItemProps(props)} />
);

Flex.Item = FlexItem;
