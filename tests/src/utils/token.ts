import { AnchorProvider } from '@coral-xyz/anchor'
import { getAssociatedTokenAddressSync, createAssociatedTokenAccountInstruction, getAccount } from '@solana/spl-token'
import { Keypair, Transaction } from '@solana/web3.js'

export async function createTokenUser(provider: AnchorProvider, tokenMint: Keypair) {
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
