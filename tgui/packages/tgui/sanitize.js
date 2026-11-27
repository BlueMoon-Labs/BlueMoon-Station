/**
 * Uses DOMPurify to purify/sanitise HTML.
 */

import DOMPurify from 'dompurify';

// Default tags available to all players
const defTag = [
  'b',
  'blockquote',
  'br',
  'center',
  'code',
  'dd',
  'del',
  'div',
  'dl',
  'dt',
  'em',
  'font',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'hr',
  'i',
  'ins',
  'li',
  'menu',
  'ol',
  'p',
  'pre',
  'span',
  'strong',
  'table',
  'tbody',
  'td',
  'th',
  'thead',
  'tfoot',
  'tr',
  'u',
  'ul',
];

// Advanced HTML tags that we can trust admins (but not players) with.
// Now includes video embedding tags.
const advTag = ['img', 'video', 'source', 'track'];

// Attributes that are explicitly forbidden (removed even if tag is allowed)
const defAttr = ['class', 'style'];

const paperAttrs = [
  'align', 'bgcolor', 'border', 'cellpadding', 'cellspacing', 'color',
  'colspan', 'face', 'height', 'rowspan', 'size', 'valign', 'width',
];
const paperMediaAttrs = [
  'alt', 'controls', 'kind', 'label', 'loop', 'muted', 'poster',
  'src', 'srclang', 'style', 'title', 'type',
];
const paperStyles = [
  'background-color', 'border', 'border-collapse', 'border-radius', 'color',
  'display', 'font-family', 'font-size', 'font-style', 'font-weight',
  'height', 'line-height', 'margin', 'max-height', 'max-width', 'padding',
  'text-align', 'text-decoration', 'vertical-align', 'white-space', 'width',
];

// Возвращает проверенные узлы для бумаги, факсов и книг.
export const sanitizePaperMarkup = (input, advanced = false) => {
  if (!DOMPurify.isSupported) {
    const text = document.createDocumentFragment();
    text.append(input);
    return text;
  }
  const fragment = DOMPurify.sanitize(input, {
    ALLOWED_TAGS: advanced ? defTag.concat(advTag) : defTag,
    ALLOWED_ATTR: advanced ? paperAttrs.concat(paperMediaAttrs) : paperAttrs,
    ALLOW_ARIA_ATTR: false,
    ALLOW_DATA_ATTR: false,
    RETURN_DOM_FRAGMENT: true,
  });

  if (advanced) {
    for (const element of fragment.querySelectorAll('[style], [src], [poster]')) {
      if (element.hasAttribute('style')) {
        const values = paperStyles.map((property) => [
          property, element.style.getPropertyValue(property),
        ]);
        element.removeAttribute('style');
        for (const [property, value] of values) {
          if (value) {
            element.style.setProperty(property, value);
          }
        }
      }
      for (const attr of ['src', 'poster']) {
        const url = element.getAttribute(attr);
        if (url !== null && !/^https?:\/\//i.test(url)) {
          element.removeAttribute(attr);
        }
      }
    }
  }
  return fragment;
};

/**
 * Feed it a string and it should spit out a sanitized version.
 *
 * @param {string} input
 * @param {boolean} advHtml
 * @param {array} tags
 * @param {array} forbidAttr
 * @param {array} advTags
 */
export const sanitizeText = (
  input,
  advHtml,
  tags = defTag,
  forbidAttr = defAttr,
  advTags = advTag
) => {
  // This is VERY important to think first if you NEED
  // the tag you put in here.  We are pushing all this
  // though dangerouslySetInnerHTML and even though
  // the default DOMPurify kills javascript, it dosn't
  // kill href links or such
  if (advHtml) {
    tags = tags.concat(advTags);
    forbidAttr = [];
  }

  return DOMPurify.sanitize(input, {
    ALLOWED_TAGS: tags,
    FORBID_ATTR: forbidAttr,
  });
};
