// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract MystikoClaim is AccessControl {
    uint256 public immutable CLAIM_DELAY_BLOCKS;

    struct Claim {
        uint256 amount;
        uint256 unstakeBlock;
        bool claimPaused;
    }

    mapping(address => uint256) public stakingRecords;
    mapping(address => Claim) public claimRecords;

    constructor(uint256 _stakingPeriod) {
        CLAIM_DELAY_BLOCKS = _stakingPeriod;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _stakeRecord(address _account, uint256 _block) internal returns (bool) {
        stakingRecords[_account] = _block;
        return true;
    }

    function _canUnstake(address _account) internal view returns (bool) {
        uint256 stakedBlock = stakingRecords[_account];
        require(stakedBlock > 0, "MystikoClaim: Staking record not found");
        return block.number > stakedBlock + CLAIM_DELAY_BLOCKS;
        return true;
    }

    function _unstakeRecord(address _account, uint256 _amount) internal returns (bool) {
        Claim storage claim = claimRecords[_account];
        claim.amount += _amount;
        claim.unstakeBlock = block.number;
        return true;
    }

    function _consumeClaim(address _account) internal returns (uint256) {
        Claim storage claim = claimRecords[_account];
        require(!claim.claimPaused, "MystikoClaim: Claim paused");
        require(
            block.number > claim.unstakeBlock + CLAIM_DELAY_BLOCKS,
            "MystikoClaim: Claim delay not reached"
        );
        require(claim.amount > 0, "MystikoClaim: No claimable amount");
        uint256 amount = claim.amount;
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
