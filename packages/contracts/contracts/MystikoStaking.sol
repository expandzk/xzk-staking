// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SafeERC20, IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {MystikoDAOAccessControl} from "lib/mystiko-governance/packages/contracts/contracts/MystikoDAOAccessControl.sol";
import {MystikoStakingToken} from "./token/MystikoStakingToken.sol";
import {RewardsLibrary} from "./libs/Reward.sol";
import {MystikoStakingRecord} from "./MystikoStakingRecord.sol";

contract MystikoStaking is MystikoStakingRecord, MystikoStakingToken, MystikoDAOAccessControl, ReentrancyGuard {
    // Total reward amount (50 million tokens) of underlying token
    uint256 public constant ALL_REWARD = (50_000_000 * 1e18);

    // Total shares for the underlying token
    uint256 public constant ALL_SHARES = 100;

    // Total duration 3 years)
    uint256 public constant TOTAL_DURATION_SECONDS = 3 * 365 days;

    uint256 public constant START_DELAY_SECONDS = 1 days;

    // Total factor for the staking token of total share
    uint256 public immutable TOTAL_FACTOR;

    // Total reward amount of underlying token for current staking period
    uint256 public immutable TOTAL_REWARD;

    // Start timestamp for calculating rewards
    uint256 public immutable START_TIME;

    // total staked amount of underlying token
    uint256 public totalStaked;

    // total unstaked amount of underlying token
    uint256 public totalUnstaked;

    // Whether the staking is paused
    bool public isStakingPaused;

    event Staked(address indexed account, uint256 amount, uint256 stakingAmount);
    event Unstaked(address indexed account, uint256 stakingAmount, uint256 amount);
    event Claimed(address indexed account, uint256 amount);
    event ClaimedToDao(address indexed account, uint256 amount);
    event StakingPausedByDao();
    event StakingUnpausedByDao();

    constructor(
        address _daoRegistry,
        address _pauseAdmin,
        IERC20 _underlyingToken,
        string memory _stakingTokenName,
        string memory _stakingTokenSymbol,
        uint256 _stakingPeriodSeconds,
        uint256 _totalFactor,
        uint256 _startTime
    )
        MystikoStakingToken(_underlyingToken, _stakingTokenName, _stakingTokenSymbol)
        MystikoStakingRecord(_pauseAdmin, _stakingPeriodSeconds)
        MystikoDAOAccessControl(_daoRegistry)
    {
        require(_startTime >= block.timestamp + START_DELAY_SECONDS, "Start time must one day after deployment");
        require(TOTAL_DURATION_SECONDS < 10 * 365 days, "Total duration must be less than 10 years");
        START_TIME = _startTime;
        TOTAL_FACTOR = _totalFactor;
        TOTAL_REWARD = (ALL_REWARD * TOTAL_FACTOR) / ALL_SHARES;
        totalStaked = 0;
        totalUnstaked = 0;
        isStakingPaused = false;
    }

    function stake(uint256 _amount) external nonReentrant returns (bool) {
        require(!isStakingPaused, "MystikoStaking: paused");
        address account = _msgSender();
        require(account != address(this), "MystikoStaking: Invalid receiver");
        require(_amount > 0, "MystikoStaking: Invalid amount");
        uint256 stakingAmount = swapToStakingToken(_amount);
        SafeERC20.safeTransferFrom(UNDERLYING_TOKEN, account, address(this), _amount);
        _mint(account, stakingAmount);
        if (STAKING_PERIOD_SECONDS > 0) {
            require(_stakeRecord(account, stakingAmount), "MystikoStaking: Stake record failed");
        }
        totalStaked += _amount;
        emit Staked(account, _amount, stakingAmount);
        return true;
    }

    function unstake(uint256 _stakingAmount, uint256[] calldata _nonces) external nonReentrant returns (bool) {
        require(!isStakingPaused, "MystikoStaking: paused");
        address account = _msgSender();
        require(account != address(this), "MystikoStaking: Invalid receiver");
        require(_stakingAmount > 0, "MystikoStaking: Invalid amount");
        require(_stakingAmount <= balanceOf(account), "MystikoStaking: Insufficient staking balance");
        if (STAKING_PERIOD_SECONDS > 0) {
            require(_nonces.length > 0, "MystikoClaim: Invalid parameter");
            require(_unstakeRecord(account, _stakingAmount, _nonces), "MystikoStaking: Unstake record failed");
        } else {
            require(_nonces.length == 0, "MystikoStaking: Invalid parameter");
        }
        uint256 amount = swapToUnderlyingToken(_stakingAmount);
        _burn(account, _stakingAmount);
        require(_claimRecord(account, amount), "MystikoStaking: Claim record failed");
        totalUnstaked += amount;
        emit Unstaked(account, _stakingAmount, amount);
        return true;
    }

    function claim() external nonReentrant returns (bool) {
        require(!isStakingPaused, "MystikoStaking: paused");
        address account = _msgSender();
        require(account != address(this), "MystikoStaking: Invalid receiver");
        uint256 amount = _consumeClaim(account);
        SafeERC20.safeTransfer(UNDERLYING_TOKEN, account, amount);
        emit Claimed(account, amount);
        return true;
    }

    function claimToDao(uint256 _amount) external onlyMystikoDAO {
        require(_amount > 0, "MystikoStaking: Invalid amount");
        SafeERC20.safeTransfer(UNDERLYING_TOKEN, _msgSender(), _amount);
        emit ClaimedToDao(_msgSender(), _amount);
    }

    function pauseStaking() external onlyMystikoDAO {
        isStakingPaused = true;
        emit StakingPausedByDao();
    }

    function unpauseStaking() external onlyMystikoDAO {
        isStakingPaused = false;
        emit StakingUnpausedByDao();
    }

    function swapToStakingToken(uint256 _amount) public view returns (uint256) {
        uint256 totalReward = currentTotalReward();
        uint256 total = totalStaked + totalReward - totalUnstaked;
        uint256 totalSupply = totalSupply();
        if (total == 0 || totalSupply == 0) {
            return _amount;
        }
        uint256 swapAmount = (_amount * totalSupply) / total;
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
        if (block.timestamp <= START_TIME) {
            return 0;
        }

        uint256 timePassed = block.timestamp - START_TIME;
        if (timePassed >= TOTAL_DURATION_SECONDS) {
            return TOTAL_REWARD;
        }

        uint256 reward = RewardsLibrary.calcTotalReward(timePassed);
        return (reward * TOTAL_FACTOR) / ALL_SHARES;
    }
}
