import { createPopper } from '@popperjs/core';
import { BooleanLike } from 'common/react';
import { classes } from 'common/react';
import { Component, findDOMfromVNode, render } from 'inferno';

import { useSharedState } from '../../backend';
import { Box, Button, Flex } from '../../components';
import { BoxProps } from '../../components/Box';
import { formatMoney, formatSiUnit } from '../../format';

export const MATERIAL_KEYS = {
  "iron": "sheet-metal_3",
  "glass": "sheet-glass_3",
  "silver": "sheet-silver_3",
  "gold": "sheet-gold_3",
  "diamond": "sheet-diamond",
  "plasma": "sheet-plasma_3",
  "uranium": "sheet-uranium",
  "bananium": "sheet-bananium",
  "titanium": "sheet-titanium_3",
  "bluespace crystal": "polycrystal",
  "plastic": "sheet-plastic_3",
} as const;

export type Material = {
  name: keyof typeof MATERIAL_KEYS;
  ref: string;
  amount: number;
  sheets: number;
  removable: BooleanLike;
};

interface MaterialIconProps extends BoxProps {
  readonly material: keyof typeof MATERIAL_KEYS;
}

export const MaterialIcon = (props: MaterialIconProps) => {
  const { material, ...rest } = props;

  return (<Box
    {...rest}
    className={classes([
      'sheetmaterials32x32',
      MATERIAL_KEYS[material],
    ])} />);
};

const clampInt = (n: number, min: number, max: number) =>
  Math.max(min, Math.min(max, Math.floor(n)));

const MINERAL_MATERIAL_AMOUNT = 2000;

const getSheetsFloat = (material: Material) => {
  const amount = Number(material?.amount) || 0;
  return amount / MINERAL_MATERIAL_AMOUNT;
};

const MaterialEjectDock = (props: {
  readonly material: Material;
  readonly onEject: (amount: number) => void;
}, context) => {
  const { material, onEject } = props;

  const sheetsFloat = getSheetsFloat(material);
  const sheetsInt = Math.floor(sheetsFloat);

  const maxQty = clampInt(sheetsInt, 0, 50);
  const canEject = !!material.removable && sheetsInt >= 1;

  const eject = (qty: number) => {
    if (!canEject) return;
    const q = clampInt(qty, 1, 50);
    if (q > sheetsInt) return;
    onEject(q);
  };

  const getBtnTextColor = (need: number) => {
    if (!canEject) return 'bad';
    if (need > sheetsInt) return 'bad';
    return false;
  };

  const BUTTON_WIDTH = 6
  const BUTTON_AMOUNTS = [5, 10, 25]
  const min_sheets_to_round = 10

  const dockContent = (
  <Flex align="center" direction="column" backgroundColor="rgba(27, 27, 27, 1)">
    {BUTTON_AMOUNTS.map((amt) => (
      <Flex.Item key={amt}>
        <Button
          width={BUTTON_WIDTH}
          align="center"
          color="transparent"
          content={
            <Box color={getBtnTextColor(amt)}>
              &times;{amt}
            </Box>
          }
          onClick={() => {
            if (canEject && sheetsInt >= amt) {
              eject(amt);
            }
          }}
        />
      </Flex.Item>
    ))}

    <Flex.Item>
      <Button
        width={BUTTON_WIDTH}
        align="center"
        color="transparent"
        content={
          <Box color={getBtnTextColor(maxQty)}>
            Max [x{maxQty}]
          </Box>
        }
        onClick={() => {
          if (canEject && maxQty >= 1) {
            eject(maxQty);
          }
        }}
      />
    </Flex.Item>
  </Flex>
);

  return (
    <div style={{ width: '100%' }}>
      <MaterialDockTooltip content={dockContent} position="bottom">
        <Button
          color="transparent"
          content={
            <Flex
              direction="column"
              textAlign="center"
              onClick={() => { if (canEject) eject(1); }}
            >
              <Flex.Item>
                <MaterialIcon material={material.name} />
              </Flex.Item>
              <Flex.Item>
                {(sheetsFloat < min_sheets_to_round) ? sheetsFloat : sheetsInt}
              </Flex.Item>
            </Flex>
          }
        />

      </MaterialDockTooltip>
    </div>
  );

};

export const Materials = (props: {
  readonly materials: Material[];
  readonly onEject: (ref: string, amount: number) => void;
  readonly formatting?: MaterialFormatting;
}, context) => {
  const formatting = props.formatting ?? MaterialFormatting.SIUnits;

  return (
    <Flex wrap>
      {props.materials.map((material) => (
        <Flex.Item key={material.name} grow={1} shrink={1}>
          <MaterialEjectDock
            material={material}
            onEject={(amount) => props.onEject(material.ref, amount)}
          />
        </Flex.Item>
      ))}
    </Flex>
  );
};


export enum MaterialFormatting {
  SIUnits,
  Money,
  Locale,
  Sheets,
}

