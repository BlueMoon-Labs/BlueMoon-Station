import { useDispatch, useSelector } from 'common/redux';

import { selectEmotes } from './selectors';

export const useEmotes = () => {
  const emotes = useSelector(selectEmotes);
  const dispatch = useDispatch();
  return {
    ...emotes,
    toggle: () => dispatch({ type: 'emotes/toggle' }),
  };
};
