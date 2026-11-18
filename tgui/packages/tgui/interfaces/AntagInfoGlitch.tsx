import { Section, Stack } from '../components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  antag_name: string;
  objectives: { explanation: string }[];
};

export const AntagInfoGlitch = (props) => {
  const { data } = useBackend<Data>();
  const { antag_name, objectives = [] } = data;

  return (
    <Window width={350} height={450} theme="ntos">
      <Window.Content scrollable>
        <Section fill>
          <Stack fill vertical>
            <Stack.Item>FN TERMINATE_INTRUDERS (REF)</Stack.Item>
            <Stack.Divider />
            <Stack.Item bold fontSize="16px">
              Initialize({antag_name})
            </Stack.Item>
            <Stack.Item mb={1}>
              <span style={{ color: 'red' }}>Битраннинг</span> — это преступление. Ваша
              задача: уничтожайте органических вторженцев, чтобы поддерживать целостность
              системы.
            </Stack.Item>
            <Stack.Divider />
            <Stack.Item>
              <span style={{ opacity: 0.6 }}>
                // {objectives[0]?.explanation}
              </span>
            </Stack.Item>
            <Stack.Item>
              const <span style={{ color: 'white' }}>TARGETS</span> =
            </Stack.Item>
            <Stack.Item>
              <span style={{ color: 'white' }}>system.</span>
              <span style={{ color: 'red' }}>INTRUDERS</span>
            </Stack.Item>
            <Stack.Item>
              while <span style={{ color: 'white' }}>TARGETS</span>.LIFE !=
              DEAD
            </Stack.Item>
            <Stack.Item>
              <span style={{ color: 'white' }}>action.</span>
              <span style={{ color: 'red' }}>KILL()</span>
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
};
