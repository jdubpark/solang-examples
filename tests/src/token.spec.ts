import BN from 'bn.js'
import expect from 'expect'
import { describe } from 'mocha'

import TokenERC20 from '@/token/erc20'
import { loadEnvironment, loadEnvironmentWithUsers } from '@/utils'

describe('ERC-20', function () {
  this.timeout(500000)

  const defaultMintAmount = 100_000
  const defaultTransferAmount = 10_000

  it('Reads', async function () {
    const { program, owner, storageKeypair, tokenKeypair, decimals } = await loadEnvironment('idl/BasicToken.json')

    const token = new TokenERC20(program, tokenKeypair, owner, storageKeypair)

    const readDecimals = await token.decimals()
    expect(decimals.eq(new BN(readDecimals))).toBe(true)
  })

  it('Mints', async function () {
    const { program, owner, storageKeypair, tokenKeypair, users } = await loadEnvironmentWithUsers(
      'idl/BasicToken.json',
      1
    )
    const [alice, aliceTokenAccount] = users[0]

    const token = new TokenERC20(program, tokenKeypair, owner, storageKeypair)

    const balanceBefore = await token.balanceOf(alice)

    // 1. Mint
    await token.mintTo(alice, defaultMintAmount)

    // 2. Check
    const balanceAfter = await token.balanceOf(alice)
    const expectedBalanceAfter = balanceBefore.add(new BN(defaultMintAmount))
    expect(balanceAfter.eq(expectedBalanceAfter)).toBe(true)
  })

  it('Transfers', async function () {
    const { program, owner, storageKeypair, tokenKeypair, users } = await loadEnvironmentWithUsers(
      'idl/BasicToken.json',
      2
    )
    const [alice, aliceTokenAccount] = users[0]
    const [bob, bobTokenAccount] = users[1]

    const token = new TokenERC20(program, tokenKeypair, owner, storageKeypair)

    const bobBalanceBefore = await token.balanceOf(bob)

    // 1. Mint
    await token.mintTo(alice, defaultMintAmount)

    // 2. Transfer
    await token.transfer(alice, bob, defaultTransferAmount)

    // 3. Check
    const bobBalanceAfter = await token.balanceOf(bob)
    const expectedBobBalanceAfter = bobBalanceBefore.add(new BN(defaultTransferAmount))
    expect(bobBalanceAfter.eq(expectedBobBalanceAfter)).toBe(true)
  })

  // it('Approves', async function () {})

  // More tests...
})
