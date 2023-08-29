const EXTRA = artifacts.require("EXTRA");
const SUUPNFT = artifacts.require("SUUPNFT");

contract('SUUPNFT', (accounts) => {
  let extra;
  let suupNFTInstance;
  const name = "SUUP NFT";
  const symbol = "SUUPNFT";
  const admin = accounts[0];

  before( async () => {
    extra = await EXTRA.deployed();
    suupNFTInstance = await SUUPNFT.deployed(name, symbol, admin);
  });

  const admin_1 = accounts[1];
  const admin_2 = accounts[2];
  const admin_3 = accounts[3];
  const admin_4 = accounts[4];

  const user_1 = accounts[5];
  const user_2 = accounts[6];
  const user_3 = accounts[7];
  const user_4 = accounts[8];

  const uri = 'https://www.testurl.com/metadata';

  it('should add an admin', async() => {
    const result = await suupNFTInstance.addAdmin(admin_1, { from: admin});
    assert.isTrue(result.receipt.status, "Admin addition failed!");
  });

  it('should delete an admin', async() => {
    const result = await suupNFTInstance.deleteAdmin(admin_1, { from: admin});
    assert.isTrue(result.receipt.status, "Admin delete failed!");
  });

  it("should return admin list", async () => {
    const adminList = await suupNFTInstance.adminLists({ from: admin });
    assert.isArray(adminList, "Admin list is not an array");
  });

  it("should return current token id", async () => {
    const totalSupply = await suupNFTInstance.totalSupply({ from: admin });
    assert.equal(totalSupply.toString(), '0', "Invalid total supply");
  });

  it("should min nft and return token id", async () => {
    
    const mint = await suupNFTInstance.mint(user_1, uri, { from: admin});
    assert.property(mint, 'tx', "Minting failed");
    assert.property(mint, 'logs', "Minting failed");
    assert.equal(mint.logs[0].args.tokenId, '1', "Minting failed");
  });

  it("should return owner of token", async () => {
    const owner = await suupNFTInstance.ownerOf('1',{ from: admin});
    assert.equal(owner, user_1, "Invalid owner of nft");
  });

  it("should return token id of token uri", async () => {
    const tokenUri = await suupNFTInstance.tokenURI('1',{ from: admin});
    assert.equal(tokenUri, uri, "Invalid token uri");
  });

  it("should approve a address for transfer token", async () => {
    const result = await suupNFTInstance.approve(user_2, '1', { from: user_1});
    assert.isTrue(result.receipt.status, "Approved fail");

    const approved = await suupNFTInstance.getApproved('1', { from: user_1});
    assert.equal(approved, user_2, "Invalid approved");
    assert.notEqual(approved, user_3, "Invalid approved");
  });

  it("should approve a address for transfer token", async () => {
    const result = await suupNFTInstance.approve(user_2, '1', { from: user_1});
    assert.isTrue(result.receipt.status, "Approved fail");

    const approved = await suupNFTInstance.getApproved('1', { from: user_1});
    assert.equal(approved, user_2, "Invalid approved");
    assert.notEqual(approved, user_3, "Invalid approved");
  });

  it("should set approved for all user", async () => {
    const result = await suupNFTInstance.setApprovalForAll(user_2, true, { from: user_1});
    assert.isTrue(result.receipt.status, "Approved fail");

    const approved = await suupNFTInstance.getApproved('1', { from: user_1});
    assert.equal(approved, user_2, "Invalid approved");
    assert.notEqual(approved, user_4, "Invalid approved");
  });

  it("Transfer token from user_1 to user_2", async () => {
    const result = await suupNFTInstance.safeTransferFrom(user_1, user_2, '1', { from: user_1});
    assert.isTrue(result.receipt.status, "Transfer failed");

    const owner = await suupNFTInstance.ownerOf('1', { from: admin});
    assert.equal(owner, user_2, "Invalid transfer");
    assert.notEqual(owner, user_1, "Invalid transfer");
  });
});
