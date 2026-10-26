export type ProcedureFSMState =
  | 'IDLE'
  | 'READING'
  | 'INTERACTING'
  | 'EVALUATING'
  | 'STEP_PASSED'
  | 'STEP_FAILED'
  | 'CASE_COMPLETED';

export class ProcedureStateMachine {
  private currentState: ProcedureFSMState = 'IDLE';

  public getState(): ProcedureFSMState {
    return this.currentState;
  }

  public transitionTo(nextState: ProcedureFSMState): boolean {
    this.currentState = nextState;
    return true;
  }

  public canCheck(): boolean {
    return (
      this.currentState === 'READING' ||
      this.currentState === 'INTERACTING' ||
      this.currentState === 'STEP_FAILED'
    );
  }

  public resetForStep(isAlreadyPassed: boolean): void {
    this.currentState = isAlreadyPassed ? 'STEP_PASSED' : 'INTERACTING';
  }
}

export const procedureFSM = new ProcedureStateMachine();
