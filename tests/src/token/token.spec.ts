import { Keypair } from '@solana/web3.js'
import BN from 'bn.js'
import expect from 'expect'
import { describe } from 'mocha'

import { loadEnvironment, loadEnvironmentWithUsers } from '@/environment'
import { TokenAccount } from '@/types'
import { getTokenBalance, getTokenUser, isBnEqual } from '@/utils'

describe('ERC-20', function () {
  this.timeout(500000)

  it('Reads', async function () {
    const { storage, program, tokenMint, decimals } = await loadEnvironment('token/BasicToken.json')

    const readDecimals = (await program.methods
      .decimals()
      .accounts({ dataAccount: storage.publicKey })
      .remainingAccounts([{ pubkey: tokenMint.publicKey, isWritable: true, isSigner: false }])
      .view()) as number // uint8 is returned as number

    expect(decimals.eq(new BN(readDecimals))).toBe(true)

    // const mintAccountData = await program.methods
    //   .getMintAccountData()
    //   .accounts({ dataAccount: storage.publicKey })
    //   .remainingAccounts([{ pubkey: tokenMint.publicKey, isWritable: true, isSigner: false }])
    //   .view()

    // console.log('data', mintAccountData)

    // const mint = (await program.methods.getMint().accounts({ dataAccount: storage.publicKey }).view()) as PublicKey
  })

  it('Mints', async function () {
    const { storage, payer, program, tokenMint, users } = await loadEnvironmentWithUsers('token/BasicToken.json', 1)
    const [alice, aliceTokenAccount] = users[0]

    const mintAmount = 100_000

    const balanceBefore = await getTokenBalance(alice, aliceTokenAccount, storage, program)

    // Anchor implicitly signs transactions with the wallet, ie. payer (token contract owner as we've specified as such)
    const txId = await program.methods
      .mintTo(alice.publicKey, new BN(mintAmount))
      .accounts({ dataAccount: storage.publicKey })
      .remainingAccounts([
        { pubkey: aliceTokenAccount.address, isWritable: true, isSigner: false },
        { pubkey: tokenMint.publicKey, isWritable: true, isSigner: false },
        { pubkey: payer, isWritable: true, isSigner: true } // owner of the token account
      ])
      .rpc()

    const balanceAfter = await getTokenBalance(alice, aliceTokenAccount, storage, program)
    const expectedBalanceAfter = balanceBefore.add(new BN(mintAmount))

    // Balance After = 100_000 + Balance Before
    expect(balanceAfter.eq(expectedBalanceAfter)).toBe(true)
  })

  it('Transfers', async function() {
    const { storage, payer, program, tokenMint, users } = await loadEnvironmentWithUsers('token/BasicToken.json', 2)
    const [alice, aliceTokenAccount] = users[0]
    const [bob, bobTokenAccount] = users[1]

    const mintAmount = 100_000
    const transferAmount = 50_000

    const bobBalanceBefore = await getTokenBalance(bob, bobTokenAccount, storage, program)

    //
    // 1. Mint
    //
    await program.methods
      .mintTo(alice.publicKey, new BN(mintAmount))
      .accounts({ dataAccount: storage.publicKey })
      .remainingAccounts([
        { pubkey: aliceTokenAccount.address, isWritable: true, isSigner: false },
        { pubkey: tokenMint.publicKey, isWritable: true, isSigner: false },
        { pubkey: payer, isWritable: true, isSigner: true } // owner of the token account
      ])
      .rpc()
    
    //
    // 2. Transfer
    //
    await program.methods
      .transfer(alice.publicKey, bob.publicKey, new BN(transferAmount))
      .accounts({ dataAccount: storage.publicKey })
      .remainingAccounts([
        { pubkey: aliceTokenAccount.address, isWritable: true, isSigner: false },
        { pubkey: bobTokenAccount.address, isWritable: true, isSigner: false },
        { pubkey: alice.publicKey, isWritable: true, isSigner: true } // alice pays
      ])
      .signers([alice]) // alice signs
      .rpc()
    
    const bobBalanceAfter = await getTokenBalance(bob, bobTokenAccount, storage, program)
    const expectedBobBalanceAfter = bobBalanceBefore.add(new BN(transferAmount))

    // Balance After = 50_000 + Balance Before
    expect(bobBalanceAfter.eq(expectedBobBalanceAfter)).toBe(true)
  })

  // More tests...
})
