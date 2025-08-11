module hrithvika_addr::TokenAllowance {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::table::{Self, Table};

    
    struct AllowanceStore has store, key {
        allowances: Table<address, u64>,  
    }

    
    const E_INSUFFICIENT_ALLOWANCE: u64 = 1;
    const E_ALLOWANCE_STORE_NOT_FOUND: u64 = 2;

   
    public fun approve(owner: &signer, spender: address, amount: u64) acquires AllowanceStore {
        let owner_addr = signer::address_of(owner);
        
        if (!exists<AllowanceStore>(owner_addr)) {
            let allowance_store = AllowanceStore {
                allowances: table::new(),
            };
            move_to(owner, allowance_store);
        };

        
        let allowance_store = borrow_global_mut<AllowanceStore>(owner_addr);
        if (table::contains(&allowance_store.allowances, spender)) {
            *table::borrow_mut(&mut allowance_store.allowances, spender) = amount;
        } else {
            table::add(&mut allowance_store.allowances, spender, amount);
        };
    }

    
    public fun transfer_from(spender: &signer, from: address, to: address, amount: u64) acquires AllowanceStore {
        let spender_addr = signer::address_of(spender);
        
       
        assert!(exists<AllowanceStore>(from), E_ALLOWANCE_STORE_NOT_FOUND);
        
        let allowance_store = borrow_global_mut<AllowanceStore>(from);
        
        
        assert!(table::contains(&allowance_store.allowances, spender_addr), E_INSUFFICIENT_ALLOWANCE);
        let current_allowance = *table::borrow(&allowance_store.allowances, spender_addr);
        assert!(current_allowance >= amount, E_INSUFFICIENT_ALLOWANCE);

       
        let coins = coin::withdraw<AptosCoin>(spender, amount);
        coin::deposit<AptosCoin>(to, coins);

        
        *table::borrow_mut(&mut allowance_store.allowances, spender_addr) = current_allowance - amount;
    }

}
