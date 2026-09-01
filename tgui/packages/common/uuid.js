/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

/**
 * Creates a UUID v4 string
 *
 * @return {string}
 */
export const createUuid = () => crypto.randomUUID();
