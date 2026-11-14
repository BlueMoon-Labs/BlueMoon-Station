/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { classes } from 'common/react';
import { useDispatch } from 'common/redux';
import { decodeHtmlEntities, toTitleCase } from 'common/string';
import { Component } from 'react';

import { backendSuspendStart, useBackend } from '../backend';
import { Icon } from '../components';
import { UI_DISABLED, UI_INTERACTIVE, UI_UPDATE } from '../constants';
import { useDebug } from '../debug';
import { toggleKitchenSink } from '../debug/actions';
import { dragStartHandler, getWindowSize, recallWindowGeometry, resizeStartHandler, setWindowKey } from '../drag';
import { parseWingetSize } from '../drag.utils';
import { IS_DEVELOPMENT } from '../env';
import { createLogger } from '../logging';
import { Layout } from './Layout';

const logger = createLogger('Window');

const DEFAULT_SIZE = [400, 600];
const getZoomKey = config => (
  config.window?.zoom_key
  || (config.interface && `tgui:${config.interface}`)
  || 'tgui'
);

export class Window extends Component {
  state = { maximized: false };
  _mounted = false;
  _maximizedRead = 0;

  componentDidMount() {
    this._mounted = true;
    this.trackMaximized(this.props.canMaximize);
    const { suspended, config } = useBackend();
    const { canClose = true } = this.props;
    this._wasSuspended = suspended;
    this._lastWindowKey = config.window?.key;
    this._lastWindowScale = config.window?.scale;
    this._lastZoomKey = getZoomKey(config);
    if (suspended) {
      return;
    }
    Byond.winset(window.__windowId__, {
      'can-close': Boolean(canClose),
    });
    logger.log('mounting');
    this.updateGeometry();
  }

  componentDidUpdate(prevProps) {
    if (prevProps.canMaximize !== this.props.canMaximize) {
      this.trackMaximized(this.props.canMaximize);
      if (!this.props.canMaximize) {
        this._cancelRestoreDrag?.();
        Byond.winset(window.__windowId__, { 'is-maximized': false });
      }
    }
    const { suspended, config } = useBackend();
    const wasSuspended = this._wasSuspended;
    const zoomKey = getZoomKey(config);
    const shouldUpdateGeometry = (
      this.props.width !== prevProps.width
      || this.props.height !== prevProps.height
      || (wasSuspended && !suspended)
      || this._lastWindowKey !== config.window?.key
      || this._lastWindowScale !== config.window?.scale
      || this._lastZoomKey !== zoomKey
    );
    if (!suspended && shouldUpdateGeometry) {
      this.updateGeometry();
    }
    this._wasSuspended = suspended;
    this._lastWindowKey = config.window?.key;
    this._lastWindowScale = config.window?.scale;
    this._lastZoomKey = zoomKey;
  }

  componentWillUnmount() {
    this._mounted = false;
    this.trackMaximized(false);
    this._cancelRestoreDrag?.();
    if (this.props.canMaximize) {
      // Окно пула может следующим получить другой интерфейс.
      Byond.winset(window.__windowId__, { 'is-maximized': false });
    }
  }

  trackMaximized(enabled) {
    clearTimeout(this._maximizedResizeTimer);
    window.removeEventListener('resize', this.scheduleMaximizedRead);
    window.removeEventListener('focus', this.readMaximized);
    if (enabled) {
      window.addEventListener('resize', this.scheduleMaximizedRead);
      window.addEventListener('focus', this.readMaximized);
      this.readMaximized();
    }
  }

  scheduleMaximizedRead = () => {
    // Изменение размера порождает много resize; не отправляем winget на каждый кадр.
    clearTimeout(this._maximizedResizeTimer);
    this._maximizedResizeTimer = setTimeout(this.readMaximized, 100);
  };

  readMaximized = async () => {
    const request = ++this._maximizedRead;
    try {
      const value = await Byond.winget(window.__windowId__, 'is-maximized');
      if (value === undefined || value === null) return null;
      const maximized = value === true || value === 1
        || value === 'true' || value === '1';
      if (this._mounted && request === this._maximizedRead
          && this.state.maximized !== maximized) {
        this.setState({ maximized });
      }
      return maximized;
    }
    catch (error) {
      logger.warn('Не удалось прочитать состояние окна', error);
      return null;
    }
  };

  toggleMaximize = async () => {
    if (this._maximizing) return;
    this._maximizing = true;
    try {
      const maximized = await this.readMaximized();
      if (!this._mounted || maximized === null) return;
      Byond.winset(window.__windowId__, { 'is-maximized': !maximized });
      await this.readMaximized();
    }
    finally {
      this._maximizing = false;
    }
  };

