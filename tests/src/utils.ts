import { AnchorProvider, Program } from '@coral-xyz/anchor'
import {
  getAssociatedTokenAddressSync,
  createAssociatedTokenAccountInstruction,
  getAccount,
  Account
} from '@solana/spl-token'
import { Keypair, Transaction, SystemProgram, PublicKey } from '@solana/web3.js'
import BN from 'bn.js'
import expect from 'expect'
import * as fs from 'fs'
import * as path from 'path'
import { describe } from 'mocha'
import { homedir } from 'os'

export async function getTokenBalance(user: Keypair, userTokenAccount: Account, storage: Keypair, program: Program) {
  return (await program.methods
    .balanceOf(user.publicKey)
    .accounts({ dataAccount: storage.publicKey })
    .remainingAccounts([{ pubkey: userTokenAccount.address, isWritable: true, isSigner: false }])
    .view()) as BN
}

export async function getTokenUser(provider: AnchorProvider, tokenMint: Keypair) {
  const user = Keypair.generate()

  // `getOrCreateAssociatedTokenAccount` requires signer but AnchorProvider is type Wallet and not Signer,
  // so we get or create ATA on our own and send using AnchorProvider's `sendAndConfirm`.

  const associatedTokenAddress = getAssociatedTokenAddressSync(tokenMint.publicKey, user.publicKey)
  let userTokenAccount
  try {
    userTokenAccount = await getAccount(provider.connection, associatedTokenAddress)
  } catch (err) {
    const transaction = new Transaction().add(
      createAssociatedTokenAccountInstruction(
        provider.wallet.publicKey,
        associatedTokenAddress,
        user.publicKey,
        tokenMint.publicKey
      )
    )

    await provider.sendAndConfirm(transaction) // use Anchor to sign transaction using the default wallet
    userTokenAccount = await getAccount(provider.connection, associatedTokenAddress)
  }

  return { user, userTokenAccount }
}

export async function isBnEqual(a: BN, b: BN) {
  return a.eq(b) || a.toString() == b.toString()
}