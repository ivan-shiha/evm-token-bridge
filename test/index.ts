import { expect } from "chai";
import { BigNumber, Signer } from "ethers";
import { ethers } from "hardhat";
import { LimeToken } from "../typechain-types/LimeToken";
import { TokenBridge } from "../typechain-types/TokenBridge";
import { generateNonce, prepareMessage } from "./utils";

describe("TokenBridge", () => {

  let signer: Signer;
  let addrs: Signer[];

  let limeToken: LimeToken;
  let tokenBridge: TokenBridge;

  const amountBN = BigNumber.from(1);
  const nonceBN = generateNonce();
  const chainId = 31337;
  const serviceFeeWei = BigNumber.from("100000000000000");

  let escrowAddress: string;
  let limeTokenAddress: string;

  beforeEach(async () => {
    [signer, ...addrs] = await ethers.getSigners();

    const limeTokenFactory = await ethers.getContractFactory("LimeToken", signer);
    limeToken = await limeTokenFactory.deploy(BigNumber.from(1));
    limeTokenAddress = limeToken.address;

    const tokenBridgeFactory = await ethers.getContractFactory("TokenBridge", signer);
    tokenBridge = await tokenBridgeFactory.deploy();
    escrowAddress = await tokenBridge.getEscrowAddress();
    const approveTx = await limeToken.approve(escrowAddress, amountBN);
    await approveTx.wait();
  });

  it("Should transfer successfuly", async () => {
    const message = prepareMessage(escrowAddress, amountBN, nonceBN, BigNumber.from(chainId));
    const signature = await signer.signMessage(message);
    const tx = await tokenBridge.transfer(limeTokenAddress, amountBN, nonceBN, signature, { value: serviceFeeWei });
    const receipt = await tx.wait();
    expect(receipt.status).to.be.equal(1);
  });

  it("Should claim successfuly", async () => {
    const message = prepareMessage(escrowAddress, amountBN, nonceBN, BigNumber.from(chainId));
    const signature = await signer.signMessage(message);
    const tx = await tokenBridge.claim(limeTokenAddress, amountBN, nonceBN, signature);
    const receipt = await tx.wait();
    expect(receipt.status).to.be.equal(1);
  });

  it("Should transfer and claim back", async () => {
    const message = prepareMessage(escrowAddress, amountBN, nonceBN, BigNumber.from(chainId));
    const signature = await signer.signMessage(message);
    const signerAddress = await signer.getAddress();

    const transferTx = await tokenBridge.transfer(limeTokenAddress, amountBN, nonceBN, signature, { value: serviceFeeWei });
    const transferReceipt = await transferTx.wait();
    expect(transferReceipt.status).to.be.equal(1);
    expect(await limeToken.balanceOf(signerAddress)).to.be.equal(BigNumber.from(0));

    const claimTx = await tokenBridge.claim(limeTokenAddress, amountBN, nonceBN, signature);
    const claimReceipt = await claimTx.wait();
    expect(claimReceipt.status).to.be.equal(1);
    expect(await limeToken.balanceOf(signerAddress)).to.be.equal(BigNumber.from(1));
  });

  it("Should claim and transfer back", async () => {
    const message = prepareMessage(escrowAddress, amountBN, nonceBN, BigNumber.from(chainId));
    const signature = await signer.signMessage(message);
    const signerAddress = await signer.getAddress();

    const claimTx = await tokenBridge.claim(limeTokenAddress, amountBN, nonceBN, signature);
    const claimReceipt = await claimTx.wait();
    expect(claimReceipt.status).to.be.equal(1);

    const wrappedTokenAddress = await tokenBridge.getTokenAddress(limeTokenAddress);
    const WrappedTokenFactory = await ethers.getContractFactory('WrappedToken');
    const wrappedToken = WrappedTokenFactory.attach(wrappedTokenAddress);
    expect(await wrappedToken.balanceOf(signerAddress)).to.be.equal(BigNumber.from(1));

    const transferTx = await tokenBridge.transfer(wrappedTokenAddress, amountBN, nonceBN, signature, { value: serviceFeeWei });
    const transferReceipt = await transferTx.wait();
    expect(transferReceipt.status).to.be.equal(1);
    expect(await wrappedToken.balanceOf(signerAddress)).to.be.equal(BigNumber.from(0));
  });
});
