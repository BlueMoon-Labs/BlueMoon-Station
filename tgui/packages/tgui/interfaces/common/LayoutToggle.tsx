import { useLayoutEffect, useRef } from 'react';

import { useBackend } from '../../backend';
import { Button, Stack } from '../../components';

export type VendingLayout = 'grid' | 'list';

// Сохраняем видимый товар, переводя экранные отступы в локальные пиксели TGUI.
export const useLayoutScroll = (layout: VendingLayout | undefined) => {
  const scrollableRef = useRef<HTMLDivElement>(null);
  const anchor = useRef<{ key: string; offset: number } | null>(null);
  const previousLayout = useRef(layout);
  const onScroll = () => {
    const container = scrollableRef.current;
    if (!container) {
      return;
    }
    const bounds = container.getBoundingClientRect();
    const scale = bounds.width / container.clientWidth || 1;
    const first = Array.from(container.querySelectorAll<HTMLElement>('[data-product-key]'))
      .find((element) => element.getBoundingClientRect().bottom > bounds.top);
    anchor.current = first ? {
      key: first.dataset.productKey!,
      offset: (first.getBoundingClientRect().top - bounds.top) / scale,
    } : null;
  };
  useLayoutEffect(() => {
    const container = scrollableRef.current;
    if (container && previousLayout.current !== layout && anchor.current) {
      const bounds = container.getBoundingClientRect();
      const scale = bounds.width / container.clientWidth || 1;
      const target = Array.from(container.querySelectorAll<HTMLElement>('[data-product-key]'))
        .find((element) => element.dataset.productKey === anchor.current?.key);
      if (target) {
        container.scrollTop += (target.getBoundingClientRect().top - bounds.top) / scale - anchor.current.offset;
      }
    }
    previousLayout.current = layout;
    onScroll();
  }, [layout]);
  return { scrollableRef, onScroll };
};

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
