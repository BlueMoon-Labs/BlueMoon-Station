import { highlightNode, linkifyNode, replaceInTextNode } from './replaceInTextNode';

// Helper: create a parent div with a text node child
const createTextInDiv = (text) => {
  const div = document.createElement('div');
  div.textContent = text;
  return div;
};

// Helper: create a wrapper node for replacements
const createBoldNode = (text) => {
  const node = document.createElement('b');
  node.textContent = text;
  return node;
};

describe('replaceInTextNode', () => {
  test('replaces matching text with custom nodes', () => {
    const div = createTextInDiv('hello world hello');
    const textNode = div.firstChild;

    const count = replaceInTextNode(/hello/g, createBoldNode)(textNode);

    expect(count).toBe(2);
    // Should have: <b>hello</b> " world " <b>hello</b>
    expect(div.childNodes.length).toBe(3);
    expect(div.childNodes[0].tagName).toBe('B');
    expect(div.childNodes[0].textContent).toBe('hello');
    expect(div.childNodes[1].textContent).toBe(' world ');
    expect(div.childNodes[2].tagName).toBe('B');
    expect(div.childNodes[2].textContent).toBe('hello');
  });

  test('returns count of matches', () => {
    const div = createTextInDiv('aaa');
    const textNode = div.firstChild;

    const count = replaceInTextNode(/a/g, createBoldNode)(textNode);
    expect(count).toBe(3);
  });

  test('returns 0 and does not modify DOM when no match', () => {
    const div = createTextInDiv('goodbye');
    const textNode = div.firstChild;

    const count = replaceInTextNode(/hello/g, createBoldNode)(textNode);
    expect(count).toBe(0);
    expect(div.textContent).toBe('goodbye');
    expect(div.childNodes.length).toBe(1);
  });

  test('handles regex matching at start of text', () => {
    const div = createTextInDiv('hello world');
    const textNode = div.firstChild;

    replaceInTextNode(/^hello/g, createBoldNode)(textNode);

    expect(div.childNodes[0].tagName).toBe('B');
    expect(div.childNodes[0].textContent).toBe('hello');
    expect(div.childNodes[1].textContent).toBe(' world');
  });

  test('handles regex matching at end of text', () => {
    const div = createTextInDiv('world hello');
    const textNode = div.firstChild;

    replaceInTextNode(/hello$/g, createBoldNode)(textNode);

    expect(div.childNodes[0].textContent).toBe('world ');
    expect(div.childNodes[1].tagName).toBe('B');
    expect(div.childNodes[1].textContent).toBe('hello');
  });

  test('handles text that is entirely a match', () => {
    const div = createTextInDiv('hello');
    const textNode = div.firstChild;

    replaceInTextNode(/hello/g, createBoldNode)(textNode);

    expect(div.childNodes.length).toBe(1);
    expect(div.childNodes[0].tagName).toBe('B');
    expect(div.childNodes[0].textContent).toBe('hello');
  });

  test('handles empty text node', () => {
    const div = document.createElement('div');
    const textNode = document.createTextNode('');
    div.appendChild(textNode);

    const count = replaceInTextNode(/anything/g, createBoldNode)(textNode);
    expect(count).toBe(0);
  });

  test('handles multiple consecutive matches', () => {
    const div = createTextInDiv('aaa');
    const textNode = div.firstChild;

    replaceInTextNode(/a/g, createBoldNode)(textNode);

    expect(div.childNodes.length).toBe(3);
    for (let i = 0; i < 3; i++) {
      expect(div.childNodes[i].tagName).toBe('B');
      expect(div.childNodes[i].textContent).toBe('a');
    }
  });

  test('preserves unmatched text between matches as text nodes', () => {
    const div = createTextInDiv('XaYaZ');
    const textNode = div.firstChild;

    replaceInTextNode(/a/g, createBoldNode)(textNode);

    // X <b>a</b> Y <b>a</b> Z
    expect(div.childNodes.length).toBe(5);
    expect(div.childNodes[0].nodeType).toBe(3); // text
    expect(div.childNodes[0].textContent).toBe('X');
    expect(div.childNodes[1].tagName).toBe('B');
    expect(div.childNodes[2].nodeType).toBe(3); // text
    expect(div.childNodes[2].textContent).toBe('Y');
    expect(div.childNodes[3].tagName).toBe('B');
    expect(div.childNodes[4].nodeType).toBe(3); // text
    expect(div.childNodes[4].textContent).toBe('Z');
  });
});

