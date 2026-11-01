import { GLYPH_TYPES, glyphSvgPaths, nodeGlyph } from './nodeGlyphs';
import { NODE_NAMES } from './types';

test('every known device has its own cached glyph rather than the generic circle', () => {
  for (const type of Object.keys(NODE_NAMES)) {
    expect(GLYPH_TYPES).toContain(type);
    expect(nodeGlyph(type).family).not.toBe('device');
    expect(glyphSvgPaths(type)).toBe(glyphSvgPaths(type));
  }
  expect(glyphSvgPaths('relay').body).not.toEqual(glyphSvgPaths('gateway').body);
  expect(glyphSvgPaths('camera').body).not.toEqual(glyphSvgPaths('terminal').body);
});
