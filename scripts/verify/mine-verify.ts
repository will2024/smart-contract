
import { verifyContract } from "../utils/verify-helper";
import hre from "hardhat";
import { ethers } from "hardhat";

const func = async function () {
  const { getNamedAccounts, deployments } = hre;
  const { deployer } = await getNamedAccounts();

  // ——————————————verify mine————————————————————
  const CloneFactory = await deployments.get("CloneFactory");
  const WorldesApproveProxy = await deployments.get("WorldesApproveProxy");
  const ERC20Mine = await deployments.get("ERC20Mine");
  const WorldesMineRegistry = await deployments.get("WorldesMineRegistry");
  const WorldesMineProxy = await deployments.get("WorldesMineProxy");
  const WorldesAirdrop = await deployments.get("WorldesAirdrop");

  //verify ERC20Mine template
  console.log("\n- Verifying ERC20Mine template...\n");
  const ERC20MineParams :string[] = [];
  await verifyContract(
    "ERC20Mine",
    ERC20Mine.address,
    "contracts/mining/ERC20Mine.sol:ERC20Mine",
    ERC20MineParams
  );

  //verify WorldesMineRegistry
  console.log("\n- Verifying WorldesMineRegistry...\n");
  const WorldesMineRegistryParams :string[] = [];
  await verifyContract(
    "WorldesMineRegistry",
    WorldesMineRegistry.address,
    "contracts/mining/WorldesMineRegistry.sol:WorldesMineRegistry",
    WorldesMineRegistryParams
  );

  //verify WorldesMineProxy
  console.log("\n- Verifying WorldesMineProxy...\n");
  const WorldesMineProxyParams :string[] = [
    CloneFactory.address,
    ERC20Mine.address,
    WorldesApproveProxy.address,
    WorldesMineRegistry.address,
  ];
  await verifyContract(
    "WorldesMineProxy",
    WorldesMineProxy.address,
    "contracts/proxy/WorldesMineProxy.sol:WorldesMineProxy",
    WorldesMineProxyParams
  );

  //verify WorldesAirdrop
  console.log("\n- Verifying WorldesAirdrop...\n");
  const WorldesAirDropParams :string[] = [];
  await verifyContract(
    "WorldesAirdrop",
    WorldesAirdrop.address,
    "contracts/mining/WorldesAirdrop.sol:WorldesAirdrop",
    WorldesAirDropParams
  );
};

func().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
