/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { selectBackend } from './backend';
import { Icon, Stack } from './components';
import { KitchenSink } from './debug';
import { selectDebug } from './debug/selectors';
import { IS_DEVELOPMENT } from './env';
import { Window } from './layouts';

const interfaceModules = import.meta.glob('./interfaces/**/*.{js,tsx}', {
  eager: true,
});
const loggedMissingExports = new Set();

const routingError = (type, name) => () => {
  return (
    <Window>
      <Window.Content scrollable>
        {type === 'notFound' && (
          <div>Interface <b>{name}</b> was not found.</div>
        )}
        {type === 'missingExport' && (
          <div>Interface <b>{name}</b> is missing an export.</div>
        )}
      </Window.Content>
    </Window>
  );
};

const SuspendedWindow = () => {
  return (
    <Window>
      <Window.Content scrollable />
    </Window>
  );
};

const RefreshingWindow = () => {
  return (
    <Window height={130} title="Loading" width={150}>
      <Window.Content>
        <Stack align="center" fill justify="center" vertical>
          <Stack.Item>
            <Icon color="blue" name="toolbox" spin size={4} />
          </Stack.Item>
          <Stack.Item>
            Please wait...
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const resolveInterfaceComponent = (esModule, name) => {
  if (!esModule) {
    return null;
  }
  if (typeof esModule === 'function') {
    return esModule;
  }
  if (esModule[name]) {
    return esModule[name];
  }
  const defaultExport = esModule.default;
  if (defaultExport?.[name]) {
    return defaultExport[name];
  }
  if (typeof defaultExport === 'function') {
    return defaultExport;
  }
  return null;
};

export const getRoutedComponent = store => {
  const state = store.getState();
  const { suspended, config } = selectBackend(state);
  if (suspended) {
    return SuspendedWindow;
  }
  if (config.refreshing) {
    return RefreshingWindow;
  }
  if (IS_DEVELOPMENT) {
    const debug = selectDebug(state);
    // Show a kitchen sink
    if (debug.kitchenSink) {
      return KitchenSink;
    }
  }
  const name = config?.interface;
  const interfacePathCandidates = [
    `./interfaces/${name}.tsx`,
    `./interfaces/${name}.js`,
    `./interfaces/${name}/index.tsx`,
    `./interfaces/${name}/index.js`,
  ];
  const esModule = interfacePathCandidates
    .map(path => interfaceModules[path])
    .find(Boolean);
  if (!esModule) {
    return routingError('notFound', name);
  }
  const Component = resolveInterfaceComponent(esModule, name);
  if (!Component) {
    if (IS_DEVELOPMENT && !loggedMissingExports.has(name)) {
      loggedMissingExports.add(name);
      console.error(`Interface ${name} is missing an export.`, {
        exports: Object.keys(esModule),
      });
    }
    return routingError('missingExport', name);
  }
  return Component;
};
