import { useBackend } from '../backend';
import { Section, TextArea } from '../components';
import { NtosWindow } from '../layouts';

export const NtosNotepad = (props, context) => {
  const { act, data } = useBackend(context);
  const { note = '' } = data;

  return (
    <NtosWindow width={450} height={600}>
      <NtosWindow.Content>
        <Section fill scrollable>
          <TextArea
            fluid
            height="100%"
            value={note}
            onInput={(e, val) => act('UpdateNote', { newnote: val })}
          />
        </Section>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
