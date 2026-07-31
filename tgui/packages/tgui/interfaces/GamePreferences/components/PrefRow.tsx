import { Button, Stack, Tooltip } from '../../../components';

type PrefRowProps = {
  label: string;
  checked?: boolean;
  onClick: () => void;
  hint?: string;
  tooltip?: string;
};

export const PrefRow = (props: PrefRowProps) => {
  const { label, checked, onClick, hint, tooltip } = props;

  const labelEl = (
    <div className="GamePreferences__label">{label}</div>
  );

  return (
    <Stack.Item>
      <Stack align="center" fill className="GamePreferences__row">
        <Stack.Item grow basis={0}>
          {tooltip ? (
            <Tooltip content={tooltip}>{labelEl}</Tooltip>
          ) : (
            labelEl
          )}
          {hint && (
            <div className="GamePreferences__hint">{hint}</div>
          )}
        </Stack.Item>
        <Stack.Item>
          <Button
            icon={checked ? 'toggle-on' : 'toggle-off'}
            selected={checked}
            color={checked ? 'good' : 'default'}
            onClick={onClick}
          />
        </Stack.Item>
      </Stack>
    </Stack.Item>
  );
};
