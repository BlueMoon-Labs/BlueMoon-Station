import { createPopper, OptionsGeneric } from "@popperjs/core";
import { Component, findDOMFromVNode, InfernoNode, render } from "inferno";

type PopperProps = {
  readonly popperContent: InfernoNode;
  readonly options?: Partial<OptionsGeneric<unknown>>;
  readonly additionalStyles?: Record<string, string>,
};

export class Popper extends Component<PopperProps> {
  static id: number = 0;

  renderedContent: HTMLDivElement;
  popperInstance: ReturnType<typeof createPopper>;

  constructor() {
    super();

    Popper.id += 1;
  }

  componentDidMount() {
    const {
      additionalStyles,
      options,
    } = this.props;

    this.renderedContent = document.createElement("div");
    if (additionalStyles) {
      for (const [attribute, value] of Object.entries(additionalStyles)) {
        this.renderedContent.style[attribute] = value;
      }
    }

    this.renderPopperContent(() => {
      // DPI fix: append to <html> instead of <body> to escape body zoom.
      // Popper.js then works in viewport coords for both positioning and
      // overflow detection, fixing tooltip shift near screen edges.
      document.documentElement.appendChild(this.renderedContent);

      // HACK: We don't want to create a wrapper, as it could break the layout
      // of consumers, so we do the inferno equivalent of `findDOMNode(this)`.
      // This code is copied from `findDOMNode` in inferno-extras.
      // Because this component is written in TypeScript, we will know
      // immediately if this internal variable is removed.
      const domNode = findDOMFromVNode(this.$LI, true);

      this.popperInstance = createPopper(
        domNode,
        this.renderedContent,
        options,
      );
    });
  }

  componentDidUpdate() {
    this.renderPopperContent(() => this.popperInstance?.update());
  }

  componentWillUnmount() {
    this.popperInstance?.destroy();
    this.renderedContent.remove();
    this.renderedContent = null;
  }

  renderPopperContent(callback: () => void) {
    // DPI fix: apply body zoom to content so it matches the rest of the UI,
    // since the container is outside body zoom (appended to <html>).
    const zoom = document.body.style.zoom || '100%';
    render(
      <div style={{ zoom }}>{this.props.popperContent}</div>,
      this.renderedContent,
      callback,
    );
  }

  render() {
    return this.props.children;
  }
}
