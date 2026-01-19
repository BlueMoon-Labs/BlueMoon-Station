
import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Box, Button, Flex, Icon, Section } from '../components';
import { Window } from "../layouts";

export const Safe = (properties, context) => {
  const { act, data } = useBackend(context);
  const {
    dial,
    open,
    theme = "ntos",
  } = data;
  return (
    <Window
      width={625}
      height={800}
      theme={theme}>
      <Window.Content>
        <Box className="Safe__engraving">
          <Dialer />
          <Box>
            <Box
              className="Safe__engraving-hinge"
              top="25%" />
            <Box
              className="Safe__engraving-hinge"
              top="75%" />
          </Box>
          <Icon
            className="Safe__engraving-arrow"
            name="long-arrow-alt-down"
            size="5"
          /><br />
          {open ? (
            <Contents />
          ) : (
            <Box
              as="img"
              className="Safe__dial"
              src={resolveAsset('safe_dial.png')}
              style={{
                "transform": "rotate(-" + (3.6 * dial) + "deg)",
              }}
            />
          )}
        </Box>
        {!open && (
          <Help />
        )}
      </Window.Content>
    </Window>
  );
};

const Dialer = (properties, context) => {
  const { act, data } = useBackend(context);
  const {
    dial,
    open,
    locked,
    broken,
  } = data;
  const dialButton = (amount, right) => {
    return (
      <Button
        disabled={open || (right && !locked) || broken}
        icon={"arrow-" + (right ? "right" : "left")}
        content={(right ? "Right" : "Left") + " " + amount}
        iconPosition={right ? "right" : "left"}
        onClick={() => act(!right ? "turnright" : "turnleft", {
          num: amount,
        })}
      />
    );
  };
  return (
    <Box className="Safe__dialer">
      <Button
        disabled={locked && !broken}
        icon={open ? "lock" : "lock-open"}
        content={open ? "Close" : "Open"}
        mb="0.5rem"
        onClick={() => act('open')}
      /><br />
      <Box position="absolute">
        {[dialButton(50), dialButton(10), dialButton(1)]}
      </Box>
      <Box
        className="Safe__dialer-right"
        position="absolute" right="5px">
        {[dialButton(1, true), dialButton(10, true), dialButton(50, true)]}
      </Box>
      <Box className="Safe__dialer-number">
        {dial}
      </Box>
    </Box>
  );
};

const Contents = (properties, context) => {
  const { act, data } = useBackend(context);
  const { contents } = data;
  return (
    <Box
      className="Safe__contents"
      scrollable>
      <Flex wrap="wrap" spacing={1}>
        {contents.map((item, index) => (
          <Flex.Item key={item} basis="50%">
            <Button
              fluid
              title={item.name}
              style={{
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
              }}
              onClick={() => act("retrieve", { index: index + 1 })}>
              <Box
                as="img"
                src={item.sprite + ".png"}
                verticalAlign="middle"
                ml="-6px"
                mr="0.5rem"
              />
              {item.name}
            </Button>
          </Flex.Item>
        ))}
      </Flex>
    </Box>
  );
};

const Help = (properties, context) => {
  return (
    <Section
      className="Safe__help"
      title="Инструкция по открытию сейфа (ввиду вашей неизлечимой забывчивости)">
      <Box>
        1. Проверните циферблат влево к первому числу.<br />
        2. Проверните циферблат вправо ко второму числу.<br />
        3. Повторите процедуру со всеми числами, каждый
        раз меняя проворот влево и вправо.<br />
        4. Откройте сейф.
      </Box>
      <Box bold>
        Чтобы закрыть: проверните циферблат закрытого сейфа налево.
      </Box>
    </Section>
  );
};
