type EventCallback<T = any> = (payload: T) => void;

export class GameEventBus {
  private listeners: Map<string, Set<EventCallback>> = new Map();

  public subscribe<T = any>(event: string, callback: EventCallback<T>): () => void {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, new Set());
    }
    this.listeners.get(event)!.add(callback);
    return () => {
      this.listeners.get(event)?.delete(callback);
    };
  }

  public emit<T = any>(event: string, payload?: T): void {
    const callbacks = this.listeners.get(event);
    if (!callbacks) return;
    callbacks.forEach((cb) => {
      try {
        cb(payload);
      } catch (err) {
        console.error(`[GameEventBus] Error in listener for ${event}:`, err);
      }
    });
  }
}

export const gameEventBus = new GameEventBus();
