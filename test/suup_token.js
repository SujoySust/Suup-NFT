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

  it('should add an admin', async() => {
    const result = await suupNFTInstance.addAdmin(admin_1, { from: accounts[0]});
    assert.isTrue(result.receipt.status, "Admin addition failed!");
  });

  it('should delete an admin', async() => {
    const result = await suupNFTInstance.deleteAdmin(admin_1, { from: accounts[0]});
    assert.isTrue(result.receipt.status, "Admin delete failed!");
  });

  it("should return admin list", async () => {
    const adminList = await suupNFTInstance.adminLists({ from: accounts[0] });
    assert.isArray(adminList, "Admin list is not an array");
  });
});
