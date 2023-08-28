const Extra = artifacts.require("Extra");
const SUUPNFT = artifacts.require("SUUPNFT");

module.exports = function(deployer) {
  const name = "SUUP NFT";
  const symbol = "SUUPNFT";
  const admin = "0xf6a1a452AA3E1792600ADF1aA53f78A5Bc6708Ce"

  deployer.deploy(Extra);
  deployer.link(Extra, SUUPNFT);
  deployer.deploy(SUUPNFT, name, symbol, admin);
};
