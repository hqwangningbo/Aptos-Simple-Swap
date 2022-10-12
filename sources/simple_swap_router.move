module swap_account::SimplpSwapRouter{
    //generate_lp_coin
    //create_pool
    //swap
    //add_liquidity
    //remove_liquidity

    use aptos_framework::coin::{Coin, MintCapability, BurnCapability};
    use std::string;
    use aptos_framework::coin;
    use my_address::Coins::LP;
    use std::string::String;
    #[test_only]
    use my_address::Coins::{NB, USDT, issue};
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    #[test_only]
    use std::signer::address_of;


    struct Pool<phantom X, phantom Y> has key{
        x_coin:Coin<X>,
        y_coin:Coin<Y>,
        lp_mint:MintCapability<LP<X,Y>>,
        lp_burn:BurnCapability<LP<X,Y>>,
    }

    //NB,USDT-> LP-NB-USDT
    fun generate_lp_name_symbol<X, Y>():String {
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

        //会判断是否swap_pool_account addr == swap_account
        let (lp_burn,lp_freeze,lp_mint) = coin::initialize<LP<X,Y>>(
            swap_pool_account,
            lp_name_symbol,
            lp_name_symbol,
            6,
            true
        );
        coin::destroy_freeze_cap(lp_freeze);

        move_to(swap_pool_account,Pool<X,Y>{
            x_coin:coin::zero<X>(),
            y_coin:coin::zero<Y>(),
            lp_mint,
            lp_burn,
        })
    }

    #[test(sender=@my_address)]
    fun generate_lp_name_symbol_should_work(sender:&signer) {
        issue(sender);
        let lp_name_symbol = generate_lp_name_symbol<NB,USDT>();
        assert!(string::utf8(b"LP-NB-USDT") == lp_name_symbol,0);
    }

    #[test(sender=@my_address)]
    fun create_pool_should_work(sender:&signer) {
        create_account_for_test(address_of(sender));
        issue(sender);
        create_pool<NB,USDT>(sender);
    }

}
