import { providers, Signer } from 'ethers';
import { ERC20, ERC20__factory, XzkStaking, XzkStaking__factory } from './typechain/staking-rewards';

export type SupportedContractType = XzkStaking;

export class MystikoStakingContractFactory {
  public static connect<T extends SupportedContractType>(
    contractName: string,
    address: string,
    signerOrProvider: Signer | providers.Provider,
  ): T {
    if (contractName === 'XzkStaking') {
      return XzkStaking__factory.connect(address, signerOrProvider) as T;
    }
    throw new Error(`unsupported contract name ${contractName}`);
  }
}

export class ERC20ContractFactory {
  public static connect(
    contractName: string,
    address: string,
    signerOrProvider: Signer | providers.Provider,
  ): ERC20 {
    return ERC20__factory.connect(address, signerOrProvider);
  }
}
