export class SFXEngine {
  private ac: AudioContext | null = null;
  public soundEnabled = true;
  public hapticsEnabled = true;

  private tone(
    notes: Array<[number, number, number]>,
    opt?: { type?: OscillatorType; vol?: number }
  ): void {
    if (!this.soundEnabled) return;
    const o = Object.assign({ type: 'sine' as OscillatorType, vol: 0.2 }, opt);
    try {
      const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioCtx) return;
      this.ac = this.ac || new AudioCtx();
      if (this.ac.state === 'suspended') {
        this.ac.resume();
      }
      const t0 = this.ac.currentTime;
      notes.forEach(([f, d, at]) => {
        if (!this.ac) return;
        const osc = this.ac.createOscillator();
        const g = this.ac.createGain();
        osc.type = o.type;
        osc.frequency.setValueAtTime(f, t0 + at);
        g.gain.setValueAtTime(0.0001, t0 + at);
        g.gain.exponentialRampToValueAtTime(o.vol, t0 + at + 0.012);
        g.gain.exponentialRampToValueAtTime(0.0001, t0 + at + d);
        osc.connect(g);
        g.connect(this.ac.destination);
        osc.start(t0 + at);
        osc.stop(t0 + at + d + 0.03);
      });
    } catch {
      // audio unsupported or blocked
    }
  }

  public pick(): void {
    this.tone([[680, 0.07, 0]]);
  }

  public drop(): void {
    this.tone([
      [430, 0.06, 0],
      [760, 0.09, 0.05],
    ]);
  }

  public ok(): void {
    this.tone(
      [
        [523, 0.12, 0],
        [659, 0.12, 0.09],
        [784, 0.12, 0.18],
        [1046, 0.28, 0.27],
      ],
      { type: 'triangle', vol: 0.24 }
    );
  }

  public bad(): void {
    this.tone(
      [
        [210, 0.18, 0],
        [150, 0.24, 0.13],
      ],
      { type: 'sawtooth', vol: 0.13 }
    );
  }

  public star(i: number): void {
    this.tone(
      [
        [784 + i * 220, 0.3, 0],
        [1175 + i * 220, 0.25, 0.08],
      ],
      { type: 'triangle', vol: 0.22 }
    );
  }

  public win(): void {
    this.tone(
      [
        [523, 0.14, 0],
        [659, 0.14, 0.12],
        [784, 0.14, 0.24],
        [1046, 0.14, 0.36],
        [1318, 0.4, 0.48],
      ],
      { type: 'triangle', vol: 0.24 }
    );
  }

  public haptic(pattern: number | number[]): void {
    if (this.hapticsEnabled && typeof navigator !== 'undefined' && navigator.vibrate) {
      try {
        navigator.vibrate(pattern);
      } catch {
        // noop
      }
    }
  }
}

export const SFX = new SFXEngine();
