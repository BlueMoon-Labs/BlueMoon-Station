import { MESSAGE_STYLES } from '../settings/constants';
import { RADIO_JOB_IDS } from '../settings/radioJobs';
import { getChatColorProps, getChatCustomProps, getGameFxRootClasses, getRadioJobRoot, getSettleRootClasses, getStyleOverrideRoot, isGameFxRootClass, isRadioJobRootClass, isStyleOverrideClass } from './rootAppearance';

const BASE = {
  chatAnimSpeed: 'normal',
  textGlow: 'none',
  textGlowColor: '',
  chatAccentColor: '',
  messageSpacing: 2,
  fontWeight: 400,
  letterSpacing: 0,
  borderRadius: 8,
};

test('custom props of default settings', () => {
  expect(getChatCustomProps(BASE)).toEqual({
    '--chat-anim-speed': '320ms',
    '--chat-glow': null,
    '--chat-msg-spacing': '2px',
    '--chat-font-weight': '400',
    '--chat-letter-spacing': '0px',
    '--chat-border-radius': '8px',
  });
});

test('animation speed comes from the speed list', () => {
  expect(getChatCustomProps({ ...BASE, chatAnimSpeed: 'fast' })['--chat-anim-speed'])
    .toBe('180ms');
  expect(getChatCustomProps({ ...BASE, chatAnimSpeed: 'slow' })['--chat-anim-speed'])
    .toBe('550ms');
  expect(getChatCustomProps({ ...BASE, chatAnimSpeed: 'bogus' })['--chat-anim-speed'])
    .toBe('320ms');
});

test('glow takes its own color, then the accent, then yellow', () => {
  const glow = settings => getChatCustomProps({ ...BASE, ...settings })['--chat-glow'];
  expect(glow({ textGlow: 'subtle' })).toBe('0 0 4px #ffdd44');
  expect(glow({ textGlow: 'subtle', chatAccentColor: '#123456' }))
    .toBe('0 0 4px #123456');
  expect(glow({ textGlow: 'strong', chatAccentColor: '#123456', textGlowColor: '#abcdef' }))
    .toBe('0 0 10px #abcdef, 0 0 20px #abcdef');
});

test('empty colors are removed', () => {
  expect(getChatColorProps('#101010', '', undefined)).toEqual({
    '--chat-bg': '#101010',
    '--chat-text': null,
    '--chat-accent': null,
  });
});

test('style overrides map to root classes and colors', () => {
  const { classes, props } = getStyleOverrideRoot({
    emote: { color: '#ff0000' },
    whisper: { disabled: true },
  }, false);
  expect(classes).toEqual(['Chat--fxAnimOff', 'Chat--plain-whisper']);
  expect(props['--cs-emote-color']).toBe('#ff0000');
  expect(props['--cs-whisper-color']).toBeNull();
  expect(Object.keys(props)).toHaveLength(MESSAGE_STYLES.length);
  expect(getStyleOverrideRoot({}, true).classes).toEqual([]);
  expect(classes.every(isStyleOverrideClass)).toBe(true);
  expect(isStyleOverrideClass('Chat--style-seccon')).toBe(false);
});

test('game effect switches map to root classes', () => {
  expect(getGameFxRootClasses({ tremble: false, drunk: true, bogus: false }, true))
    .toEqual(['Chat--fxOff-tremble']);
  expect(getGameFxRootClasses({ tremble: false }, false))
    .toEqual(['Chat--gameFxOff']);
  expect(getGameFxRootClasses(undefined, true)).toEqual([]);
  expect(isGameFxRootClass('Chat--gameFxOff')).toBe(true);
  expect(isGameFxRootClass('Chat--fxOff-dizzy')).toBe(true);
  expect(isGameFxRootClass('Chat--fxAnimOff')).toBe(false);
});

test('settle switch maps to a root class', () => {
  expect(getSettleRootClasses(false)).toEqual(['Chat--noSettle']);
  expect(getSettleRootClasses(true)).toEqual([]);
  expect(getSettleRootClasses(undefined)).toEqual([]);
});

test('radio job defaults: department colors and a head icon', () => {
  const { classes, props } = getRadioJobRoot({});
  expect(classes).toEqual(['Chat--rjHead-icon']);
  expect(Object.keys(props)).toHaveLength(RADIO_JOB_IDS.length);
  expect(Object.values(props).every(value => value === null)).toBe(true);
});

test('radio job modes, head marks and names map to root classes', () => {
  expect(getRadioJobRoot({ radioJobColorMode: 'legacy' }).classes)
    .toContain('Chat--rjLegacy');
  expect(getRadioJobRoot({ radioJobColorMode: 'none' }).classes)
    .toContain('Chat--rjNoColor');
  expect(getRadioJobRoot({ radioJobColorMode: 'bogus', radioJobHeadMark: 'bogus' })
    .classes).toEqual(['Chat--rjHead-icon']);
  expect(getRadioJobRoot({ radioJobHeadMark: 'none' }).classes).toEqual([]);
  expect(getRadioJobRoot({ radioJobHeadMark: 'command', radioJobColorNames: true })
    .classes).toEqual(['Chat--rjHead-command', 'Chat--rjNames']);
  const all = getRadioJobRoot({
    radioJobColorMode: 'none', radioJobHeadMark: 'bold', radioJobColorNames: true,
  }).classes;
  expect(all.every(isRadioJobRootClass)).toBe(true);
  expect(isRadioJobRootClass('Chat--hideRadioJobs')).toBe(false);
});

test('job icons are on unless turned off', () => {
  expect(getRadioJobRoot({}).classes).not.toContain('Chat--rjNoIcon');
  expect(getRadioJobRoot({ radioJobIcons: true }).classes)
    .not.toContain('Chat--rjNoIcon');
  const off = getRadioJobRoot({ radioJobIcons: false }).classes;
  expect(off).toContain('Chat--rjNoIcon');
  expect(off.every(isRadioJobRootClass)).toBe(true);
});

test('radio job colors become properties, junk is dropped', () => {
  const { props } = getRadioJobRoot({
    radioJobColors: { med: '#00ff00', sec: 'red', bogus: '#123456' },
  });
  expect(props['--rj-med']).toBe('#00ff00');
  expect(props['--rj-sec']).toBeNull();
  expect(props['--rj-bogus']).toBeUndefined();
});
