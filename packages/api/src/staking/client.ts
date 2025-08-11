import axios, { AxiosError, AxiosInstance, AxiosResponse } from 'axios';
import { XZKStakingErrorCode, XZKStakingError } from '../error';

export class StakingBackendClient {
  public axiosInstance: AxiosInstance;

  constructor(url: string, timeout: number = 20000) {
    this.axiosInstance = axios.create({
      baseURL: url,
      timeout,
    });
    this.axiosInstance.interceptors.response.use(
      function (response: AxiosResponse) {
        const resp = response.data;
        if (resp) {
          if (resp.code === 0) {
            return resp.data;
          } else {
            return Promise.reject(new XZKStakingError(resp.message, XZKStakingErrorCode.STAKING_API_ERROR));
          }
        }
        const request = response.request;
        if (request) {
          return Promise.reject(
            new XZKStakingError(
              `Api request error: requestUrl: ${response.config.baseURL}${request.path}, method: ${request.method}`,
              XZKStakingErrorCode.STAKING_API_ERROR,
            ),
          );
        }
        return Promise.reject(new XZKStakingError(`Unknown error`, XZKStakingErrorCode.STAKING_API_ERROR));
      },
      function (error) {
        if (error instanceof AxiosError) {
          const requestConfig = error.config;
          return Promise.reject(
            new XZKStakingError(
              `Api request error: message: ${error.message}, requestUrl: ${requestConfig?.baseURL}${requestConfig?.url}, method: ${requestConfig?.method}, code: ${error.code}`,
              XZKStakingErrorCode.STAKING_API_ERROR,
            ),
          );
        }
        return Promise.reject(new XZKStakingError(error.message, XZKStakingErrorCode.STAKING_API_ERROR));
      },
    );
  }

  public async health(): Promise<string> {
    return this.axiosInstance.get('/health');
  }

  public async getSummary() {
    return this.axiosInstance.get('/v1/summary');
  }

  public async getPoolSummary(token: string, period: string) {
    return this.axiosInstance.get('/v1/pool/summary', {
      params: {
        token,
        period,
      },
    });
  }
}
