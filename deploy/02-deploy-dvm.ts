import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import hre from "hardhat";

import { config } from "dotenv";
import { getDeployedContractWithDefaultName, getWethAddress } from "../scripts/utils/env-utils";
config({ path: "../.env" });

const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  console.log("deployer: ", deployer);
  let tx;
  
  // ——————————————load deployed contacts————————————————————
  const cloneFactory = await getDeployedContractWithDefaultName("CloneFactory");
  const feeRateModelTemplate = await getDeployedContractWithDefaultName("FeeRateModel");
  const worlderApproveProxy = await getDeployedContractWithDefaultName("WorldesApproveProxy");

  // ——————————————deploy dvm————————————————————
  console.log("start deploy dvm");

  // Deploy DVM template
  console.log("- Deployment of DVM template contract");
  await deploy("DVM", {
    contract: "DVM",
    from: deployer,
  }).then((res) => {
    console.log("DVMTemplate deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const dvmTemplate = await getDeployedContractWithDefaultName("DVM");

  // Deploy DVMFactory
  console.log("- Deployment of DVMFactory contract");
  await deploy("DVMFactory", {
    contract: "DVMFactory",
    from: deployer,
    args: [cloneFactory.target, dvmTemplate.target, deployer, feeRateModelTemplate.target],
  }).then((res) => {
    console.log("DVMFactory deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const dvmFactory = await getDeployedContractWithDefaultName("DVMFactory");

  // Deploy WorldesDvmProxy
  console.log("- Deployment of WorldesDvmProxy contract");
  await deploy("WorldesDvmProxy", {
    contract: "WorldesDvmProxy",
    from: deployer,
    args: [dvmFactory.target, await getWethAddress(), worlderApproveProxy.target],
  }).then((res) => {
    console.log("WorldesDvmProxy deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const worlderDvmProxy = await getDeployedContractWithDefaultName("WorldesDvmProxy");

  try {
    tx = await worlderDvmProxy.initOwner(deployer);
    await tx.wait().then(() => {
      console.log("worlderDvmProxy set initOwner done!");
    });
  } catch (error) {
    console.log("worlderDvmProxy set initOwner error: ");
  }

  console.log("deploy dvm done");
};

//
export default deployFunction;
deployFunction.tags = ["dvm"];
if (hre.network.name == "hardhat") {
  deployFunction.dependencies = ["libs", "mocks"];  
} else {
  deployFunction.dependencies = ["libs"];  
}
