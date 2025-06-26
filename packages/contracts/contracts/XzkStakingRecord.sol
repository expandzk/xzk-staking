// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract XzkStakingRecord is AccessControl {
    uint256 public constant CLAIM_DELAY_SECONDS = 1 days;
    uint256 public immutable STAKING_PERIOD_SECONDS;

    struct StakingRecord {
        uint256 stakingTime;
        uint256 tokenAmount;
        uint256 stakingTokenAmount;
        uint256 stakingTokenRemaining;
    }

    struct UnstakingRecord {
        uint256 unstakingTime;
        uint256 claimTime;
        uint256 stakingTokenAmount;
        uint256 tokenAmount;
        uint256 tokenRemaining;
    }

    mapping(address => uint256) public stakingNonces;
    mapping(address => mapping(uint256 => StakingRecord)) public stakingRecords;
    mapping(address => uint256) public unstakingNonces;
    mapping(address => mapping(uint256 => UnstakingRecord)) public unstakingRecords;
    mapping(address => bool) public unstakingPaused;

    event AccountPaused(address indexed account);
    event AccountUnpaused(address indexed account);

    constructor(address _pauseAdmin, uint256 _stakingPeriodSeconds) {
        STAKING_PERIOD_SECONDS = _stakingPeriodSeconds;
        _grantRole(DEFAULT_ADMIN_ROLE, _pauseAdmin);
    }

    function _stakeRecord(address _account, uint256 _tokenAmount, uint256 _stakingTokenAmount)
        internal
        returns (bool)
    {
        require(_tokenAmount > 0, "Invalid token amount");
        require(_stakingTokenAmount > 0, "Invalid staking token amount");
        uint256 nonce = stakingNonces[_account];
        stakingRecords[_account][nonce] = StakingRecord({
            stakingTime: block.timestamp,
            tokenAmount: _tokenAmount,
            stakingTokenAmount: _stakingTokenAmount,
            stakingTokenRemaining: _stakingTokenAmount
        });
        stakingNonces[_account] = nonce + 1;
        return true;
    }

    function _unstakeVerify(address _account, uint256 _stakingTokenAmount, uint256 _startNonce, uint256 _endNonce)
        internal
        returns (bool)
    {
        uint256 totalCanUnstake = 0;
        for (uint256 i = _startNonce; i <= _endNonce; i++) {
            StakingRecord storage record = stakingRecords[_account][i];
            require(record.stakingTime > 0, "Staking time zero error");
            require(block.timestamp > record.stakingTime + STAKING_PERIOD_SECONDS, "Staking period not ended");
            require(record.tokenAmount > 0, "Token amount zero error");
            require(record.stakingTokenAmount > 0, "Staking token amount zero error");
            require(record.stakingTokenRemaining > 0, "Staking token remaining zero error");
            totalCanUnstake += record.stakingTokenRemaining;
            if (totalCanUnstake < _stakingTokenAmount) {
                record.stakingTokenRemaining = 0;
            } else if (totalCanUnstake == _stakingTokenAmount) {
                record.stakingTokenRemaining = 0;
                break;
            } else {
                record.stakingTokenRemaining = totalCanUnstake - _stakingTokenAmount;
                break;
            }
        }
        require(totalCanUnstake >= _stakingTokenAmount, "No enough staking token amount");
        return true;
    }

    function _unstakeRecord(address _account, uint256 _tokenAmount, uint256 _stakingTokenAmount) internal {
        uint256 nonce = unstakingNonces[_account];
        unstakingRecords[_account][nonce] = UnstakingRecord({
            unstakingTime: block.timestamp,
            claimTime: 0,
            stakingTokenAmount: _stakingTokenAmount,
            tokenAmount: _tokenAmount,
            tokenRemaining: _tokenAmount
        });
        unstakingNonces[_account] = nonce + 1;
    }

    function _claimRecord(address _account, uint256 _startNonce, uint256 _endNonce) internal returns (uint256) {
        require(!unstakingPaused[_account], "Unstaking paused");
        uint256 totalCanClaim = 0;
        for (uint256 i = _startNonce; i <= _endNonce; i++) {
            UnstakingRecord storage record = unstakingRecords[_account][i];
            require(record.unstakingTime > 0, "Unstaking time zero error");
            require(block.timestamp > record.unstakingTime + CLAIM_DELAY_SECONDS, "Claim delay not reached");
            require(record.tokenAmount > 0, "Token amount zero error");
            require(record.stakingTokenAmount > 0, "Staking token amount zero error");
            require(record.tokenRemaining > 0, "Token remaining zero error");
            require(record.claimTime == 0, "Claim time not zero error");
            totalCanClaim += record.tokenRemaining;
            record.tokenRemaining = 0;
            record.claimTime = block.timestamp;
        }
        return totalCanClaim;
    }

    function pauseClaim(address _account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        unstakingPaused[_account] = true;
        emit AccountPaused(_account);
    }

    function unpauseClaim(address _account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        unstakingPaused[_account] = false;
        emit AccountUnpaused(_account);
    }
}
