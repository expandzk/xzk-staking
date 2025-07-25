import numpy as np
import matplotlib.pyplot as plt

TOTAL_REWARD = 50_000_000*10**18
TOTAL_DURATION_SECONDS_3_YEARS = 3*365*24*3600
TOTAL_DURATION_SECONDS_4_HOURS = 4*3600
SCALE = 10**18
lambda_decay = 20*10**9

def calc_raw_reward(time_passed: int) -> int:
    x = time_passed*lambda_decay
    exp_val = exp_taylor(x)
    scaledExpVal = SCALE*SCALE//exp_val
    raw_reward = SCALE-scaledExpVal
    return raw_reward

# exp Taylor series approximation same with solidity
def exp_taylor(x: int, terms: int = 20) -> int:
    sum_ = SCALE
    term = SCALE

    for i in range(1, terms):
        term = term * x // SCALE
        term = term // i
        sum_ += term
    return sum_

def main():
    raw_total_reward = calc_raw_reward(TOTAL_DURATION_SECONDS_3_YEARS)
    factor_3_years = TOTAL_REWARD/raw_total_reward
    print(f"factor_3_years: {factor_3_years:.9f}")
    raw_total_reward = calc_raw_reward(TOTAL_DURATION_SECONDS_4_HOURS)
    factor_4_hours = TOTAL_REWARD/raw_total_reward
    print(f"factor_4_hours: {factor_4_hours:.9f}")

if __name__ == "__main__":
    main()
