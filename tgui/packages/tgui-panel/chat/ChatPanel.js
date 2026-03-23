/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { shallowDiffers } from 'common/react';
import { Component, createRef } from 'inferno';

import { chatRenderer } from './renderer';

export class ChatPanel extends Component {
  constructor() {
    super();
    this.ref = createRef();
  }

  componentDidMount() {
    const rootNode = this.ref.current;
    const scrollNode = rootNode?.closest('.Layout__content--scrollable');
    chatRenderer.mount(rootNode, scrollNode);
    chatRenderer.applyPendingAppearance();
    this.componentDidUpdate();
  }

  componentDidUpdate(prevProps) {
    requestAnimationFrame(() => {
      chatRenderer.ensureScrollTracking();
    });
    const shouldUpdateStyle = (
      !prevProps || shallowDiffers(this.props, prevProps)
    );
    if (shouldUpdateStyle) {
      chatRenderer.assignStyle({
        'width': '100%',
        'white-space': 'pre-wrap',
        'font-size': this.props.fontSize,
        'line-height': this.props.lineHeight,
      });
    }
  }

  render() {
    return (
      <div className="Chat" ref={this.ref} />
    );
  }
}
