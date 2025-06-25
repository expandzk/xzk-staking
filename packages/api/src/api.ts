import { ClientOptions, InitOptions } from '.';
import { ContractClient } from './client';
import { ClientContext } from './client/context';
import { GlobalClientOptions } from './config/config';
import { createErrorPromise } from './error';
import { PopulatedTransaction } from 'ethers';
import { StakingSummary, ClaimSummary } from './index';

class StakingApiClient implements StakingApiClient {
    private clients: Map<ClientOptions, ContractClient>;
    private initStatus: boolean = false;

    constructor() {
        this.clients = new Map<ClientOptions, ContractClient>();
    }

    public initialize(options: InitOptions): void {
        if (this.initStatus) {
            return;
        }

        const context = new ClientContext(options);
        for (const clientOption of GlobalClientOptions) {
            const client = new ContractClient(context, clientOption);
            this.clients.set(clientOption, client);
        }
        this.initStatus = true;
    }

    public get isInitialized(): boolean {
        return this.initStatus;
    }

    public resetInitStatus(): void {
        this.initStatus = false;
    }

    public getChainId(options: ClientOptions): Promise<number> {
        return this.getClient(options).getChainId().catch((error: any) => createErrorPromise(error.toString()));
    }

    public tokenContractAddress(options: ClientOptions): Promise<string> {
        return this.getClient(options).tokenContractAddress().catch((error: any) => createErrorPromise(error.toString()));
    }

    public stakingContractAddress(options: ClientOptions): Promise<string> {
        return this.getClient(options).stakingContractAddress().catch((error: any) => createErrorPromise(error.toString()));
    }

    public stakingStartTimestamp(options: ClientOptions): Promise<number> {
        return this.getClient(options).stakingStartTimestamp().catch((error: any) => createErrorPromise(error.toString()));
    }

    public totalDurationSeconds(options: ClientOptions): Promise<number> {
        return this.getClient(options).totalDurationSeconds().catch((error: any) => createErrorPromise(error.toString()));
    }

    public stakingPeriodSeconds(options: ClientOptions): Promise<number> {
        return this.getClient(options).stakingPeriodSeconds().catch((error: any) => createErrorPromise(error.toString()));
    }

    public claimDelaySeconds(options: ClientOptions): Promise<number> {
        return this.getClient(options).claimDelaySeconds().catch((error: any) => createErrorPromise(error.toString()));
    }

    public isStakingPaused(options: ClientOptions): Promise<boolean> {
        return this.getClient(options).isStakingPaused().catch((error: any) => createErrorPromise(error.toString()));
    }

    public totalStaked(options: ClientOptions): Promise<number> {
        return this.getClient(options).totalStaked().catch((error: any) => createErrorPromise(error.toString()));
    }

    public totalUnstaked(options: ClientOptions): Promise<number> {
        return this.getClient(options).totalUnstaked().catch((error: any) => createErrorPromise(error.toString()));
    }

    public stakingTotalSupply(options: ClientOptions): Promise<number> {
        return this.getClient(options).stakingTotalSupply().catch((error: any) => createErrorPromise(error.toString()));
    }

    public currentTotalReward(options: ClientOptions): Promise<number> {
        return this.getClient(options).currentTotalReward().catch((error: any) => createErrorPromise(error.toString()));
    }

    public tokenBalance(options: ClientOptions, account: string): Promise<number> {
        return this.getClient(options).tokenBalance(account).catch((error: any) => createErrorPromise(error.toString()));
    }

    public stakingBalance(options: ClientOptions, account: string): Promise<number> {
        return this.getClient(options).stakingBalance(account).catch((error: any) => createErrorPromise(error.toString()));
    }

    public swapToStakingToken(options: ClientOptions, amount: number): Promise<number> {
        return this.getClient(options).swapToStakingToken(amount).catch((error: any) => createErrorPromise(error.toString()));
    }

    public swapToUnderlyingToken(options: ClientOptions, amount: number): Promise<number> {
        return this.getClient(options).swapToUnderlyingToken(amount).catch((error: any) => createErrorPromise(error.toString()));
    }

    public stakingSummary(options: ClientOptions, account: string): Promise<StakingSummary> {
        return this.getClient(options).stakingSummary(account).catch((error: any) => createErrorPromise(error.toString()));
    }

    public claimSummary(options: ClientOptions, account: string): Promise<ClaimSummary> {
        return this.getClient(options).claimSummary(account).catch((error: any) => createErrorPromise(error.toString()));
    }

    public tokenApprove(options: ClientOptions, account: string, amount: number): Promise<PopulatedTransaction | undefined> {
        return this.getClient(options).tokenApprove(account, amount).catch((error: any) => createErrorPromise(error.toString()));
    }

    public stake(options: ClientOptions, account: string, amount: number): Promise<PopulatedTransaction> {
        return this.getClient(options).stake(account, amount).catch((error: any) => createErrorPromise(error.toString()));
    }

    public unstake(options: ClientOptions, account: string, amount: number, nonces: number[]): Promise<PopulatedTransaction> {
        return this.getClient(options).unstake(account, amount, nonces).catch((error: any) => createErrorPromise(error.toString()));
    }

    public claim(options: ClientOptions, to?: string): Promise<PopulatedTransaction> {
        return this.getClient(options).claim(to).catch((error: any) => createErrorPromise(error.toString()));
    }

    private getClient(options: ClientOptions): ContractClient {
        const client = this.clients.get(options);
        if (!client) {
            throw new Error(`Client not found for options: ${JSON.stringify(options)}`);
        }
        return client;
    }
}

const stakingApiClient = new StakingApiClient();
export default stakingApiClient;
