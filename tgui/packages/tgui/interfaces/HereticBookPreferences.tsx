import { storage } from 'common/storage';
import { useEffect, useRef, useState } from 'react';

import { BookPresentation } from './HereticBookAtmosphere';

const readingModes: { value: BookPresentation; name: string; description: string }[] = [
  { value: 'living', name: 'Живая книга', description: 'Фактура страниц, анимации и подвижная застёжка.' },
  { value: 'muted', name: 'Приглушённый', description: 'Приглушённые цвета, без постоянных анимаций.' },
  { value: 'plain', name: 'Простой', description: 'Светлые страницы без фактуры и анимаций.' },
];

const storageQueues = new Map<string, Promise<unknown>>();

// Чтение может переносить старую настройку в hubStorage; запись должна дождаться этого переноса.
function queueStorage<T>(key: string, operation: () => Promise<T>): Promise<T> {
  const pending = (storageQueues.get(key) || Promise.resolve()).catch(() => {}).then(operation);
  storageQueues.set(key, pending);
  pending.finally(() => {
    if (storageQueues.get(key) === pending) storageQueues.delete(key);
  }).catch(() => {});
  return pending;
}

export const useBookPresentation = (reader: string = 'local') => {
  const key = `heretic-book-view-v1:${reader || 'local'}`;
  const [presentation, setPresentation] = useState<BookPresentation>('living');
  const [ready, setReady] = useState(false);
  const revision = useRef(0);
  const [reducedMotion, setReducedMotion] = useState(() => (
    typeof window.matchMedia === 'function' && window.matchMedia('(prefers-reduced-motion: reduce)').matches
  ));

  useEffect(() => {
    let mounted = true;
    const loadingRevision = revision.current;
    setReady(false);
    setPresentation('living');
    queueStorage(key, () => storage.get(key)).then((saved: unknown) => {
      if (!mounted || revision.current !== loadingRevision) return;
      if (readingModes.some((mode) => mode.value === saved)) setPresentation(saved as BookPresentation);
    }).catch(() => {}).finally(() => {
      if (mounted) setReady(true);
    });
    return () => { mounted = false; };
  }, [key]);

  useEffect(() => {
    if (typeof window.matchMedia !== 'function') return;
    const preference = window.matchMedia('(prefers-reduced-motion: reduce)');
    const changed = () => setReducedMotion(preference.matches);
    changed();
    if (preference.addEventListener) {
      preference.addEventListener('change', changed);
      return () => preference.removeEventListener('change', changed);
    }
    preference.addListener(changed);
    return () => preference.removeListener(changed);
  }, []);

  const choose = (mode: BookPresentation) => {
    if (!readingModes.some((entry) => entry.value === mode)) return;
    revision.current++;
    setPresentation(mode);
    setReady(true);
    queueStorage(key, () => storage.set(key, mode)).catch(() => {});
  };

  return { presentation, effectivePresentation: ready ? presentation : 'muted' as BookPresentation, reducedMotion, choose };
};

export const HereticBookPreferences = ({ presentation, reducedMotion, onChange }: {
  presentation: BookPresentation;
  reducedMotion: boolean;
  onChange: (mode: BookPresentation) => void;
}) => {
  const panel = useRef<HTMLDetailsElement>(null);
  const toggle = useRef<HTMLElement>(null);
  return (
    <details className="HereticBook__readingOptions" ref={panel} onKeyDown={(event) => {
      if (event.key === 'Escape' && panel.current) {
        panel.current.open = false;
        toggle.current?.focus();
        event.stopPropagation();
      }
    }}>
      <summary ref={toggle} aria-label="Настроить вид книги">Вид книги</summary>
      <div className="HereticBook__readingPanel">
        <fieldset>
          <legend>Оформление книги</legend>
          {readingModes.map((mode) => (
            <label key={mode.value}>
              <input type="radio" name="heretic-book-view" value={mode.value} checked={presentation === mode.value} onChange={() => onChange(mode.value)} />
              <span><strong>{mode.name}</strong><small>{mode.description}</small></span>
            </label>
          ))}
        </fieldset>
        <p>Выбор сохранится для ваших книг на этом устройстве.</p>
        {reducedMotion && <p role="status">Движение отключено системной настройкой.</p>}
      </div>
    </details>
  );
};
