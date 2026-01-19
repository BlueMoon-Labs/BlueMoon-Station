import { useDispatch, useSelector } from 'common/redux';

import { selectEmotes } from './selectors';

export const useEmotes = context => {
  const emotes = useSelector(context, selectEmotes);
  const dispatch = useDispatch(context);
  return {
    ...emotes,
    toggle: () => dispatch({ type: 'emotes/toggle' }),
  };
};
