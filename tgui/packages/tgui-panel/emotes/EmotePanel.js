import { useCallback, useEffect, useMemo, useRef } from 'react';
import { sendAct, sendMessage } from 'tgui/backend';
import { Button, Flex, Section } from 'tgui/components';

import { useEmotes } from './hooks';

const emoteColors = { 1: 'blue', 2: 'purple', 3: 'orange' };

export const EmotePanel = () => {
  const { list, order, revision, slot } = useEmotes();
  const activeDrag = useRef(null);
  const skipClick = useRef(null);
  const names = useMemo(() => {
    const available = new Set(Object.keys(list || {})
      .filter(name => Object.hasOwn(emoteColors, list[name]?.type)));
    const ordered = (Array.isArray(order) ? order : []).filter(name => available.delete(name));
    return ordered.concat([...available].sort((a, b) => a.localeCompare(b, 'en')));
  }, [list, order]);

  const finishDrag = useCallback(() => {
    const drag = activeDrag.current;
    if (!drag) return;
    activeDrag.current = null;
    if (drag.target) drag.target.classList.remove(drag.marker);
    if (drag.started) {
      skipClick.current = drag.button.dataset.emote;
      drag.button.classList.remove('ChatEmoteDragging');
    }
    if (drag.button.hasPointerCapture(drag.pointerId)) {
      drag.button.releasePointerCapture(drag.pointerId);
    }
  }, []);

  useEffect(() => {
    window.addEventListener('blur', finishDrag);
    return () => {
      window.removeEventListener('blur', finishDrag);
      finishDrag();
    };
  }, [finishDrag]);

  useEffect(() => {
    finishDrag();
  }, [finishDrag, revision]);

  const startDrag = event => {
    const button = event.target.closest('.ChatEmoteButton');
    if (event.button !== 0 || activeDrag.current || !button?.setPointerCapture) return;
    skipClick.current = null;
    button.setPointerCapture(event.pointerId);
    activeDrag.current = {
      button,
      list: event.currentTarget,
      pointerId: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      revision,
      started: false,
      target: null,
      marker: '',
    };
  };

  const updateDrag = event => {
    const drag = activeDrag.current;
    if (!drag || drag.pointerId !== event.pointerId) return;
    const { clientX, clientY } = event;
    if (!drag.started) {
      const dx = clientX - drag.x;
      const dy = clientY - drag.y;
      if (dx * dx + dy * dy < 25) return;
      drag.started = true;
      drag.button.classList.add('ChatEmoteDragging');
    }
    // Координаты указателя и границы кнопок уже учитывают масштаб окна.
    const hit = document.elementFromPoint(clientX, clientY)?.closest('.ChatEmoteButton');
    const target = hit !== drag.button && drag.list.contains(hit) ? hit : null;
    let marker = '';
    if (target) {
      const rect = target.getBoundingClientRect();
      marker = clientX < (rect.left + rect.right) / 2 ? 'ChatEmoteBefore' : 'ChatEmoteAfter';
    }
    if (drag.target !== target || drag.marker !== marker) {
      if (drag.target) drag.target.classList.remove(drag.marker);
      drag.target = target;
      drag.marker = marker;
      if (target) target.classList.add(marker);
    }
    return drag;
  };

  const drop = event => {
    const drag = activeDrag.current;
    if (!drag || drag.pointerId !== event.pointerId) return;
    updateDrag(event);
    finishDrag();
    if (!drag.target || drag.revision !== revision || slot == null) return;
    const from = names.indexOf(drag.button.dataset.emote);
    let to = names.indexOf(drag.target.dataset.emote);
    if (from < 0 || to < 0) return;
    if (drag.marker === 'ChatEmoteAfter') to++;
    if (from < to) to--;
    if (from === to) return;
    const newOrder = [...names];
    const [moved] = newOrder.splice(from, 1);
    newOrder.splice(to, 0, moved);
    sendAct('emotes/setOrder', { order: newOrder, slot, revision });
  };

  const cancelDrag = event => {
    if (activeDrag.current?.pointerId === event.pointerId) finishDrag();
  };

  return (
    <Section>
      <Flex
        align="center"
        wrap
        onPointerDown={startDrag}
        onPointerMove={updateDrag}
        onPointerUp={drop}
        onPointerCancel={cancelDrag}
        onLostPointerCapture={cancelDrag}>
        {names.map(name => {
          const { type, key, message_override, message } = list[name];
          const tooltip = type === 3 ? `"${message}"`
            : type === 2 ? `*${key} | "${message_override}"` : `*${key}`;
          return (
            <Flex.Item mx={0.5} mt={1} key={name}>
              <Button
                className="ChatEmoteButton"
                data-emote={name}
                content={name}
                onClick={event => {
                  if (event.detail && skipClick.current === name) {
                    skipClick.current = null;
                    return;
                  }
                  sendMessage({ type: 'emotes/execute', payload: { name } });
                }}
                onContextMenu={event => {
                  event.preventDefault();
                  if (!activeDrag.current?.started) {
                    sendMessage({ type: 'emotes/contextAction', payload: { name } });
                  }
                }}
                tooltip={tooltip}
                color={emoteColors[type]}
              />
            </Flex.Item>
          );
        })}
        <Flex.Item mx={0.5} mt={1}>
          <Button
            icon="plus"
            color="green"
            onClick={() => sendMessage({ type: 'emotes/create' })}
          />
        </Flex.Item>
      </Flex>
    </Section>
  );
};
