/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

export const connectionsMatch = (a, b) => (
  a.ckey === b.ckey
    && a.address === b.address
    && a.computer_id === b.computer_id
);
