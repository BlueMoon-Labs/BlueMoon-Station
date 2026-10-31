/** One measured conversion between browser client pixels and Pixi/DOM layout
 * coordinates. CSS zoom can differ from devicePixelRatio; the actual rectangle
 * already accounts for both and must not be multiplied by DPR again.
 */
export class ViewportCoordinates {
  private readonly scaleX: number;
  private readonly scaleY: number;

  constructor(private readonly bounds: DOMRect, width: number, height: number) {
    this.scaleX = bounds.width > 0 ? width / bounds.width : 1;
    this.scaleY = bounds.height > 0 ? height / bounds.height : 1;
  }

  point(clientX: number, clientY: number) {
    return this.delta(clientX - this.bounds.left, clientY - this.bounds.top);
  }

  delta(clientX: number, clientY: number) {
    return { x: clientX * this.scaleX, y: clientY * this.scaleY };
  }
}
