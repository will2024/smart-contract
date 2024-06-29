import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import hre from "hardhat";

import { config } from "dotenv";
import { getDeployedContractWithDefaultName } from "../scripts/utils/env-utils";
config({ path: "../.env" });

const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts } = hre;

  const { deployer } = await getNamedAccounts();
  console.log("deployer: ", deployer);
  let tx;
  
  // ——————————————load deployed contacts————————————————————
  const worlderDvmProxy = await getDeployedContractWithDefaultName("WorldesDvmProxy");
  const worlderDspProxy = await getDeployedContractWithDefaultName("WorldesDspProxy");
  const worldesMineProxy = await getDeployedContractWithDefaultName("WorldesMineProxy");
  const worldesLimitOrder = await getDeployedContractWithDefaultName("WorldesLimitOrder");
  const worlderApprove = await getDeployedContractWithDefaultName("WorldesApprove");
  const worlderApproveProxy = await getDeployedContractWithDefaultName("WorldesApproveProxy");

  // ——————————————deploy helper————————————————————
  console.log("start deploy init");

  //init
  try {
    tx = await worlderApprove.init(
      deployer,
      worlderApproveProxy.target
    );
    await tx.wait().then(() => {
      console.log("worlderApprove init done!");
    });
  } catch (e) {
    console.log("worlderApprove init failed!");
  }

  try {

    tx = await worlderApproveProxy.init(
      deployer,
      [worlderDvmProxy.target, worlderDspProxy.target, worldesMineProxy.target, worldesLimitOrder.target]
    )
    await tx.wait().then(() => {
      console.log("worlderApproveProxy init done!");
    });
  } catch (e) {
    console.log("worlderApproveProxy set initOwner failed!");
  }

  console.log("init done");
}

//
export default deployFunction;
deployFunction.tags = ["init"];
if (hre.network.name == "hardhat") {
  deployFunction.dependencies = ["libs", "dvm", "dsp", "mine", "limit-order", "mocks"];  
} else {
  deployFunction.dependencies = ["libs", "dvm", "dsp", "mine", "limit-order"];
}