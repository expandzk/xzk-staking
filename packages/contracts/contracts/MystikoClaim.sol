// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract MystikoClaim is AccessControl {
    uint256 public constant claimDelayBlocks = 7200; // 1 days / 12s block time

    struct Claim {
        uint256 amount;
        uint256 unstakeBlock;
        bool claimPaused;
    }

    mapping(address => Claim) public claims;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _unstakeRecord(address _account, uint256 _amount) internal returns (bool) {
        Claim storage claim = claims[_account];
        claim.amount += _amount;
        claim.unstakeBlock = block.number;
        return true;
    }

    function _consumeClaim(address _account) internal returns (uint256) {
        Claim storage claim = claims[_account];
        require(!claim.claimPaused, "MystikoClaim: Claim paused");
        require(block.number > claim.unstakeBlock + claimDelayBlocks, "MystikoClaim: Claim delay not reached");
        require(claim.amount > 0, "MystikoClaim: No claimable amount");
        uint256 amount = claim.amount;
        delete claims[_account];
        return amount;
    }

    function pause(address _account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        claims[_account].claimPaused = true;
    }

    function unpause(address _account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        claims[_account].claimPaused = false;
    }
}
