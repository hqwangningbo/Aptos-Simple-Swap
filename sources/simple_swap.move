module swap_account::SimplpSwap{
    //generate_lp_coin
    //create_pool
    //swap
    //add_liquidity
    //remove_liquidity

    use aptos_framework::coin::{Self,Coin, MintCapability, BurnCapability};
    use std::string;
    use std::string::String;
    use std::option;
    use swap_account::Math::{sqrt,min};
    use std::signer::address_of;

    const MINIMUM_LIQUIDITY: u64 = 1000;

    struct LP<phantom X,phantom Y>{}

    struct Pair<phantom X, phantom Y> has key{
        x_coin:Coin<X>,
        y_coin:Coin<Y>,
        lp_locked:Coin<LP<X,Y>>,
        lp_mint:MintCapability<LP<X,Y>>,
        lp_burn:BurnCapability<LP<X,Y>>,
    }

    //NB,USDT-> LP-NB-USDT
    public fun generate_lp_name_symbol<X, Y>():String {
        let lp_name_symbol = string::utf8(b"");
        string::append_utf8(&mut lp_name_symbol,b"LP");
        string::append_utf8(&mut lp_name_symbol,b"-");
        string::append(&mut lp_name_symbol,coin::symbol<X>());
        string::append_utf8(&mut lp_name_symbol,b"-");
        string::append(&mut lp_name_symbol,coin::symbol<Y>());
        lp_name_symbol
    }

    public entry fun create_pool<X,Y>(swap_pool_account:&signer) {
        let lp_name_symbol = generate_lp_name_symbol<X,Y>();

        let (lp_burn,lp_freeze,lp_mint) = coin::initialize<LP<X,Y>>(
            swap_pool_account,
            lp_name_symbol,
            lp_name_symbol,
            6,
            true
        );
        coin::destroy_freeze_cap(lp_freeze);

        move_to(swap_pool_account,Pair<X,Y>{
            x_coin:coin::zero<X>(),
            y_coin:coin::zero<Y>(),
            lp_locked:coin::zero<LP<X,Y>>(),
            lp_mint,
            lp_burn,
        })
    }

    /*
    Liquidity added for the first time:
        sqrt(x_amount * y_amount) - MINIMUM_LIQUIDITY(1000)
    Add liquidity:
         min(x_amount / x_reserve * lp_total_supply , y_amount / y_reserve * lp_total_supply)
    */
    public entry fun add_liquiduty<X,Y>(sneder:&signer,x_amount:u64,y_amount:u64) acquires Pair {
        //make sure lp exists
        assert!(pair_exist<X,Y>(@swap_account),1000);

        //EINSUFFICIENT_BALANCE
        let x_amount_coin = coin::withdraw<X>(sneder,x_amount);
        let y_amount_coin = coin::withdraw<Y>(sneder,y_amount);

        let pair = borrow_global_mut<Pair<X,Y>>(@swap_pool_account);


        let x_reserve = (coin::value(&pair.x_coin) as u128);
        let y_reserve = (coin::value(&pair.x_coin) as u128);

        let x_amount = (x_amount as u128);
        let y_amount = (x_amount as u128);

        //calc liquidity
        let liquidity;
        let total_supply = *option::borrow(&coin::supply<LP<X,Y>>());

        if(total_supply == 0) {
            liquidity = sqrt(((x_amount * y_amount) as u128)) - MINIMUM_LIQUIDITY;
            let lp_locked = coin::mint(MINIMUM_LIQUIDITY,&pair.lp_mint);
            coin::merge(&mut pair.lp_locked, lp_locked);
        }else {
            liquidity = (min(x_amount * total_supply / x_reserve,y_amount * total_supply / y_reserve) as u64);
        };

        // deposit tokens
        coin::merge(&mut pair.x_coin, x_amount_coin);
        coin::merge(&mut pair.y_coin, y_amount_coin);

        // mint liquidity and return it
        let lp_coin = coin::mint<LP<X, Y>>(liquidity, &pair.lp_mint);
        let addr = address_of(sneder);
        if (!coin::is_account_registered<LP<X, Y>>(addr)) {
            coin::register<LP<X, Y>>(sneder);
        };
        coin::deposit(addr, lp_coin);
    }

    public fun pair_exist<X,Y>(addr:address):bool{
        exists<Pair<X,Y>>(addr)
    }



}
