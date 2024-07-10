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

  // ——————————————deploy dsp————————————————————
  console.log("start deploy dsp");

  // Deploy DSP template
  console.log("- Deployment of DSP template contract");
  await deploy("DSP", {
    contract: "DSP",
    from: deployer,
  }).then((res) => {
    console.log("DSPTemplate deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const dspTemplate = await getDeployedContractWithDefaultName("DSP");

  // Deploy DSPFactory
  console.log("- Deployment of DSPFactory contract");
  await deploy("DSPFactory", {
    contract: "DSPFactory",
    from: deployer,
    args: [cloneFactory.target, dspTemplate.target, deployer, feeRateModelTemplate.target],
  }).then((res) => {
    console.log("DSPFactory deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const dspFactory = await getDeployedContractWithDefaultName("DSPFactory");

  // Deploy WorldesDspProxy
  console.log("- Deployment of WorldesDspProxy contract");
  await deploy("WorldesDspProxy", {
    contract: "WorldesDspProxy",
    from: deployer,
    args: [dspFactory.target, await getWethAddress(), worlderApproveProxy.target],
  }).then((res) => {
    console.log("WorldesDspProxy deployed to: %s, %s", res.address, res.newlyDeployed);
  });

  console.log("deploy dsp done");
};

//
export default deployFunction;
deployFunction.tags = ["dsp"];
if (hre.network.name == "hardhat") {
  deployFunction.dependencies = ["libs", "dvm", "mocks"];  
} else {
  deployFunction.dependencies = ["dvm"];  
}