describe('highlightNode', () => {
  test('highlights text in direct text node children', () => {
    const div = createTextInDiv('find me here');
    const count = highlightNode(div, /find/g);

    expect(count).toBe(1);
    // Should have: <span>find</span> " me here"
    expect(div.querySelector('span')).not.toBeNull();
    expect(div.querySelector('span').textContent).toBe('find');
  });

  test('returns total match count across all text nodes', () => {
    const div = document.createElement('div');
    const span1 = document.createElement('span');
    span1.textContent = 'hello world';
    const span2 = document.createElement('span');
    span2.textContent = 'hello again';
    div.appendChild(span1);
    div.appendChild(span2);

    const count = highlightNode(div, /hello/g);
    expect(count).toBe(2);
  });

  test('recursively processes nested elements', () => {
    const div = document.createElement('div');
    div.innerHTML = '<p><span>search term</span></p>';

    const count = highlightNode(div, /search/g);
    expect(count).toBe(1);
    const highlighted = div.querySelector('p span span');
    expect(highlighted).not.toBeNull();
    expect(highlighted.textContent).toBe('search');
  });

  test('only processes text nodes (nodeType 3)', () => {
    const div = document.createElement('div');
    const child = document.createElement('span');
    child.setAttribute('class', 'find-me');
    child.textContent = 'no match in attributes';
    div.appendChild(child);

    // The regex should not match against element attribute values
    const count = highlightNode(div, /find-me/g);
    expect(count).toBe(0);
  });

  test('uses default highlight style when no createNode provided', () => {
    const div = createTextInDiv('highlight me');
    highlightNode(div, /highlight/g);

    const span = div.querySelector('span');
    expect(span).not.toBeNull();
    expect(span.getAttribute('style')).toContain('background-color');
  });

  test('uses custom createNode when provided', () => {
    const div = createTextInDiv('custom highlight');
    const factory = jest.fn((text) => {
      const em = document.createElement('em');
      em.textContent = text;
      return em;
    });

    highlightNode(div, /custom/g, factory);

    expect(factory).toHaveBeenCalledWith('custom');
    expect(div.querySelector('em')).not.toBeNull();
  });

  test('handles node with no text content', () => {
    const div = document.createElement('div');
    const count = highlightNode(div, /anything/g);
    expect(count).toBe(0);
  });
});

describe('linkifyNode', () => {
  test('converts https URLs to anchor tags', () => {
    const div = createTextInDiv('visit https://example.com today');
    linkifyNode(div);

    const link = div.querySelector('a');
    expect(link).not.toBeNull();
    expect(link.href).toBe('https://example.com/');
    expect(link.textContent).toBe('https://example.com');
  });

  test('converts http URLs to anchor tags', () => {
    const div = createTextInDiv('go to http://example.com now');
    linkifyNode(div);

    const link = div.querySelector('a');
    expect(link).not.toBeNull();
    expect(link.textContent).toContain('http://example.com');
  });

  test('converts www. URLs to anchor tags', () => {
    const div = createTextInDiv('visit www.example.com today');
    linkifyNode(div);

    const link = div.querySelector('a');
    expect(link).not.toBeNull();
    expect(link.textContent).toContain('www.example.com');
  });

  test('does not double-linkify existing anchor tags', () => {
    const div = document.createElement('div');
    div.innerHTML = '<a href="https://example.com">https://example.com</a>';
    const anchorCountBefore = div.querySelectorAll('a').length;

    linkifyNode(div);

    const anchorCountAfter = div.querySelectorAll('a').length;
    expect(anchorCountAfter).toBe(anchorCountBefore);
  });

  test('handles URLs with query strings', () => {
    const div = createTextInDiv('link: https://example.com/path?q=1&r=2');
    linkifyNode(div);

    const link = div.querySelector('a');
    expect(link).not.toBeNull();
    expect(link.textContent).toContain('?q=1&r=2');
  });

  test('handles URLs with parentheses', () => {
    const div = createTextInDiv(
      'see https://en.wikipedia.org/wiki/Test_(computing)',
    );
    linkifyNode(div);

    const link = div.querySelector('a');
    expect(link).not.toBeNull();
    expect(link.textContent).toContain('Test_(computing)');
  });

  test('handles multiple URLs in same text node', () => {
    const div = createTextInDiv(
      'go to https://a.com and https://b.com please',
    );
    linkifyNode(div);

    const links = div.querySelectorAll('a');
    expect(links.length).toBe(2);
  });

  test('does not match plain text without URL patterns', () => {
    const div = createTextInDiv('no urls here at all');
    const count = linkifyNode(div);
    expect(count).toBe(0);
    expect(div.querySelectorAll('a').length).toBe(0);
  });

  test('recursively processes nested elements but skips anchors', () => {
    const div = document.createElement('div');
    div.innerHTML =
      '<a href="#">existing link with https://skip.com</a>' +
      '<span>https://find.me</span>';

    linkifyNode(div);

    const links = div.querySelectorAll('a');
    // Original anchor + new one from span = 2
    expect(links.length).toBe(2);
    // The existing anchor's content should be unchanged
    expect(links[0].textContent).toContain('https://skip.com');
    // The span should have been linkified
    expect(links[1].textContent).toContain('https://find.me');
  });

  test('regex lastIndex resets between calls', () => {
    // Verify that calling linkifyNode on multiple nodes in sequence
    // works correctly — the global regex state doesn't corrupt across calls
    const div1 = createTextInDiv('first https://one.com');
    const div2 = createTextInDiv('second https://two.com');

    linkifyNode(div1);
    linkifyNode(div2);

    expect(div1.querySelector('a').textContent).toContain('https://one.com');
    expect(div2.querySelector('a').textContent).toContain('https://two.com');
  });
});

describe('URL_REGEX edge cases', () => {
  test('does not match bare domain without protocol or www', () => {
    const div = createTextInDiv('just example.com nothing special');
    linkifyNode(div);
    expect(div.querySelectorAll('a').length).toBe(0);
  });

  test('handles URL at end of text', () => {
    const div = createTextInDiv('click https://example.com');
    linkifyNode(div);
    expect(div.querySelector('a')).not.toBeNull();
  });

  test('handles URL with fragment', () => {
    const div = createTextInDiv('see https://example.com/page#section');
    linkifyNode(div);

    const link = div.querySelector('a');
    expect(link).not.toBeNull();
    expect(link.textContent).toContain('#section');
  });

  test('handles URL with port number', () => {
    const div = createTextInDiv('go to https://example.com:8080/api');
    linkifyNode(div);

    const link = div.querySelector('a');
    expect(link).not.toBeNull();
    expect(link.textContent).toContain(':8080');
  });
});
