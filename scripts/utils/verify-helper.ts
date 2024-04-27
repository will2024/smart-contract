import { Contract } from "ethers";
import hre from "hardhat";

const fatalErrors = [
  `The address provided as argument contains a contract, but its bytecode`,
  `Daily limit of 100 source code submissions reached`,
  `has no bytecode. Is the contract deployed to this network`,
  `The constructor for`,
];

const okErrors = [`Contract source code already verified`, `Already Verified`];

const unableVerifyError = "Fail - Unable to verify";

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// export const verifyContract = async (
//   name: string, 
//   instance: string, 
//   args?: (string | string[])[],
//   libraries?: (string | string[])[]
// ) => {
//   if (name == "TakerUpgradeableProxy") {
//     await verifyEtherscanContract(
//       name,
//       instance,
//       args,
//       libraries,
//       "contracts/libraries/proxy/TakerUpgradeableProxy.sol:TakerUpgradeableProxy"
//     );
//   } else {
//     await verifyEtherscanContract(name, instance, args, libraries);
//   }
//   return instance;
// };

export const verifyContract = async (
  name: string,
  address: string,
  contract: string,
  constructorArguments: (string | string[])[],
  libraries?: (string | string[])[]
) => {

  try {
    console.log("======>Start verify %s contract(%s)", name, address);
    const msDelay = 3000;
    const times = 2;

    const params = {
      address: address,
      constructorArguments,
      libraries,
      contract,
      relatedSources: true,
    };
    await runTaskWithRetry("verify:verify", params, name, times, msDelay);
  } catch (error: any) {}
};

export const runTaskWithRetry = async (
  task: string,
  params: any,
  name: string,
  times: number,
  msDelay: number
) => {
  let counter = times;
  await delay(msDelay);

  try {
    if (times >= 1) {
      await hre.run(task, params);
    }  else if (times === 1) {
      console.log("[ETHERSCAN][WARNING] Trying to verify via uploading all sources.");
      delete params.relatedSources;
      await hre.run(task, params);
    } else {
      console.error("[ETHERSCAN][ERROR] Errors after all the retries, check the logs for more information.");
      console.info("%s contract(%s) verify failed!", name, params.address);
    }

    if (times >= 1) {
      console.info("%s contract(%s) verify successed!", name, params.address);
    }
  } catch (error: any) {
    counter--;

    if (okErrors.some((okReason) => error.message.includes(okReason))) {
      console.info("[ETHERSCAN][INFO] Skipping due OK response: ", error.message);
      return;
    }

    if (fatalErrors.some((fatalError) => error.message.includes(fatalError))) {
      console.error("[ETHERSCAN][ERROR] Fatal error detected, skip retries and resume deployment.", error.message);
      return;
    }

    console.error("[ETHERSCAN][ERROR]", error.message);
    console.log();
    console.info(`[ETHERSCAN][[INFO] Retrying attemps: ${counter}.`);
    await runTaskWithRetry(task, params, name, counter, msDelay);
    if (error.message.includes(unableVerifyError)) {
      console.log("[ETHERSCAN][WARNING] Trying to verify via uploading all sources.");
      delete params.relatedSources;
    }

  }

};
