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

// Additional attributes that should be allowed for all tags when advHtml = true
// (DOMPurify already allows safe attributes like 'src', 'width', etc., but we
// explicitly list them to be safe and ensure video attributes pass through).
const allowedAttributes = [
  'href',
  'src',
  'width',
  'height',
  'controls',
  'autoplay',
  'loop',
  'muted',
  'preload',
  'type',
  'class',
  'style',
  'alt',
  'title',
];

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
  }

  // Configure DOMPurify with allowed tags, forbidden attributes,
  // and an explicit list of allowed attributes to support video embedding.
  return DOMPurify.sanitize(input, {
    ALLOWED_TAGS: tags,
    FORBID_ATTR: forbidAttr,
    ALLOWED_ATTR: allowedAttributes,
    // Keep data: URIs disabled (default) for security.
    // If you need data: images, you may add 'img' to ALLOWED_URI_REGEXP.
  });
};
