#[test_only]
module swap_account::Coins{
    use aptos_framework::coin::{MintCapability, BurnCapability};
    use aptos_framework::coin;
    use std::string;
    use std::signer::address_of;
    use swap_account::SimplpSwapRouter::{generate_lp_name_symbol, create_pool, LP};
    #[test_only]
    use aptos_framework::account::create_account_for_test;
    #[test_only]
    use swap_account::SimplpSwapRouter::{add_liquiduty, pair_exist};
    use swap_account::Math::sqrt;

    struct NB {}
    struct USDT {}

    struct Caps<phantom CoinType> has key {
        mint:MintCapability<CoinType>,
        burn:BurnCapability<CoinType>
    }

    #[test_only]
    public fun issue(sender:&signer){
        let (burn_nb,freeze_nb,mint_nb) = coin::initialize<NB>(
            sender,
            string::utf8(b"nb token"),
            string::utf8(b"NB"),
            8,
            true
        );

        let (burn_usdt,freeze_usdt,mint_usdt) = coin::initialize<USDT>(
            sender,
            string::utf8(b"usdt token"),
            string::utf8(b"USDT"),
            6,
            true
        );

        coin::destroy_freeze_cap(freeze_nb);
        coin::destroy_freeze_cap(freeze_usdt);

        move_to(sender,Caps<NB>{
            mint:mint_nb,
            burn:burn_nb
        });

        move_to(sender,Caps<USDT>{
            mint:mint_usdt,
            burn:burn_usdt
        });

    }
    #[test_only]
    public fun mint(sender:&signer) acquires Caps{
        let caps = borrow_global<Caps<NB>>(address_of(sender));
        let nb = coin::mint(1000000000,&caps.mint);
        coin::deposit(address_of(sender),nb);

        let caps = borrow_global<Caps<USDT>>(address_of(sender));
        let usdt = coin::mint(1000000000,&caps.mint);
        coin::deposit(address_of(sender),usdt);
    }

    #[test(sender=@swap_account)]
    public fun test_should_work(sender:&signer) acquires Caps {
        create_account_for_test(@swap_account);
        issue(sender);
        coin::register<NB>(sender);
        coin::register<USDT>(sender);
        mint(sender);
        assert!(coin::is_account_registered<NB>(address_of(sender)),0);
        assert!(coin::is_account_registered<USDT>(address_of(sender)),0);
        assert!(coin::balance<NB>(address_of(sender))==1000000000,0);
        assert!(coin::balance<USDT>(address_of(sender))==1000000000,0);
        assert!(coin::symbol<NB>() == string::utf8(b"NB"),0);
    }

    #[test(sender=@swap_account)]
    fun generate_lp_name_symbol_should_work(sender:&signer) {
        issue(sender);
        let lp_name_symbol = generate_lp_name_symbol<NB,USDT>();
        assert!(string::utf8(b"LP-NB-USDT") == lp_name_symbol,0);
    }

    #[test(sender=@swap_account)]
    fun create_pool_should_work(sender:&signer) {
        create_account_for_test(address_of(sender));
        issue(sender);
        create_pool<NB,USDT>(sender);
        assert!(pair_exist<NB,USDT>(@swap_account),0);
    }

    #[test(sender=@swap_account)]
    fun add_liquidity_should_work(sender:&signer) acquires Caps {
        create_account_for_test(address_of(sender));
        issue(sender);
        coin::register<NB>(sender);
        coin::register<USDT>(sender);
        mint(sender);
        assert!(coin::balance<NB>(address_of(sender))==1000000000,0);
        assert!(coin::balance<USDT>(address_of(sender))==1000000000,0);

        create_pool<NB,USDT>(sender);
        add_liquiduty<NB,USDT>(sender,1000000,1000000);

        assert!(coin::balance<NB>(address_of(sender))==1000000000 - 1000000,0);
        assert!(coin::balance<USDT>(address_of(sender))==1000000000 - 1000000,0);
        assert!(coin::balance<LP<NB,USDT>>(address_of(sender))== sqrt(1000000u128 * 1000000) - 1000,0);
    }

}
