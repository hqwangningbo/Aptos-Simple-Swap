module my_address::Coins{
    use aptos_framework::coin::{MintCapability, BurnCapability};
    use aptos_framework::coin;
    use std::string;
    use std::signer::address_of;
    #[test_only]
    use aptos_framework::account::create_account_for_test;

    struct NB {}
    struct USDT {}
    struct LP<phantom X,phantom Y>{}

    struct Caps<phantom CoinType> has key {
        mint:MintCapability<CoinType>,
        burn:BurnCapability<CoinType>
    }

    //issue
    public entry fun issue(sender:&signer){
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

        move_to(sender,Caps<NB>{
            mint:mint_nb,
            burn:burn_nb
        });

        move_to(sender,Caps<USDT>{
            mint:mint_usdt,
            burn:burn_usdt
        });

    }
    //mint
    public entry fun mint(sender:&signer) acquires Caps{
        let caps = borrow_global<Caps<NB>>(address_of(sender));
        let nb = coin::mint(1000000000,&caps.mint);
        coin::deposit(address_of(sender),nb);

        let caps = borrow_global<Caps<USDT>>(address_of(sender));
        let usdt = coin::mint(1000000000,&caps.mint);
        coin::deposit(address_of(sender),usdt);
    }

    #[test(sender=@my_address)]
    public fun test_should_work(sender:&signer) acquires Caps {
        create_account_for_test(@my_address);
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

}
