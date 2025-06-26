// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20, ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {EIP712} from "lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

abstract contract XzkStakingToken is ERC20, ERC20Votes {
    IERC20 public immutable UNDERLYING_TOKEN;

    constructor(IERC20 _mystikoToken, string memory _stakingTokenName, string memory _stakingTokenSymbol)
        ERC20(_stakingTokenName, _stakingTokenSymbol)
        EIP712(_stakingTokenName, "1")
    {
        UNDERLYING_TOKEN = _mystikoToken;
    }

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    function decimals() public view override(ERC20) returns (uint8) {
        return super.decimals();
    }

    function _update(address _from, address _to, uint256 _amount) internal override(ERC20, ERC20Votes) {
        super._update(_from, _to, _amount);
    }

    // Disable transfer
    function transfer(address, uint256) public pure override returns (bool) {
        revert("Transfers are disabled for this token");
    }

    // Disable transferFrom
    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("Transfers are disabled for this token");
    }
}
