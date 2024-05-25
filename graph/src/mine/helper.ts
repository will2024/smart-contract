import {ERC20Mine, ERC20Mine__rewardTokenInfosResult} from "../../types/mine/WorldesMineProxy/ERC20Mine"
import {Address, BigInt} from "@graphprotocol/graph-ts"

export function getRewardNum(address: Address): BigInt {
    let contract = ERC20Mine.bind(address);
    let num = contract.getRewardNum();
    return num;
}

export function rewardTokenInfos(address: Address, index: BigInt): ERC20Mine__rewardTokenInfosResult {
    let contract = ERC20Mine.bind(address);
    let rewardTokenInfosResult = contract.rewardTokenInfos(index);
    return rewardTokenInfosResult as ERC20Mine__rewardTokenInfosResult;
}

export function getIdByRewardToken(address: Address, token: Address): BigInt {
    let contract = ERC20Mine.bind(address);
    let ID = contract.getIdByRewardToken(token);
    return ID;
}

export function getToken(address: Address): Address {
    let contract = ERC20Mine.bind(address);
    let token = contract._TOKEN_();
    return token;
}
