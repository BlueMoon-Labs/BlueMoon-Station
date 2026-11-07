import { useSelector } from 'common/redux';
import { Button } from 'tgui/components';

import { selectSettings } from '../settings/selectors';
import { chatRenderer } from './renderer';
import { selectChat, selectCurrentChatPage } from './selectors';

export const formatScrollButtonLabel = (unreadCount, showCount) => {
  const label = 'Прокрутить вниз';
  if (!showCount || !(unreadCount > 0)) {
    return label;
  }
  return label + ' (' + (unreadCount > 999 ? '999+' : unreadCount) + ')';
};

export const ChatScrollButton = () => {
  const { scrollTracking } = useSelector(selectChat);
  const page = useSelector(selectCurrentChatPage);
  const { newMessagesMarker } = useSelector(selectSettings);
  if (scrollTracking) {
    return null;
  }
  return (
    <Button
      className="Chat__scrollButton"
      icon="arrow-down"
      onClick={() => chatRenderer.scrollToBottom({ smooth: true })}>
      {formatScrollButtonLabel(page?.unreadCount,
        newMessagesMarker !== false)}
    </Button>
  );
};
