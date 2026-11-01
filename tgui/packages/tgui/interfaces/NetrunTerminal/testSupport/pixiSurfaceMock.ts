import type { GraphBase, GraphOverlay } from '../graphPresentation';
import type { GraphScene } from '../graphScene';
import type { GraphPoint } from '../mapLayout';
import type { PixiSurface } from '../pixiSurface';

export type MockPixiSurface = jest.Mocked<PixiSurface> & {
  element: HTMLCanvasElement;
  setSuspended: jest.Mock;
};

/** Component tests exercise the real viewport/controller without a GPU in jsdom.
 * Renderer behavior is tested separately against Pixi scene objects and real WebGL.
 */
export const makePixiSurfaceMock = (host: HTMLElement): MockPixiSurface => {
  const element = document.createElement('canvas');
  element.setAttribute('data-net-pixi', '');
  element.setAttribute('aria-hidden', 'true');
  host.appendChild(element);
  let live: GraphScene | null = null;
  return {
    element,
    updateScene: jest.fn((_scene: GraphScene, _base: GraphBase) => true),
    updateActors: jest.fn((scene: GraphScene, _overlay: GraphOverlay) => { live = scene; }),
    updateCamera: jest.fn((_camera: { x: number; y: number; zoom: number }) => {}),
    setInteracting: jest.fn((_interacting: boolean) => {}),
    resize: jest.fn((_width: number, _height: number) => true),
    hitTest: jest.fn((point: GraphPoint, zoom: number) => live?.hit(point, zoom) ?? null),
    setSuspended: jest.fn(),
    destroy: jest.fn(() => element.remove()),
  };
};
