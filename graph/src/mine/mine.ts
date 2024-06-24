import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import {
  Deposit,
  Withdraw,
  NewRewardToken,
  UpdateReward,
  UpdateEndTime,
  DepositByRobot,
  WithdrawByRobot,
} from "../../../generated/templates/ERC20Mine/ERC20Mine";
import { MinePool, RewardDetail, StakeHistory, UserStake, StakeDetail, RobotStakeHistory } from "../../../generated/schema";
import { getRewardNum, rewardTokenInfos } from "./helper";

export function handleDeposit(event: Deposit): void {
  let id = event.params.user
    .toHexString()
    .concat("-")
    .concat(event.address.toHexString());
  let userStake = UserStake.load(id);
  if (userStake == null) {
    userStake = new UserStake(id);
    userStake.user = event.params.user;
    userStake.pool = event.address;
    userStake.balance = BigInt.fromI32(0);
  }
  userStake.balance = userStake.balance.plus(event.params.amount);
  userStake.updatedAt = event.block.timestamp;
  userStake.save();

  let minePool = MinePool.load(event.address.toHexString());
  if (minePool == null)  {
    log.error("minePool is null", []);
    return;
  }

  let stakeDetailId = event.params.stakeId.toHexString();
  let stakeDetail = StakeDetail.load(stakeDetailId);
  if (stakeDetail != null) {
    log.error("stakeDetail is not null", []);
    return;
  }
  
  if (stakeDetail == null) {
    stakeDetail = new StakeDetail(stakeDetailId);
    stakeDetail.user = event.params.user;
    stakeDetail.pool = minePool.id;
    stakeDetail.amount = event.params.amount;
    stakeDetail.stakeTime = event.block.timestamp;
    stakeDetail.unlockTime = event.block.timestamp.plus(minePool.lockDuration!);
    stakeDetail.withdrawTime = BigInt.fromI32(0);
  }
  stakeDetail.save();

  let userStakeHistoryId = event.transaction.hash.toHexString().concat("-").concat(event.logIndex.toString());
  let userStakeHistory = StakeHistory.load(userStakeHistoryId);
  if (userStakeHistory != null) {
    log.error("userStakeHistory is not null", []);
    return;
  }
  if (userStakeHistory == null) {
    userStakeHistory = new StakeHistory(userStakeHistoryId);
    userStakeHistory.user = event.params.user;
    userStakeHistory.pool = minePool.id;
    userStakeHistory.amount = event.params.amount;
    userStakeHistory.updatedAt = event.block.timestamp;
    userStakeHistory.type = "DEPOSIT";
  }
  userStakeHistory.save();
}

export function handleWithdraw(event: Withdraw): void {
  let id = event.params.user
    .toHexString()
    .concat("-")
    .concat(event.address.toHexString());
  let userStake = UserStake.load(id);
  if (userStake == null) {
    userStake = new UserStake(id);
    userStake.user = event.params.user;
    userStake.pool = event.address;
    userStake.balance = BigInt.fromI32(0);
  }
  userStake.balance = userStake.balance.minus(event.params.amount);
  userStake.updatedAt = event.block.timestamp;
  userStake.save();

  let minePool = MinePool.load(event.address.toHexString());
  if (minePool == null)  {
    log.error("minePool is null", []);
    return;
  }

  let stakeDetailId = event.params.stakeId.toHexString();
  let stakeDetail = StakeDetail.load(stakeDetailId);
  if (stakeDetail == null) {
    log.error("stakeDetail is null", []);
    return;
  }
  stakeDetail.withdrawTime = event.block.timestamp;
  stakeDetail.save();

  let userStakeHistoryId = event.transaction.hash.toHexString().concat("-").concat(event.logIndex.toString());
  let userStakeHistory = StakeHistory.load(userStakeHistoryId);
  if (userStakeHistory != null) {
    log.error("userStakeHistory is not null", []);
    return;
  }
  if (userStakeHistory == null) {
    userStakeHistory = new StakeHistory(userStakeHistoryId);
    userStakeHistory.user = event.params.user;
    userStakeHistory.pool = minePool.id;
    userStakeHistory.amount = event.params.amount;
    userStakeHistory.updatedAt = event.block.timestamp;
    userStakeHistory.type = "WITHDRAW";
  }
  userStakeHistory.save();
}

