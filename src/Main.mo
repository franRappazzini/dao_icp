import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Error "mo:base/Error";
import ICRaw "mo:base/ExperimentalInternetComputer";
import List "mo:base/List";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import TrieMap "mo:base/TrieMap";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Debug "mo:base/Debug";
import Nat8 "mo:base/Nat8";
import Types "./Types";
import ICRC "./ICRC";
import Sonic "./Sonic";

shared actor class BOXDAO(init : Types.BasicDaoStableStorage) = Self {
    stable var accounts = Types.accounts_fromArray(init.accounts);
    stable var proposals = Types.proposals_fromArray(init.proposals);
    stable var next_proposal_id : Nat = 0;
    // stable var system_params : Types.SystemParams = init.system_params;
    stable var lastProposalsStable : [(Principal, Int)] = [];

    // set boxy token
    let box : ICRC.Actor = actor ("2vgyc-jqaaa-aaaao-a2gdq-cai"); // mainnet
    // let box : ICRC.Actor = actor ("bd3sg-teaaa-aaaaa-qaaba-cai"); // local
    let sonic : Sonic.Self = actor ("3xwpq-ziaaa-aaaah-qcn4a-cai"); //mainnet

    // on going tx
    let onGoingTx = TrieMap.TrieMap<Principal, Bool>(Principal.equal, Principal.hash);
    // last proposal per principal
    let lastProposals = TrieMap.TrieMap<Principal, Int>(Principal.equal, Principal.hash);

    system func heartbeat() : async () {
        await execute_accepted_proposals();
    };

    func account_get(id : Principal) : ?Types.Tokens = Trie.get(accounts, Types.account_key(id), Principal.equal);
    func account_put(id : Principal, tokens : Types.Tokens) {
        accounts := Trie.put(accounts, Types.account_key(id), Principal.equal, tokens).0;
    };
    func proposal_get(id : Nat) : ?Types.Proposal = Trie.get(proposals, Types.proposal_key(id), Nat.equal);
    func proposal_put(id : Nat, proposal : Types.Proposal) {
        proposals := Trie.put(proposals, Types.proposal_key(id), Nat.equal, proposal).0;
    };

    /// Transfer tokens from the caller's account to another account
    // public shared ({ caller }) func transfer(transfer : Types.TransferArgs) : async Types.Result<(), Text> {
    //     switch (account_get caller) {
    //         case null { #err "Caller needs an account to transfer funds" };
    //         case (?from_tokens) {
    //             let fee = system_params.transfer_fee.amount_e8s;
    //             let amount = transfer.amount.amount_e8s;
    //             if (from_tokens.amount_e8s < amount + fee) {
    //                 #err("Caller's account has insufficient funds to transfer " # debug_show (amount));
    //             } else {
    //                 let from_amount : Nat = from_tokens.amount_e8s - amount - fee;
    //                 account_put(caller, { amount_e8s = from_amount });
    //                 let to_amount = Option.get(account_get(transfer.to), Types.zeroToken).amount_e8s + amount;
    //                 account_put(transfer.to, { amount_e8s = to_amount });
    //                 #ok;
    //             };
    //         };
    //     };
    // };

    /// Return the account balance of the caller
    public query ({ caller }) func account_balance() : async Types.Tokens {
        Option.get(account_get(caller), Types.zeroToken);
    };

    /// Lists all accounts
    public query func list_accounts() : async [Types.Account] {
        Iter.toArray(
            Iter.map(
                Trie.iter(accounts),
                func((owner : Principal, tokens : Types.Tokens)) : Types.Account = {
                    owner;
                    tokens;
                },
            )
        );
    };

    /// Submit a proposal
    ///
    /// A proposal contains a canister ID, method name and method args. If enough users
    /// vote "yes" on the proposal, the given method will be called with the given method
    /// args on the given canister.
    public shared ({ caller }) func submit_proposal(payload : Types.ProposalPayload) : async Types.Result<Nat, Text> {
        // verify if caller is on going txs
        if (onGoingTx.get(caller) == ?true) return #err("You are on going tx.");
        // add caller on going txs
        onGoingTx.put(caller, true);

        // [x] During the first vote, we need to ensure that no one else can create a new proposal
        switch (proposal_get(0)) {
            case (null) {};
            case (?res) if (res.state == #open) {
                // remove caller from on going txs
                onGoingTx.delete(caller);
                return #err("The first proposal is open.");
            };
        };

        try {
            // calculate how many BOX are 1 ICP from Sonic Pool
            let pairInfo = await sonic.getPair(Principal.fromText("2vgyc-jqaaa-aaaao-a2gdq-cai"), Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai"));
            switch (pairInfo) {
                case (null) return #err("Sorry, we can't calculate the $BOX amount. Please, contact with the team.");
                case (?res) {
                    let price : Float = (Float.fromInt(res.reserve0) / Float.fromInt(res.reserve1)) * 100;
                    let parsedPrice : Nat = Int.abs(Float.toInt(price));
                    // let parsedPrice = 1825;

                    // let tx = await makeTx(caller, parsedPrice /* system_params.proposal_submission_deposit.amount_e8s */);
                    // verify if the user balance is enough
                    let balance = await box.icrc1_balance_of({
                        owner = caller;
                        subaccount = null;
                    });
                    Debug.print(debug_show caller);

                    let fee = await box.icrc1_fee();
                    let decimals = Nat8.toNat(await box.icrc1_decimals());

                    let amount = parsedPrice * (10 ** decimals);
                    Debug.print(debug_show (amount, fee, balance));

                    if ((amount + fee) > balance) {
                        // remove caller from on going txs
                        onGoingTx.delete(caller);
                        return #err("You don't have enough balance.");
                    };

                    // let approve = await box.icrc2_approve({
                    //     from_subaccount = null;
                    //     spender = {
                    //         owner = Principal.fromActor(Self);
                    //         subaccount = null;
                    //     };
                    //     amount = 1825 * 10 ** 6; // FIXME only necesary tokens
                    //     expected_allowance = null;
                    //     expires_at = null;
                    //     fee = null;
                    //     memo = null;
                    //     created_at_time = null;
                    // });

                    // Debug.print(debug_show ("aprover errror:", approve));
                    // switch (approve) {
                    //     case (#Ok(_)) {};
                    //     case (#Err(_)) {
                    //         // remove caller from on going txs
                    //         onGoingTx.delete(caller);
                    //         return #err("Approve error.");
                    //     };
                    // };

                    // [x] 2. verify last caller proposal
                    switch (lastProposals.get(caller)) {
                        case (null) lastProposals.put(caller, Time.now());
                        case (?res) {
                            let nanosecPerDay = 86_400_000_000_000;
                            let time = Time.now();
                            let timeParsed = time / nanosecPerDay;
                            let lastProposal = res / nanosecPerDay;

                            if (timeParsed == lastProposal) {
                                // remove caller from on going txs
                                onGoingTx.delete(caller);
                                return #err("You only can create 1 proposal per day.");
                            } else lastProposals.put(caller, time);
                        };
                    };

                    // deposit to create the proposal
                    let tx = await box.icrc2_transfer_from({
                        spender_subaccount = null;
                        from = { owner = caller; subaccount = null };
                        to = {
                            owner = Principal.fromActor(Self);
                            subaccount = null;
                        };
                        amount /*=  system_params.proposal_submission_deposit.amount_e8s */;
                        fee = ?fee;
                        memo = null;
                        created_at_time = null;
                    });

                    Debug.print(debug_show tx);

                    switch (tx) {
                        case (#Ok(nat)) { /* return #ok(nat) */ };
                        case (#Err(_)) {
                            // remove caller from on going txs
                            onGoingTx.delete(caller);
                            return #err("Tx error.");
                        };
                    };

                    // switch (tx) {
                    //     case (#ok) {};
                    //     case (#err(msg)) {
                    //         // remove caller from on going txs
                    //         onGoingTx.delete(caller);
                    //         return #err(msg);
                    //     };
                    // };

                    Result.chain(
                        // anyone can create a proposal
                        // deduct_proposal_submission_deposit(caller),
                        #ok,
                        func(()) : Types.Result<Nat, Text> {
                            let proposal_id = next_proposal_id;
                            next_proposal_id += 1;

                            let proposal : Types.Proposal = {
                                id = proposal_id;
                                timestamp = Time.now();
                                proposer = caller;
                                payload;
                                state = #open;
                                votes_yes = Types.zeroToken;
                                votes_no = Types.zeroToken;
                                voters = List.nil();
                            };
                            proposal_put(proposal_id, proposal);
                            // remove caller from on going txs
                            onGoingTx.delete(caller);
                            #ok(proposal_id);
                        },
                    );
                };
            };

        } catch (e) {
            // remove caller from on going txs
            onGoingTx.delete(caller);
            #err("Unexpected error." # Error.message(e));
        };
    };

    /// Return the proposal with the given ID, if one exists
    public query func get_proposal(proposal_id : Nat) : async ?Types.Proposal {
        proposal_get(proposal_id);
    };

    /// Return the list of all proposals
    public query func list_proposals() : async [Types.Proposal] {
        Iter.toArray(Iter.map(Trie.iter(proposals), func(kv : (Nat, Types.Proposal)) : Types.Proposal = kv.1));
    };

    // Vote on an open proposal
    public shared ({ caller }) func vote(args : Types.VoteArgs) : async Types.Result<Types.ProposalState, Text> {
        switch (proposal_get(args.proposal_id)) {
            case (null) #err("No proposal with ID " # debug_show (args.proposal_id) # " exists");
            case (?proposal) {
                // [x] 3. if you are the proposal creator you can't vote
                // if (proposal.proposer == caller) return #err("You are the proposal creator, you can't vote on them.");

                var state = proposal.state;
                if (state != #open) {
                    return #err("Proposal " # debug_show (args.proposal_id) # " is not open for voting");
                };

                if (List.some(proposal.voters, func(e : Principal) : Bool = e == caller)) return #err("Already voted");

                try {
                    // let tx = await makeTx(caller, system_params.proposal_vote_threshold.amount_e8s);
                    // switch (tx) {
                    //     case (#ok) {};
                    //     case (#err(msg)) return #err(msg);
                    // };

                    var votes_yes = proposal.votes_yes.amount_e8s;
                    var votes_no = proposal.votes_no.amount_e8s;
                    // TODO ver voting power
                    switch (args.vote) {
                        case (#yes) votes_yes += 1;
                        case (#no) votes_no += 1;
                    };
                    let voters = List.push(caller, proposal.voters);

                    let updated_proposal = {
                        id = proposal.id;
                        votes_yes = { amount_e8s = votes_yes };
                        votes_no = { amount_e8s = votes_no };
                        voters;
                        state;
                        timestamp = proposal.timestamp;
                        proposer = proposal.proposer;
                        payload = proposal.payload;
                    };
                    proposal_put(args.proposal_id, updated_proposal);

                } catch (e) {
                    return #err("Unexpected error." # Error.message(e));
                };

                #ok(state);

                // TODO ver de cambiar account_get
                // switch (account_get(caller)) {
                //     case null {
                //         return #err("Caller does not have any tokens to vote with");
                //     };
                //     case (?{ amount_e8s = voting_tokens }) {
                //         // if (List.some(proposal.voters, func(e : Principal) : Bool = e == caller)) {
                //         //     return #err("Already voted");
                //         // };

                //         var votes_yes = proposal.votes_yes.amount_e8s;
                //         var votes_no = proposal.votes_no.amount_e8s;
                //         switch (args.vote) {
                //             case (#yes) { votes_yes += voting_tokens };
                //             case (#no) { votes_no += voting_tokens };
                //         };
                //         let voters = List.push(caller, proposal.voters);

                //         // TODO sin sentido?
                //         // if (votes_yes >= system_params.proposal_vote_threshold.amount_e8s) {
                //         //     // Refund the proposal deposit when the proposal is accepted
                //         //     ignore do ? {
                //         //         let account = account_get(proposal.proposer)!;
                //         //         let refunded = account.amount_e8s + system_params.proposal_submission_deposit.amount_e8s;
                //         //         account_put(proposal.proposer, { amount_e8s = refunded });
                //         //     };
                //         //     state := #accepted;
                //         // };

                //         // if (votes_no >= system_params.proposal_vote_threshold.amount_e8s) {
                //         //     state := #rejected;
                //         // };

                //         let updated_proposal = {
                //             id = proposal.id;
                //             votes_yes = { amount_e8s = votes_yes };
                //             votes_no = { amount_e8s = votes_no };
                //             voters;
                //             state;
                //             timestamp = proposal.timestamp;
                //             proposer = proposal.proposer;
                //             payload = proposal.payload;
                //         };
                //         proposal_put(args.proposal_id, updated_proposal);
                //     };
                // };
            };
        };
    };

    /// Get the current system params
    // public query func get_system_params() : async Types.SystemParams {
    //     system_params;
    // };

    /// Update system params
    ///
    /// Only callable via proposal execution
    // public shared ({ caller }) func update_system_params(payload : Types.UpdateSystemParamsPayload) : async () {
    //     if (caller != Principal.fromActor(Self)) {
    //         return;
    //     };
    //     system_params := {
    //         transfer_fee = Option.get(payload.transfer_fee, system_params.transfer_fee);
    //         proposal_vote_threshold = Option.get(payload.proposal_vote_threshold, system_params.proposal_vote_threshold);
    //         proposal_submission_deposit = Option.get(payload.proposal_submission_deposit, system_params.proposal_submission_deposit);
    //     };
    // };

    /// Deduct the proposal submission deposit from the caller's account
    // func deduct_proposal_submission_deposit(caller : Principal) : Types.Result<(), Text> {
    //     switch (account_get(caller)) {
    //         case null {
    //             // remove caller from on going txs
    //             onGoingTx.delete(caller);
    //             #err "Caller needs an account to submit a proposal";
    //         };
    //         case (?from_tokens) {
    //             // let threshold = system_params.proposal_submission_deposit.amount_e8s;
    //             // if (from_tokens.amount_e8s < threshold) {
    //             //     // remove caller from on going txs
    //             //     onGoingTx.delete(caller);
    //             //     #err("Caller's account must have at least " # debug_show (threshold) # " to submit a proposal");
    //             // } else {
    //             //     let from_amount : Nat = from_tokens.amount_e8s - threshold;
    //             //     account_put(caller, { amount_e8s = from_amount });
    //             //     #ok;
    //             // };
    //             #ok();
    //         };
    //     };
    // };

    /// Execute all accepted proposals
    func execute_accepted_proposals() : async () {
        let accepted_proposals = Trie.filter(proposals, func(_ : Nat, proposal : Types.Proposal) : Bool = proposal.state == #accepted);
        // Update proposal state, so that it won't be picked up by the next heartbeat
        for ((id, proposal) in Trie.iter(accepted_proposals)) {
            update_proposal_state(proposal, #executing);
        };

        for ((id, proposal) in Trie.iter(accepted_proposals)) {
            // switch (await execute_proposal(proposal)) {
            //     case (#ok) { update_proposal_state(proposal, #succeeded) };
            //     case (#err(err)) {
            //         update_proposal_state(proposal, #failed(err));
            //     };
            // };
        };
    };

    /// Execute the given proposal
    // func execute_proposal(proposal : Types.Proposal) : async Types.Result<(), Text> {
    //     try {
    //         let payload = proposal.payload;
    //         ignore await ICRaw.call(payload.canister_id, payload.method, payload.message);
    //         #ok;
    //     } catch (e) { #err(Error.message e) };
    // };

    func update_proposal_state(proposal : Types.Proposal, state : Types.ProposalState) {
        let updated = {
            state;
            id = proposal.id;
            votes_yes = proposal.votes_yes;
            votes_no = proposal.votes_no;
            voters = proposal.voters;
            timestamp = proposal.timestamp;
            proposer = proposal.proposer;
            payload = proposal.payload;
        };
        proposal_put(proposal.id, updated);
    };

    func makeTx(caller : Principal, price : Nat) : async Types.Result<(), Text> {
        try {
            // verify if the user balance is enough
            let balance = await box.icrc1_balance_of({
                owner = caller;
                subaccount = null;
            });
            Debug.print(debug_show caller);

            let fee = await box.icrc1_fee();
            let decimals = Nat8.toNat(await box.icrc1_decimals());

            let amount = price * (10 ** decimals);
            Debug.print(debug_show (amount, fee, balance));

            if ((amount + fee) > balance) {
                // remove caller from on going txs
                onGoingTx.delete(caller);
                return #err("You don't have enough balance.");
            };

            let approve = await box.icrc2_approve({
                from_subaccount = null;
                spender = {
                    owner = Principal.fromActor(Self);
                    subaccount = null;
                };
                amount = balance; // FIXME only necesary tokens
                expected_allowance = null;
                expires_at = null;
                fee = null;
                memo = null;
                created_at_time = null;
            });

            Debug.print(debug_show (approve));
            switch (approve) {
                case (#Ok(_)) {};
                case (#Err(_)) {
                    // remove caller from on going txs
                    onGoingTx.delete(caller);
                    return #err("Approve error.");
                };
            };

            // [x] 2. verify last caller proposal
            switch (lastProposals.get(caller)) {
                case (null) lastProposals.put(caller, Time.now());
                case (?res) {
                    let nanosecPerDay = 86_400_000_000_000;
                    let time = Time.now();
                    let timeParsed = time / nanosecPerDay;
                    let lastProposal = res / nanosecPerDay;

                    if (timeParsed == lastProposal) {
                        // remove caller from on going txs
                        onGoingTx.delete(caller);
                        return #err("You only can create 1 proposal per day.");
                    } else lastProposals.put(caller, time);
                };
            };

            // deposit to create the proposal
            let tx = await box.icrc2_transfer_from({
                spender_subaccount = null;
                from = { owner = caller; subaccount = null };
                to = { owner = Principal.fromActor(Self); subaccount = null };
                amount /*=  system_params.proposal_submission_deposit.amount_e8s */;
                fee = ?fee;
                memo = null;
                created_at_time = null;
            });

            Debug.print(debug_show tx);

            switch (tx) {
                case (#Err(_)) {
                    // remove caller from on going txs
                    onGoingTx.delete(caller);
                    return #err("Tx error.");
                };
                case (#Ok(nat)) return #ok();
            };
        } catch (e) {
            // remove caller from on going txs
            onGoingTx.delete(caller);
            return #err("Unexpected error making tx." # Error.message(e));
        };
    };

    func verifyStatus(proposalId : Nat) : Types.Result<(), Text> {
        switch (Trie.get(proposals, Types.proposal_key(proposalId), Nat.equal)) {
            case (?proposal) {
                let nanosecPerDay = 86_400_000_000_000;
                let limitDate = proposal.timestamp + (3 * nanosecPerDay);

                if (proposal.state == #open and Time.now() > limitDate) {
                    let yes = proposal.votes_yes.amount_e8s;
                    let no = proposal.votes_no.amount_e8s;
                    if (yes > no) update_proposal_state(proposal, #succeeded) else update_proposal_state(proposal, #rejected);
                    return #err("Proposal is finished.");
                };
                #ok();
            };
            case (null) #ok();
        };
    };

    // ---- SYSTEM FUNCTIONS ----
    system func preupgrade() {
        lastProposalsStable := Iter.toArray(lastProposals.entries());
    };

    system func postupgrade() {
        for ((key, val) in lastProposalsStable.vals()) {
            lastProposals.put(key, val);
        };
    };
};
