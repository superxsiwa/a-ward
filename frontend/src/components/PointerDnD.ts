import React, { useEffect } from 'react';
import { StepRuntimeState } from '../types/game';
import { moveItemInState } from '../pages/GamePage';
import { SFX } from '../engine/SFXEngine';

export function usePointerDnD(
  viewportRef: React.RefObject<HTMLElement | null>,
  stateRef: React.MutableRefObject<StepRuntimeState>,
  stepIdx: number,
  bedNum: number,
  onUpdateStepState: (updater: (prev: StepRuntimeState) => StepRuntimeState) => void,
  onTapChip: (id: string) => void
): void {
  useEffect(() => {
    const viewEl = viewportRef.current;
    if (!viewEl) return;

    let dnd: any = null;

    const insertIndex = (zone: HTMLElement, y: number, id: string) => {
      const chips = Array.from(zone.querySelectorAll<HTMLElement>('[data-chip]')).filter(
        (c) => c.dataset.chip !== id
      );
      for (let i = 0; i < chips.length; i++) {
        const r = chips[i].getBoundingClientRect();
        if (y < r.top + r.height / 2) return i;
      }
      return chips.length;
    };

    const moveGhost = () => {
      if (!dnd || !dnd.ghost) return;
      dnd.ghost.style.setProperty('--x', `${dnd.x - dnd.ox}px`);
      dnd.ghost.style.setProperty('--y', `${dnd.y - dnd.oy}px`);
    };

    const setHover = (node: HTMLElement | null) => {
      if (!dnd || dnd.hover === node) return;
      if (dnd.hover) dnd.hover.classList.remove('dz-hover');
      if (node) node.classList.add('dz-hover');
      dnd.hover = node;
    };

    const autoScroll = () => {
      if (!dnd || !dnd.active || !viewportRef.current) return;
      const r = viewportRef.current.getBoundingClientRect();
      let dy = 0;
      if (dnd.y < r.top + 70) dy = -Math.min(16, (r.top + 70 - dnd.y) / 4);
      else if (dnd.y > r.bottom - 70) dy = Math.min(16, (dnd.y - (r.bottom - 70)) / 4);
      if (dy) viewportRef.current.scrollTop += dy;
      dnd.raf = requestAnimationFrame(autoScroll);
    };

    const beginDrag = () => {
      if (!dnd || dnd.active) return;
      dnd.active = true;
      clearTimeout(dnd.timer);
      const g = dnd.chip.cloneNode(true) as HTMLElement;
      g.classList.add('drag-ghost');
      g.classList.remove('is-picked', 'is-wrong');
      g.removeAttribute('data-chip');
      g.style.width = `${dnd.w}px`;
      document.body.appendChild(g);
      dnd.ghost = g;
      dnd.chip.classList.add('is-origin');
      moveGhost();
      SFX.pick();
      SFX.haptic(8);
      dnd.raf = requestAnimationFrame(autoScroll);
    };

    const endDnd = () => {
      if (!dnd) return;
      clearTimeout(dnd.timer);
      cancelAnimationFrame(dnd.raf);
      if (dnd.ghost) dnd.ghost.remove();
      if (dnd.hover) dnd.hover.classList.remove('dz-hover');
      if (dnd.chip) dnd.chip.classList.remove('is-origin');
      dnd = null;
      window.removeEventListener('pointermove', onPointerMove);
      window.removeEventListener('pointerup', onPointerUp);
      window.removeEventListener('pointercancel', onPointerCancel);
    };

    const onPointerMove = (e: PointerEvent) => {
      if (!dnd || e.pointerId !== dnd.pid) return;
      dnd.x = e.clientX;
      dnd.y = e.clientY;
      const dist = Math.hypot(dnd.x - dnd.x0, dnd.y - dnd.y0);
      if (!dnd.active) {
        if ((dnd.type === 'mouse' && dist > 3) || (dnd.type !== 'mouse' && dist > 8)) {
          beginDrag();
        }
        if (!dnd || !dnd.active) return;
      }
      if (e.cancelable) e.preventDefault();
      moveGhost();
      const t = document.elementFromPoint(dnd.x, dnd.y);
      setHover(t ? (t.closest('#task [data-drop]') as HTMLElement | null) : null);
    };

    const onPointerUp = (e: PointerEvent) => {
      if (!dnd || e.pointerId !== dnd.pid) return;
      const { active, x, y, id } = dnd;
      if (active) {
        const t = document.elementFromPoint(x, y);
        const zone = t ? (t.closest('#task [data-drop]') as HTMLElement | null) : null;
        endDnd();
        if (zone && zone.dataset.drop) {
          const dest = zone.dataset.drop;
          const idx = dest.startsWith('tray:') ? insertIndex(zone, y, id) : null;
          SFX.drop();
          SFX.haptic(10);
          onUpdateStepState((prev) => moveItemInState(prev, id, dest, idx));
        }
      } else {
        endDnd();
        onTapChip(id);
      }
    };

    const onPointerCancel = (e: PointerEvent) => {
      if (dnd && e.pointerId === dnd.pid) endDnd();
    };

    const onPointerDown = (e: PointerEvent) => {
      const chip = (e.target as HTMLElement).closest('[data-chip]') as HTMLElement | null;
      if (!chip || !chip.dataset.chip || stateRef.current.locked) return;
      if (e.pointerType === 'mouse' && e.button !== 0) return;
      const r = chip.getBoundingClientRect();
      dnd = {
        id: chip.dataset.chip,
        chip,
        pid: e.pointerId,
        type: e.pointerType,
        x0: e.clientX,
        y0: e.clientY,
        x: e.clientX,
        y: e.clientY,
        ox: e.clientX - r.left,
        oy: e.clientY - r.top,
        w: r.width,
        active: false,
        timer: e.pointerType !== 'mouse' ? setTimeout(beginDrag, 120) : null,
        hover: null,
        ghost: null,
        raf: 0,
      };
      window.addEventListener('pointermove', onPointerMove, { passive: false });
      window.addEventListener('pointerup', onPointerUp);
      window.addEventListener('pointercancel', onPointerCancel);
    };

    const onTouchMove = (e: TouchEvent) => {
      if (dnd && dnd.active && e.cancelable) e.preventDefault();
    };
    const onContextMenu = (e: MouseEvent) => {
      if ((e.target as HTMLElement)?.closest('[data-chip]')) e.preventDefault();
    };

    viewEl.addEventListener('pointerdown', onPointerDown);
    viewEl.addEventListener('contextmenu', onContextMenu);
    window.addEventListener('touchmove', onTouchMove, { passive: false });

    return () => {
      endDnd();
      viewEl.removeEventListener('pointerdown', onPointerDown);
      viewEl.removeEventListener('contextmenu', onContextMenu);
      window.removeEventListener('touchmove', onTouchMove);
    };
  }, [viewportRef, stepIdx, bedNum]);
}
