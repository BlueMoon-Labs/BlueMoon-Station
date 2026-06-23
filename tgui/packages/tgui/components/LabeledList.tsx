/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { BooleanLike, classes } from 'common/react';
import { ReactNode } from 'react';

import { Box, unit } from './Box';
import { Divider } from './Divider';

type LabeledListProps = {
  readonly children?: any;
};

export const LabeledList = (props: LabeledListProps) => {
  const { children } = props;
  return (
    <table className="LabeledList">
      <tbody>
        {children}
      </tbody>
    </table>
  );
};

type LabeledListItemProps = {
  readonly className?: string | BooleanLike;
  readonly label?: ReactNode;
  readonly labelColor?: string | BooleanLike;
  readonly color?: string | BooleanLike;
  readonly textAlign?: string | BooleanLike;
  readonly buttons?: ReactNode,
  /** @deprecated */
  readonly content?: any,
  readonly children?: ReactNode;
};

const LabeledListItem = (props: LabeledListItemProps) => {
  const {
    className,
    label,
    labelColor = 'label',
    color,
    textAlign,
    buttons,
    content,
    children,
  } = props;
  return (
    <tr
      className={classes([
        'LabeledList__row',
        className,
      ])}>
      <Box
        as="td"
        color={labelColor}
        className={classes([
          'LabeledList__cell',
          'LabeledList__label',
        ])}>
        {label ? <>{label}:</> : null}
      </Box>
      <Box
        as="td"
        color={color}
        textAlign={textAlign}
        className={classes([
          'LabeledList__cell',
          'LabeledList__content',
        ])}
        colSpan={buttons ? undefined : 2}>
        {content}
        {children}
      </Box>
      {buttons && (
        <td className="LabeledList__cell LabeledList__buttons">
          {buttons}
        </td>
      )}
    </tr>
  );
};

type LabeledListDividerProps = {
  readonly size?: number;
};

const LabeledListDivider = (props: LabeledListDividerProps) => {
  const padding = props.size
    ? unit(Math.max(0, props.size - 1))
    : 0;
  return (
    <tr className="LabeledList__row">
      <td
        colSpan={3}
        style={{
          paddingTop: padding,
          paddingBottom: padding,
        }}>
        <Divider />
      </td>
    </tr>
  );
};

LabeledList.Item = LabeledListItem;
LabeledList.Divider = LabeledListDivider;
