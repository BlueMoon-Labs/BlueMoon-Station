
import { createPopper, Placement, VirtualElement } from '@popperjs/core';
import { canDirectlyRef } from 'common/react';
import { cloneElement, Component, ReactNode } from 'react';
import { createPortal } from 'react-dom';

type TooltipProps = {
  readonly children?: ReactNode;
  readonly content: ReactNode;
  readonly position?: Placement,
};

type TooltipState = {
  hovered: boolean;
};

const DEFAULT_OPTIONS = {
  modifiers: [{
    name: "eventListeners",
    enabled: false,
  }],
};

const NULL_RECT = {
  width: 0,
  height: 0,
  top: 0,
  right: 0,
  bottom: 0,
  left: 0,
};

export class Tooltip extends Component<TooltipProps, TooltipState> {
  // Mounting poppers is really laggy because popper.js is very slow.
  // Thus, instead of using the Popper component, Tooltip creates ONE popper
  // and stores every tooltip inside that.
  // This means you can never have two tooltips at once, for instance.
  static renderedTooltip: HTMLDivElement | undefined;
  static singletonPopper: ReturnType<typeof createPopper> | undefined;
  static currentHoveredElement: Element | undefined;
  static virtualElement: VirtualElement = {
    getBoundingClientRect: () => {
      const rect = Tooltip.currentHoveredElement?.getBoundingClientRect();
      if (!rect) return NULL_RECT as DOMRect;
      return rect;
    },
  };

  state: TooltipState = {
    hovered: false,
  };

  domNode: Element | null = null;

  handleRef = (node: unknown) => {
    this.domNode = node instanceof Element ? node : null;
  };

  // The element used for positioning. A display:contents wrapper has
  // a zero-sized rect, so measure its first child instead.
  getAnchor(): Element | null {
    const node = this.domNode;
    if (!node) {
      return null;
    }
    if (node instanceof HTMLElement && node.style.display === 'contents') {
      return node.firstElementChild ?? node;
    }
    return node;
  }

  handleMouseEnter = () => {
    let renderedTooltip = Tooltip.renderedTooltip;
    if (renderedTooltip === undefined) {
      renderedTooltip = document.createElement("div");
      renderedTooltip.className = "Tooltip";
      // DPI fix: append to <html> instead of <body> to escape body zoom.
      // Popper.js then works in viewport coords for both positioning and
      // overflow detection, fixing tooltip shift near screen edges.
      document.documentElement.appendChild(renderedTooltip);
      Tooltip.renderedTooltip = renderedTooltip;
    }

    Tooltip.currentHoveredElement = this.getAnchor() ?? undefined;
    renderedTooltip.style.opacity = "1";
    this.setState({ hovered: true });
  };

  handleMouseLeave = () => {
    this.fadeOut();
    this.setState({ hovered: false });
  };

  componentDidMount() {
    const domNode = this.domNode;
    if (!domNode) {
      return;
    }
    domNode.addEventListener("mouseenter", this.handleMouseEnter);
    domNode.addEventListener("mouseleave", this.handleMouseLeave);
  }

  fadeOut() {
    if (Tooltip.currentHoveredElement !== this.getAnchor()) {
      return;
    }

    Tooltip.currentHoveredElement = undefined;
    Tooltip.renderedTooltip!.style.opacity = "0";
  }

  updatePopper() {
    const renderedTooltip = Tooltip.renderedTooltip;
    if (!renderedTooltip) {
      return;
    }
    let singletonPopper = Tooltip.singletonPopper;
    if (singletonPopper === undefined) {
      singletonPopper = createPopper(
        Tooltip.virtualElement,
        renderedTooltip,
        {
          ...DEFAULT_OPTIONS,
          placement: this.props.position || "auto",
        }
      );

      Tooltip.singletonPopper = singletonPopper;
    } else {
      singletonPopper.setOptions({
        ...DEFAULT_OPTIONS,
        placement: this.props.position || "auto",
      });

      singletonPopper.update();
    }
  }

  componentDidUpdate() {
    if (
      this.state.hovered
      && Tooltip.currentHoveredElement === this.getAnchor()
    ) {
      // The portal content has just been committed to the DOM,
      // so the popper can measure it.
      this.updatePopper();
    }
  }

  componentWillUnmount() {
    const domNode = this.domNode;
    if (domNode) {
      domNode.removeEventListener("mouseenter", this.handleMouseEnter);
      domNode.removeEventListener("mouseleave", this.handleMouseLeave);
    }
    this.fadeOut();
  }

  render() {
    const { children, content } = this.props;
    const { hovered } = this.state;

    let target: ReactNode;
    if (canDirectlyRef(children)) {
      target = cloneElement(children as any, { ref: this.handleRef });
    } else {
      // Fallback wrapper for text and class component children.
      target = (
        <span ref={this.handleRef} style={{ display: 'contents' }}>
          {children}
        </span>
      );
    }

    // DPI fix: apply body zoom to content so it matches the rest of the UI,
    // since the container is outside body zoom (appended to <html>).
    const zoom = document.body.style.zoom || '100%';
    const portal = (
      hovered
      && Tooltip.renderedTooltip
      && Tooltip.currentHoveredElement === this.getAnchor()
    )
      ? createPortal(
        <span style={{ zoom }}>{content}</span>,
        Tooltip.renderedTooltip,
      )
      : null;

    return (
      <>
        {target}
        {portal}
      </>
    );
  }
}
