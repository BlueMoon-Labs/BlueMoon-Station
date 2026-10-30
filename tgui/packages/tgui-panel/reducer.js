import { combineReducers } from 'common/redux';

import { audioReducer } from './audio';
import { chatReducer } from './chat';
import { emotesReducer } from './emotes';
import { gameReducer } from './game';
import { pingReducer } from './ping';
import { settingsReducer } from './settings';

// backend сюда не входит: его уже подключает configureStore, а второй
// backendReducer применял бы каждое действие дважды - подтверждение чанка
// снимало из очереди два чанка, и большие сохранения панели не доходили.
export const panelReducer = combineReducers({
  audio: audioReducer,
  chat: chatReducer,
  emotes: emotesReducer,
  game: gameReducer,
  ping: pingReducer,
  settings: settingsReducer,
});
