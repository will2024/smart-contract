import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import hre from "hardhat";

import { config } from "dotenv";
import { getDeployedContractWithDefaultName } from "../scripts/utils/env-utils";
config({ path: "../.env" });

const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  console.log("deployer: ", deployer);
  let tx;
  
  // ——————————————load deployed contacts————————————————————
  const cloneFactory = await getDeployedContractWithDefaultName("CloneFactory");
  const worldesApproveProxy = await getDeployedContractWithDefaultName("WorldesApproveProxy");

  // ——————————————deploy limit order————————————————————
  console.log("start deploy mine");

  //deploy ERC20Mine Template
  await deploy("ERC20Mine", {
    contract: "ERC20Mine",
    from: deployer,
  }).then((res) => {
    console.log("ERC20Mine template deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const erc20MineTemplate = await getDeployedContractWithDefaultName("ERC20Mine");

  //deploy WorldesMineRegistry
  await deploy("WorldesMineRegistry", {
    contract: "WorldesMineRegistry",
    from: deployer,
  }).then((res) => {
    console.log("WorldesMineRegistry deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const worldesMineRegistry = await getDeployedContractWithDefaultName("WorldesMineRegistry");

  //deploy WorldesMineProxy
  await deploy("WorldesMineProxy", {
    contract: "WorldesMineProxy",
    from: deployer,
    args: [
      cloneFactory.target,
      erc20MineTemplate.target,
      worldesApproveProxy.target,
      worldesMineRegistry.target,
    ],
  }).then((res) => {
    console.log("WorldesMineProxy deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const worldesMineProxy = await getDeployedContractWithDefaultName("WorldesMineProxy");

  //worldesMineRegistry owner init
  tx = await worldesMineRegistry.initOwner(deployer);
  await tx.wait().then(() => {
    console.log("worldesMineRegistry initOwner done!");
  });

  //worldesMineProxy owner init
  tx = await worldesMineProxy.initOwner(deployer);
  await tx.wait().then(() => {
    console.log("worldesMineProxy initOwner done!");
  });

  //add worldesMineProxy to worldesMineRegistry adminList
  tx = await worldesMineRegistry.addAdminList(worldesMineProxy.target);
  await tx.wait().then(() => {
    console.log("worldesMineProxy addAdminList to worldesMineRegistry!");
  });

  // //add worldesMineProxy to worldesApproveProxy
  // tx = await worldesApproveProxy.unlockAddProxy(worldesMineProxy.target);
  // await tx.wait().then(() => {
  //   console.log("worldesMineProxy unlockAddProxy to worldesApproveProxy!");
  // });
  // tx = await worldesApproveProxy.addWorldesProxy();
  // await tx.wait().then(() => {
  //   console.log("worldesMineProxy addWorldesProxy to worldesApproveProxy!");
  // });

  console.log("mine done");
}

//
export default deployFunction;
deployFunction.tags = ["mine"];
deployFunction.dependencies = ["libs", "dvm"];  
