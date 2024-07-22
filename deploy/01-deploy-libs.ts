import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import { config } from "dotenv";
import { getDeployedContractWithDefaultName } from "../scripts/utils/env-utils";
import { ADDRESS_ZERO } from "../graph/src/utils/constant";
config({ path: "../.env" });

const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  console.log("deployer: ", deployer);

  // ——————————————deploy lib-logic————————————————————
  console.log("start deploy lib-logic");
  
  // Deploy CloneFactory
  console.log("- Deployment of CloneFactory contract");
  await deploy("CloneFactory", {
    contract: "CloneFactory",
    from: deployer,
  }).then((res) => {
    console.log("CloneFactory deployed to: %s, %s", res.address, res.newlyDeployed);
  });

  // Deploy fee rate model template
  console.log("- Deployment of FeeRateModel template contract");
  await deploy("FeeRateModel", {
    contract: "FeeRateModel",
    from: deployer,
  }).then((res) => {
    console.log("FeeRateModelTemplate deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const feeRateModelTemplate = await getDeployedContractWithDefaultName("FeeRateModel");

  let fee_owner = await feeRateModelTemplate._OWNER_();
  if (fee_owner === ADDRESS_ZERO) {
    let tx = await feeRateModelTemplate.initOwner(deployer);
    await tx.wait().then(() => {
      console.log("FeeRateModel initOwner done!");
    });
  }

  // Deploy FeeRateDIP3Impl
  console.log("- Deployment of FeeRateDIP3Impl contract");
  await deploy("FeeRateDIP3Impl", {
    contract: "FeeRateDIP3Impl",
    from: deployer,
  }).then((res) => {
    console.log("FeeRateDIP3Impl deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const feeRateDIP3Impl = await getDeployedContractWithDefaultName("FeeRateDIP3Impl");

  let tx = await feeRateModelTemplate.setFeeProxy(feeRateDIP3Impl.target);
  await tx.wait().then(() => {
    console.log("FeeRateModel setFeeProxy done!");
  });

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
  
  console.log("deploy lib-logic done!");
};
export default deployFunction;
deployFunction.tags = ["libs"];
