
import { verifyContract } from "../utils/verify-helper";
import hre from "hardhat";
import { ethers } from "hardhat";

const func = async function () {
  const { getNamedAccounts, deployments } = hre;
  const { deployer } = await getNamedAccounts();

  //verify WorldesRWAToken
  console.log("\n- Verifying WorldesRWAToken...\n");
  const WorldesRWAToken = await deployments.get("WorldesRWAToken");
  const WorldesRWATokenParams :string[] = [];
  await verifyContract(
    "WorldesRWAToken",
    WorldesRWAToken.address,
    "contracts/asset/WorldesRWAToken.sol:WorldesRWAToken",
    WorldesRWATokenParams
  );

  //verify WorldesRWATokenFactory
  console.log("\n- Verifying WorldesRWATokenFactory...\n");
  const CloneFactory = await deployments.get("CloneFactory");
  const WorldesRWATokenFactory = await deployments.get("WorldesRWATokenFactory");
  const WorldesRWATokenFactoryParams :string[] = [deployer, CloneFactory.address, WorldesRWAToken.address];
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
