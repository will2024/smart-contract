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

  // Deploy WorldesApprove
  console.log("- Deployment of WorldesApprove contract");
  await deploy("WorldesApprove", {
    contract: "WorldesApprove",
    from: deployer,
  }).then((res) => {
    console.log("WorldesApprove deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const worlderApprove = await getDeployedContractWithDefaultName("WorldesApprove");

  // Deploy WorldesApproveProxy
  console.log("- Deployment of WorldesApproveProxy contract");
  await deploy("WorldesApproveProxy", {
    contract: "WorldesApproveProxy",
    from: deployer,
    args: [worlderApprove.target],
  }).then((res) => {
    console.log("WorldesApproveProxy deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const worlderApproveProxy = await getDeployedContractWithDefaultName("WorldesApproveProxy");

  // Deploy WorldesDvmProxy
  console.log("- Deployment of WorldesDvmProxy contract");
  await deploy("WorldesDvmProxy", {
    contract: "WorldesDvmProxy",
    from: deployer,
    args: [dvmFactory.target, await getWethAddress(), worlderApproveProxy.target],
  }).then((res) => {
    console.log("WorldesDvmProxy deployed to: %s, %s", res.address, res.newlyDeployed);
  });

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
