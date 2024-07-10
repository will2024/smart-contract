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
  const worlderDvmProxy = await getDeployedContractWithDefaultName("WorldesDvmProxy");
  const worlderDspProxy = await getDeployedContractWithDefaultName("WorldesDspProxy");

  // ——————————————deploy helper————————————————————
  console.log("start deploy helper");

  const dvmFactory = await worlderDvmProxy._DVM_FACTORY_();
  const dspFactory = await worlderDspProxy._DSP_FACTORY_();

  // Deploy WorldesRouterHelper
  console.log("- Deployment of WorldesRouterHelper contract");
  await deploy("WorldesRouterHelper", {
    contract: "WorldesRouterHelper",
    from: deployer,
    args: [dvmFactory, dspFactory],
  }).then((res) => {
    console.log("WorldesRouterHelper deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  
  console.log("deploy helper done");
};

//
export default deployFunction;
deployFunction.tags = ["hepler"];
if (hre.network.name == "hardhat") {
  deployFunction.dependencies = ["libs", "dvm", "dsp", "mocks"];  
} else {
  deployFunction.dependencies = ["dsp"];  
}
