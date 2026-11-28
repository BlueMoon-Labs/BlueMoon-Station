import { useLayoutEffect, useMemo, useRef } from 'react';

import { sanitizePaperMarkup } from '../../sanitize';

export const PaperMarkup = ({ fragment, className }: {
  fragment: DocumentFragment;
  className?: string;
}) => {
  const content = useRef<HTMLSpanElement>(null);
  useLayoutEffect(() => {
    content.current?.replaceChildren(fragment.cloneNode(true));
  }, [fragment]);
  return <span className={className} ref={content} />;
};

export const PaperHtml = ({ text, allowMedia = true }: {
  text: string;
  allowMedia?: boolean;
}) => {
  const fragment = useMemo(
    () => sanitizePaperMarkup(text, true, allowMedia),
    [text, allowMedia]
  );
  return <PaperMarkup fragment={fragment} />;
};
