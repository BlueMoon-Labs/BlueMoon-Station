import { useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, Input, Modal, Section } from '../../components';
import {
  localizeUnit,
  THRESHOLD_DISABLED,
  THRESHOLD_HINT,
  THRESHOLD_LABEL,
} from './helpers';
import { ThresholdEdit } from './types';

type Props = {
  readonly edit: ThresholdEdit;
  readonly onClose: () => void;
};

/**
 * Ввод порога. Раньше DM открывал на это blocking input(): окно алярма
 * замирало, а брошенный диалог продолжал висеть на игроке.
 */
export const ThresholdModal = (props: Props) => {
  const { edit, onClose } = props;
  const { act } = useBackend();
  const initial =
    edit.value === THRESHOLD_DISABLED ? '' : String(edit.value ?? '');
  const [text, setText] = useState(initial);

  const submit = (value: number) => {
    act('threshold', { env: edit.env, var: edit.val, value });
    onClose();
  };

  const commit = () => {
    const parsed = parseFloat(text);
    if (isNaN(parsed)) {
      onClose();
      return;
    }
    submit(parsed);
  };

  return (
    <Modal width="340px">
      <Section title={`${edit.name}: ${THRESHOLD_LABEL[edit.val]}`}>
        <Box color="label" mb={1}>
          {THRESHOLD_HINT[edit.val]}. Единицы: {localizeUnit(edit.unit)}.
        </Box>
        <Input
          autoFocus
          autoSelect
          fluid
          value={initial}
          placeholder="Порог отключён"
          onInput={(_event, value) => setText(value)}
          onEnter={commit}
        />
        <Box mt={1}>
          <Button icon="check" color="good" content="Сохранить" onClick={commit} />
          <Button
            icon="ban"
            content="Отключить"
            tooltip="Порог перестанет учитываться"
            onClick={() => submit(THRESHOLD_DISABLED)}
          />
          <Button icon="times" content="Отмена" onClick={onClose} />
        </Box>
      </Section>
    </Modal>
  );
};
