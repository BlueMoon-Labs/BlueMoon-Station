import { useBackend } from '../backend';
import { Box, Button, ByondUi, NoticeBox, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const Gateway = () => {
  return (
    <Window width={350} height={440}>
      <Window.Content scrollable>
        <GatewayContent />
      </Window.Content>
    </Window>
  );
};

const GatewayContent = (props) => {
  const { act, data } = useBackend();
  const {
    gateway_present = false,
    gateway_status = false,
    current_target = null,
    destinations = [],
    gateway_mapkey,
  } = data;
  if (!gateway_present) {
    return (
      <Section>
        <NoticeBox>Нет подключённых врат</NoticeBox>
        <Button fluid onClick={() => act('linkup')}>
          Соединить
        </Button>
      </Section>
    );
  }
  if (current_target) {
    return (
      <Section title={current_target.name}>
        <ByondUi
          height="320px"
          params={{
            id: gateway_mapkey,
            type: 'map',
          }}
        />
        <Button
          mt="2px"
          textAlign="center"
          fluid
          onClick={() => act('deactivate')}>
          Деактивировать
        </Button>
      </Section>
    );
  }
  if (!destinations.length) {
    return <Section>Не обнаружено путеводных узлов.</Section>;
  }
  return (
    <>
      {!gateway_status && <NoticeBox>Врата не запитаны</NoticeBox>}
      {destinations.map((dest) => (
        <Section key={dest.ref} title={dest.name}>
          {(dest.available && (
            <Button
              fluid
              onClick={() =>
                act('activate', {
                  destination: dest.ref,
                })
              }>
              Активировать
            </Button>
          )) || (
            <>
              <Box m={1} textColor="bad">
                {dest.reason}
              </Box>
              {!!dest.timeout && (
                <ProgressBar value={dest.timeout}>Калибровка...</ProgressBar>
              )}
            </>
          )}
        </Section>
      ))}
    </>
  );
};
