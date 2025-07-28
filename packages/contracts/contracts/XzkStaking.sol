// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SafeERC20, IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {MystikoDAOAccessControl} from "lib/mystiko-governance/packages/contracts/contracts/MystikoDAOAccessControl.sol";
import {XzkStakingToken} from "./token/XzkStakingToken.sol";
import {Constants} from "./libs/constant.sol";
import {RewardsLibrary} from "./libs/Reward.sol";
import {XzkStakingRecord} from "./XzkStakingRecord.sol";

contract XzkStaking is XzkStakingRecord, XzkStakingToken, MystikoDAOAccessControl, ReentrancyGuard {
    // Total shares for the underlying token
    uint256 public constant ALL_SHARES = 10000;

    uint256 public constant START_DELAY_SECONDS = 5 days;

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

    // total claimed amount of underlying token
    uint256 public totalClaimed;

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
        XzkStakingToken(_underlyingToken, _stakingTokenName, _stakingTokenSymbol)
        XzkStakingRecord(_pauseAdmin, _stakingPeriodSeconds)
        MystikoDAOAccessControl(_daoRegistry)
    {
        require(_startTime >= block.timestamp + START_DELAY_SECONDS, "Start time must be after start delay");
        START_TIME = _startTime;
        TOTAL_FACTOR = _totalFactor;
        TOTAL_REWARD = (Constants.ALL_REWARD * TOTAL_FACTOR) / ALL_SHARES;
        totalStaked = 0;
        totalUnstaked = 0;
        totalClaimed = 0;
        isStakingPaused = false;
    }

    function stake(uint256 _amount) external nonReentrant returns (bool) {
        require(!isStakingPaused, "XzkStaking: paused");
        address account = _msgSender();
        require(account != address(this), "XzkStaking: Invalid receiver");
        require(_amount > 0, "XzkStaking: Invalid amount");
        uint256 stakingAmount = swapToStakingToken(_amount);
        SafeERC20.safeTransferFrom(UNDERLYING_TOKEN, account, address(this), _amount);
        _mint(account, stakingAmount);
        require(_stakeRecord(account, _amount, stakingAmount), "XzkStaking: Stake record failed");
        totalStaked += _amount;
        emit Staked(account, _amount, stakingAmount);
        return true;
    }

    function unstake(uint256 _stakingAmount, uint256 _startNonce, uint256 _endNonce)
        external
        nonReentrant
        returns (bool)
    {
        require(!isStakingPaused, "Staking paused");
        address account = _msgSender();
        require(account != address(this), "Invalid receiver");
        require(_stakingAmount > 0, "Invalid amount");
        require(_stakingAmount <= balanceOf(account), "Insufficient staking balance");
        require(_startNonce <= _endNonce, "Invalid parameter");
        uint256 amount = swapToUnderlyingToken(_stakingAmount);
        require(_unstakeVerify(account, _stakingAmount, _startNonce, _endNonce), "Unstake record failed");
        _burn(account, _stakingAmount);
        _unstakeRecord(account, amount, _stakingAmount);
        totalUnstaked += amount;
        emit Unstaked(account, _stakingAmount, amount);
        return true;
    }

    function claim(address _to, uint256 _startNonce, uint256 _endNonce) external nonReentrant returns (bool) {
        require(!isStakingPaused, "Staking paused");
        address account = _msgSender();
        require(account != address(this), "Invalid receiver");
        uint256 amount = _claimRecord(account, _startNonce, _endNonce);
        require(amount > 0, "No amount to claim");
        SafeERC20.safeTransfer(UNDERLYING_TOKEN, _to, amount);
        totalClaimed += amount;
        emit Claimed(_to, amount);
        return true;
    }

    function estimatedApr(uint256 baseAmount) external view returns (uint256) {
        require(baseAmount > 0, "Invalid amount");
        require(baseAmount < UNDERLYING_TOKEN.totalSupply(), "Invalid amount");
        uint256 stakingAmount = swapToStakingToken(baseAmount);
        uint256 totalRewardAfterYear = totalRewardAt(block.timestamp + 365 days);
        uint256 stakingTotalSupply = totalSupply() + stakingAmount;
        uint256 totalAmountAfterYear = totalStaked + totalRewardAfterYear - totalUnstaked + baseAmount;
        uint256 swapAmountAfterYear = (stakingAmount * totalAmountAfterYear) / stakingTotalSupply;
        if (swapAmountAfterYear > baseAmount) {
            return ((swapAmountAfterYear - baseAmount) * 1e18) / baseAmount;
        } else {
            return 0;
        }
    }

    function stakerApr() external view returns (uint256) {
        uint256 currentTotalReward = totalRewardAt(block.timestamp);
        uint256 currentTotal = totalStaked + currentTotalReward - totalUnstaked;
        uint256 totalRewardAfterYear = totalRewardAt(block.timestamp + 365 days);
        uint256 afterYearTotal = totalStaked + totalRewardAfterYear - totalUnstaked;
        if (afterYearTotal > currentTotal && currentTotal > 0) {
            return ((afterYearTotal - currentTotal) * 1e18) / currentTotal;
        } else {
            return 0;
        }
    }

    function claimToDao(uint256 _amount) external onlyMystikoDAO {
        require(_amount > 0, "XzkStaking: Invalid amount");
        SafeERC20.safeTransfer(UNDERLYING_TOKEN, _msgSender(), _amount);
        totalClaimed += _amount;
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
        uint256 totalReward = totalRewardAt(block.timestamp);
        uint256 total = totalStaked + totalReward - totalUnstaked;
        uint256 totalStakingSupply = totalSupply();
        if (total == 0 || totalStakingSupply == 0) {
            return _amount;
        }
        uint256 swapAmount = (_amount * totalStakingSupply) / total;
        return swapAmount;
    }

    function swapToUnderlyingToken(uint256 _stakedAmount) public view returns (uint256) {
        uint256 currentTotalReward = totalRewardAt(block.timestamp);
        uint256 total = totalStaked + currentTotalReward - totalUnstaked;
        if (total == 0) {
            return _stakedAmount;
        }
        uint256 totalStakingSupply = totalSupply();
        require(totalStakingSupply > 0, "XzkStaking: Total supply is zero");
        uint256 swapAmount = (_stakedAmount * total) / totalStakingSupply;
        return swapAmount;
    }

    function totalRewardAt(uint256 _time) public view returns (uint256) {
        if (_time <= START_TIME) {
            return 0;
        }

        uint256 timePassed = _time - START_TIME;
        if (timePassed >= Constants.TOTAL_DURATION_SECONDS) {
            return TOTAL_REWARD;
        }

        uint256 reward = RewardsLibrary.calcTotalReward(timePassed);
        return (reward * TOTAL_FACTOR) / ALL_SHARES;
    }

    function allReward() public pure returns (uint256) {
        return Constants.ALL_REWARD;
    }

    function totalDurationSeconds() public pure returns (uint256) {
        return Constants.TOTAL_DURATION_SECONDS;
    }

    function totalFactor() public pure returns (uint256) {
        return Constants.TOTAL_FACTOR;
    }
}
