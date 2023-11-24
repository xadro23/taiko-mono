// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

import "./BaseTranslator.sol";

interface IUsdcBurn {
    /// @notice Burns `amount` tokens from address(this)
    /// @param amount The amount of tokens to burn.
    function burn(uint256 amount) external;
}

/// @title UsdcTranslator
/// @notice It serves as a wrapper between the deployed USDC and the ERC20Vault - an extra layer for
/// flexibility. It is not an ERC20 contract, but we need to implement the interfaces the ERC20Vault
/// calls and relay over to the USDC contract. The reason this contract needs to be 'custom' is the
/// different mechanisms how each native tokens handling some functions. In this case the
/// 'troublemaker' is the burn function which behaves differently (in USDC) than usual.
contract UsdcTranslator is BaseTranslator {
    /// @notice Mints tokens to an account.
    /// @dev Only an ERC20Vault can call this function.
    /// @param account The account to mint tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(address account, uint256 amount) public onlyFromNamed("erc20_vault") {
        IERC20TokenVaultRelayer(nativeTokenContract).mint(account, amount);
    }

    /// @notice Burns tokens from an account.
    /// @dev Only an ERC20Vault can call this function.
    /// @param account The account to burn tokens from.
    /// @param amount The amount of tokens to burn.
    function burn(address account, uint256 amount) public onlyFromNamed("erc20_vault") {
        // Same as USDC does.
        // 1. transferFrom() to this account
        // 2. burn() it the way USDC burns
        IERC20TokenVaultRelayer(nativeTokenContract).transferFrom({
            from: account,
            to: address(this),
            amount: amount
        });
        IUsdcBurn(nativeTokenContract).burn(amount);
    }

    /// @notice We need to keep this because tokenVault will use the SafeERC20Upgradeable's
    /// safeTransfer, which eventuall calls into this.
    /// @param to The account to transfer tokens to.
    /// @param amount The amount of tokens to transfer.
    function transfer(address to, uint256 amount) public returns (bool) {
        return IERC20TokenVaultRelayer(nativeTokenContract).transfer(to, amount);
    }

    /// @notice Transfers tokens from one account to another account.
    /// @dev Any address can call this. Caller must have allowance of at least
    /// 'amount' for 'from's tokens.
    /// @param from The account to transfer tokens from.
    /// @param to The account to transfer tokens to.
    /// @param amount The amount of tokens to transfer.
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        return IERC20TokenVaultRelayer(nativeTokenContract).transferFrom(from, to, amount);
    }
}

/// @title ProxiedUsdcTranslator
/// @notice Proxied version of the parent contract.
contract ProxiedUsdcTranslator is Proxied, UsdcTranslator { }
