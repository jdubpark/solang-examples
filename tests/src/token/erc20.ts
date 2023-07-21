import { Program } from '@coral-xyz/anchor'
import { getAssociatedTokenAddressSync } from '@solana/spl-token'
import { Keypair, PublicKey } from '@solana/web3.js'
import BN from 'bn.js'

export default class TokenERC20 {
  tokenProgram: Program
  tokenKeypair: Keypair
  ownerPublicKey: PublicKey
  storageKeypair: Keypair

  /**
   * @param tokenProgram `Program` from Anchor (has token IDL)
   * @param tokenKeypair Keypair of the token program
   * @param ownerPublicKey PublicKey of the owner of the token program (e.g. can mint). Right now, this is `provider.wallet` loaded from Anchor.
   * @param storageKeypair Keypair of the account holding the data of the token program
   */
  constructor(tokenProgram: Program, tokenKeypair: Keypair, ownerPublicKey: PublicKey, storageKeypair: Keypair) {
    this.tokenProgram = tokenProgram
    this.tokenKeypair = tokenKeypair
    this.ownerPublicKey = ownerPublicKey
    this.storageKeypair = storageKeypair
  }

  get program() {
    return this.tokenProgram
  }

  get token() {
    return this.tokenKeypair
  }

  get storage() {
    return this.storageKeypair
  }

  async decimals() {
    const accountsToPassIn = [{ pubkey: this.token.publicKey, isWritable: true, isSigner: false }]

    const decimals = await this.program.methods
      .decimals()
      .accounts({ dataAccount: this.storage.publicKey })
      .remainingAccounts(accountsToPassIn)
      .view()
    return decimals as number // uint8 is returned as number
  }

  async balanceOf(user: PublicKey | Keypair) {
    const userPubKey = this._parsePubkeyOrKeypair(user)
    const userTokenAccount = getAssociatedTokenAddressSync(this.token.publicKey, userPubKey)

    const accountsToPassIn = [{ pubkey: userTokenAccount, isWritable: true, isSigner: false }]

    const tokenBalance = await this.program.methods
      .balanceOf(userPubKey)
      .accounts({ dataAccount: this.storage.publicKey })
      .remainingAccounts(accountsToPassIn)
      .view()
    return tokenBalance as BN
  }

  async mintTo(user: PublicKey | Keypair, amount: number | string | BN) {
    const userPubKey = this._parsePubkeyOrKeypair(user)
    const userTokenAccount = getAssociatedTokenAddressSync(this.token.publicKey, userPubKey)
    const amountBN = this._parseAmount(amount)

    const accountsToPassIn = [
      { pubkey: userTokenAccount, isWritable: true, isSigner: false },
      { pubkey: this.token.publicKey, isWritable: true, isSigner: false },
      { pubkey: this.ownerPublicKey, isWritable: true, isSigner: true }
    ]

    // Anchor implicitly signs transactions with the wallet, ie. payer (token contract owner as we've specified as such)
    return this.program.methods
      .mintTo(userPubKey, amountBN)
      .accounts({ dataAccount: this.storage.publicKey })
      .remainingAccounts(accountsToPassIn)
      .rpc()
  }

  /**
   * Transfer Token from `from` to `to`. Specify `txPayer` for someone else to pay for the transaction, in which case the `txPayer` must sign the tx as well.
   * @param from
   * @param to
   * @param amount
   * @param txPayer
   * @returns
   */
  async transfer(from: Keypair, to: PublicKey | Keypair, amount: number | string | BN, txPayer?: Keypair) {
    const toUserPubKey = this._parsePubkeyOrKeypair(to)
    const fromUserTokenAccount = getAssociatedTokenAddressSync(this.token.publicKey, from.publicKey)
    const toUserTokenAccount = getAssociatedTokenAddressSync(this.token.publicKey, toUserPubKey)
    const amountBN = this._parseAmount(amount)

    const payer = txPayer || from

    const accountsToPassIn = [
      { pubkey: fromUserTokenAccount, isWritable: true, isSigner: false },
      { pubkey: toUserTokenAccount, isWritable: true, isSigner: false },
      { pubkey: from.publicKey, isWritable: true, isSigner: true } // `from` pays for the transaction
    ]

    return this.program.methods
      .transfer(from.publicKey, toUserPubKey, amountBN)
      .accounts({ dataAccount: this.storage.publicKey })
      .remainingAccounts(accountsToPassIn)
      .signers([from, payer]) // `from` user needs to sign the tx
      .rpc()
  }

  private _parsePubkeyOrKeypair(key: PublicKey | Keypair) {
    return key instanceof PublicKey ? key : key.publicKey
  }

  private _parseAmount(amount: number | string | BN) {
    return amount instanceof BN ? amount : new BN(amount)
  }
}
