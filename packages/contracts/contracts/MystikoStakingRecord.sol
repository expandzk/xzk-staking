// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract MystikoStakingRecord is AccessControl {
    uint256 public constant CLAIM_DELAY_BLOCKS = 7200;
    uint256 public immutable STAKING_PERIOD;

    struct StakingRecord {
        uint256 stakedBlock;
        uint256 amount;
        uint256 remaining;
    }

    struct ClaimRecord {
        uint256 amount;
        uint256 unstakeBlock;
        bool claimPaused;
    }

    mapping(address => uint256) public stakingNonces;
    mapping(address => mapping(uint256 => StakingRecord)) public stakingRecords;
    mapping(address => ClaimRecord) public claimRecords;

    constructor(uint256 _stakingPeriod) {
        STAKING_PERIOD = _stakingPeriod;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _stakeRecord(address _account, uint256 _stakingAmount) internal returns (bool) {
        require(_stakingAmount > 0, "MystikoClaim: Invalid staking token amount");
        uint256 nonce = stakingNonces[_account];
        stakingRecords[_account][nonce] =
            StakingRecord({stakedBlock: block.number, amount: _stakingAmount, remaining: _stakingAmount});
        stakingNonces[_account] = nonce + 1;
        return true;
    }

    function _unstakeRecord(address _account, uint256 _stakingAmount, uint256[] calldata _nonces)
        internal
        returns (bool)
    {
        uint256 totalRemaining = 0;
        uint256 length = _nonces.length;
        for (uint256 i = 0; i < length; i++) {
            StakingRecord storage record = stakingRecords[_account][_nonces[i]];
            require(record.stakedBlock > 0, "MystikoClaim: Staking record not found");
            require(block.number > record.stakedBlock + STAKING_PERIOD, "MystikoClaim: Staking period not ended");
            require(record.amount > 0, "MystikoClaim: Staking record not found");
            require(record.remaining > 0, "MystikoClaim: Staking record not found");
            totalRemaining += record.remaining;
            if (totalRemaining < _stakingAmount) {
                record.remaining = 0;
            } else if (totalRemaining == _stakingAmount) {
                record.remaining = 0;
                break;
            } else {
                record.remaining = totalRemaining - _stakingAmount;
                break;
            }
        }
        require(totalRemaining >= _stakingAmount, "MystikoClaim: Invalid remaining amount");
        return true;
    }

    function _claimRecord(address _account, uint256 _amount) internal returns (bool) {
        ClaimRecord storage record = claimRecords[_account];
        record.amount += _amount;
        record.unstakeBlock = block.number;
        record.claimPaused = false;
        return true;
    }

    function _consumeClaim(address _account) internal returns (uint256) {
        ClaimRecord storage record = claimRecords[_account];
        require(!record.claimPaused, "MystikoClaim: Claim paused");
        require(block.number > record.unstakeBlock + CLAIM_DELAY_BLOCKS, "MystikoClaim: Claim delay not reached");
        require(record.amount > 0, "MystikoClaim: No claimable amount");
        uint256 amount = record.amount;
        delete claimRecords[_account];
        return amount;
    }

    function pause(address _account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        claimRecords[_account].claimPaused = true;
    }

    function unpause(address _account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        claimRecords[_account].claimPaused = false;
    }
}
