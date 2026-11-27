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

export const PaperHtml = ({ text }: { text: string }) => {
  const fragment = useMemo(() => sanitizePaperMarkup(text, true), [text]);
  return <PaperMarkup fragment={fragment} />;
};
