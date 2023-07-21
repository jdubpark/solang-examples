import { AnchorProvider, Program } from '@coral-xyz/anchor'
import { Keypair, Transaction, SystemProgram } from '@solana/web3.js'
import { Account } from '@solana/spl-token'
import BN from 'bn.js'
import * as fs from 'fs'
import * as path from 'path'
import { homedir } from 'os'

import { createTokenUser } from './token'

const TOKEN_PROGRAM_ID = 'CR3JGL7NVpm9Y7ohEHw92x3SPseMvPwgx1oviu5ixJKv'

export async function loadEnvironment(pathToIDLJsonFromSrc: string) {
  //
  // Set up Anchor
  //

  const idl = JSON.parse(fs.readFileSync(path.join(__dirname, '../', pathToIDLJsonFromSrc), 'utf8'))
  if (!idl) throw new Error('IDL not found')

  process.env['ANCHOR_WALLET'] = path.join(homedir(), '.config/solana/id.json')

  const provider = AnchorProvider.local(process.env.RPC_URL || 'http://127.0.0.1:8899')
  const program = new Program(idl, TOKEN_PROGRAM_ID, provider)

  //
  // Note: By default, the owner of the Token (e.g. can mint) is the account loaded locally.
  //

  const owner = provider.wallet.publicKey

  //
  // Create storage account to store the contract data
  //

  const storageKeypair = Keypair.generate()
  const storagePubkey = storageKeypair.publicKey
  const storageSpace = 8192
  const storageLamports = await provider.connection.getMinimumBalanceForRentExemption(storageSpace)

  const transaction = new Transaction()
  transaction.add(
    SystemProgram.createAccount({
      fromPubkey: provider.wallet.publicKey,
      newAccountPubkey: storagePubkey,
      lamports: storageLamports,
      space: storageSpace,
      programId: program.programId
    })
  )

  const signers = [storageKeypair]
  const createStorageTxId = await provider.sendAndConfirm(transaction, signers)

  //
  // Call the contract's constructor
  //

  const mintKeypair = Keypair.generate()
  const mintPubkey = mintKeypair.publicKey
  // const mintLamports = await provider.connection.getMinimumBalanceForRentExemption(82) // 82 is the size of the mint account
	const mintDecimals = 9

  const initTxId = await program.methods
    .new(
      owner, // owner, also payer
      mintPubkey, // mint address
      // new BN(mintLamports), // lamports
      new BN(mintDecimals) // decimals
    )
    .accounts({ dataAccount: storagePubkey })
    .remainingAccounts([{ pubkey: mintPubkey, isSigner: true, isWritable: true }])
    .signers([mintKeypair])
    .rpc()

  return {
    provider,
    connection: provider.connection,
    owner,
    program,
    storageKeypair,
    tokenKeypair: mintKeypair, // == token mint
		decimals: new BN(mintDecimals),
  }
}

export async function loadEnvironmentWithUsers(pathToIDLJsonFromSrc: string, count: number) {
  const env = await loadEnvironment(pathToIDLJsonFromSrc)
  const { provider, tokenKeypair } = env

	const users: [Keypair, Account][] = []
	for (let i = 0; i < count; i++) {
		const userData = await createTokenUser(provider, tokenKeypair)
		users.push([userData.user, userData.userTokenAccount])
	}

  return { ...env, users }
}
