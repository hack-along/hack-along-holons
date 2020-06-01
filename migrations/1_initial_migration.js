const Migrations = artifacts.require("Migrations");
const HolonFactory = artifacts.require("HolonFactory");
const TestToken = artifacts.require("TestToken");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(HolonFactory);
  deployer.deploy(TestToken,100000000);
};
