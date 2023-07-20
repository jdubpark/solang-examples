import { BN } from '@coral-xyz/anchor'
import { PublicKey } from '@solana/web3.js'

export type TokenAccount = {
  mintAccount: PublicKey
  owner: PublicKey
  balance: BN
  delegatePresent: boolean
  delegate: PublicKey
  state: { initialized: any }
  isNativePresent: boolean
  isNative: BN
  delegatedAmount: BN
  closeAuthorityPresent: boolean
  closeAuthority: PublicKey
}