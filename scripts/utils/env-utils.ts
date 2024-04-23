import hre, { deployments, ethers } from "hardhat";
import { config } from "dotenv";
config({ path: "../.env" });

export const getAddress = (name: string) => {
  const configName = name.toUpperCase() + "_" + hre.network.name.toUpperCase();
  const address = process.env[configName];
  console.log("Get address for %s: %s", configName, address);
  return address || "";
};

export const getWethAddress = async () => {
  if (hre.network.name === "hardhat") {
    return (await deployments.get("WETH")).address;
  } else {
    return getAddress("weth");
  }
};

export const getDeployedContractWithDefaultName = async (contractName: string) => {
  return await getDeployedContract(contractName, contractName);
};

export const getDeployedContract = async (contractName: string, deployName: string) => {
  let deployedAddr = (await deployments.get(deployName)).address;
  return await ethers.getContractAt(contractName, deployedAddr);
};