import 'solana';

import {ERC20Like} from '../../libraries/token/ERC20Like.sol';

/// NOTE Basic ERC-20-like token on Solana! Run the tests in `tests/src/token` using `yarn test:basic_token`.
@program_id("CR3JGL7NVpm9Y7ohEHw92x3SPseMvPwgx1oviu5ixJKv")
contract BasicToken is ERC20Like {
    /// NOTE Assigning the `mint` address binds this contract to a specific mint forever.
    ///      This is by design — deploy a new contract for a different mint.
    @payer(payer)
    constructor(address owner, address mintAddress, uint64 lamports, uint8 _decimals) ERC20Like(owner, mintAddress, lamports, _decimals) {}

    function mintTo(address to, uint64 amount) onlyOwner public {
        super._mintTo(to, amount);
    }

    function burn(address from, uint64 amount) public {
        bool isCallerSigned = false;
        for (uint64 i = 0; i < tx.accounts.length; i++) {
            AccountInfo acctInfo = tx.accounts[i];
            if (acctInfo.key == from && acctInfo.is_signer) {
                isCallerSigned = true;
                break;
            }
        }
        require(isCallerSigned, "Only burner can burn their token");

        super._burn(from, amount);
    }
}

