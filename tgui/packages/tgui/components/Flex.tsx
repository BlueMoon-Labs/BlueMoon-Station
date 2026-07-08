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
    // Absent props must not land in the object even as undefined,
    // otherwise they clobber the same keys in consumer style.
    style: {
      ...rest.style,
      ...(direction !== undefined && { flexDirection: direction }),
      ...(wrap !== undefined && { flexWrap: wrap === true ? 'wrap' : wrap }),
      ...(align !== undefined && { alignItems: align }),
      ...(justify !== undefined && { justifyContent: justify }),
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
      ...(grow !== undefined && { flexGrow: Number(grow) }),
      ...(shrink !== undefined && { flexShrink: Number(shrink) }),
      ...(basis !== undefined && { flexBasis: unit(basis) }),
      ...(order !== undefined && { order }),
      ...(align !== undefined && { alignSelf: align }),
    },
  };
};

const FlexItem = props => (
  <Box {...computeFlexItemProps(props)} />
);

Flex.Item = FlexItem;
