import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import hre from "hardhat";

import { config } from "dotenv";
import { getDeployedContractWithDefaultName } from "../scripts/utils/env-utils";
import { ADDRESS_ZERO } from "../graph/src/utils/constant";
config({ path: "../.env" });

const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  console.log("deployer: ", deployer);
  let tx;
  
  // ——————————————load deployed contacts————————————————————
  

  // ——————————————deploy airdrop————————————————————
  console.log("start deploy airdrop");

  //deploy WorldesRWATokenFactory
  await deploy("WorldesAirdrop", {
    contract: "WorldesAirdrop",
    from: deployer,
    args: [ADDRESS_ZERO],
  }).then((res) => {
    console.log("WorldesAirdrop deployed to: %s, %s", res.address, res.newlyDeployed);
  });

  console.log("airdrop done");
}

//
export default deployFunction;
deployFunction.tags = ["airdrop"];
