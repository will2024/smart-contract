
import { verifyContract } from "../utils/verify-helper";
import hre from "hardhat";
import { ethers } from "hardhat";
import { SymbolMap, decimalsType } from "../../deploy/00-deploy-mocks";

const func = async function () {
  const { getNamedAccounts, deployments } = hre;
  const { deployer } = await getNamedAccounts();

  let reserveSymbols = ["USDT", "USDE", "MOCKA", "MOCKB", "MOCKC", "MOCKD", "MOCKE", "MOCKF"];
  let reservesConfig = {
    USDT: { reserveDecimals: 9 },
    USDE: { reserveDecimals: 9 },
    MOCKA: { reserveDecimals: 18 },
    MOCKB: { reserveDecimals: 18 },
    MOCKC: { reserveDecimals: 18 },
    MOCKD: { reserveDecimals: 18 },
    MOCKE: { reserveDecimals: 12 },
    MOCKF: { reserveDecimals: 9 },
  } as SymbolMap<decimalsType>;

  const Faucet = await deployments.get("Faucet");

  // verify Faucet
  console.log("\n- Verifying Faucet...\n");
  console.log("deployer address: ", deployer);
  const FaucetParams :string[] = [deployer, "false"];
  await verifyContract(
    "Faucet",
    Faucet.address,
    "contracts/mock/Faucet.sol:Faucet",
    FaucetParams
  );

  for (const token of reserveSymbols) {
    console.log("\n- Verifying " + token + "...\n");
    let decimals = reservesConfig[token].reserveDecimals;
    const TOKEN = await deployments.get(token);
    const TOKENParams :string[] = [
      token, 
      token.toUpperCase(), 
      decimals.toString(), 
      Faucet.address
    ];
    await verifyContract(
      token,
      TOKEN.address,
      "contracts/mock/TestnetERC20.sol:TestnetERC20",
      TOKENParams
    );
  }

};

func().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
