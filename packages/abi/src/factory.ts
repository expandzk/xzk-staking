import { providers, Signer } from 'ethers';
import {
  AccessControl,
  AccessControl__factory,
  MystikoStaking,
  MystikoStaking__factory,
} from './typechain/staking-rewards';

export type SupportedContractType = AccessControl | MystikoStaking;

export class MystikoStakingContractFactory {
  public static connect<T extends SupportedContractType>(
    contractName: string,
    address: string,
    signerOrProvider: Signer | providers.Provider,
  ): T {
    if (contractName === 'AccessControl') {
      return AccessControl__factory.connect(address, signerOrProvider) as T;
    }
    if (contractName === 'MystikoStaking') {
      return MystikoStaking__factory.connect(address, signerOrProvider) as T;
    }
    throw new Error(`unsupported contract name ${contractName}`);
  }
}
