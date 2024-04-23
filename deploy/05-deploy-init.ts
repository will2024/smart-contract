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
  const worlderApprove = await getDeployedContractWithDefaultName("WorldesApprove");
  const worlderApproveProxy = await getDeployedContractWithDefaultName("WorldesApproveProxy");

  // ——————————————deploy helper————————————————————
  console.log("start deploy init");

  //init
  tx = await worlderDvmProxy.initOwner(deployer);
  await tx.wait().then(() => {
    console.log("worlderDvmProxy set initOwner done!");
  });

  tx = await worlderApprove.init(
    deployer,
    worlderApproveProxy.target
  );
  await tx.wait().then(() => {
    console.log("worlderApprove init done!");
  });

  tx = await worlderApproveProxy.init(
    deployer,
    [worlderDvmProxy.target, worlderDspProxy.target]
  )
  await tx.wait().then(() => {
    console.log("worlderApproveProxy init done!");
  });

  console.log("init done");
}

//
export default deployFunction;
deployFunction.tags = ["init"];
if (hre.network.name == "hardhat") {
  deployFunction.dependencies = ["libs", "dvm", "dsp", "mocks"];  
} else {
  deployFunction.dependencies = ["libs", "dvm", "dsp"];
}