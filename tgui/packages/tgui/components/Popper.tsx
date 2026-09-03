import { createPopper, OptionsGeneric } from "@popperjs/core";
import { canDirectlyRef } from 'common/react';
import { cloneElement, Component, ReactNode } from "react";
import { createPortal } from "react-dom";

type PopperProps = {
  readonly popperContent: ReactNode;
  readonly options?: Partial<OptionsGeneric<unknown>>;
  readonly additionalStyles?: Record<string, string>,
  readonly children?: ReactNode;
};

export class Popper extends Component<PopperProps> {
  static id: number = 0;

  renderedContent: HTMLDivElement | null = null;
  popperInstance: ReturnType<typeof createPopper> | null = null;
  domNode: Element | null = null;

  constructor(props: PopperProps) {
    super(props);

    Popper.id += 1;
  }

  handleRef = (node: unknown) => {
    this.domNode = node instanceof Element ? node : null;
  };

  getContainer(): HTMLDivElement {
    if (!this.renderedContent) {
      this.renderedContent = document.createElement("div");
    }
    return this.renderedContent;
  }

  componentDidMount() {
    const {
      additionalStyles,
      options,
    } = this.props;

    const renderedContent = this.getContainer();
    if (additionalStyles) {
      for (const [attribute, value] of Object.entries(additionalStyles)) {
        renderedContent.style[attribute] = value;
      }
    }

    // DPI fix: append to <html> instead of <body> to escape body zoom.
    // Popper.js then works in viewport coords for both positioning and
    // overflow detection, fixing tooltip shift near screen edges.
    document.documentElement.appendChild(renderedContent);

    if (this.domNode) {
      this.popperInstance = createPopper(
        this.domNode,
        renderedContent,
        options,
      );
    }
  }

  componentDidUpdate() {
    this.popperInstance?.update();
  }

  componentWillUnmount() {
    this.popperInstance?.destroy();
    this.popperInstance = null;
    this.renderedContent?.remove();
    this.renderedContent = null;
  }

  render() {
    const { children, popperContent } = this.props;

    let target: ReactNode;
    if (canDirectlyRef(children)) {
      target = cloneElement(children as any, { ref: this.handleRef });
    } else {
      target = (
        <span ref={this.handleRef} style={{ display: 'contents' }}>
          {children}
        </span>
      );
    }

    // DPI fix: apply body zoom to content so it matches the rest of the UI,
    // since the container is outside body zoom (appended to <html>).
    const zoom = document.body.style.zoom || '100%';
    const portal = createPortal(
      <div style={{ zoom }}>{popperContent}</div>,
      this.getContainer(),
    );

    return (
      <>
        {target}
        {portal}
      </>
    );
  }
}
