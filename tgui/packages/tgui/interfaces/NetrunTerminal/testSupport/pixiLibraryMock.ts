/** Display-list test double. Tests assert resource ownership/geometry, never GPU pixels. */
export class MockPoint {
  x = 0; y = 0;
  set(x: number, y = x) { this.x = x; this.y = y; }
}
export class MockContainer {
  static instances: MockContainer[] = [];
  children: MockContainer[] = [];
  parent: MockContainer | null = null;
  position = new MockPoint(); scale = new MockPoint(); anchor = new MockPoint();
  label = ''; visible = true; alpha = 1; destroyed = false;
  constructor() { MockContainer.instances.push(this); }
  addChild(...children: MockContainer[]) {
    for (const child of children) { child.parent?.removeChild(child); child.parent = this; this.children.push(child); }
    return children[0];
  }
  removeChild(child: MockContainer) { this.children = this.children.filter((entry) => entry !== child); child.parent = null; }
  destroy(options?: { children?: boolean }) {
    if (this.destroyed) { throw new Error('Double destroy'); }
    this.destroyed = true;
    if (options?.children) { for (const child of [...this.children]) { child.destroy(options); } }
    this.parent?.removeChild(this);
  }
}
export class MockGraphics extends MockContainer {
  static graphics: MockGraphics[] = [];
  calls: { op: string; args: unknown[] }[] = [];
  clears = 0;
  constructor() { super(); MockGraphics.graphics.push(this); }
  clear() { this.clears++; this.calls = []; return this; }
  private op(op: string, args: unknown[]) { this.calls.push({ op, args }); return this; }
  moveTo(...args: unknown[]) { return this.op('moveTo', args); }
  lineTo(...args: unknown[]) { return this.op('lineTo', args); }
  stroke(...args: unknown[]) { return this.op('stroke', args); }
  circle(...args: unknown[]) { return this.op('circle', args); }
  rect(...args: unknown[]) { return this.op('rect', args); }
  roundRect(...args: unknown[]) { return this.op('roundRect', args); }
  fill(...args: unknown[]) { return this.op('fill', args); }
  closePath(...args: unknown[]) { return this.op('closePath', args); }
}
export class MockText extends MockContainer {
  text: string;
  style: { fill?: number };
  constructor(options: { text: string; style: { fill?: number } }) { super(); this.text = options.text; this.style = options.style; }
  get width() { return this.text.length * 6.6; }
}
export class MockApplication {
  static instances: MockApplication[] = [];
  static pending: Promise<void> | null = null;
  static rejectInit = false;
  stage = new MockContainer();
  renderer = { resize: jest.fn(), render: jest.fn(), destroy: jest.fn(), background: { color: 0 } };
  canvas: HTMLCanvasElement;
  stops = 0; destroys = 0;
  constructor() { MockApplication.instances.push(this); }
  async init(options: { canvas: HTMLCanvasElement }) {
    this.canvas = options.canvas;
    if (MockApplication.pending) { await MockApplication.pending; }
    if (MockApplication.rejectInit) { throw new Error('init failed'); }
  }
  stop() { this.stops++; }
  destroy(_renderer: unknown, options: { children?: boolean }) { this.destroys++; this.stage.destroy(options); this.renderer.destroy(); }
}
export const mockPixi = { Application: MockApplication, Container: MockContainer, Graphics: MockGraphics, Text: MockText } as unknown as typeof import('pixi.js');
export function resetPixiMock() {
  MockApplication.instances = []; MockApplication.pending = null; MockApplication.rejectInit = false;
  MockContainer.instances = []; MockGraphics.graphics = [];
}
