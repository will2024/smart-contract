
import { verifyContract } from "../utils/verify-helper";
import hre from "hardhat";
import { ethers } from "hardhat";

const func = async function () {
  const { getNamedAccounts, deployments } = hre;
  const { deployer } = await getNamedAccounts();

  //verify WorldesRWATokenFactory
  console.log("\n- Verifying WorldesRWATokenFactory...\n");
  const WorldesRWATokenFactory = await deployments.get("WorldesRWATokenFactory");
  const WorldesRWATokenFactoryParams :string[] = [deployer];
  await verifyContract(
    "WorldesRWATokenFactory",
    WorldesRWATokenFactory.address,
    "contracts/asset/WorldesRWATokenFactory.sol:WorldesRWATokenFactory",
    WorldesRWATokenFactoryParams
  );

  //verify WorldesPropertyRights
  console.log("\n- Verifying WorldesPropertyRights...\n");
  const WorldesPropertyRights = await deployments.get("WorldesPropertyRights");
  const WorldesPropertyRightsParams :string[] = [deployer, WorldesRWATokenFactory.address];
  await verifyContract(
    "WorldesPropertyRights",
    WorldesPropertyRights.address,
    "contracts/asset/WorldesPropertyRights.sol:WorldesPropertyRights",
    WorldesPropertyRightsParams
  );

};

func().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
