export type ActionFeedbackState = Readonly<{
  nonce: string;
  action: string;
  label: string;
  phase: 'sent' | 'received' | 'delayed';
  payload: Readonly<{ address?: string }>;
}>;

export const ACTION_FEEDBACK_TIMING = Object.freeze({ duplicate: 50, response: 5000, receipt: 1500 });
let sessionSequence = 0;

/** One UI owns one bounded, correlated receipt. It never infers gameplay success,
 * retries a command or exposes private command arguments in the public snapshot.
 */
export class NetrunActionFeedback {
  private readonly session = `${Date.now().toString(36)}-${++sessionSequence}`;
  private sequence = 0;
  private state: ActionFeedbackState | null = null;
  private listeners = new Set<() => void>();
  private timer: ReturnType<typeof setTimeout> | null = null;
  private lastKey = '';
  private lastSent = -Infinity;

  snapshot = () => this.state;
  subscribe = (listener: () => void) => { this.listeners.add(listener); return () => { this.listeners.delete(listener); }; };

  begin(action: string, payload: object, label: string): string {
    const key = action + JSON.stringify(payload);
    // Keep the same transport nonce for WebView's duplicate click. A fresh nonce
    // here would bypass sendAct's existing 50 ms identical-message guard.
    if (this.state && key === this.lastKey && Date.now() - this.lastSent < ACTION_FEEDBACK_TIMING.duplicate) {
      return this.state.nonce;
    }
    this.lastKey = key; this.lastSent = Date.now();
    const address = (payload as { address?: unknown }).address;
    const nonce = `${this.session}-${++this.sequence}`;
    this.replace({ nonce, action, label, phase: 'sent', payload: typeof address === 'string' ? { address } : {} });
    this.schedule(() => {
      if (this.state?.nonce === nonce && this.state.phase === 'sent') {
        this.replace({ ...this.state, phase: 'delayed' });
      }
    }, ACTION_FEEDBACK_TIMING.response);
    return nonce;
  }

  acknowledge(nonce: string | undefined | null) {
    if (!nonce || this.state?.nonce !== nonce || this.state.phase === 'received') { return; }
    this.replace({ ...this.state, phase: 'received' });
    this.schedule(() => this.replace(null), ACTION_FEEDBACK_TIMING.receipt);
  }

  dispose() { this.clearTimer(); this.state = null; this.lastKey = ''; this.listeners.clear(); }

  private replace(state: ActionFeedbackState | null) {
    this.clearTimer(); this.state = state;
    for (const listener of this.listeners) { listener(); }
  }
  private clearTimer() { if (this.timer !== null) { clearTimeout(this.timer); this.timer = null; } }
  private schedule(callback: () => void, delay: number) {
    this.clearTimer();
    this.timer = setTimeout(() => { this.timer = null; callback(); }, delay);
  }
}
