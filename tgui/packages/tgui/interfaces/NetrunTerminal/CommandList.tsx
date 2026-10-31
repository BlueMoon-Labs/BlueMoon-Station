import { Box, Button } from '../../components';
import { CommandTooltip } from './CommandTooltip';
import { NetCommand, THEME } from './types';

/** Requests with a group (e.g. 'fortress') are rendered by their own section. */
export const ungroupedCommands = (commands: NetCommand[]) => commands.filter((command) => !command.group);

/** Shared risk styling, so grouped sections look exactly like the generic grid. */
export const commandClass = (command: NetCommand) => command.danger ? 'netrun-command--danger'
  : command.illegal ? 'netrun-command--risky' : 'netrun-command--standard';

export const commandColor = (command: NetCommand) => command.danger ? 'bad' : command.illegal ? 'average' : undefined;

/** The same command metadata and access explanation in a card and machine tab. */
export const CommandList = (props: {
  commands: NetCommand[];
  onCommand: (id: string) => void;
  disabled?: boolean;
}) => {
  const { onCommand, disabled } = props;
  const commands = ungroupedCommands(props.commands);
  if (!commands.length) {
    return (
      <Box color={THEME.muted}>
        Нет доступных запросов. Получите доступ к узлу или проверьте связь.
      </Box>
    );
  }
  // A uniform grid: every request is the same width and height, icons and labels
  // align in a column, and long names ellipsize instead of stretching the button.
  return (
    <Box
      className="netrun-command-grid"
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(136px, 1fr))',
        gridAutoRows: 'minmax(36px, auto)',
        gap: '6px',
      }}
    >
      {commands.map((command) => (
        <Button
          key={command.id}
          fluid
          ellipsis
          className={commandClass(command)}
          icon={command.icon}
          content={command.name}
          color={commandColor(command)}
          disabled={disabled || !command.allowed}
          style={{ height: '100%', margin: 0, minHeight: '36px', textAlign: 'left' }}
          tooltip={<CommandTooltip command={command} />}
          onClick={() => onCommand(command.id)}
        />
      ))}
    </Box>
  );
};
