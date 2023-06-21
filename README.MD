# Starknet Vault

Is a minimal smart contract for receive deposits in eth and make a rebalanced of assets to maintain 50/50 eth usdc.

## ERC20 Contract

The `erc20.cairo` contract in Starknet follows a structure that is similar to ERC20 on Ethereum with some differences due to the L2 nature of Starknet.

Struct Storage stores basic token information such as name, symbol, decimals, and total supply. It also includes two LegacyMap collections for storing balances and allowances.

Transfer and Approval are the standard ERC20 events.

The constructor function initializes the contract with the initial token supply, name, symbol, and decimals.

get_name, get_symbol, get_decimals, and get_total_supply are view functions that allow anyone to query basic information about the token.

balance_of and allowance functions allow anyone to check the balance of a particular address or the allowance a spender has from an owner.

The approve, mint, transfer, and transfer_from functions allow addresses to approve, mint, transfer, and transfer from another address respectively.

## Vault Contract

The `vault.cairo` contract is a DeFi contract that allows users to stake tokens in exchange for rewards.

Struct Storage stores information about the vault, including the owner, staking token, reward token, and maps for tracking stakers and their rewards.

The Deposit, Withdraw, Claim_Rewards, and Rebalanced are events that are emitted when users deposit or withdraw funds, claim their rewards, or when the vault is rebalanced.

The constructor function initializes the contract with the staking token, reward token, and some other parameters.

view_price_data, balanceStaked, earnedRewards, stakingToken, token_rewards, eth_staked, and usd_value_staked are view functions that provide information about the vault and its assets.

The stake function allows users to stake tokens in the vault. The staker must have approved the contract to transfer the staking tokens on their behalf.

The withdrawStake function allows stakers to withdraw their staked tokens.

The claimRewards function allows stakers to claim their rewards. Rewards are minted at the time of claim.

The rebalance function can be called by the owner to swap 50% of the staked ETH to USDC. This function also emits the Rebalanced event.

## Interfaces

For interacting with an external contracts as the `Pragma Oracle` and `ERC20` we  need to use the `#[abi]` for interact with this contract interfaces.

### Disclaimer

``This contracts are not for production purposes, they are not secure and probably has a lot of bugs``.
This is a general explanation and the actual behavior might depend on the specific implementation. Make sure to understand the code thoroughly before using it.
