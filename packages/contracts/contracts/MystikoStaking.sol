// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SafeERC20, IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {MystikoStakingToken} from "./token/MystikoStakingToken.sol";
import {RewardsLibrary} from "./libs/Reward.sol";
import {MystikoStakingRecord} from "./MystikoStakingRecord.sol";

contract MystikoStaking is MystikoStakingRecord, MystikoStakingToken, ReentrancyGuard {
    // Total reward amount (50 million tokens)
    uint256 public constant ALL_REWARD_AMOUNT = (50_000_000 * 1e18);

    // Total duration in blocks (7,776,000 blocks at 12s block time ≈ 3 years)
    uint256 public constant TOTAL_BLOCKS = 7_776_000;

    // Total reward amount factor (1.094396414 = 1094396414000000000/10^18)
    int256 public constant EXP_FACTOR = 1_094_396_414 * 1e9;

    uint256 public constant START_DELAY_BLOCKS = 7200; // 1 days / 12s block time

    // Total factor for the staking token
    uint256 public constant TOTAL_SHARE = 100;

    // Total factor for the staking token of total share
    uint256 public immutable TOTAL_FACTOR;

    // Total reward amount of current staking period
    uint256 public immutable TOTAL_REWARD_AMOUNT;

    // Start block for calculating rewards
    uint256 public immutable START_BLOCK;

    uint256 public totalStaked;

    uint256 public totalUnstaked;

    event Staked(address indexed account, uint256 amount, uint256 stakingAmount);
    event Unstaked(address indexed account, uint256 stakingAmount, uint256 amount);
    event Claimed(address indexed account, uint256 amount);

    constructor(
        IERC20 _mystikoToken,
        string memory _stakingTokenName,
        string memory _stakingTokenSymbol,
        uint256 _stakingPeriod,
        uint256 _totalFactor,
        uint256 _startBlock
    )
        MystikoStakingToken(_mystikoToken, _stakingTokenName, _stakingTokenSymbol)
        MystikoStakingRecord(_stakingPeriod)
    {
        require(_startBlock > block.number + START_DELAY_BLOCKS, "Start block must one day after deployment");
        START_BLOCK = _startBlock;
        TOTAL_FACTOR = _totalFactor;
        TOTAL_REWARD_AMOUNT = (ALL_REWARD_AMOUNT * TOTAL_FACTOR) / TOTAL_SHARE;
        totalStaked = 0;
        totalUnstaked = 0;
    }

    function stake(uint256 _amount) external nonReentrant returns (bool) {
        address account = _msgSender();
        require(account != address(this), "MystikoStaking: Invalid receiver");
        require(_amount > 0, "MystikoStaking: Invalid amount");
        uint256 stakingAmount = swapToStakingToken(_amount);
        SafeERC20.safeTransferFrom(UNDERLYING_TOKEN, account, address(this), _amount);
        _mint(account, stakingAmount);
        require(_stakeRecord(account, block.number), "MystikoStaking: Stake record failed");
        totalStaked += _amount;
        emit Staked(account, _amount, stakingAmount);
        return true;
    }

    function unstake(uint256 _stakingAmount) external nonReentrant returns (bool) {
        address account = _msgSender();
        require(account != address(this), "MystikoStaking: Invalid receiver");
        require(_stakingAmount > 0, "MystikoStaking: Invalid staking amount");
        require(_stakingAmount <= balanceOf(account), "MystikoStaking: Insufficient staking balance");
        require(_canUnstake(account), "MystikoStaking: Staking period not ended");
        uint256 amount = swapToUnderlyingToken(_stakingAmount);
        _burn(account, _stakingAmount);
        require(_unstakeRecord(account, amount), "MystikoStaking: Unstake record failed");
        totalUnstaked += amount;
        emit Unstaked(account, _stakingAmount, amount);
        return true;
    }

    function claim() external nonReentrant returns (bool) {
        address account = _msgSender();
        require(account != address(this), "MystikoStaking: Invalid receiver");
        uint256 amount = _consumeClaim(account);
        SafeERC20.safeTransfer(UNDERLYING_TOKEN, account, amount);
        emit Claimed(account, amount);
        return true;
    }

    function claimTo(address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(_amount > 0, "MystikoStaking: Invalid amount");
        SafeERC20.safeTransfer(UNDERLYING_TOKEN, _to, _amount);
        emit Claimed(_to, _amount);
        return true;
    }

    function swapToStakingToken(uint256 _amount) public view returns (uint256) {
        uint256 totalReward = currentTotalReward();
        uint256 total = totalStaked + totalReward - totalUnstaked;
        if (total == 0) {
            return _amount;
        }
        uint256 swapAmount = (_amount * totalSupply()) / total;
        return swapAmount;
    }

    function swapToUnderlyingToken(uint256 _stakedAmount) public view returns (uint256) {
        uint256 totalReward = currentTotalReward();
        uint256 total = totalStaked + totalReward - totalUnstaked;
        if (total == 0) {
            return _stakedAmount;
        }
        uint256 totalSupply = totalSupply();
        require(totalSupply > 0, "MystikoStaking: Total supply is zero");
        uint256 swapAmount = (_stakedAmount * total) / totalSupply;
        return swapAmount;
    }

    function currentTotalReward() public view returns (uint256) {
        int256 blocksPassed = int256(block.number) - int256(START_BLOCK);
        if (blocksPassed <= 0) {
            return 0;
        }
        if (blocksPassed >= int256(TOTAL_BLOCKS)) {
            return TOTAL_REWARD_AMOUNT;
        }
        uint256 reward = RewardsLibrary.calcTotalRewardAtBlock(blocksPassed, EXP_FACTOR);
        return (reward * TOTAL_FACTOR) / TOTAL_SHARE;
    }
}
