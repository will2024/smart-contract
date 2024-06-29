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
  const worldesApprove = await getDeployedContractWithDefaultName("WorldesApprove");
  const worldesApproveProxy = await getDeployedContractWithDefaultName("WorldesApproveProxy");

  // ——————————————deploy limit order————————————————————
  console.log("start deploy limit order");

  //deploy worldesLimitOrder
  await deploy("WorldesLimitOrder", {
    contract: "WorldesLimitOrder",
    from: deployer,
  }).then((res) => {
    console.log("WorldesLimitOrder deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const worldesLimitOrder = await getDeployedContractWithDefaultName("WorldesLimitOrder");

  try {
    tx = await worldesLimitOrder.init(
      deployer,   //owner
      worldesApproveProxy.target, 
      deployer   //fee reciver
    );
    await tx.wait().then(() => {
      console.log("worldesLimitOrder init done!");
    });
  } catch (e) {
    console.log("worldesLimitOrder init failed!");
  }

  //deploy worldesLimitOrderBot
  await deploy("WorldesLimitOrderBot", {
    contract: "WorldesLimitOrderBot",
    from: deployer,
  }).then((res) => {
    console.log("WorldesLimitOrderBot deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const worldesLimitOrderBot = await getDeployedContractWithDefaultName("WorldesLimitOrderBot");

  try {
    tx = await worldesLimitOrderBot.init(
      deployer,     //owner
      worldesLimitOrder.target,
      deployer,    //fee reciver
      worldesApprove.target
    );
    await tx.wait().then(() => {
      console.log("worldesLimitOrderBot init done!");
    });
  } catch (e) {
    console.log("worldesLimitOrderBot init failed!");
  }

  // //add worldesLimitOrder to worldesApproveProxy
  // tx = await worldesApproveProxy.unlockAddProxy(worldesLimitOrder.target);
  // await tx.wait().then(() => {
  //   console.log("worldesLimitOrder unlockAddProxy to worldesApproveProxy!");
  // });
  // tx = await worldesApproveProxy.addWorldesProxy();
  // await tx.wait().then(() => {
  //   console.log("worldesLimitOrder addWorldesProxy to worldesApproveProxy!");
  // });

  console.log("limit-order done");
}

//
export default deployFunction;
deployFunction.tags = ["limit-order"];
deployFunction.dependencies = ["libs"];  
