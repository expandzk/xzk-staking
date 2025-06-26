import { XZKStakingErrorCode, XZKStakingError } from './error';

// Re-export types from api to maintain backward compatibility
export type {
  TokenName,
  StakingPeriod,
  InitOptions,
  ClientOptions,
  StakingSummary,
  StakingRecord,
  UnstakingSummary,
  UnstakingRecord,
  IStakingClient,
} from './api';

export { XZKStakingErrorCode, XZKStakingError };
export { default as stakingApiClient } from './api';
