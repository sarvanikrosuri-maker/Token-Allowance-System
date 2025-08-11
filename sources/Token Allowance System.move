module hrithvika_addr::TokenAllowance {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::table::{Self, Table};

    /// Struct to store allowances for delegated transfers
    struct AllowanceStore has store, key {
        allowances: Table<address, u64>,  // Maps spender address to allowed amount
    }

    /// Error codes
    const E_INSUFFICIENT_ALLOWANCE: u64 = 1;
    const E_ALLOWANCE_STORE_NOT_FOUND: u64 = 2;

    /// Function to approve a spender to transfer tokens on behalf of the owner
    /// @param owner: The account that owns the tokens
    /// @param spender: The account that will be allowed to spend tokens
    /// @param amount: The maximum amount the spender can transfer
    public fun approve(owner: &signer, spender: address, amount: u64) acquires AllowanceStore {
        let owner_addr = signer::address_of(owner);
        
        // Check if AllowanceStore exists for the owner, if not create it
        if (!exists<AllowanceStore>(owner_addr)) {
            let allowance_store = AllowanceStore {
                allowances: table::new(),
            };
            move_to(owner, allowance_store);
        };

        // Update or set the allowance
        let allowance_store = borrow_global_mut<AllowanceStore>(owner_addr);
        if (table::contains(&allowance_store.allowances, spender)) {
            *table::borrow_mut(&mut allowance_store.allowances, spender) = amount;
        } else {
            table::add(&mut allowance_store.allowances, spender, amount);
        };
    }

    /// Function to transfer tokens from owner to recipient using allowance
    /// @param spender: The account spending the tokens (must have allowance)
    /// @param from: The token owner's address
    /// @param to: The recipient's address
    /// @param amount: The amount to transfer
    public fun transfer_from(spender: &signer, from: address, to: address, amount: u64) acquires AllowanceStore {
        let spender_addr = signer::address_of(spender);
        
        // Check if AllowanceStore exists
        assert!(exists<AllowanceStore>(from), E_ALLOWANCE_STORE_NOT_FOUND);
        
        let allowance_store = borrow_global_mut<AllowanceStore>(from);
        
        // Check if spender has sufficient allowance
        assert!(table::contains(&allowance_store.allowances, spender_addr), E_INSUFFICIENT_ALLOWANCE);
        let current_allowance = *table::borrow(&allowance_store.allowances, spender_addr);
        assert!(current_allowance >= amount, E_INSUFFICIENT_ALLOWANCE);

        // Perform the transfer
        let coins = coin::withdraw<AptosCoin>(spender, amount);
        coin::deposit<AptosCoin>(to, coins);

        // Update the allowance
        *table::borrow_mut(&mut allowance_store.allowances, spender_addr) = current_allowance - amount;
    }
}