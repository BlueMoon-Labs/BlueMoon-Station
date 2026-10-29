import { useBackend } from '../backend';
import { ColorPickerPanel } from '../components';
import { Window } from '../layouts';
import { Loader } from './common/Loader';

type ColorInputData = {
  init_value: string;
  large_buttons: boolean;
  message: string;
  timeout?: number;
  title: string;
};

export const ColorInputModal = () => {
  const { act, data } = useBackend<ColorInputData>();
  const {
    init_value,
    large_buttons,
    message,
    timeout,
    title,
  } = data;

  return (
    <Window title={title} width={820} height={460}>
      {!!timeout && <Loader value={timeout} />}
      <Window.Content
        onKeyDown={(event) => {
          if (event.key === 'Escape') {
            event.preventDefault();
            act('cancel');
          }
        }}
      >
        <ColorPickerPanel
          className="ColorPicker--input"
          value={init_value}
          title=""
          message={message}
          largeButtons={!!large_buttons}
          onCommit={(entry) => act('submit', { entry })}
          onCancel={() => act('cancel')}
        />
      </Window.Content>
    </Window>
  );
};