export const MaterialAmount = (props: {
  readonly name: keyof typeof MATERIAL_KEYS,
  readonly amount: number,
  readonly formatting?: MaterialFormatting,
  readonly color?: string,
  readonly style?: Record<string, string>,
}) => {
  const {
    name,
    amount,
    color,
    style,
  } = props;

  const MINERAL_MATERIAL_AMOUNT = 2000

  let amountDisplay;

  switch (props.formatting) {
    case MaterialFormatting.SIUnits:
      amountDisplay = formatSiUnit(amount, 0);
      break;
    case MaterialFormatting.Money:
      amountDisplay = formatMoney(amount);
      break;
    case MaterialFormatting.Locale:
      amountDisplay = amount.toLocaleString();
      break;
    case MaterialFormatting.Sheets:
      amountDisplay = Math.round((amount / MINERAL_MATERIAL_AMOUNT) * 1000) / 1000; // Округляем до 3х знаков
      break;
    default:
      amountDisplay = amount;
  }

  return (
    <Flex direction="column" textAlign="center">
      <Flex.Item>
        <MaterialIcon material={name} style={style} />
      </Flex.Item>
      <Flex.Item color={color}>
        {amountDisplay}
      </Flex.Item>
    </Flex>
  );
};


type DockTooltipProps = {
  readonly content: any;
  readonly position?: any; // Placement
};

type DockTooltipState = {};

const DOCK_DEFAULT_OPTIONS = {
  modifiers: [{
    name: 'eventListeners',
    enabled: false,
  }],
};

const DOCK_NULL_RECT = {
  width: 0,
  height: 0,
  top: 0,
  right: 0,
  bottom: 0,
  left: 0,
};

class MaterialDockTooltip extends Component<DockTooltipProps, DockTooltipState> {
  static renderedDock: HTMLDivElement | undefined;
  static singletonPopper: ReturnType<typeof createPopper> | undefined;
  static currentAnchor: Element | undefined;
  static dockHovered = false;

  static virtualElement = {
    getBoundingClientRect: () => (
      MaterialDockTooltip.currentAnchor?.getBoundingClientRect()
      ?? DOCK_NULL_RECT
    ) as DOMRect,
  };

  getDOMNode() {
    return findDOMfromVNode(this.$LI, true);
  }

  ensureDockEl() {
    let el = MaterialDockTooltip.renderedDock;
    if (!el) {
      el = document.createElement('div');
      el.className = 'MaterialDockTooltip'; // можно потом оформить в scss
      el.style.position = 'absolute';
      el.style.zIndex = '999999';
      el.style.opacity = '0';

      // ВАЖНО: скрытый док не должен ловить мышь
      el.style.pointerEvents = 'none';

      document.body.appendChild(el);

      el.addEventListener('mouseenter', () => {
        // если док закрыт (нет якоря) — вообще не реагируем
        if (!MaterialDockTooltip.currentAnchor) return;

        MaterialDockTooltip.dockHovered = true;
        el!.style.opacity = '1';
        el!.style.pointerEvents = 'auto';
      });

      el.addEventListener('mouseleave', (e: MouseEvent) => {
        const to = e.relatedTarget as Node | null;
        const anchor = MaterialDockTooltip.currentAnchor;

        MaterialDockTooltip.dockHovered = false;

        // Если ушли с дока обратно на якорь — НЕ закрываем
        if (anchor && to && anchor.contains(to)) return;

        if (!MaterialDockTooltip.currentAnchor) {
          el!.style.opacity = '0';
          el!.style.pointerEvents = 'none';
        } else {
          // якорь есть, но мы не на доке — закрываем
          MaterialDockTooltip.currentAnchor = undefined;
          el!.style.opacity = '0';
          el!.style.pointerEvents = 'none';
        }
      });


      MaterialDockTooltip.renderedDock = el;
    }
    return el;
  }

  open(anchor: Element) {
    const el = this.ensureDockEl();
    MaterialDockTooltip.currentAnchor = anchor;

    el.style.opacity = '1';
    el.style.pointerEvents = 'auto';

    this.renderDock();
  }

  close(anchor: Element) {
    if (MaterialDockTooltip.currentAnchor !== anchor) return;
    if (MaterialDockTooltip.dockHovered) return;

    MaterialDockTooltip.currentAnchor = undefined;

    const el = MaterialDockTooltip.renderedDock;
    if (el) {
      el.style.opacity = '0';
      el.style.pointerEvents = 'none'; // ВАЖНО
    }
  }

  renderDock() {
    const el = MaterialDockTooltip.renderedDock;
    if (!el) return;

    render(
      <div>{this.props.content}</div>,
      el,
      () => {
        let pop = MaterialDockTooltip.singletonPopper;
        if (!pop) {
          pop = createPopper(
            MaterialDockTooltip.virtualElement as any,
            el,
            {
              ...DOCK_DEFAULT_OPTIONS,
              placement: this.props.position || 'bottom',
            }
          );
          MaterialDockTooltip.singletonPopper = pop;
        } else {
          pop.setOptions({
            ...DOCK_DEFAULT_OPTIONS,
            placement: this.props.position || 'bottom',
          });
          pop.update();
        }
      },
      this.context,
    );
  }

  componentDidMount() {
    const anchor = this.getDOMNode();
    if (!anchor) return;

    anchor.addEventListener('mouseenter', () => this.open(anchor));

    anchor.addEventListener('mouseleave', (e: MouseEvent) => {
      const to = e.relatedTarget as Node | null;
      const dock = MaterialDockTooltip.renderedDock;

      // Если ушли курсором в док — НЕ закрываем
      if (dock && to && dock.contains(to)) return;

      this.close(anchor);
    });
  }

  componentDidUpdate() {
    const anchor = this.getDOMNode();
    if (MaterialDockTooltip.currentAnchor !== anchor) return;
    this.renderDock();
  }

  componentWillUnmount() {
    MaterialDockTooltip.dockHovered = false;
    const anchor = this.getDOMNode();
    if (anchor) this.close(anchor);
  }

  render() {
    return this.props.children;
  }
}
