import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import { config } from "dotenv";
import { getDeployedContractWithDefaultName } from "../scripts/utils/env-utils";
config({ path: "../.env" });

export interface SymbolMap<T> {
  [symbol: string]: T;
}

export type decimalsType = {
  reserveDecimals: number;
};

const deployFunction: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();
  console.log("deployer: ", deployer);
  
  if (hre.network.name == "hardhat") {
    //deploy WETH9Mock
    await deploy("WETH", {
      contract: "WETH9",
      from: deployer,
      args: [],
    }).then((res) => {
      console.log("WETH deployed to: %s, %s", res.address, res.newlyDeployed);
    });
  }

  //Deploy FaucetOwnable contract
  console.log("- Deployment of FaucetOwnable contract");
  await deploy("Faucet", {
    contract: "Faucet",
    args: [deployer, false],
    from: deployer,
  }).then((res) => {
    console.log("Faucet deployed to: %s, %s", res.address, res.newlyDeployed);
  });
  const faucet = await getDeployedContractWithDefaultName("Faucet");

  // Deploy mock tokens
  // let reserveSymbols = ["USDT", "USDE", "MOCKA", "MOCKB", "MOCKC", "MOCKD", "MOCKE", "MOCKF"];
  // let reservesConfig = {
  //   USDT: { reserveDecimals: 9 },
  //   USDE: { reserveDecimals: 9 },
  //   MOCKA: { reserveDecimals: 18 },
  //   MOCKB: { reserveDecimals: 18 }, 
  //   MOCKC: { reserveDecimals: 18 },
  //   MOCKD: { reserveDecimals: 18 },
  //   MOCKE: { reserveDecimals: 12 },
  //   MOCKF: { reserveDecimals: 9 },
  // } as SymbolMap<decimalsType>;
  // let reserveSymbols = ["WES"];
  // let reservesConfig = {
  //   WES: { reserveDecimals: 18 },
  // } as SymbolMap<decimalsType>;

  // for (const token of reserveSymbols) {
  //   let decimals = reservesConfig[token].reserveDecimals;
  //   await deploy(token, {
  //     contract: "TestnetERC20",
  //     from: deployer,
  //     args: [
  //       token, 
  //       token.toUpperCase(), 
  //       decimals, 
  //       faucet.target
  //     ],
  //   }).then((res) => {
  //     console.log("%s deployed to: %s, %s", token, res.address, res.newlyDeployed);
  //   });
  // }

};

//
export default deployFunction;
deployFunction.tags = ["mocks"];
