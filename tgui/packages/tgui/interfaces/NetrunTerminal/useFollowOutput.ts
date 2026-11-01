import { useEffect, useRef, useState } from 'react';

/** Follow live output until the player scrolls up to read; capped logs still advance. */
export const useFollowOutput = (version: string, active = true) => {
  const scroller = useRef<HTMLDivElement>(null);
  const following = useRef(true);
  const previousVersion = useRef(version);
  const [unread, setUnread] = useState(false);
  const handleFollowLatest = () => {
    following.current = true;
    setUnread(false);
    if (scroller.current) { scroller.current.scrollTop = scroller.current.scrollHeight; }
  };
  const handleScroll = () => {
    const element = scroller.current;
    if (!element || !active) { return; }
    following.current = element.scrollHeight - element.clientHeight - element.scrollTop <= 24;
    if (following.current) { setUnread(false); }
  };
  useEffect(() => {
    const changed = previousVersion.current !== version;
    previousVersion.current = version;
    if (!following.current) { if (changed) { setUnread(true); } return; }
    if (active && scroller.current) { scroller.current.scrollTop = scroller.current.scrollHeight; }
  }, [version, active]);
  return { scroller, handleScroll, unread, handleFollowLatest };
};
