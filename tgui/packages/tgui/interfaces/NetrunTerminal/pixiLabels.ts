import type { Container, Graphics, Text } from 'pixi.js';

import { layoutLabels } from './graphLabels';
import { GRAPH_TILE } from './graphLayout';
import type { GraphOverlay } from './graphPresentation';
import type { GraphScene, PlacedNode } from './graphScene';
import { GraphViewport } from './graphViewport';
import { destroyDisplay, PixiLibrary } from './pixiPrimitives';

type Caption = { text: Text; background: Graphics; rectangle: string };
/** From this zoom every device may be captioned; below it only important nodes are. */
export const LABEL_ALL_ZOOM = .9;

/** Screen-space Pixi text stays sharp, collision checked and keyed by address. */
export class PixiLabels {
  readonly layer: Container;
  private readonly captions = new Map<string, Caption>();
  private readonly metric: Text;
  constructor(private readonly pixi: PixiLibrary) {
    this.layer = new pixi.Container(); this.layer.label = 'screen-labels';
    this.metric = this.newText();
  }
  private newText() { return new this.pixi.Text({ text: '', style: { fontFamily: 'monospace', fontSize: 12, fill: 0xa9c3d2 } }); }

  update(scene: GraphScene, overlay: GraphOverlay, view: GraphViewport, width: number, height: number,
    displayed: (node: PlacedNode) => PlacedNode) {
    const padding = 32 / view.zoom + GRAPH_TILE * 4;
    const nodes = [...new Map<string, PlacedNode>(scene.visible(-view.x / view.zoom - padding, -view.y / view.zoom - padding,
      (width - view.x) / view.zoom + padding, (height - view.y) / view.zoom + padding)
      .map((node) => [node.address, displayed(node)] as const)).values()];
    const caption = (node: PlacedNode) => ['apc', 'gateway', 'relay'].includes(node.type)
      ? [overlay.gateways.get(node.network)?.code, node.sector?.replace('sector:', 'S'), node.name].filter(Boolean).join(' · ') : node.name;
    const priority = (node: PlacedNode) => node.address === overlay.selected ? 10 : node.address === overlay.hovered ? 9
      : node.address === overlay.entityHost ? 8 : node.ice ? 6 : node.police || node.fortress ? 5 : node.bots ? 4
        : ['apc', 'gateway', 'relay', 'server', 'ai'].includes(node.type) ? 3 : 0;
    // Away from close-up zoom only meaningful places are named; everything stays on hover.
    const overview = view.zoom < LABEL_ALL_ZOOM;
    const candidates = overview ? nodes.filter((node) => priority(node) > 0) : nodes;
    const placed = layoutLabels(candidates, view, width, height, (text) => {
      this.metric.text = text; return this.metric.width;
    }, priority, caption, overview ? 40 : 80);
    const visible = new Set<string>();
    for (const label of placed) {
      visible.add(label.node.address);
      let entry = this.captions.get(label.node.address);
      if (!entry) {
        entry = { text: this.newText(), background: new this.pixi.Graphics(), rectangle: '' };
        this.captions.set(label.node.address, entry); this.layer.addChild(entry.background, entry.text);
      }
      if (entry.text.text !== label.text) { entry.text.text = label.text; }
      entry.text.position.set(label.rect.left + 4, label.rect.top + 2);
      entry.text.style.fill = label.node.address === overlay.selected ? 0xd9fff2 : 0x99b2c1;
      const rectangle = `${label.rect.left},${label.rect.top},${label.rect.right},${label.rect.bottom}`;
      if (rectangle !== entry.rectangle) {
        entry.rectangle = rectangle;
        entry.background.clear().roundRect(label.rect.left, label.rect.top, label.rect.right - label.rect.left, 19, 4)
          .fill({ color: 0x102331, alpha: .9 })
          .stroke({ color: 0x294b5b, width: .6, alpha: .6 });
      }
    }
    for (const [address, entry] of this.captions) {
      if (!visible.has(address)) { destroyDisplay(entry.text); destroyDisplay(entry.background); this.captions.delete(address); }
    }
  }
  destroy() { this.captions.clear(); destroyDisplay(this.metric); destroyDisplay(this.layer); }
}
