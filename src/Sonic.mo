// This is a generated Motoko binding.
// Please use `import service "ic:canister_id"` instead to call canisters on the IC if possible.

module {
    public type CanisterSettings = {
        freezing_threshold : ?Nat;
        controllers : ?[Principal];
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
    };
    public type CanisterStatus = {
        status : Status;
        memory_size : Nat;
        cycles : Nat;
        settings : CanisterSettings;
        module_hash : ?[Nat8];
    };
    public type CapDetails = {
        CapV2RootBucketId : ?Text;
        CapV1Status : Bool;
        CapV2Status : Bool;
        CapV1RootBucketId : ?Text;
    };
    public type DepositSubAccounts = {
        depositAId : Text;
        subaccount : [Nat8];
        created_at : Time;
        transactionOwner : Principal;
    };
    public type ICRC1SubAccountBalance = { #ok : Nat; #err : Text };
    public type ICRCTxReceipt = { #Ok : [Nat8]; #Err : Text };
    public type MonitorMetrics = {
        tokenBalancesSize : Nat;
        canisterStatus : CanisterStatus;
        blocklistedUsersCount : Nat;
        rewardTokensSize : Nat;
        lptokensSize : Nat;
        cycles : Nat;
        tokenAllowanceSize : Nat;
        rewardInfo : Nat;
        lpTokenAllowanceSize : Nat;
        rewardPairsSize : Nat;
        tokenCount : Nat;
        lpTokenBalancesSize : Nat;
        pairsCount : Nat;
        depositTransactionSize : Nat;
    };
    public type PairInfoExt = {
        id : Text;
        price0CumulativeLast : Nat;
        creator : Principal;
        reserve0 : Nat;
        reserve1 : Nat;
        lptoken : Text;
        totalSupply : Nat;
        token0 : Text;
        token1 : Text;
        price1CumulativeLast : Nat;
        kLast : Nat;
        blockTimestampLast : Int;
    };
    public type Result = { #ok : Bool; #err : Text };
    public type Result_1 = { #ok : (Nat, Nat); #err : Text };
    public type RewardInfo = { tokenId : Text; amount : Nat };
    public type Status = { #stopped; #stopping; #running };
    public type SwapInfo = {
        owner : Principal;
        cycles : Nat;
        tokens : [TokenInfoExt];
        pairs : [PairInfoExt];
        feeOn : Bool;
        feeTo : Principal;
    };
    public type SwapInfoExt = {
        owner : Principal;
        txcounter : Nat;
        depositCounter : Nat;
        feeOn : Bool;
        feeTo : Principal;
    };
    public type SwapLastTransaction = {
        #RemoveLiquidityOutAmount : (Nat, Nat);
        #SwapOutAmount : Nat;
        #NotFound : Bool;
    };
    public type Time = Int;
    public type TokenAnalyticsInfo = {
        fee : Nat;
        decimals : Nat8;
        name : Text;
        totalSupply : Nat;
        symbol : Text;
    };
    public type TokenBlockType = { #Full : Bool; #None : Bool; #Partial : Bool };
    public type TokenInfoExt = {
        id : Text;
        fee : Nat;
        decimals : Nat8;
        name : Text;
        totalSupply : Nat;
        symbol : Text;
    };
    public type TokenInfoWithType = {
        id : Text;
        fee : Nat;
        decimals : Nat8;
        name : Text;
        totalSupply : Nat;
        blockStatus : Text;
        tokenType : Text;
        symbol : Text;
    };
    public type TxReceipt = { #ok : Nat; #err : Text };
    public type UserInfo = {
        lpBalances : [(Text, Nat)];
        balances : [(Text, Nat)];
    };
    public type UserInfoPage = {
        lpBalances : ([(Text, Nat)], Nat);
        balances : ([(Text, Nat)], Nat);
    };
    public type ValidateFunctionReturnType = { #Ok : Text; #Err : Text };
    public type WithdrawRefundReceipt = { #Ok : Bool; #Err : Text };
    public type WithdrawState = {
        tokenId : Text;
        refundStatus : Bool;
        value : Nat;
        userPId : Principal;
    };
    public type Self = actor {
        addAuth : shared Principal -> async Bool;
        addLiquidity : shared (
            Principal,
            Principal,
            Nat,
            Nat,
            Nat,
            Nat,
            Int,
        ) -> async TxReceipt;
        addLiquidityForUser : shared (
            Principal,
            Principal,
            Principal,
            Nat,
            Nat,
            Bool,
        ) -> async TxReceipt;
        addLiquidityForUserTest : shared (
            Principal,
            Principal,
            Principal,
            Nat,
            Nat,
        ) -> async Text;
        addNatLabsToken : shared Text -> async Bool;
        addToken : shared (Principal, Text) -> async TxReceipt;
        addTokenToBlocklist : shared (Principal, TokenBlockType) -> async Bool;
        addTokenToBlocklistValidate : shared (
            Principal,
            TokenBlockType,
        ) -> async ValidateFunctionReturnType;
        addTokenValidate : shared (
            Principal,
            Text,
        ) -> async ValidateFunctionReturnType;
        addUserToBlocklist : shared Principal -> async Bool;
        allowance : shared query (Text, Principal, Principal) -> async Nat;
        approve : shared (Text, Principal, Nat) -> async Bool;
        balanceOf : shared query (Text, Principal) -> async Nat;
        burn : shared (Text, Nat) -> async Bool;
        createPair : shared (Principal, Principal) -> async TxReceipt;
        decimals : shared query Text -> async Nat8;
        deposit : shared (Principal, Nat) -> async TxReceipt;
        depositTo : shared (Principal, Principal, Nat) -> async TxReceipt;
        executeFundRecoveryForUser : shared Principal -> async TxReceipt;
        exportBalances : shared query Text -> async ?[(Principal, Nat)];
        exportFaileWithdraws : shared query () -> async [(Text, WithdrawState)];
        exportLPTokens : shared query () -> async [TokenInfoExt];
        exportPairs : shared query () -> async [PairInfoExt];
        exportRewardInfo : shared query () -> async [(Principal, [RewardInfo])];
        exportRewardPairs : shared query () -> async [PairInfoExt];
        exportSubAccounts : shared query () -> async [(Principal, DepositSubAccounts)];
        exportSwapInfo : shared query () -> async SwapInfoExt;
        exportTokenTypes : shared query () -> async [(Text, Text)];
        exportTokens : shared query () -> async [TokenInfoExt];
        failedWithdrawRefund : shared Text -> async WithdrawRefundReceipt;
        getAllPairs : shared query () -> async [PairInfoExt];
        getAllRewardPairs : shared query () -> async [PairInfoExt];
        getAuthList : shared query () -> async [(Principal, Bool)];
        getBlockedTokens : shared () -> async [(Principal, TokenBlockType)];
        getBlocklistedUsers : shared () -> async [(Principal, Bool)];
        getCapDetails : shared query () -> async CapDetails;
        getHolders : shared query Text -> async Nat;
        getICRC1SubAccountBalance : shared (
            Principal,
            Text,
        ) -> async ICRC1SubAccountBalance;
        getLPTokenId : shared query (Principal, Principal) -> async Text;
        getLastTransactionOutAmount : shared query () -> async SwapLastTransaction;
        getNatLabsToken : shared () -> async [(Text, Bool)];
        getNumPairs : shared query () -> async Nat;
        getPair : shared query (Principal, Principal) -> async ?PairInfoExt;
        getPairs : shared query (Nat, Nat) -> async ([PairInfoExt], Nat);
        getSupportedTokenList : shared query () -> async [TokenInfoWithType];
        getSupportedTokenListByName : shared query (Text, Nat, Nat) -> async (
            [TokenInfoExt],
            Nat,
        );
        getSupportedTokenListSome : shared query (Nat, Nat) -> async (
            [TokenInfoExt],
            Nat,
        );
        getSwapInfo : shared query () -> async SwapInfo;
        getTokenMetadata : shared query Text -> async TokenAnalyticsInfo;
        getUserBalances : shared query Principal -> async [(Text, Nat)];
        getUserICRC1SubAccount : shared Principal -> async Text;
        getUserInfo : shared query Principal -> async UserInfo;
        getUserInfoAbove : shared query (Principal, Nat, Nat) -> async UserInfo;
        getUserInfoByNamePageAbove : shared query (
            Principal,
            Int,
            Text,
            Nat,
            Nat,
            Int,
            Text,
            Nat,
            Nat,
        ) -> async UserInfoPage;
        getUserLPBalances : shared query Principal -> async [(Text, Nat)];
        getUserLPBalancesAbove : shared query (Principal, Nat) -> async [(Text, Nat)];
        getUserReward : shared query (Principal, Text, Text) -> async Result_1;
        historySize : shared query () -> async Nat;
        initiateICRC1Transfer : shared () -> async [Nat8];
        initiateICRC1TransferForUser : shared Principal -> async ICRCTxReceipt;
        monitorMetrics : shared () -> async MonitorMetrics;
        name : shared query Text -> async Text;
        registerFundRecoveryForUser : shared (
            Principal,
            Principal,
            Nat,
        ) -> async TxReceipt;
        removeAuth : shared Principal -> async Bool;
        removeLiquidity : shared (
            Principal,
            Principal,
            Nat,
            Nat,
            Nat,
            Principal,
            Int,
        ) -> async TxReceipt;
        removeNatLabsToken : shared Text -> async Bool;
        removeTokenFromBlocklist : shared Principal -> async Bool;
        removeTokenFromBlocklistValidate : shared Principal -> async ValidateFunctionReturnType;
        removeUserFromBlocklist : shared Principal -> async Bool;
        retryDeposit : shared Principal -> async TxReceipt;
        retryDepositTo : shared (Principal, Principal, Nat) -> async TxReceipt;
        setCapV1EnableStatus : shared Bool -> async Bool;
        setCapV2CanisterId : shared Text -> async Bool;
        setCapV2EnableStatus : shared Bool -> async Result;
        setFeeForToken : shared (Text, Nat) -> async Bool;
        setFeeOn : shared Bool -> async Bool;
        setFeeTo : shared Principal -> async Bool;
        setGlobalTokenFee : shared Nat -> async Bool;
        setMaxTokenValidate : shared Nat -> async ValidateFunctionReturnType;
        setMaxTokens : shared Nat -> async Bool;
        setOwner : shared Principal -> async Bool;
        swapExactTokensForTokens : shared (
            Nat,
            Nat,
            [Text],
            Principal,
            Int,
        ) -> async TxReceipt;
        symbol : shared query Text -> async Text;
        totalSupply : shared query Text -> async Nat;
        transferFrom : shared (Text, Principal, Principal, Nat) -> async Bool;
        updateAllTokenMetadata : shared () -> async Bool;
        updateTokenFees : shared () -> async Bool;
        updateTokenMetadata : shared Text -> async Bool;
        updateTokenType : shared (Principal, Text) -> async Bool;
        updateTokenTypeValidate : shared (
            Principal,
            Text,
        ) -> async ValidateFunctionReturnType;
        validateExecuteFundRecoveryForUser : shared Principal -> async ValidateFunctionReturnType;
        validateRegisterFundRecoveryForUser : shared (
            Principal,
            Principal,
            Nat,
        ) -> async ValidateFunctionReturnType;
        withdraw : shared (Principal, Nat) -> async TxReceipt;
    };
};
