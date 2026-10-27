import { useBackend } from '../backend';
import { Box } from '../components';
import { Window } from '../layouts';
import { MODsuit } from './MODsuit';

export const MODsuitRemote = (props) => {
  const { data } = useBackend();
  if (data.linked_suit) {
    return <MODsuit {...props} />;
  }
  return (
    <Window width={380} height={160}>
      <Window.Content>
        <Box color="label">Связанный модуль не установлен в MOD.</Box>
      </Window.Content>
    </Window>
  );
};
