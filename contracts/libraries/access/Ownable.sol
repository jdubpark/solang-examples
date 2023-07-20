import 'solana';

contract Ownable {
    address public owner;

    /// NOTE Solang does not support `msg.sender` as SVM does not support the concept.
    ///       
    ///       Refer to https://solang.readthedocs.io/en/v0.3.1/targets/solana.html#msg-sender-solana.
    ///	
    modifier onlyOwner() {
        for (uint64 i = 0; i < tx.accounts.length; i++) {
            AccountInfo acctInfo = tx.accounts[i];

            if (acctInfo.key == owner && acctInfo.is_signer) {
                _;
                return;
            }
        }

        print("Not signed by authority");
        revert();
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function setOwner(address _owner) onlyOwner public {
        owner = _owner;
    }
}