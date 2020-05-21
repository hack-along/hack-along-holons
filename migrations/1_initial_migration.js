const Migrations = artifacts.require("Migrations");
const HackAlong = artifacts.require("HackAlong");
const TestToken = artifacts.require("TestToken");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(HackAlong);
  deployer.deploy(TestToken,100);
};
