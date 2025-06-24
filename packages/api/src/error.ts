export enum XZKStakingErrorCode {
  UNKNOWN_ERROR = 0,
  NOT_INITIALIZED_ERROR = 1,
  PARAMETER_ERROR = 2,
  BALANCE_ERROR = 3,
  APPROVE_AMOUNT_ERROR = 4,
}

export class XZKStakingError extends Error {
  public readonly code: XZKStakingErrorCode;

  constructor(message: string, code: XZKStakingErrorCode) {
    super(message);
    this.code = code;
  }
}

export function createError(message: string, code?: XZKStakingErrorCode): XZKStakingError {
  return new XZKStakingError(message, code || XZKStakingErrorCode.UNKNOWN_ERROR);
}

export function createErrorPromise(message: string, code?: XZKStakingErrorCode): Promise<any> {
  return Promise.reject(createError(message, code));
}
