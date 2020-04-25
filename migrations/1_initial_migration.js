const Migrations = artifacts.require("Migrations");
const HackAlong = artifacts.require("HackAlong");
const Team = artifacts.require("Team");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(HackAlong);
};
