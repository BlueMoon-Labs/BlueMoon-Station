import { Box, Button } from '../../components';
import { NodeInteraction, THEME } from './types';
import { useNetrunBackend as useBackend } from './useNetrunBackend';

/** Availability and denial messages come from the same server rules as dispatch. */
export const NodeInteractions = (props: { actions?: NodeInteraction[]; pending: boolean }) => {
  const { act } = useBackend([]);
  if (!props.actions?.length) { return null; }
  return (
    <Box mt={1} mb={1}>
      <Box bold color={THEME.text} mb={0.5}>Взаимодействия</Box>
      {props.actions.map((action) => (
        <Box key={action.id} mb={0.5}>
          <Button icon={action.icon} content={action.name}
            disabled={props.pending || !action.enabled}
            tooltip={action.reason || undefined}
            onClick={() => act('node_interact', { id: action.id })} />
          {!action.enabled && !!action.reason && (
            <Box color={THEME.muted} fontSize="11px">{action.reason}</Box>
          )}
        </Box>
      ))}
    </Box>
  );
};
