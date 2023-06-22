use starknet::ContractAddress;

#[abi]
trait IERC20 {
    fn get_name() -> felt252;
    fn get_symbol() -> felt252;
    fn get_decimals() -> u8;
    fn get_total_supply() -> u256;
    fn balance_of(account: ContractAddress) -> u256;
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(recipient: ContractAddress, amount: u256);
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256);
    fn approve(spender: ContractAddress, amount: u256);
    fn increase_allowance(spender: ContractAddress, added_value: u256);
    fn decrease_allowance(spender: ContractAddress, subtracted_value: u256);
    fn mint(recipient: ContractAddress, amount: u256);
}

#[abi]
trait IPragmaOracle {
    fn get_spot_median(pair_id: felt252) -> (felt252, felt252, felt252, felt252);
    fn get_spot(
        pair_id: felt252, aggregation_mode: felt252
    ) -> (felt252, felt252, felt252, felt252);
}

#[contract]
mod Vault {
    use starknet::ContractAddress;
    use array::ArrayTrait;
    use traits::{ Into, TryInto };
    use super::{ IPragmaOracleDispatcher, IPragmaOracleDispatcherTrait };
    use super::{ IERC20Dispatcher, IERC20DispatcherTrait };
    use starknet::{get_block_timestamp, get_caller_address, get_contract_address};
    use option::OptionTrait;

    struct Storage {
        _owner_address: ContractAddress,
        _pragma_address: ContractAddress,
        _key_pair: felt252,
        _staking_token: ContractAddress,
        _token_rewards: ContractAddress,
        // User address, amount
        _stakers: LegacyMap<ContractAddress, u256>,
        _rewards: LegacyMap<ContractAddress, u256>
    }

    //#########
    // Events #
    //########
    #[event]
    fn Deposit(sender: ContractAddress, value: u256) {}

    #[event]
    fn Withdraw(sender: ContractAddress, value: u256) {}

    #[event]
    fn Claim_Rewards(sender: ContractAddress, value: u256) {}

    #[event]
    fn Rebalanced(value: u256, _time: u64){}

    #[constructor]
    fn constructor(staking_token: ContractAddress, token_rewards: ContractAddress, pragma_address: ContractAddress, key_pair: felt252, _owner: ContractAddress) {
        _owner_address::write(_owner);
        _staking_token::write(staking_token);
        _token_rewards::write(token_rewards);
        _pragma_address::write(pragma_address);
        _key_pair::write(key_pair);
    }

     #[view]
    fn view_price_data() -> felt252 {
        let _pragma_oracle = IPragmaOracleDispatcher { contract_address: _pragma_address::read() };
        let (eth_price, decimals, timestamp, num_sources) = _pragma_oracle.get_spot_median(
            _key_pair::read()
        );

        eth_price
    }

     #[view]
    fn balanceStaked(account: ContractAddress) -> u256 {
        _stakers::read(account)
    }

    #[view]
    fn earnedRewards(account: ContractAddress) -> u256 {
        _rewards::read(account)
    }

    #[view]
    fn stakingToken() -> ContractAddress {
        _staking_token::read()
    }

    #[view]
    fn token_rewards() -> ContractAddress {
        _token_rewards::read()
    }

    // #[view]
    // fn deposit_value() -> u256 {
    //     _deposit_value_in_usd::read()
    // }

    #[view]
    fn eth_staked() -> u256 {
        let self = get_contract_address();
        let staking_token = IERC20Dispatcher { contract_address: _staking_token::read() };
        let balance = staking_token.balance_of(self);
        balance
    }

    #[view]
    fn usd_value_staked() -> u256 {
        let eth_balance = eth_staked();
        let eth_price = view_price_data();
        let value = eth_price.into() * eth_balance;
        value
    }
    
    #[external]
    fn stake(amount: u256, user_stake: ContractAddress) -> u256 {
        // let caller = get_caller_address();
        let this_contract = get_contract_address();
        let staking_token = IERC20Dispatcher { contract_address: _staking_token::read() };

        let approved: u256 = staking_token.allowance(user_stake, this_contract);
        assert(approved > 1.into(), 'Not approved');
        assert(amount != 0.into(), 'Must be greater than 0');

        staking_token.transfer_from(user_stake, this_contract, amount);
        _stakers::write(user_stake, amount);
        _rewards::write(user_stake, _rewards::read(user_stake) + 500000.into());
        
        Deposit(user_stake, amount);
        
        amount
    }

    #[external]
    fn withdrawStake(amount: u256, user_stake: ContractAddress) {
        // let caller = get_caller_address();
        let amount_staked = _stakers::read(user_stake);
        assert(amount_staked > 0.into(), 'Dont have amount staked');
        assert(amount <= amount_staked, 'Dont have enough amount staked');

        let staking_token = IERC20Dispatcher { contract_address: _staking_token::read() };

        _stakers::write(user_stake, (amount_staked - amount));
        staking_token.transfer(user_stake, amount);

        Withdraw(user_stake, amount);
    }

    #[external]
    fn claimRewards(user_stake: ContractAddress) {
        // let caller = get_caller_address();
        let this_contract = get_contract_address();
        let rewards = earnedRewards(user_stake);
        assert(rewards > 0.into(), 'Dont have rewards');
        let reward_token = IERC20Dispatcher { contract_address: _token_rewards::read() };

        _rewards::write(user_stake, 0.into()); // se actualiza el registro
        reward_token.mint(user_stake, 50000.into()); // lo mintea el contrato

        Claim_Rewards(user_stake, rewards);
    }

    #[external]
    fn rebalance() {
        let caller = get_caller_address();
        let eth_price = view_price_data();
        let self = get_contract_address();
        let owner = _owner_address::read();
        assert(caller == owner, 'Only Owner');
        let eth_balance = eth_staked();
        // 50% staked eth swap to usdc
        let amount_to_swap = eth_balance*500000000000000000;
        let staking_token = IERC20Dispatcher { contract_address: _staking_token::read() };
        staking_token.transfer_from(self, owner, amount_to_swap);

        Rebalanced(amount_to_swap, get_block_timestamp());
    }
    
} 
