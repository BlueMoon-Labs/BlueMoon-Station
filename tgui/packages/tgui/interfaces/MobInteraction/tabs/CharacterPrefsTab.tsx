import { useBackend, useLocalState } from '../../../backend';
import { Box, Button, Flex, LabeledList, Modal, Tooltip } from '../../../components';

type CharacterPrefsInfo = {
  erp_pref: number,
  noncon_pref: number,
  vore_pref: number,
  extreme_pref: number,
  unholy_pref: number,
  unholy_hard_pref: number,
  extreme_harm: boolean,
  mobsex_pref: boolean,
  tattoo_pref: number,
}

type ConfirmState = {
  char_pref: string;
  value: number;
  description: string;
} | null;

const CONFIRM_DESCRIPTIONS: Record<string, string> = {
  unholy_pref: 'Грязные взаимодействия, моча, смегма и излишние запахи. При включении вы сможете участвовать и наблюдать соответствующие сцены.',
  unholy_hard_pref: 'Особые грязные взаимодействия, коричневое золото, газы, другое. При включении вы сможете участвовать и наблюдать соответствующие сцены.',
  extreme_pref: 'Экстремальные сцены ебля в глаза, уши, укусы. При включении вы сможете участвовать и наблюдать соответствующие сцены.',
  extreme_harm: 'Экстремальные сцены с особым физическим уроном. При включении вы сможете участвовать и наблюдать соответствующие сцены.',
};

