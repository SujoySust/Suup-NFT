const Extra = artifacts.require("Extra");
const SUUPNFT = artifacts.require("SUUPNFT");

module.exports = function(deployer) {
  const name = "SUUP NFT";
  const symbol = "SUUPNFT";
  const admin = "0x1cA32B885d69C983C8a94766d03dc119a09886Aa"

  deployer.deploy(Extra);
  deployer.link(Extra, SUUPNFT);
  deployer.deploy(SUUPNFT, name, symbol, admin);
};
