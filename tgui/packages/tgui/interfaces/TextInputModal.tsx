import { KEY_ENTER, KEY_ESCAPE } from '../../common/keycodes';
import { useBackend, useLocalState } from '../backend';
import { Box, Section, Stack, TextArea } from '../components';
import { Window } from '../layouts';
import { InputButtons } from './common/InputButtons';
import { Loader } from './common/Loader';

type TextInputData = {
  large_buttons: boolean;
  max_length: number;
  message: string;
  multiline: boolean;
  placeholder: string;
  timeout: number;
  title: string;
};

export const TextInputModal = (_, context) => {
  const { act, data } = useBackend<TextInputData>(context);
  const {
    large_buttons,
    max_length,
    message = "",
    multiline,
    placeholder,
    timeout,
    title,
  } = data;
  const [input, setInput] = useLocalState<string>(
    context,
    'input',
    placeholder || ''
  );
  const onType = (value: string) => {
    if (value === input) {
      return;
    }
    setInput(value);
  };
  // Dynamically changes the window height based on the message.
  const windowHeight
    = 140
    + (message.length > 30 ? Math.ceil(message.length * 0.45) : 0)
    + (multiline ? 195 : 0)
    + (message.length && large_buttons ? 5 : 0)

  // Window width based multiline.
  const windowWidth
    = 300
    + (multiline ? 100 : 0)

  return (
    <Window title={title} width={windowWidth} height={windowHeight}>
      {timeout && <Loader value={timeout} />}
      <Window.Content
        onKeyDown={(event) => {
          if (event.key === KEY_ENTER && (!multiline || !event.shiftKey)) {
            act('submit', { entry: input });
          }
          if (event.key === KEY_ESCAPE) {
            act('cancel');
          }
        }}
        onClick={() => (document.querySelector('.TextArea__textarea' ) as HTMLElement)?.focus()}>
        <Section fill>
          <Stack fill vertical>
            <Stack.Item>
              <Box color="label">{message}</Box>
            </Stack.Item>
            <Stack.Item grow>
              <InputArea input={input} onType={onType} />
            </Stack.Item>
            <Stack.Item>
              <InputButtons
                input={input}
                message={max_length > 0 && max_length <= 2147483647
                  ? `${input.length}/${max_length}`
                  : `${input.length}`}
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};

/** Gets the user input and invalidates if there's a constraint. */
const InputArea = (props, context) => {
  const { act, data } = useBackend<TextInputData>(context);
  const { max_length, multiline } = data;
  const { input, onType } = props;

  return (
    <TextArea
      scrollbar = {multiline}
      singleline = {!multiline}
      autoFocus
      autoSelect
      height = {multiline ? '100%' : '3em'}
      maxLength={max_length > 0 && max_length <= 2147483647 ? max_length : undefined}
      onEscape={() => act('cancel')}
      onEnter={(event) => {
        act('submit', { entry: input });
      }}
      onKeyDown={(event) => {
        if(event.key === KEY_ENTER && (!event.shiftKey || !multiline)) {
          event.preventDefault();
      }}}
      onInput={(_, value) => onType(value)}
      placeholder="Type something..."
      value={input}
    />
  );
};