export const CharacterPrefsTab = (props) => {
  const { act, data } = useBackend<CharacterPrefsInfo>();
  const {
    erp_pref,
    noncon_pref,
    vore_pref,
    unholy_pref,
    unholy_hard_pref,
    extreme_pref,
    extreme_harm,
    mobsex_pref,
    tattoo_pref,
  } = data;

  const [confirmDialog, setConfirmDialog] = useLocalState<ConfirmState>('confirmPrefDialog', null);

  const currentValues: Record<string, number> = {
    unholy_pref,
    unholy_hard_pref,
    extreme_pref,
    extreme_harm: extreme_harm ? 1 : 0,
  };

  const confirmAndAct = (char_pref, value) => {
    const desc = CONFIRM_DESCRIPTIONS[char_pref];
    if (desc && currentValues[char_pref] === 0) {
      setConfirmDialog({ char_pref, value, description: desc });
    } else {
      act('char_pref', { char_pref, value });
    }
  };

  return (
    <Flex direction="column">
      {confirmDialog && (
        <Modal>
          <Box fontSize="1.2rem" bold mb={2}>Подтверждение</Box>
          <Box mb={3}>{confirmDialog.description}</Box>
          <Box textAlign="center">
            <Button
              color="green"
              icon="check"
              content="Да, включить"
              mr={2}
              onClick={() => {
                act('char_pref', { char_pref: confirmDialog.char_pref, value: confirmDialog.value });
                setConfirmDialog(null);
              }}
            />
            <Button
              color="red"
              icon="times"
              content="Отмена"
              onClick={() => setConfirmDialog(null)}
            />
          </Box>
        </Modal>
      )}
      <LabeledList>
        <LabeledList.Item label={<Tooltip content="Эротические взаимодействия"><span>ERP Preference</span></Tooltip>}>
          <Button
            icon={"check"}
            color={erp_pref === 1 ? "green" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'erp_pref',
              value: 1,
            })} />
          <Button
            icon={"question"}
            color={erp_pref === 2 ? "yellow" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'erp_pref',
              value: 2,
            })} />
          <Button
            icon={"times"}
            color={erp_pref === 0 ? "red" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'erp_pref',
              value: 0,
            })} />
        </LabeledList.Item>
        <LabeledList.Item label={<Tooltip content="Принудительные сцены без вашего согласия"><span>Noncon Preference</span></Tooltip>}>
          <Button
            icon={"check"}
            color={noncon_pref === 1 ? "green" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'noncon_pref',
              value: 1,
            })} />
          <Button
            icon={"question"}
            color={noncon_pref === 2 ? "yellow" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'noncon_pref',
              value: 2,
            })} />
          <Button
            icon={"times"}
            color={noncon_pref === 0 ? "red" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'noncon_pref',
              value: 0,
            })} />
        </LabeledList.Item>
        <LabeledList.Item label={<Tooltip content="Пожирание и переваривание."><span>Vore Preference</span></Tooltip>}>
          <Button
            icon={"check"}
            color={vore_pref === 1 ? "green" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'vore_pref',
              value: 1,
            })} />
          <Button
            icon={"question"}
            color={vore_pref === 2 ? "yellow" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'vore_pref',
              value: 2,
            })} />
          <Button
            icon={"times"}
            color={vore_pref === 0 ? "red" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'vore_pref',
              value: 0,
            })} />
        </LabeledList.Item>
        <LabeledList.Item label={<Tooltip content="Татуировки"><span>Tattoo Preference</span></Tooltip>}>
          <Button
            icon={"check"}
            color={tattoo_pref === 1 ? "green" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'tattoo_pref',
              value: 1,
            })} />
          <Button
            icon={"question"}
            color={tattoo_pref === 2 ? "yellow" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'tattoo_pref',
              value: 2,
            })} />
          <Button
            icon={"times"}
            color={tattoo_pref === 0 ? "red" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'tattoo_pref',
              value: 0,
            })} />
        </LabeledList.Item>
        <LabeledList.Item label={<Tooltip content="Грязные взаимодействия, моча, смегма, запахи"><span>Unholy Preference</span></Tooltip>}>
          <Button
            icon={"check"}
            color={unholy_pref === 1 ? "green" : "default"}
            onClick={() => confirmAndAct('unholy_pref', 1)} />
          <Button
            icon={"question"}
            color={unholy_pref === 2 ? "yellow" : "default"}
            onClick={() => confirmAndAct('unholy_pref', 2)} />
          <Button
            icon={"times"}
            color={unholy_pref === 0 ? "red" : "default"}
            onClick={() => confirmAndAct('unholy_pref', 0)} />
        </LabeledList.Item>
        <LabeledList.Item label={<Tooltip content="Особые грязные взаимодействия, коричневое золото, газы, другое"><span>Unholy Hard Preference</span></Tooltip>}>
          <Button
            icon={"check"}
            color={unholy_hard_pref === 1 ? "green" : "default"}
            onClick={() => confirmAndAct('unholy_hard_pref', 1)} />
          <Button
            icon={"question"}
            color={unholy_hard_pref === 2 ? "yellow" : "default"}
            onClick={() => confirmAndAct('unholy_hard_pref', 2)} />
          <Button
            icon={"times"}
            color={unholy_hard_pref === 0 ? "red" : "default"}
            onClick={() => confirmAndAct('unholy_hard_pref', 0)} />
        </LabeledList.Item>
        <LabeledList.Item label={<Tooltip content="Экстремальные сцены"><span>Extreme Preference</span></Tooltip>}>
          <Button
            icon={"check"}
            color={extreme_pref === 1 ? "green" : "default"}
            onClick={() => confirmAndAct('extreme_pref', 1)} />
          <Button
            icon={"question"}
            color={extreme_pref === 2 ? "yellow" : "default"}
            onClick={() => confirmAndAct('extreme_pref', 2)} />
          <Button
            icon={"times"}
            color={extreme_pref === 0 ? "red" : "default"}
            onClick={() => confirmAndAct('extreme_pref', 0)} />
        </LabeledList.Item>
        {extreme_pref ? (
          <LabeledList.Item label={<Tooltip content="Особо жестокие сцены"><span>Extreme Harm</span></Tooltip>}>
            <Button
              icon={"check"}
              color={extreme_harm ? "green" : "default"}
              onClick={() => confirmAndAct('extreme_harm', 1)} />
            <Button
              icon={"times"}
              color={extreme_harm ? "default" : "red"}
              onClick={() => confirmAndAct('extreme_harm', 0)} />
          </LabeledList.Item>
        ) : (null)}
        <LabeledList.Item label={<Tooltip content="Принудительный секс с мобами"><span>Mob Noncon Sex</span></Tooltip>}>
          <Button
            icon={"check"}
            color={mobsex_pref ? "green" : "default"}
            onClick={() => act('char_pref', {
              char_pref: 'mobsex_pref',
              value: 1,
            })} />
          <Button
            icon={"times"}
            color={mobsex_pref ? "default" : "red"}
            onClick={() => act('char_pref', {
              char_pref: 'mobsex_pref',
              value: 0,
            })} />
        </LabeledList.Item>
      </LabeledList>
    </Flex>
  );
};
