
import { verifyContract } from "../utils/verify-helper";
import hre from "hardhat";
import { ethers } from "hardhat";
import { getWethAddress } from "../utils/env-utils";

const func = async function () {
  const { getNamedAccounts, deployments } = hre;
  const { deployer } = await getNamedAccounts();

  // get deployed contracts
  const CloneFactory = await deployments.get("CloneFactory");
  const FeeRateModel = await deployments.get("FeeRateModel");
  const DVMTemplate = await deployments.get("DVM");
  const DSPTemplate = await deployments.get("DSP");
  const DVMFactory = await deployments.get("DVMFactory");
  const DSPFactory = await deployments.get("DSPFactory");
  const WorldesApprove = await deployments.get("WorldesApprove");
  const WorldesApproveProxy = await deployments.get("WorldesApproveProxy");
  const WorldesDvmProxy = await deployments.get("WorldesDvmProxy");
  const WorldesDspProxy = await deployments.get("WorldesDspProxy");
  const WorldesRouterHelper = await deployments.get("WorldesRouterHelper");


  // verify CloneFactory
  console.log("\n- Verifying CloneFactory...\n");
  const CloneFactoryParams :string[] = [];
  await verifyContract(
    "CloneFactory",
    CloneFactory.address,
    "contracts/libraries/CloneFactory.sol:CloneFactory",
    CloneFactoryParams
  );

  // verify FeeRateModel
  console.log("\n- Verifying FeeRateModel...\n");
  const FeeRateModelParams :string[] = [];
  await verifyContract(
    "FeeRateModel",
    FeeRateModel.address,
    "contracts/libraries/FeeRateModel.sol:FeeRateModel",
    FeeRateModelParams
  );

  // verify DVM
  console.log("\n- Verifying DVM...\n");
  const DVMTemplateParams :string[] = [];
  await verifyContract(
    "DVM",
    DVMTemplate.address,
    "contracts/vendingMachine/implements/DVM.sol:DVM",
    DVMTemplateParams
  );

  // verify DSP
  console.log("\n- Verifying DSP...\n");
  const DSPTemplateParams :string[] = [];
  await verifyContract(
    "DSP",
    DSPTemplate.address,
    "contracts/stablePool/implements/DSP.sol:DSP",
    DSPTemplateParams
  );

  // verify DVMFactory
  console.log("\n- Verifying DVMFactory...\n");
  const DVMFactoryParams :string[] = [
    CloneFactory.address,
    DVMTemplate.address,
    deployer,
    FeeRateModel.address,
  ];
  await verifyContract(
    "DVMFactory",
    DVMFactory.address,
    "contracts/factory/DVMFactory.sol:DVMFactory",
    DVMFactoryParams
  );

  // verify DSPFactory
  console.log("\n- Verifying DSPFactory...\n");
  const DSPFactoryParams :string[] = [
    CloneFactory.address,
    DSPTemplate.address,
    deployer,
    FeeRateModel.address,
  ];
  await verifyContract(
    "DSPFactory",
    DSPFactory.address,
    "contracts/factory/DSPFactory.sol:DSPFactory",
    DSPFactoryParams
  );

  // verify WorldesApprove
  console.log("\n- Verifying WorldesApprove...\n");
  const WorldesApproveParams :string[] = [];
  await verifyContract(
    "WorldesApprove",
    WorldesApprove.address,
    "contracts/proxy/WorldesApprove.sol:WorldesApprove",
    WorldesApproveParams
  );

  // verify WorldesApproveProxy
  console.log("\n- Verifying WorldesApproveProxy...\n");
  const WorldesApproveProxyParams :string[] = [
    WorldesApprove.address,
  ];
  await verifyContract(
    "WorldesApproveProxy",
    WorldesApproveProxy.address,
    "contracts/proxy/WorldesApproveProxy.sol:WorldesApproveProxy",
    WorldesApproveProxyParams
  );

  // verify WorldesDvmProxy
  console.log("\n- Verifying WorldesDvmProxy...\n");
  const WorldesDvmProxyParams :string[] = [
    DVMFactory.address,
    await getWethAddress(),
    WorldesApproveProxy.address,
  ];
  await verifyContract(
    "WorldesDvmProxy",
    WorldesDvmProxy.address,
    "contracts/proxy/WorldesDvmProxy.sol:WorldesDvmProxy",
    WorldesDvmProxyParams
  );
  
  // verify WorldesDspProxy
  console.log("\n- Verifying WorldesDspProxy...\n");
  const WorldesDspProxyParams :string[] = [
    DSPFactory.address,
    await getWethAddress(),
    WorldesApproveProxy.address,
  ];
  await verifyContract(
    "WorldesDspProxy",
    WorldesDspProxy.address,
    "contracts/proxy/WorldesDspProxy.sol:WorldesDspProxy",
    WorldesDspProxyParams
  );

  // verify WorldesRouterHelper
  console.log("\n- Verifying WorldesRouterHelper...\n");
  const WorldesRouterHelperParams :string[] = [
    WorldesDvmProxy.address,
    WorldesDspProxy.address,
  ];
  await verifyContract(
    "WorldesRouterHelper",
    WorldesRouterHelper.address,
    "contracts/helper/WorldesRouterHelper.sol:WorldesRouterHelper",
    WorldesRouterHelperParams
  );

  // ——————————————verify limit order————————————————————
  const WorldesLimitOrder = await deployments.get("WorldesLimitOrder");
  const WorldesLimitOrderBot = await deployments.get("WorldesLimitOrderBot");

  // verify WorldesLimitOrder
  console.log("\n- Verifying WorldesLimitOrder...\n");
  const WorldesLimitOrderParams :string[] = [];
  await verifyContract(
    "WorldesLimitOrder",
    WorldesLimitOrder.address,
    "contracts/limitOrder/WorldesLimitOrder.sol:WorldesLimitOrder",
    WorldesLimitOrderParams
  );

  // verify WorldesLimitOrderBot
  console.log("\n- Verifying WorldesLimitOrderBot...\n");
  const WorldesLimitOrderBotParams :string[] = [];
  await verifyContract(
    "WorldesLimitOrderBot",
    WorldesLimitOrderBot.address,
    "contracts/limitOrder/WorldesLimitOrderBot.sol:WorldesLimitOrderBot",
    WorldesLimitOrderBotParams
  );

};

func().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
