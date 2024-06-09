import { MinePool, RewardDetail } from "../../../generated/schema";
// import { CreateMine } from "../../../generated/WorldesMineProxy/WorldesMineProxy";
import { CreateMine as V2CreateMine } from "../../../generated/WorldesMineProxy/WorldesMineProxy";
import { ERC20Mine as ERC20MineTemplate } from "../../../generated/templates";

import { getRewardNum, rewardTokenInfos, getToken } from "./helper";
import { BigInt, log } from "@graphprotocol/graph-ts";

// export function handleCreateMine(event: CreateMine): void {
//   let minePool = MinePool.load(event.params.mineV3.toHexString());

//   if (minePool == null) {
//     minePool = new MinePool(event.params.mineV3.toHexString());
//   }
//   minePool.creator = event.params.account;
//   minePool.pool = event.params.mineV3;
//   minePool.timestamp = event.block.timestamp;
//   minePool.stakeToken = getToken(event.params.mineV3);

//   let rewardTokensNum = getRewardNum(event.params.mineV3);

//   for (let i = 0; i < rewardTokensNum.toI32(); i++) {
//     let rewardData = rewardTokenInfos(event.params.mineV3, BigInt.fromI32(i));
//     let detailID = event.params.mineV3
//       .toHexString()
//       .concat("-")
//       .concat(rewardData.value0.toHexString());
//     let rewardDetail = RewardDetail.load(detailID);

//     if (rewardDetail == null) {
//       rewardDetail = new RewardDetail(detailID);
//     }
//     rewardDetail.minePool = minePool.id;
//     rewardDetail.token = rewardData.value0;
//     rewardDetail.startBlock = rewardData.value1;
//     rewardDetail.endBlock = rewardData.value2;
//     rewardDetail.rewardPerBlock = rewardData.value4;
//     rewardDetail.updatedAt = event.block.timestamp;
//     rewardDetail.save();
//   }

//   minePool.updatedAt = event.block.timestamp;
//   minePool.save();

//   //will get "fatalError":{"message":"type mismatch with parameters: expected 1 types, found 0"
//   log.debug("mineV3 address: {}", [event.params.mineV3.toHexString()]);
//   log.info("mineV3 address: {}", [event.params.mineV3.toHexString()]);
//   ERC20MineTemplate.create(event.params.mineV3);
// }

export function handleV2CreateMine(event: V2CreateMine): void {
  let minePool = MinePool.load(event.params.mine.toHexString());

  if (minePool == null) {
    minePool = new MinePool(event.params.mine.toHexString());
  }
  minePool.creator = event.params.account;
  minePool.pool = event.params.mine;
  minePool.timestamp = event.block.timestamp;
  minePool.platform = event.params.platform;
  minePool.stakeToken = getToken(event.params.mine);

  let rewardTokensNum = getRewardNum(event.params.mine);

  for (let i = 0; i < rewardTokensNum.toI32(); i++) {
    let rewardData = rewardTokenInfos(event.params.mine, BigInt.fromI32(i));
    let detailID = event.params.mine
      .toHexString()
      .concat("-")
      .concat(rewardData.value0.toHexString());
    let rewardDetail = RewardDetail.load(detailID);

    if (rewardDetail == null) {
      rewardDetail = new RewardDetail(detailID);
    }
    rewardDetail.minePool = minePool.id;
    rewardDetail.token = rewardData.value0;
    rewardDetail.startBlock = rewardData.value1;
    rewardDetail.endBlock = rewardData.value2;
    rewardDetail.rewardPerBlock = rewardData.value4;
    rewardDetail.updatedAt = event.block.timestamp;
    rewardDetail.save();
  }

  minePool.updatedAt = event.block.timestamp;
  minePool.save();

  //will get "fatalError":{"message":"type mismatch with parameters: expected 1 types, found 0"
  log.debug("mine address: {}", [event.params.mine.toHexString()]);
  log.info("mine address: {}", [event.params.mine.toHexString()]);
  ERC20MineTemplate.create(event.params.mine);
}
