import { globalStore } from 'common/redux';
import { createContext, ReactNode, useCallback, useContext, useEffect, useLayoutEffect, useMemo, useRef, useState, useSyncExternalStore } from 'react';

import { useBackend } from '../../backend';
import { NetrunActionFeedback } from './actionFeedback';
import { netrunStoreFor } from './reactiveStore';
import { NetrunData } from './types';

const FeedbackContext = createContext<NetrunActionFeedback | null>(null);
const NO_FEEDBACK = () => null;
const NO_SUBSCRIPTION = () => () => {};

const LABELS: Record<string, string> = {
  select: 'Выбор узла', select_network: 'Выбор сети', focus_host: 'Возврат к своему узлу',
  map_sector: 'Смена сектора или этажа', map_resync: 'Синхронизация карты', search: 'Поиск узлов',
  breach: 'Начало взлома', breach_pick: 'Выбор кода', breach_abort: 'Прерывание взлома',
  move: 'Переход в узел', hop: 'Переход в узел', relay_hop: 'Переход через реле', travel: 'Автопроход', travel_cancel: 'Остановка маршрута',
  pursue: 'Захват и преследование цели', pursuit_stop: 'Остановка преследования',
  security_probe: 'Проверка следов взлома', security_trace: 'Контртрассировка источника',
  security_map: 'Отметить источник атаки', security_pursue: 'Преследование по следу атаки',
  agent_order: 'Приказ агенту', bot_launch: 'Запуск агента', agent_create: 'Создание агента',
  file_new: 'Создание файла', file_edit: 'Сохранение файла', file_rename: 'Переименование файла',
  file_copy: 'Копирование файла', file_move: 'Перенос файла', file_select: 'Выбор файла', file_import: 'Импорт в локальную память',
  delete_local: 'Удаление файла', delete_remote: 'Удаление файла с устройства',
  read: 'Чтение файла', upload: 'Загрузка файла', download: 'Скачивание файла',
  window_open: 'Открытие устройства', window_close: 'Закрытие устройства', window_focus: 'Выбор устройства',
  set_waypoint: 'Построение маршрута', clear_waypoint: 'Сброс маршрута',
  program_use: 'Запуск программы', combat_pass: 'Завершить ход', combat_join: 'Вступить в бой', recover_salvage: 'Подбор данных', chat_send: 'Отправка сообщения',
  cli: 'Команда терминала', web_site: 'Открытие сайта', web_page: 'Открытие страницы', web_back: 'Навигация WEB',
  entity_signal: 'Сигнал сущности', entity_message: 'Личное сообщение сущности',
  entity_file_offer: 'Предложить копию файла', entity_file_accept: 'Принять файл в память', entity_file_reject: 'Отклонить файл',
  access_export: 'Создание ключа доступа',
  set_theme: 'Тема интерфейса', appearance_update: 'Профиль сущности',
};

const actionLabel = (action: string, params: Record<string, unknown>, data: NetrunData) => {
  if (action === 'node_interact') {
    return data.selected?.interactions?.find((entry) => entry.id === params.id)?.name || 'Взаимодействие с узлом';
  }
  if (action === 'command' || action === 'window_act') {
    const id = action === 'command' ? params.id : params.waction;
    const commands = action === 'command' ? data.selected?.commands : data.window?.commands;
    return commands?.find((entry) => entry.id === id)?.name || 'Команда устройства';
  }
  if (action === 'remote_act') {
    const actions = data.window?.remote && data.window.remote.actions;
    return (Array.isArray(actions) && actions.find((entry) => entry.id === params.request)?.name) || 'Управление устройством';
  }
  return LABELS[action] || (Array.isArray(data.host_actions) && data.host_actions.find((entry) => entry.id === action)?.name) || 'Действие в сети';
};

export const NetrunFeedbackProvider = ({ children }: { children: ReactNode }) => {
  const receipt = useNetrunSelector((data) => data.input_ack);
  const [feedback] = useState(() => new NetrunActionFeedback());
  useLayoutEffect(() => { feedback.acknowledge(receipt); }, [feedback, receipt]);
  useEffect(() => () => feedback.dispose(), [feedback]);
  return <FeedbackContext.Provider value={feedback}>{children}</FeedbackContext.Provider>;
};

const sameSelection = <T, >(previous: T, next: T) => {
  if (Object.is(previous, next)) { return true; }
  if (!previous || !next || typeof previous !== 'object' || typeof next !== 'object'
    || Array.isArray(previous) !== Array.isArray(next)) { return false; }
  const keys = Object.keys(next);
  return keys.length === Object.keys(previous).length
    && keys.every((key) => Object.prototype.hasOwnProperty.call(previous, key) && Object.is(previous[key], next[key]));
};

/** Compare selected fields, never traverse map transport messages or retained graphs. */
export const useNetrunSelector = <T, >(select: (data: NetrunData) => T): T => {
  const store = netrunStoreFor(globalStore);
  const selector = useRef(select); selector.current = select;
  const read = useMemo(() => {
    let previous: T;
    return () => {
      const next = selector.current(store.read());
      if (!sameSelection(previous, next)) { previous = next; }
      return previous;
    };
  }, [store]);
  return useSyncExternalStore(store.subscribe, read, read);
};

export const useNetrunFeedback = () => {
  const feedback = useContext(FeedbackContext);
  return useSyncExternalStore(feedback?.subscribe || NO_SUBSCRIPTION, feedback?.snapshot || NO_FEEDBACK, NO_FEEDBACK);
};

/** Same backend contract for every NetRun host, with a local receipt before transport.
 * No provider is required by standalone panels or other games' interfaces.
 */
export const useNetrunBackend = <TData extends NetrunData = NetrunData>(fields?: readonly (keyof TData)[]) => {
  const backend = useBackend<TData>();
  const store = netrunStoreFor(globalStore);
  // [] subscribes only to actions. Omitting fields subscribes to the whole state.
  useNetrunSelector((data) => fields ? fields.map((key) => data[key as keyof NetrunData]) : data);
  const feedback = useContext(FeedbackContext);
  const act = useCallback((action: string, payload: object = {}) => {
    if (!feedback || action === 'workspace_view' || action === 'set_handle' || action === 'map_sync_ack') {
      return backend.act(action, payload);
    }
    const nonce = feedback.begin(action, payload, actionLabel(action, payload as Record<string, unknown>, store.read()));
    return backend.act(action, { ...payload, _netrun_action: nonce });
  }, [feedback, store, backend.act]);
  return { ...backend, data: store.read() as TData, act };
};
