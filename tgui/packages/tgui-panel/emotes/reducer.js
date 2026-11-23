const initialState = {
  enabled: false,
  visible: false,
  list: {},
  order: [],
  slot: null,
  revision: null,
};

export const emotesReducer = (state = initialState, action) => {
  const { type, payload } = action;
  if (type === 'emotes/toggle') {
    return {
      ...state,
      visible: !state.visible,
    };
  }
  if (type === 'emotes/setList') {
    return {
      ...state,
      enabled: !!payload.enabled,
      visible: !!payload.enabled && state.visible,
      list: payload.list,
      order: payload.order,
      slot: payload.slot,
      revision: payload.revision,
    };
  }
  return state;
};
