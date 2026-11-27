import { Box, Button, ColorPicker, Icon, Input, Stack, Tooltip } from 'tgui/components';

const HEX_COLOR = /^#[0-9a-fA-F]{6}$/;

// Diagonal line: "no color", so an empty value does not read as black.
const EMPTY_SWATCH_BG = 'linear-gradient(to top right, transparent 45%,'
  + ' rgba(255, 90, 90, 0.8) 45%, rgba(255, 90, 90, 0.8) 55%, transparent 55%)';

const ColorSwatch = (props) => {
  const { value, defaultColor, onChange } = props;
  const displayColor = value || defaultColor;
  const empty = !HEX_COLOR.test(displayColor || '');
  return (
    <Box
      position="relative"
      style={{ width: '22px', height: '22px' }}>
      <ColorPicker
        value={empty ? null : displayColor}
        width="22px"
        height="22px"
        onCommit={onChange}
      />
      {empty && (
        <Box
          className="ColorSwatch__empty"
          style={{
            position: 'absolute',
            inset: '0',
            borderRadius: '2px',
            pointerEvents: 'none',
            background: EMPTY_SWATCH_BG + ', #9a9a9a',
          }}
        />
      )}
    </Box>
  );
};

/**
 * Color input with the shared TGUI picker and a text field.
 * compact: only the swatch, the value goes into the tooltip.
 */
export const ColorInput = (props) => {
  const {
    value,
    defaultColor,
    placeholder,
    compact,
    onChange,
    onClear,
  } = props;
  if (compact) {
    return (
      <Box inline nowrap>
        <Tooltip content={value || placeholder}>
          <Box inline verticalAlign="middle">
            <ColorSwatch
              value={value}
              defaultColor={defaultColor}
              onChange={onChange} />
          </Box>
        </Tooltip>
        {onClear && (
          <Tooltip content="Убрать цвет">
            <Box
              inline
              className="ColorInput__clear"
              color="label"
              verticalAlign="middle"
              textAlign="center"
              style={{
                width: '12px',
                cursor: 'pointer',
                visibility: value ? 'visible' : 'hidden',
              }}
              onClick={onClear}>
              <Icon name="times" />
            </Box>
          </Tooltip>
        )}
      </Box>
    );
  }
  return (
    <Stack inline align="center">
      <Stack.Item>
        <ColorSwatch
          value={value}
          defaultColor={defaultColor}
          onChange={onChange}
        />
      </Stack.Item>
      <Stack.Item>
        <Input
          width="6em"
          monospace
          placeholder={placeholder}
          value={value}
          onInput={(e, v) => onChange(v)}
        />
      </Stack.Item>
      {!!value && onClear && (
        <Stack.Item>
          <Button
            icon="times"
            ml={1}
            onClick={onClear}
          />
        </Stack.Item>
      )}
    </Stack>
  );
};
