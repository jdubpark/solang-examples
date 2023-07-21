import BN from 'bn.js'

export async function isBnEqual(a: BN, b: BN) {
  return a.eq(b) || a.toString() == b.toString()
}
