import { BigNumber, utils } from "ethers";

export function generateNonce(): BigNumber {
  return BigNumber.from(utils.randomBytes(32));
}

export function prepareMessage(tokenAddress: string,
  amount: BigNumber,
  nonce: BigNumber,
  chainId: BigNumber): Uint8Array {
  const data = utils.solidityPack([
    "address",
    "uint256",
    "uint256",
    "uint256"
  ], [
    tokenAddress,
    amount,
    nonce,
    chainId
  ]);
  return utils.arrayify(utils.keccak256(data));
}
