// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "./ERC20Permit.sol";

import "./interface/IERC2612Permit.sol";

// Fork from SushiBar contract from SushiSwap

// This contract handles swapping to and from xPremia, PremiaSwap's staking token.
contract PremiaStaking is ERC20Permit {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public premia;

    // Define the Premia token contract
    constructor(IERC20 _premia) ERC20("PremiaStaking", "xPREMIA") {
        premia = _premia;
    }

    // Enter using IERC2612 permit
    function enterWithPermit(uint256 _amount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public {
        IERC2612Permit(address(premia)).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        enter(_amount);
    }

    // Enter the staking contract. Pay some PREMIAs. Earn some shares.
    // Locks Premia and mints xPremia
    function enter(uint256 _amount) public {
        // Gets the amount of Premia locked in the contract
        uint256 totalPremia = premia.balanceOf(address(this));
        // Gets the amount of xPremia in existence
        uint256 totalShares = totalSupply();
        // If no xPremia exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalPremia == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xPremia the Premia is worth. The ratio will change overtime, as xPremia is burned/minted and Premia deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalPremia);
            _mint(msg.sender, what);
        }
        // Lock the Premia in the contract
        premia.safeTransferFrom(msg.sender, address(this), _amount);
    }

    // Leave the staking contract. Claim back your PREMIAs.
    // Unlocks the staked + gained Premia and burns xPremia
    function leave(uint256 _share) public {
        // Gets the amount of xPremia in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Premia the xPremia is worth
        uint256 what = _share.mul(premia.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        premia.safeTransfer(msg.sender, what);
    }
}