export function handleDepositByRobot(event: DepositByRobot): void {
  let minePool = MinePool.load(event.address.toHexString());
  if (minePool == null)  {
    log.error("minePool is null", []);
    return;
  }

  let robotStakeHistoryId = event.transaction.hash.toHexString().concat("-").concat(event.logIndex.toString());
  let robotStakeHistory = RobotStakeHistory.load(robotStakeHistoryId);
  if (robotStakeHistory != null) {
    log.error("robotStakeHistory is not null", []);
    return;
  }
  if (robotStakeHistory == null) {
    robotStakeHistory = new RobotStakeHistory(robotStakeHistoryId);
    robotStakeHistory.robot = event.params.robot;
    robotStakeHistory.pool = minePool.id;
    robotStakeHistory.amount = event.params.amount;
    robotStakeHistory.updatedAt = event.block.timestamp;
    robotStakeHistory.type = "DEPOSIT";
  }
  robotStakeHistory.save();
}

export function handleWithdrawByRobot(event: WithdrawByRobot): void {
  let minePool = MinePool.load(event.address.toHexString());
  if (minePool == null)  {
    log.error("minePool is null", []);
    return;
  }

  let robotStakeHistoryId = event.transaction.hash.toHexString().concat("-").concat(event.logIndex.toString());
  let robotStakeHistory = RobotStakeHistory.load(robotStakeHistoryId);
  if (robotStakeHistory != null) {
    log.error("robotStakeHistory is not null", []);
    return;
  }
  if (robotStakeHistory == null) {
    robotStakeHistory = new RobotStakeHistory(robotStakeHistoryId);
    robotStakeHistory.robot = event.params.robot;
    robotStakeHistory.pool = minePool.id;
    robotStakeHistory.amount = event.params.amount;
    robotStakeHistory.updatedAt = event.block.timestamp;
    robotStakeHistory.type = "WITHDRAW";
  }
  robotStakeHistory.save();
}

export function handleNewRewardToken(event: NewRewardToken): void {
  let minePool = MinePool.load(event.address.toHexString());
  if (minePool == null) return;
  let rewardTokensNum = getRewardNum(event.address);

  for (let i = 0; i < rewardTokensNum.toI32(); i++) {
    let rewardData = rewardTokenInfos(event.address, BigInt.fromI32(i));
    let detailID = event.address
      .toHexString()
      .concat("-")
      .concat(rewardData.value0.toHexString());
    let rewardDetail = RewardDetail.load(detailID);

    if (rewardDetail == null) {
      rewardDetail = new RewardDetail(detailID);
    }
    rewardDetail.minePool = minePool.id;
    rewardDetail.token = rewardData.value0;
    rewardDetail.startTime = rewardData.value1;
    rewardDetail.endTime = rewardData.value2;
    rewardDetail.rewardPerSecond = rewardData.value4;
    rewardDetail.updatedAt = event.block.timestamp;
    rewardDetail.save();
  }

  minePool.updatedAt = event.block.timestamp;
  minePool.save();
}

export function handleUpdateEndTime(event: UpdateEndTime): void {
  let minePool = MinePool.load(event.address.toHexString());
  if (minePool == null) return;
  let rewardTokensNum = getRewardNum(event.address);

  for (let i = 0; i < rewardTokensNum.toI32(); i++) {
    let rewardData = rewardTokenInfos(event.address, BigInt.fromI32(i));
    let detailID = event.address
      .toHexString()
      .concat("-")
      .concat(rewardData.value0.toHexString());
    let rewardDetail = RewardDetail.load(detailID);

    if (rewardDetail == null) {
      rewardDetail = new RewardDetail(detailID);
    }
    rewardDetail.minePool = minePool.id;
    rewardDetail.token = rewardData.value0;
    rewardDetail.startTime = rewardData.value1;
    rewardDetail.endTime = rewardData.value2;
    rewardDetail.rewardPerSecond = rewardData.value4;
    rewardDetail.updatedAt = event.block.timestamp;
    rewardDetail.save();
  }

  minePool.updatedAt = event.block.timestamp;
  minePool.save();
}

export function handleUpdateReward(event: UpdateReward): void {
  let minePool = MinePool.load(event.address.toHexString());
  if (minePool == null) return;
  let rewardTokensNum = getRewardNum(event.address);

  for (let i = 0; i < rewardTokensNum.toI32(); i++) {
    let rewardData = rewardTokenInfos(event.address, BigInt.fromI32(i));
    let detailID = event.address
      .toHexString()
      .concat("-")
      .concat(rewardData.value0.toHexString());
    let rewardDetail = RewardDetail.load(detailID);

    if (rewardDetail == null) {
      rewardDetail = new RewardDetail(detailID);
    }
    rewardDetail.minePool = minePool.id;
    rewardDetail.token = rewardData.value0;
    rewardDetail.startTime = rewardData.value1;
    rewardDetail.endTime = rewardData.value2;
    rewardDetail.rewardPerSecond = rewardData.value4;
    rewardDetail.updatedAt = event.block.timestamp;
    rewardDetail.save();
  }

  minePool.updatedAt = event.block.timestamp;
  minePool.save();
}