  handleDragStart = event => {
    if (event.button !== 0) return;
    // Перетаскивание временно отключает pointer-events, поэтому dblclick не доходит до заголовка.
    if (this.props.canMaximize && event.detail === 2) {
      this._cancelRestoreDrag?.();
      this.toggleMaximize();
      return;
    }
    if (!this.props.canMaximize || !this.state.maximized) {
      dragStartHandler(event);
      return;
    }
    this._cancelRestoreDrag?.();
    const anchor = {
      horizontalRatio: event.clientX / window.innerWidth,
      clientY: event.clientY,
    };
    const start = [event.screenX, event.screenY];
    let latestEvent = event;
    let active = true;
    let restoring = false;
    const cancel = () => {
      active = false;
      document.removeEventListener('mousemove', move);
      document.removeEventListener('mouseup', cancel);
      window.removeEventListener('blur', cancel);
      this._cancelRestoreDrag = null;
    };
    const move = async moveEvent => {
      if (!moveEvent.buttons) {
        cancel();
        return;
      }
      latestEvent = moveEvent;
      // Один клик по заголовку не должен снимать максимизацию.
      if (restoring || Math.hypot(moveEvent.screenX - start[0], moveEvent.screenY - start[1]) < 4) return;
      restoring = true;
      Byond.winset(window.__windowId__, { 'is-maximized': false });
      try {
        const [size] = await Promise.all([
          Byond.winget(window.__windowId__, 'size'),
          this.readMaximized(),
        ]);
        if (!active || !this._mounted) return;
        cancel();
        dragStartHandler(latestEvent, {
          ...anchor,
          width: (parseWingetSize(size) || getWindowSize())[0],
        });
      }
      catch (error) {
        cancel();
        logger.warn('Не удалось восстановить окно для перетаскивания', error);
      }
    };
    this._cancelRestoreDrag = cancel;
    document.addEventListener('mousemove', move);
    document.addEventListener('mouseup', cancel);
    window.addEventListener('blur', cancel);
  };

  updateGeometry() {
    const { config } = useBackend();
    const options = {
      size: DEFAULT_SIZE,
      ...config.window,
    };
    if (this.props.width && this.props.height) {
      options.size = [this.props.width, this.props.height];
    }
    options.zoom_key = getZoomKey(config);
    if (config.window?.key) {
      setWindowKey(config.window.key);
    }
    recallWindowGeometry(options);
  }

  render() {
    const {
      canClose = true,
      theme,
      title,
      children,
      buttons,
      canMaximize,
    } = this.props;
    const {
      config,
      suspended,
    } = useBackend();
    const { debugLayout } = useDebug();
    const dispatch = useDispatch();
    const fancy = config.window?.fancy;
    const { maximized } = this.state;
    // Determine when to show dimmer
    const showDimmer = config.user && (
      config.user.observer
        ? config.status < UI_DISABLED
        : config.status < UI_INTERACTIVE
    );
    return (
      <Layout
        className="Window"
        theme={theme}>
        <TitleBar
          className="Window__titleBar"
          title={!suspended && (title || decodeHtmlEntities(config.title))}
          status={config.status}
          fancy={fancy}
          maximized={maximized}
          onMaximize={canMaximize ? this.toggleMaximize : undefined}
          onDragStart={this.handleDragStart}
          onClose={() => {
            logger.log('pressed close');
            dispatch(backendSuspendStart());
          }}
          canClose={canClose}>
          {buttons}
        </TitleBar>
        <div
          className={classes([
            'Window__rest',
            debugLayout && 'debug-layout',
          ])}>
          {!suspended && children}
          {showDimmer && (
            <div className="Window__dimmer" />
          )}
        </div>
        {!!fancy && !(canMaximize && maximized) && (
          <>
            <div className="Window__resizeHandle__e"
              onMouseDown={resizeStartHandler(1, 0)} />
            <div className="Window__resizeHandle__s"
              onMouseDown={resizeStartHandler(0, 1)} />
            <div className="Window__resizeHandle__se"
              onMouseDown={resizeStartHandler(1, 1)} />
          </>
        )}
      </Layout>
    );
  }
}

const WindowContent = props => {
  const {
    className,
    fitted,
    children,
    ...rest
  } = props;
  return (
    <Layout.Content
      className={classes([
        'Window__content',
        className,
      ])}
      {...rest}>
      {fitted && children || (
        <div className="Window__contentPadding">
          {children}
        </div>
      )}
    </Layout.Content>
  );
};

Window.Content = WindowContent;

const statusToColor = status => {
  switch (status) {
    case UI_INTERACTIVE:
      return 'good';
    case UI_UPDATE:
      return 'average';
    case UI_DISABLED:
    default:
      return 'bad';
  }
};

const TitleBar = (props) => {
  const {
    className,
    title,
    status,
    canClose,
    fancy,
    maximized,
    onMaximize,
    onDragStart,
    onClose,
    children,
  } = props;
  const dispatch = useDispatch();
  return (
    <div
      className={classes([
        'TitleBar',
        className,
      ])}>
      {status === undefined && (
        <Icon
          className="TitleBar__statusIcon"
          name="tools"
          opacity={0.5} />
      ) || (
        <Icon
          className="TitleBar__statusIcon"
          color={statusToColor(status)}
          name="eye" />
      )}
      <div
        className="TitleBar__dragZone"
        onMouseDown={onDragStart} />
      <div className="TitleBar__title">
        {typeof title === 'string'
          && title === title.toLowerCase()
          && toTitleCase(title)
          || title}
        {!!children && (
          <div className="TitleBar__buttons">
            {children}
          </div>
        )}
      </div>
      {!!onMaximize && (
        <button
          type="button"
          className={classes([
            'TitleBar__maximize TitleBar__clickable',
            fancy && canClose && 'TitleBar__maximize--withClose',
          ])}
          title={maximized ? 'Восстановить размер окна' : 'Развернуть окно'}
          aria-label={maximized ? 'Восстановить размер окна' : 'Развернуть окно'}
          onMouseDown={event => event.stopPropagation()}
          onClick={onMaximize}>
          <Icon name={maximized ? 'window-restore' : 'window-maximize'} />
        </button>
      )}
      {IS_DEVELOPMENT && (
        <div
          className="TitleBar__devBuildIndicator"
          onClick={() => dispatch(toggleKitchenSink())}>
          <Icon name="bug" />
        </div>
      )}
      {Boolean(fancy && canClose) && (
        <div
          className="TitleBar__close TitleBar__clickable"
          onClick={onClose}>
          ×
        </div>
      )}
    </div>
  );
};
