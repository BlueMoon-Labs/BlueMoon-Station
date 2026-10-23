import { useBackend } from '../../backend';
import { Button, Stack } from '../../components';

export type VendingLayout = 'grid' | 'list';

export const LayoutToggle = () => {
  const { act, data } = useBackend<{ vending_layout: VendingLayout }>();
  const grid = data.vending_layout === 'grid';
  return (
    <Stack.Item>
      <Button
        icon={grid ? 'list' : 'border-all'}
        tooltip={grid ? 'Показать списком' : 'Показать сеткой'}
        tooltipPosition="bottom-end"
        onClick={() => act('set_vending_layout', { layout: grid ? 'list' : 'grid' })}
      />
    </Stack.Item>
  );
};
