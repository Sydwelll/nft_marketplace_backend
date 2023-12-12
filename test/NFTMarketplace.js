const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("NFTMarketplace", function () {
  let NFTMarketplace;
  let nftMarketplace;
  let owner;
  let addr1;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    NFTMarketplace = await ethers.getContractFactory("NFTMarketplace");
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy a new contract before each test.
    nftMarketplace = await NFTMarketplace.deploy(owner.address);
    await nftMarketplace.deployed();
  });

  describe("Minting and Listing", function () {
    it("Should mint a new token and list it for sale", async function () {
      const mintTx = await nftMarketplace.safeMint(
        owner.address,
        "http://example.com/token1",
        true,
        ethers.utils.parseEther("1")
      );

      await expect(mintTx)
        .to.emit(nftMarketplace, "TokenMinted")
        .withArgs(owner.address, 0, "http://example.com/token1");

      expect(await nftMarketplace.ownerOf(0)).to.equal(owner.address);
      expect(await nftMarketplace.getTokenSalePrice(0)).to.equal(
        ethers.utils.parseEther("1")
      );
    });
  });

  describe("Buying a Token", function () {
    beforeEach(async function () {
      await nftMarketplace.safeMint(
        owner.address,
        "http://example.com/token2",
        true,
        ethers.utils.parseEther("1")
      );
    });

    it("Should allow a user to buy a token", async function () {
      await expect(
        nftMarketplace
          .connect(addr1)
          .buyCredit(0, { value: ethers.utils.parseEther("1") })
      ).to.changeEtherBalances(
        [addr1, owner],
        [ethers.utils.parseEther("-1"), ethers.utils.parseEther("0.9")] // Considering 10% commission
      );

      expect(await nftMarketplace.ownerOf(0)).to.equal(addr1.address);
    });
  });

  describe("Burning a Token", function () {
    beforeEach(async function () {
      await nftMarketplace.safeMint(
        owner.address,
        "http://example.com/token3",
        false,
        ethers.utils.parseEther("1")
      );
    });

    it("Should allow the owner to burn a token", async function () {
      await expect(nftMarketplace.burn(0))
        .to.emit(nftMarketplace, "TokenBurned")
        .withArgs(0);

      await expect(nftMarketplace.ownerOf(0)).to.be.revertedWith(
        "ERC721: owner query for nonexistent token"
      );
    });
  });
});
