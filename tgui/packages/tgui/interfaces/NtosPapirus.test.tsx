/**
 * BLUEMOON ADD - тесты Папируса: перевод текста в лист и обратно, синхронизация и печать.
 */
import { act as reactAct, fireEvent, render, screen } from '@testing-library/react';
import { combineReducers, createStore, setGlobalStore } from 'common/redux';

import { backendReducer, backendUpdate } from '../backend';
import { debugReducer } from '../debug';
import { htmlToText, NtosPapirus, textToHtml } from './NtosPapirus';

const baseData = {
  doc: {
    title: 'Рапорт',
    blocks: [
      { id: 1, type: 'h1', align: 'center', text: 'РАПОРТ' },
      { id: 2, type: 'p', align: 'left', text: 'Докладываю, что **важно** {поле}' },
      { id: 3, type: 'hr', align: 'left', text: '' },
    ],
  },
  revision: 1,
  autofill: true,
  code: '',
  max_length: 5000,
  max_block_text: 2000,
  max_blocks: 60,
  has_printer: true,
  paper: 10,
  max_paper: 30,
  id_name: 'Иван Иванов',
  id_job: 'Капитан',
  builtin_templates: [{ id: 'report', name: 'Рапорт' }],
  user_templates: [],
};

let topic: jest.Mock;

const setupStore = (data = {}) => {
  topic = jest.fn();
  (global as any).Byond = { winset: () => {}, topic };
  const store = createStore(combineReducers({ backend: backendReducer, debug: debugReducer }));
  setGlobalStore(store);
  store.dispatch(
    backendUpdate({
      config: { interface: 'NtosPapirus' },
      data: { ...baseData, ...data },
    }),
  );
  return store;
};

const actCalls = (topic: jest.Mock, action: string) =>
  topic.mock.calls
    .filter((c) => c[0]?.type === `act/${action}`)
    .map((c) => JSON.parse(c[0].payload));

describe('Папирус: перевод текста', () => {
  test.each([
    'Простой текст',
    'Докладываю, что **важно** и *срочно*',
    'Подпись: {подпись}, дата: {дата}',
    'Первая строка\nВторая строка',
    'Пустая строка между\n\nабзацами',
    'Подчёркнутый <u>текст</u> и поле [______]',
  ])('текст переживает дорогу на лист и обратно: %s', (text) => {
    expect(htmlToText(textToHtml(text))).toBe(text);
  });

  test('токены становятся нередактируемыми полями', () => {
    const html = textToHtml('Подпись: {подпись}');
    expect(html).toContain('data-token="подпись"');
    expect(html).toContain('contenteditable="false"');
  });

  test('HTML из текста экранируется', () => {
    expect(textToHtml('<script>x</script>')).not.toContain('<script>');
  });

  test('жирный с пробелами по краям не ломает Markdown', () => {
    expect(htmlToText('<div>а<b> жирный </b>б</div>')).toBe('а **жирный** б');
  });
});

describe('Папирус: интерфейс', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => jest.useRealTimers());

  test('лист показывает блоки сразу оформленными', () => {
    setupStore();
    const { container } = render(<NtosPapirus />);
    const editors = container.querySelectorAll('[data-papirus-ed]');
    expect(editors).toHaveLength(2);
    expect(editors[0].className).toContain('Papirus__ed--h1');
    expect(editors[1].querySelector('b')?.textContent).toBe('важно');
    // Поле подписано тем, что в него впишут при печати - здесь пустое поле
    expect(editors[1].querySelector('[data-token="поле"]')).toBeTruthy();
    expect(container.querySelector('.Papirus__hr')).toBeTruthy();
  });

  test('набранный текст уходит на сервер после паузы', () => {
    setupStore();
    const { container } = render(<NtosPapirus />);
    const editor = container.querySelectorAll('[data-papirus-ed]')[1] as HTMLElement;
    editor.innerHTML = '<div>Новый <b>текст</b> {x}</div>';
    fireEvent.input(editor);
    expect(actCalls(topic, 'sync')).toHaveLength(0);
    reactAct(() => {
      jest.advanceTimersByTime(1000);
    });
    const syncs = actCalls(topic, 'sync');
    expect(syncs).toHaveLength(1);
    const doc = JSON.parse(syncs[0].doc);
    expect(doc.blocks[1].text).toBe('Новый **текст** {x}');
    expect(doc.blocks[0].text).toBe('РАПОРТ');
  });

  test('печать сразу несёт свежий документ', () => {
    setupStore();
    const { container } = render(<NtosPapirus />);
    const editor = container.querySelectorAll('[data-papirus-ed]')[0] as HTMLElement;
    editor.innerHTML = 'ПРИКАЗ';
    fireEvent.input(editor);
    fireEvent.click(screen.getByText('Печать'));
    const prints = actCalls(topic, 'print');
    expect(prints).toHaveLength(1);
    expect(JSON.parse(prints[0].doc).blocks[0].text).toBe('ПРИКАЗ');
    // Отложенная синхронизация отменена: печать её уже отправила
    reactAct(() => {
      jest.advanceTimersByTime(1000);
    });
    expect(actCalls(topic, 'sync')).toHaveLength(0);
  });

  test('отмена возвращает прежний текст', () => {
    setupStore();
    const { container } = render(<NtosPapirus />);
    let editor = container.querySelectorAll('[data-papirus-ed]')[0] as HTMLElement;
    editor.innerHTML = 'Изменено';
    fireEvent.input(editor);
    editor = container.querySelectorAll('[data-papirus-ed]')[0] as HTMLElement;
    fireEvent.keyDown(editor, { key: 'z', code: 'KeyZ', ctrlKey: true });
    editor = container.querySelectorAll('[data-papirus-ed]')[0] as HTMLElement;
    expect(htmlToText(editor.innerHTML)).toBe('РАПОРТ');
  });

  test('Ctrl+Enter добавляет абзац после блока', () => {
    setupStore();
    const { container } = render(<NtosPapirus />);
    const editor = container.querySelectorAll('[data-papirus-ed]')[0] as HTMLElement;
    fireEvent.keyDown(editor, { key: 'Enter', code: 'Enter', ctrlKey: true });
    const editors = container.querySelectorAll('[data-papirus-ed]');
    expect(editors).toHaveLength(3);
    expect(editors[1].className).toContain('Papirus__ed--p');
  });

  test('новая ревизия с сервера заменяет документ', () => {
    const store = setupStore();
    const { container, rerender } = render(<NtosPapirus />);
    reactAct(() => {
      store.dispatch(
        backendUpdate({
          data: {
            ...baseData,
            revision: 2,
            doc: { title: 'Пропуск', blocks: [{ id: 7, type: 'p', align: 'left', text: 'Выдан: {поле}' }] },
          },
        }),
      );
    });
    rerender(<NtosPapirus />);
    const editors = container.querySelectorAll('[data-papirus-ed]');
    expect(editors).toHaveLength(1);
    expect(htmlToText(editors[0].innerHTML)).toBe('Выдан: {поле}');
  });
});
