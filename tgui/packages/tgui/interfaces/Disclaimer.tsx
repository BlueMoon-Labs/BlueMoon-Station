import { useBackend } from '../backend';
import { Box, Button, Icon, Section, Stack } from '../components';
import { Window } from '../layouts';

type LinkInfo = {
  name: string;
  url: string;
};

type DisclaimerData = {
  title: string;
  body: string;
  links: LinkInfo[];
  show_accept: boolean;
};

const ICONS = ['discord', 'book', 'gavel', 'scroll', 'link'];

export const Disclaimer = (props) => {
  const { act, data } = useBackend<DisclaimerData>();
  const lines = data.body.split('\n');
  return (
    <Window title="Дисклеймер" width={850} height={620} resizable theme="disclaimer" canClose={!data.show_accept}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Section
              fill
              style={{
                background: 'rgba(140, 0, 0, 0.4)',
                border: '2px solid #ff3c3c',
                boxShadow: 'inset 0 0 50px rgba(255, 0, 0, 0.35)',
              }}>
              <Box
                bold
                align="center"
                fontSize="4.5rem"
                color="#ff2a2a"
                style={{
                  textShadow:
                    '0 0 10px rgba(255, 60, 60, 0.95), 0 0 25px rgba(255, 0, 0, 0.65), 0 0 45px rgba(255, 0, 0, 0.4)',
                }}>
                {data.title}
              </Box>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Section
              fill
              scrollable
              style={{
                background: 'rgba(80, 0, 0, 0.25)',
                border: '1px solid #a32424',
              }}>
              <Box
                bold
                align="center"
                fontSize="1.3rem"
                color="#ff8f8f"
                mb={2}
                style={{
                  textShadow: '0 0 6px rgba(255, 60, 60, 0.7)',
                }}>
                <Icon name="exclamation-triangle" mr={1} />
                Внимание
                <Icon name="exclamation-triangle" ml={1} />
              </Box>
              <Stack vertical>
                {lines.map((line, index) => (
                  <Stack.Item key={index}>
                    <Box fontSize="1.1rem" lineHeight={1.55} color="#ffd9d9">
                      {line}
                    </Box>
                  </Stack.Item>
                ))}
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Stack wrap>
              {data.links.map((link, index) => (
                <Stack.Item key={index} grow>
                  <Button
                    fluid
                    icon={ICONS[index] || 'link'}
                    content={link.name}
                    fontSize={1.15}
                    py={1.1}
                    onClick={() => act('open_link', { url: link.url })} />
                </Stack.Item>
              ))}
            </Stack>
          </Stack.Item>
          {!!data.show_accept && (
            <Stack.Item>
              <Box
                fontSize={1.05}
                color="#ffb3b3"
                align="center"
                mb={1}
                lineHeight={1.3}>
                Ознакомившись с правилами, вы автоматически соглашаетесь с их условиями.
              </Box>
              <Button
                fluid
                textAlign="center"
                className="accept-btn"
                icon="check-circle"
                content="Понятно!"
                fontSize={1.5}
                py={1.35}
                onClick={() => act('accept')} />
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
