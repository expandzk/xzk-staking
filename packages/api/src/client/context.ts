import { Config } from "../config";
import { providers } from "ethers";
import { DefaultProviderFactory } from "@mystikonetwork/utils";
import { ERC20, ERC20ContractFactory } from '@expandzk/xzk-staking-abi';
import { ClientOptions, InitOptions } from "..";

export class ClientContext {
    public config: Config;

    public xzkContract: ERC20;

    public vXzkContract: ERC20;

    public provider: providers.Provider;

    constructor(options: InitOptions) {
        this.config = new Config(options.chainId || 1);
        const factory = new DefaultProviderFactory();
        this.provider = factory.createProvider(this.config.providers);
        this.xzkContract = ERC20ContractFactory.connect('ERC20', this.config.xzkContract, this.provider);
        this.vXzkContract = ERC20ContractFactory.connect('ERC20', this.config.vXZkContract, this.provider);
    }


    public tokenContractAddress(options: ClientOptions): ERC20 {
        if (options.tokenName === 'XZK') {
            return this.xzkContract;
        }
        return this.vXzkContract;
    }


}