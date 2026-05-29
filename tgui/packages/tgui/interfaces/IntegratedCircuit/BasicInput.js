import { Button, Stack } from '../../components';

export const BasicInput = (props, context) => {
  const { children, setValue } = props;
  return (
    <Stack onMouseDown={(e) => e.stopPropagation()}>
      <Stack.Item>
        <Button
          color="transparent"
          compact
          icon="times"
          tooltip="Сбросить в null"
          onClick={() => setValue(null, { set_null: true })}
        />
      </Stack.Item>
      <Stack.Item>{children}</Stack.Item>
    </Stack>
  );
};
