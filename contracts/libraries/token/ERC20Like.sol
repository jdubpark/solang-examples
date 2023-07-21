// SPDX-License-Identifier: Apache-2.0

// Disclaimer: This library provides a way for Solidity to interact with Solana's SPL-Token. Although it is production ready,
// it has not been audited for security, so use it at your own risk.

import 'solana';

import {Ownable} from '../access/Ownable.sol';
import {IERC20Like} from './IERC20Like.sol';
import '../solana-library/system_instruction.sol';

contract ERC20Like is IERC20Like, Ownable {
	address public mint;
	address constant TOKEN_PROGRAM_ID = address"TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA";
	address constant ASSOCIATED_TOKEN_PROGRAM_ID = address"ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL";
	uint64 constant MINT_SIZE = 82; // Size of MintAccountData, which is 4+32+8+1+1+4+32 = 82 bytes
	uint64 constant MINT_LAMPORTS = 1461600; // Rent-exempt minimum lamports required for 82 bytes

	enum TokenInstruction {
		InitializeMint, // 0
		InitializeAccount, // 1
		InitializeMultisig, // 2
		Transfer, // 3
		Approve, // 4
		Revoke, // 5
		SetAuthority, // 6
		MintTo, // 7
		Burn, // 8
		CloseAccount, // 9
		FreezeAccount, // 10
		ThawAccount, // 11
		TransferChecked, // 12
		ApproveChecked, // 13
		MintToChecked, // 14
		BurnChecked, // 15
		InitializeAccount2, // 16
		SyncNative, // 17
		InitializeAccount3, // 18
		InitializeMultisig2, // 19
		InitializeMint2, // 20
		GetAccountDataSize, // 21
		InitializeImmutableOwner, // 22
		AmountToUiAmount, // 23
		UiAmountToAmount, // 24
		InitializeMintCloseAuthority, // 25
		TransferFeeExtension, // 26
		ConfidentialTransferExtension, // 27
		DefaultAccountStateExtension, // 28
		Reallocate, // 29
		MemoTransferExtension, // 30
		CreateNativeMint // 31
	}

	///	NOTE Requires `owner` and `mintAddress` as signers.
	///
	/// ACCOUNT owner {signer} The owner account to pay for the transactions and be the token mint authority.
	/// ACCOUNT mintAddress {signer} The mint account key to be created & initialize as Mint.
	///
	constructor(address owner, address mintAddress, uint8 _decimals) Ownable(owner) {
		// TODO: check here that `owner` and `mintAddress` are included in tx.accounts & have `is_signer = true`
		//
		// Create an account for the token mint at the address `mintAddress`
		//

		mint = mintAddress; // save as the mint address
		SystemInstruction.create_account(owner, mintAddress, MINT_LAMPORTS, MINT_SIZE, TOKEN_PROGRAM_ID);

		//
		// Initialize the token mint at the address `mintAddress`
		//

		bytes instr = new bytes(67);
		instr[0] = uint8(TokenInstruction.InitializeMint2);
		instr[1] = _decimals; // 1 byte
		instr.writeAddress(owner, 2); // Mint Authority (32 bytes)
		instr[34] = 0; // Freeze Authority COPtion = 0 (1 byte)
		instr.writeAddress(address(0), 35); // Freeze Authority = null (32 bytes)

		AccountMeta[1] metas = [
			AccountMeta({pubkey: mintAddress, is_writable: true, is_signer: true})
		];

		TOKEN_PROGRAM_ID.call{accounts: metas}(instr);
	}

	modifier addressNeedsToSign(address user) {
		for (uint64 i = 0; i < tx.accounts.length; i++) {
			AccountInfo acctInfo = tx.accounts[i];
			if (acctInfo.key == user && acctInfo.is_signer) {
				_;
				return;
			}
		}

		revert("address is not signer");
	}

	/// NOTE Mint new tokens. The transaction should be signed by the mint authority keypair.
	///       Wrapper for https://github.com/solana-labs/solana-program-library/blob/master/token/program/src/processor.rs#L517
	///
	/// ACCOUNT mint_account {writable} This token account holding the Mint info.
	/// ACCOUNT to_user_account {writable} The receiver's ATA. Derived from `to` param.
	/// ACCOUNT owner_account {writable, signer} Owner account of this token account.
	///
	/// @param to the receiver's address (not the ATA)
	/// @param amount the amount of tokens to mint
	function _mintTo(address to, uint64 amount) internal {
		address toUserAta = _getAssociatedTokenAddress(to);

		bytes instr = new bytes(9);
		instr[0] = uint8(TokenInstruction.MintTo);
		instr.writeUint64LE(amount, 1);

		AccountMeta[3] metas = [
			AccountMeta({pubkey: mint, is_writable: true, is_signer: false}),
			AccountMeta({pubkey: toUserAta, is_writable: true, is_signer: false}),
			AccountMeta({pubkey: owner, is_writable: true, is_signer: true}) // owner of this token contract has to sign the mint tx
		];

		TOKEN_PROGRAM_ID.call{accounts: metas}(instr);
	}

	/// Transfer @amount token from @from to @to. The transaction should be signed by the owner
	/// keypair of the from account.
	///
	///	ACCOUNT from_user_ata {writable} The sender's ATA. Derived from `from` param.
	///	ACCOUNT to_user_ata {writable} The receiver's ATA. Derived from `to` param.
	///	ACCOUNT from {writable, signer} Owner account of the from_user_ata.
	///
	/// @param from the sender's address (not the ATA)
	/// @param to the receiver's address (not the ATA)
	/// @param amount the amount to transfer
	function transfer(address from, address to, uint64 amount) public {
		address fromUserAta = _getAssociatedTokenAddress(from);
		address toUserAta = _getAssociatedTokenAddress(to);

		bytes instr = new bytes(9);
		instr[0] = uint8(TokenInstruction.Transfer);
		instr.writeUint64LE(amount, 1);

		AccountMeta[3] metas = [
			AccountMeta({pubkey: fromUserAta, is_writable: true, is_signer: false}), // sender's ATA
			AccountMeta({pubkey: toUserAta, is_writable: true, is_signer: false}), // receiver's ATA
			AccountMeta({pubkey: from, is_writable: true, is_signer: true}) // sender has to sign the transfer tx
		];

		TOKEN_PROGRAM_ID.call{accounts: metas}(instr);
	}

	/// NOTE Burn @amount tokens in account. This transaction should be signed by the owner.
	///		    Wrapper for https://github.com/solana-labs/solana-program-library/blob/master/token/program/src/processor.rs#L580
	///
	///	ACCOUNT from_user_ata {writable} The burner's ATA. Derived from `from` param.
	///
	/// @param from the burner's address (tokens burned from its ATA)
	/// @param amount the amount to transfer
	function _burn(address from, uint64 amount) internal {
		address fromUserAta = _getAssociatedTokenAddress(from);

		bytes instr = new bytes(9);
		instr[0] = uint8(TokenInstruction.Burn);
		instr.writeUint64LE(amount, 1);

		AccountMeta[3] metas = [
			AccountMeta({pubkey: fromUserAta, is_writable: true, is_signer: false}), // burner's ATA
			AccountMeta({pubkey: mint, is_writable: true, is_signer: false}),
			AccountMeta({pubkey: from, is_writable: true, is_signer: true}) // burner has to sign the burn tx
		];

		TOKEN_PROGRAM_ID.call{accounts: metas}(instr);
	}

	/// NOTE Approve an amount to a delegate. This transaction should be signed by the owner.
	///		  Wrapper for https://github.com/solana-labs/solana-program-library/blob/master/token/program/src/processor.rs#L580
	///
	///	ACCOUNT spender_user_ata {writable} The approver's ATA. Derived from `spender` param.
	/// ACCOUNT delegate_user_ata {writable} The delegate's ATA. Derived from `delegate` param.
	/// ACCOUNT spender {writable, signer} Owner account of the spender_user_ata.
	///
	/// @param spender the approver's address (not the ATA)
	/// @param delegate the delegate's address (not the ATA)
	/// @param amount the amount to approve
	function approve(address spender, address delegate, uint64 amount) public {
		address spenderUserAta = _getAssociatedTokenAddress(spender);
		address delegateUserAta = _getAssociatedTokenAddress(delegate);

		bytes instr = new bytes(9);
		instr[0] = uint8(TokenInstruction.Approve);
		instr.writeUint64LE(amount, 1);

		AccountMeta[3] metas = [
			AccountMeta({pubkey: spenderUserAta, is_writable: true, is_signer: false}), // approver's ATA
			AccountMeta({pubkey: delegateUserAta, is_writable: false, is_signer: false}), // delegate's ATA
			AccountMeta({pubkey: spender, is_writable: false, is_signer: true}) // approver has to sign the approve tx
		];

		TOKEN_PROGRAM_ID.call{accounts: metas}(instr);
	}

	/// NOTE Revoke a previously approved delegate. This transaction should be signed by the owner. After
	/// 	  this transaction, no delgate is approved for any amount.
	/// 	  Wrapper for https://github.com/solana-labs/solana-program-library/blob/master/token/program/src/processor.rs#L580
	///
	/// ACCOUNT from_user_ata {writable} The approver's ATA. Derived from `from` param.
	/// ACCOUNT from {writable, signer} Owner account of the from_user_ata.
	///
	/// @param from the account for which a delegate should be approved
	function _revoke(address from) internal {
		address fromUserAta = _getAssociatedTokenAddress(from);

		bytes instr = new bytes(1);
		instr[0] = uint8(TokenInstruction.Revoke);

		AccountMeta[2] metas = [
			AccountMeta({pubkey: fromUserAta, is_writable: true, is_signer: false}), // from's ATA
			AccountMeta({pubkey: from, is_writable: false, is_signer: true}) // from has to sign the revoke tx
		];

		TOKEN_PROGRAM_ID.call{accounts: metas}(instr);
	}

	/// Get the total supply for the mint, i.e. the total amount in circulation
	///
	/// ACCOUNT mint_account {} This token account holding the Mint info.
	function totalSupply() public view returns (uint64) {
		AccountInfo acctInfo = _getAccountInfo(mint);
		return acctInfo.data.readUint64LE(36); // read supply from offset 36
	}

	/// Get the balance for a user account.
	///
	/// ACCOUNT associated_token_account {} The user's ATA. Derived from `user` param.
	///
	/// @param user The user's address (not the ATA)
	function balanceOf(address user) public view returns (uint64) {
		address userATA = _getAssociatedTokenAddress(user);
		AccountInfo acctInfo = _getAccountInfo(userATA);
		return acctInfo.data.readUint64LE(64);
	}

	function decimals() public view returns (uint8) {
		AccountInfo acctInfo = _getAccountInfo(mint);
		return uint8(acctInfo.data[44]);
	}

	function getMint() public view returns (address) {
		return mint;
	}

	/// Get the account info for an account. This walks the transaction account infos
	/// and find the account info, or the transaction fails.
	///
	/// @param account the account for which we want to have the acount info.
	function _getAccountInfo(address account) internal view returns (AccountInfo) {
		for (uint64 i = 0; i < tx.accounts.length; i++) {
			AccountInfo acctInfo = tx.accounts[i];
			if (acctInfo.key == account) {
				return acctInfo;
			}
		}

		revert("account missing");
	}

	/// This enum represents the state of a token account
	enum AccountState {
		Uninitialized,
		Initialized,
		Frozen
	}

	/// This struct is the return of 'getTokenAccountData'
	struct TokenAccountData {
		address mintAccount;
		address owner;
		uint64 balance;
		bool delegate_present;
		address delegate;
		AccountState state;
		bool is_native_present;
		uint64 is_native;
		uint64 delegated_amount;
		bool close_authority_present;
		address close_authority;
	}

	/// Fetch the owner, mint account and balance for an associated token account.
	///
	/// ACCOUNT tokenAccount {} A user's ATA holding the user's token info (of a particular token mint).
	///
	/// @param tokenAccount The token account
	/// @return struct TokenAccountData
	function getTokenAccountData(address tokenAccount) public view returns (TokenAccountData) {
		AccountInfo ai = _getAccountInfo(tokenAccount);

		TokenAccountData data = TokenAccountData(
			{
				mintAccount: ai.data.readAddress(0), 
				owner: ai.data.readAddress(32),
			 	balance: ai.data.readUint64LE(64),
				delegate_present: ai.data.readUint32LE(72) > 0,
				delegate: ai.data.readAddress(76),
				state: AccountState(ai.data[108]),
				is_native_present: ai.data.readUint32LE(109) > 0,
				is_native: ai.data.readUint64LE(113),
				delegated_amount: ai.data.readUint64LE(121),
				close_authority_present: ai.data.readUint32LE(129) > 10,
				close_authority: ai.data.readAddress(133)
			}
		);

		return data;
	}

	// This struct is the return of 'getMintAccountData'
	struct MintAccountData {
		bool authority_present;
		address mint_authority;
		uint64 supply;
		uint8 decimals;
		bool is_initialized;
		bool freeze_authority_present;
		address freeze_authority;
	}

	/// Retrieve the information saved in a mint account
	///
	/// ACCOUNT mintAccount {} A mint account holding the Mint info.
	///
	/// @return the MintAccountData struct
	function getMintAccountData() public view returns (MintAccountData) {
		AccountInfo ai = _getAccountInfo(mint);

		uint32 authority_present = ai.data.readUint32LE(0);
		uint32 freeze_authority_present = ai.data.readUint32LE(46);
		MintAccountData data = MintAccountData( {
			authority_present: authority_present > 0,
			mint_authority: ai.data.readAddress(4),
			supply: ai.data.readUint64LE(36),
			decimals: uint8(ai.data[44]),
			is_initialized: ai.data[45] > 0,
			freeze_authority_present: freeze_authority_present > 0,
			freeze_authority: ai.data.readAddress(50)
		});

		return data;
	}

	// function getDecimals() public view returns (uint8) {

	// }

	// A mint account has an authority, whose type is one of the members of this struct.
	enum AuthorityType {
		MintTokens,
		FreezeAccount,
		AccountOwner,
		CloseAccount
	}

	/// Remove the mint authority from a mint account
	///
	/// @param mintAccount the public key for the mint account
	/// @param mintAuthority the public for the mint authority
	function _removeMintAuthority(address mintAccount, address mintAuthority) internal {
		AccountMeta[2] metas = [
			AccountMeta({pubkey: mintAccount, is_signer: false, is_writable: true}),
			AccountMeta({pubkey: mintAuthority, is_signer: true, is_writable: false})
		];

		bytes data = new bytes(9);
		data[0] = uint8(TokenInstruction.SetAuthority);
		data[1] = uint8(AuthorityType.MintTokens);
		data[3] = 0;

		TOKEN_PROGRAM_ID.call{accounts: metas}(data);
	}

	function _toBytes(address a) private pure returns (bytes memory) {
		return abi.encodePacked(a);
	}

	// TODO: Save bytes of `TOKEN_PROGRAM_ID` and `mint` in global storage to save compute (since storage write is one-off)
	function _getAssociatedTokenAddress(address user) private pure returns (address ata) {
		(ata,) = try_find_program_address([
			_toBytes(user),
			_toBytes(TOKEN_PROGRAM_ID),
			_toBytes(mint)
		], ASSOCIATED_TOKEN_PROGRAM_ID);
	}
}