import { useBackend } from '../backend';
import { Box, Button, Icon, Section, Stack } from '../components';
import { Window } from '../layouts';

export const OutfitEditor = (props, context) => {
  const { act, data } = useBackend(context);
  const { outfit, saveable, dummy64 } = data;
  return (
    <Window
      width={600}
      height={870}>
      <Window.Content>
        <Box
          as="img"
          fillPositionedParent
          width="100%"
          height="100%"
          opacity={0.5}
          py={3}
          src={`data:image/png;base64,${dummy64}`}
          style={{
            imageRendering: 'pixelated',
          }} />
        <Section
          fill
          title={
            <Stack>
              <Stack.Item grow={1}
                style={{
                  'overflow': 'hidden',
                  'white-space': 'nowrap',
                  'text-overflow': 'ellipsis',
                }}>
                <Button
                  ml={0.5}
                  color="transparent"
                  icon="pencil-alt"
                  title="Rename this outfit"
                  onClick={() => act("rename", {})} />
                {outfit.name}
              </Stack.Item>
              <Stack.Item align="end" shrink={0}>
                <Button
                  color="transparent"
                  icon="info"
                  tooltip="Ctrl-click a button to select *any* item instead of what will probably fit in that slot."
                  tooltipPosition="bottom-start" />
                <Button
                  icon="code"
                  tooltip="Edit this outfit on a VV window"
                  tooltipPosition="bottom-start"
                  onClick={() => act("vv")} />
                <Button
                  color={!saveable && "bad"}
                  icon={saveable ? "save" : "trash-alt"}
                  tooltip={saveable
                    ? "Save this outfit to the custom outfit list"
                    : "Remove this outfit from the custom outfit list"}
                  tooltipPosition="bottom-start"
                  onClick={() => act(saveable ? "save" : "delete")} />
              </Stack.Item>
            </Stack>
          }>
          <Box textAlign="center">
            <Stack mb={2}>
              <OutfitSlot name="Right Ear" icon="headphones-alt" slot="ears_extra" />
              <OutfitSlot name="Headgear" icon="hard-hat" slot="head" />
              <OutfitSlot name="Left Ear" icon="headphones-alt" slot="ears" />
            </Stack>
            <Stack mb={2}>
              <OutfitSlot name="Mask" icon="theater-masks" slot="mask" />
              <OutfitSlot name="Glasses" icon="glasses" slot="glasses" />
            </Stack>
            <Stack mb={2}>
              <OutfitSlot name="Neck" icon="stethoscope" slot="neck" />
            </Stack>
            <Stack mb={2}>
              <OutfitSlot name="Suit" icon="user-astronaut" slot="suit" />
              <OutfitSlot name="Uniform" icon="user-tie" slot="uniform" />
              <OutfitSlot name="Shirt" icon="tshirt" slot="shirt" />
            </Stack>
            <Stack mb={2}>
              <OutfitSlot name="Suit Storage" icon="briefcase-medical" slot="suit_store" />
              <OutfitSlot name="Back" icon="shopping-bag" slot="back" />
              <OutfitSlot name="ID" icon="id-card-o" slot="id" />
            </Stack>
            <Stack mb={2}>
              <OutfitSlot name="Right Hand" icon="hand-paper" slot="r_hand" />
              <OutfitSlot name="Wrists" icon="hands" slot="wrists" />
              <OutfitSlot name="Gloves" icon="mitten" slot="gloves" />
              <OutfitSlot name="Left Hand" icon="hand-paper" slot="l_hand" />
            </Stack>
            <Stack mb={2}>
              <OutfitSlot name="Right Pocket" icon="envelope-open-o" iconRot={180} slot="r_pocket" />
              <OutfitSlot name="Underwear" icon="baby" slot="underwear" />
              <OutfitSlot name="Belt" icon="band-aid" slot="belt" />
              <OutfitSlot name="Left Pocket" icon="envelope-open-o" iconRot={180} slot="l_pocket" />
            </Stack>
            <Stack mb={2}>
              <OutfitSlot name="Socks" icon="socks" slot="socks" />
            </Stack>
            <Stack mb={2}>
              <OutfitSlot name="Shoes" icon="shoe-prints" slot="shoes" />
            </Stack>
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};

const OutfitSlot = (props, context) => {
  const { act, data } = useBackend(context);
  const { name, icon, iconRot, slot } = props;
  const { outfit } = data;
  const currItem = outfit[slot];
  return (
    <Stack.Item grow={1} basis={0}>
      <Button fluid height={2}
        bold
        // todo: intuitive way to clear items
        onClick={e => act(e.ctrlKey ? "ctrlClick" : "click", { slot })} >
        <Icon name={icon} rotation={iconRot} />
        {name}
      </Button>
      <Box height="32px">
        {currItem?.sprite && (
          <>
            <Box
              as="img"
              src={`data:image/png;base64,${currItem?.sprite}`}
              title={currItem?.desc}
              style={{
                imageRendering: 'pixelated',
              }} />
            <Icon
              position="absolute"
              name="times"
              color="label"
              style={{ cursor: 'pointer' }}
              onClick={() => act("clear", { slot })} />
          </>
        )}
      </Box>
      <Box
        color="label"
        style={{
          'overflow': 'hidden',
          'white-space': 'nowrap',
          'text-overflow': 'ellipsis',
        }}
        title={currItem?.path}>
        {currItem?.name || "Empty"}
      </Box>
    </Stack.Item>
  );
};
