module my_addr::WillTestament {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing a digital will and testament
    struct Will has store, key {
        testator: address,           // The person who created the will
        beneficiary: address,        // The person who will inherit the assets
        inheritance_amount: u64,     // Amount of tokens to be inherited
        unlock_timestamp: u64,       // Timestamp when inheritance can be claimed
        is_claimed: bool,           // Whether the inheritance has been claimed
    }

    /// Error codes
    const E_WILL_ALREADY_EXISTS: u64 = 1;
    const E_WILL_NOT_FOUND: u64 = 2;
    const E_NOT_AUTHORIZED: u64 = 3;
    const E_INHERITANCE_NOT_READY: u64 = 4;
    const E_ALREADY_CLAIMED: u64 = 5;
    const E_INSUFFICIENT_FUNDS: u64 = 6;

    /// Function to create a new will with specified beneficiary and unlock time
    public fun create_will(
        testator: &signer, 
        beneficiary: address, 
        inheritance_amount: u64, 
        unlock_delay_seconds: u64
    ) {
        let testator_addr = signer::address_of(testator);
        
        // Ensure testator has enough funds
        assert!(coin::balance<AptosCoin>(testator_addr) >= inheritance_amount, E_INSUFFICIENT_FUNDS);
        
        // Calculate unlock timestamp
        let current_time = timestamp::now_seconds();
        let unlock_time = current_time + unlock_delay_seconds;
        
        // Create the will
        let will = Will {
            testator: testator_addr,
            beneficiary,
            inheritance_amount,
            unlock_timestamp: unlock_time,
            is_claimed: false,
        };
        
        // Lock the inheritance funds by withdrawing from testator
        let inheritance_funds = coin::withdraw<AptosCoin>(testator, inheritance_amount);
        coin::deposit<AptosCoin>(testator_addr, inheritance_funds);
        
        move_to(testator, will);
    }

    /// Function for beneficiary to claim inheritance after unlock time
    public fun claim_inheritance(beneficiary: &signer, testator_address: address) acquires Will {
        let beneficiary_addr = signer::address_of(beneficiary);
        let will = borrow_global_mut<Will>(testator_address);
        
        // Verify beneficiary is authorized
        assert!(will.beneficiary == beneficiary_addr, E_NOT_AUTHORIZED);
        
        // Check if inheritance period has started
        let current_time = timestamp::now_seconds();
        assert!(current_time >= will.unlock_timestamp, E_INHERITANCE_NOT_READY);
        
        // Check if already claimed
        assert!(!will.is_claimed, E_ALREADY_CLAIMED);

        
        // Mark as claimed
        will.is_claimed = true;
    }
}