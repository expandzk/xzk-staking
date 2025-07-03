export enum XZKStakingErrorCode {
  UNKNOWN_ERROR = 0,
  PROVIDER_ERROR = 1,
  NOT_INITIALIZED_ERROR = 2,
  PARAMETER_ERROR = 3,
  BALANCE_ERROR = 4,
  APPROVE_AMOUNT_ERROR = 5,
  AMOUNT_NOT_SPECIFIED_ERROR = 6,
  NO_CLAIMABLE_AMOUNT_ERROR = 7,
  INSUFFICIENT_BALANCE_ERROR = 8,
}

export class XZKStakingError extends Error {
  public readonly code: XZKStakingErrorCode;

  constructor(message: string, code: XZKStakingErrorCode) {
    super(message);
    this.code = code;
  }
}

function createError(message: string, code: XZKStakingErrorCode): Promise<any> {
  return Promise.reject(new XZKStakingError(message, code));
}

export function createErrorPromise(code: XZKStakingErrorCode, message?: string): Promise<any> {
  switch (code) {
    case XZKStakingErrorCode.PROVIDER_ERROR: {
      return createError(message || 'Provider error', code);
    }
    case XZKStakingErrorCode.NOT_INITIALIZED_ERROR: {
      return createError(message || 'Not initialized', code);
    }
    case XZKStakingErrorCode.PARAMETER_ERROR: {
      return createError(message || 'Parameter error', code);
    }
    case XZKStakingErrorCode.BALANCE_ERROR: {
      return createError(message || 'Balance error', code);
    }
    case XZKStakingErrorCode.APPROVE_AMOUNT_ERROR: {
      return createError(message || 'Approve amount error', code);
    }
    case XZKStakingErrorCode.AMOUNT_NOT_SPECIFIED_ERROR: {
      return createError(message || 'Amount not specified error', code);
    }
    case XZKStakingErrorCode.NO_CLAIMABLE_AMOUNT_ERROR: {
      return createError(message || 'No claimable amount error', code);
    }
    case XZKStakingErrorCode.INSUFFICIENT_BALANCE_ERROR: {
      return createError(message || 'Insufficient balance error', code);
    }
    default: {
      return createError(message || 'Unknown error', code);
    }
  }
}
