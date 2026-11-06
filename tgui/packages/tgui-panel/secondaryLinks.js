/**
 * Backend-provided right-click actions for chat links.
 * data-secondary-href accepts only a local Topic query (?src=...;action=...).
 * The receiving Topic must validate permissions and the current object state.
 */
export const captureSecondaryLinks = () => {
  document.addEventListener('contextmenu', event => {
    let target = event.target;
    while (target && target !== document.body) {
      if (String(target.tagName).toLowerCase() !== 'a') {
        target = target.parentElement;
        continue;
      }

      // Our chat convention: href is left-click, data-secondary-href is right-click.
      const href = target.getAttribute('data-secondary-href') || '';
      // Never navigate to an external URL or execute a script from this attribute.
      if (href.charAt(0) !== '?' || href.includes('#')) {
        return;
      }
      const params = Object.create(null);
      try {
        // DM links use ';', ordinary query strings use '&'. Accept both.
        for (const pair of href.slice(1).split(/[;&]/)) {
          if (!pair) {
            continue;
          }
          // Split at the first '=' so values can contain the rest.
          const separator = pair.indexOf('=');
          if (separator <= 0) {
            return;
          }
          const key = decodeURIComponent(pair.slice(0, separator).replace(/\+/g, ' '));
          const value = decodeURIComponent(pair.slice(separator + 1).replace(/\+/g, ' '));
          params[key] = value;
        }
      } catch {
        // Malformed escaping: retain the ordinary context menu.
        return;
      }
      if (!params.src) {
        return;
      }
      event.preventDefault();
      Byond.topic(params);
      return;
    }
  });
};
