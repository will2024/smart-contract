
import { config } from "dotenv";
config({ path: "../.env" });
import hre from "hardhat";
import { ethers } from "hardhat";
import { getDeployedContract, getDeployedContractWithDefaultName } from "./utils/env-utils";

const func = async function () {
  const { getNamedAccounts, deployments } = hre;
  const { deployer } = await getNamedAccounts();

  const dvmProxy = await getDeployedContractWithDefaultName("WorldesDvmProxy");
  const dspProxy = await getDeployedContractWithDefaultName("WorldesDspProxy");
  const dvmFactory = await getDeployedContractWithDefaultName("DVMFactory");
  const dspFactory = await getDeployedContractWithDefaultName("DSPFactory");
  const aproveContract = await getDeployedContractWithDefaultName("WorldesApprove");
  const USDE = await getDeployedContract("TestnetERC20", "USDE");
  const USDT = await getDeployedContract("TestnetERC20", "USDT");
  const mockA = await getDeployedContract("TestnetERC20", "MOCKA");
  const mockB = await getDeployedContract("TestnetERC20", "MOCKB");
  const mockC = await getDeployedContract("TestnetERC20", "MOCKC");
  const mockD = await getDeployedContract("TestnetERC20", "MOCKD");
  const mockE = await getDeployedContract("TestnetERC20", "MOCKE");
  const mockF = await getDeployedContract("TestnetERC20", "MOCKF");
  // const WESE = await getDeployedContract("TestnetERC20", "WES");
  // const faucet = await getDeployedContractWithDefaultName("Faucet");
  // const oldFaucet = await ethers.getContractAt("Faucet", "0x9D6eC1Bba7C29F8fbb2883cd70F374d90c0F0136");
  const WETH = await ethers.getContractAt("WETH9", "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14");
  const WRP = await getDeployedContractWithDefaultName("WorldesPropertyRights");

  console.log("WorldesDvmProxy address: ", dvmProxy.target);
  console.log("USDE address: ", USDE.target);
  console.log("USDT address: ", USDT.target);
  console.log("MOCKF address: ", mockF.target);
  // console.log("Faucet address: ", faucet.target);
  console.log("current time: ", Math.floor(Date.now()/1000));
  console.log("WETH address: ", WETH.target);
  // console.log("oldFaucet address: ", oldFaucet.target);
  // console.log("WESE address: ", WESE.target);

  let tx;

  console.log(await WRP.balanceOf("0x07D613Cf314283114F764cd42C46858A7f482f21"));
  tx = await WRP.safeMint(
    "0x07D613Cf314283114F764cd42C46858A7f482f21",
    "0x384639c40DAb3137713A08e4dE838F9F8749d4Af",
    "https://lswy.s3-accelerate.amazonaws.com/worldes/nft/metadata/53204ba1b1fb4d6cab0f2f5747cb1ca6.json",
  );
  await tx.wait();
  console.log("safeMint", tx.hash);

  console.log(await WRP.balanceOf("0x07D613Cf314283114F764cd42C46858A7f482f21"));


  // tx = await faucet.mint(WESE.target, deployer, ethers.parseUnits("1000000", await WESE.decimals()));
  // await tx.wait();
  // console.log("mint WESE", tx.hash);



  // //mint USDE to deployer
  // await faucet.mint(USDE.target, deployer, ethers.parseUnits("10000", await USDE.decimals()));
  // //mint USDT to deployer
  // await faucet.mint(USDT.target, deployer, ethers.parseUnits("10000", await USDT.decimals()));
  // await faucet.mint(mockA.target, deployer, ethers.parseUnits("10000", await mockA.decimals()));
  // await faucet.mint(mockB.target, deployer, ethers.parseUnits("10000", await mockB.decimals()));
  // await faucet.mint(mockC.target, deployer, ethers.parseUnits("10000", await mockC.decimals()));
  // await faucet.mint(mockD.target, deployer, ethers.parseUnits("10000", await mockD.decimals()));
  // await faucet.mint(mockE.target, deployer, ethers.parseUnits("10000", await mockE.decimals()));
  // await faucet.mint(mockF.target, deployer, ethers.parseUnits("10000", await mockF.decimals()));
  // await WETH.deposit({value: ethers.parseUnits("0.01", 18)});
  // tx = await oldFaucet.transferOwnershipOfChild(
  //   [
  //     USDE.target, 
  //     USDT.target,
  //     mockA.target,
  //     mockB.target,
  //     mockC.target,
  //     mockD.target,
  //     mockE.target,
  //     mockF.target,
  //     WESE.target
  //   ], 
  //   faucet.target
  // );
  // await tx.wait();

  // await faucet.mint(USDE.target, deployer, ethers.parseUnits("1000000", await USDE.decimals()));
  // //mint USDT to deployer
  // await faucet.mint(USDT.target, deployer, ethers.parseUnits("1000000", await USDT.decimals()));
  // await faucet.mint(mockA.target, deployer, ethers.parseUnits("1000000", await mockA.decimals()));
  // await faucet.mint(mockB.target, deployer, ethers.parseUnits("1000000", await mockB.decimals()));
  // await faucet.mint(mockC.target, deployer, ethers.parseUnits("1000000", await mockC.decimals()));
  // await faucet.mint(mockD.target, deployer, ethers.parseUnits("1000000", await mockD.decimals()));
  // await faucet.mint(mockE.target, deployer, ethers.parseUnits("1000000", await mockE.decimals()));
  // await faucet.mint(mockF.target, deployer, ethers.parseUnits("1000000", await mockF.decimals()));
  // console.log(await USDE.balanceOf(deployer));
  // console.log(await USDT.balanceOf(deployer));
  // console.log(await mockA.balanceOf(deployer));
  // console.log(await mockB.balanceOf(deployer));
  // console.log(await mockC.balanceOf(deployer));
  // console.log(await mockD.balanceOf(deployer));
  // console.log(await mockE.balanceOf(deployer));
  // console.log(await mockF.balanceOf(deployer));
  // console.log(await WESE.balanceOf(deployer));



  // //aproval to worldesApproveProxy
  // await WETH.approve(aproveContract.target, ethers.parseUnits("200", await WETH.decimals()));
  // await USDT.approve(aproveContract.target, ethers.parseUnits("200", await USDT.decimals()));
  // await USDE.approve(aproveContract.target, ethers.parseUnits("200", await USDE.decimals()));
  // await mockF.approve(aproveContract.target, ethers.parseUnits("200", await mockF.decimals()));

  // //create pool
  // tx = await dvmProxy.createVendingMachine(
  //   WETH.target,
  //   USDE.target,
  //   ethers.parseUnits("0.01", await WETH.decimals()),
  //   ethers.parseUnits("30", await USDE.decimals()),
  //   ethers.parseUnits("0.003", 18),
  //   100000,
  //   ethers.parseUnits("1", 18),
  //   false,
  //   Math.floor(Date.now()/1000) + 60
  // ); 
  // await tx.wait();

  // console.log(await dvmFactory.getPairPool(WETH.target, USDE.target));
  
  // //create stable pair
  // tx = await dspProxy.createStablePair(
  //   USDT.target,
  //   USDE.target,
  //   ethers.parseUnits("200", await USDT.decimals()),
  //   ethers.parseUnits("200", await USDE.decimals()),
  //   ethers.parseUnits("0.003", 18),
  //   100000,
  //   ethers.parseUnits("0.01", 18),
  //   true,
  //   Math.floor(Date.now()/1000) + 60
  // );
  // await tx.wait();

  // console.log(await dspFactory.getPairPoolByUser(deployer));

};

func().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
