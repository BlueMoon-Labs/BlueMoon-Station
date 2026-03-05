/**
 * @file
 * @copyright 2026
 * @license MIT
 */

export const NODE_ENV = process.env.NODE_ENV || 'development';
export const IS_PRODUCTION = NODE_ENV === 'production';
export const IS_DEVELOPMENT = !IS_PRODUCTION;
