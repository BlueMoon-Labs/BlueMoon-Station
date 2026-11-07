import { useEffect, useState } from 'react';
import { Button } from 'tgui/components';

import { hasOlderChatHistory, loadOlderChatHistory } from './middleware';
import { chatRenderer } from './renderer';

/**
 * Кнопка над чатом, когда его прокрутили до самого верха, а в истории
 * остались сообщения старше.
 */
export const ChatHistoryButton = () => {
  const [atTop, setAtTop] = useState(chatRenderer.atTop);
  const [loading, setLoading] = useState(false);
  useEffect(() => {
    chatRenderer.events.on('atTopChanged', setAtTop);
    return () => chatRenderer.events.off('atTopChanged', setAtTop);
  }, []);
  if (!atTop || !hasOlderChatHistory()) {
    return null;
  }
  return (
    <Button
      className="Chat__historyButton"
      icon={loading ? 'spinner' : 'history'}
      iconSpin={loading}
      disabled={loading}
      onClick={async () => {
        setLoading(true);
        await loadOlderChatHistory();
        setLoading(false);
      }}>
      Ранние сообщения
    </Button>
  );
};
