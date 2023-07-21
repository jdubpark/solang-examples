import 'solana';
import {ERC20Like} from '../../libraries/token/ERC20Like.sol';

@program_id("CR3JGL7NVpm9Y7ohEHw92x3SPseMvPwgx1oviu5ixJKv")

contract BasicToken is ERC20Like {
    @payer(payer)
    constructor(address owner, address mintAddress, uint8 _decimals) ERC20Like(owner, mintAddress, _decimals) {}

    function mintTo(address to, uint64 amount) onlyOwner public {
        super._mintTo(to, amount);
    }

    function burn(address from, uint64 amount) public addressNeedsToSign(from) {
        super._burn(from, amount);
    }
}

