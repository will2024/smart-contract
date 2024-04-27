import {
  BigInt,
  BigDecimal,
  ethereum,
  log,
  Address,
  store,
  dataSource,
} from "@graphprotocol/graph-ts";
import {
  OrderHistory,
  Token,
  Pair,
} from "../../../generated/schema";
import {
  createToken,
  createLpToken,
  createUser,
  ZERO_BI,
  ZERO_BD,
  ONE_BI,
  convertTokenToDecimal,
  getWorldes,
  getQuoteTokenAddress,
  createPairDetail,
} from "../utils/helpers";
import { NewDVM, RemoveDVM } from "../../../generated/DVMFactory/DVMFactory";
import { NewDSP, RemoveDSP } from "../../../generated/DSPFactory/DSPFactory";
import { DVM } from "../../../generated/DVMFactory/DVM";
import { DSP } from "../../../generated/DSPFactory/DSP";

import {
  DVM as DVMTemplate,
  DSP as DSPTemplate,
} from "../../../generated/templates";
import {
  TYPE_DVM_POOL,
  TYPE_DSP_POOL,
  TYPE_CLASSICAL_POOL,
  SOURCE_SMART_ROUTE,
  SOURCE_POOL_SWAP,
} from "../utils/constant";
import { ADDRESS_ZERO } from "../utils/constant";

export function handleNewDVM(event: NewDVM): void {
  log.info("handleNewDVM start", []);
  log.info("handleNewDVM 0, {}", [event.params.dvm.toHexString()]);
  createUser(event.params.creator, event);
  //1、获取token schema信息
  let baseToken = createToken(event.params.baseToken, event);
  let quoteToken = createToken(event.params.quoteToken, event);
  let pair = Pair.load(event.params.dvm.toHexString());
  log.info("handleNewDVM 1, {}", [event.params.dvm.toHexString()]);
  if (pair == null) {
    pair = new Pair(event.params.dvm.toHexString());
    pair.baseToken = event.params.baseToken.toHexString();
    pair.type = TYPE_DVM_POOL;
    pair.quoteToken = event.params.quoteToken.toHexString();
    pair.baseSymbol = baseToken.symbol;
    pair.quoteSymbol = quoteToken.symbol;

    pair.creator = event.params.creator;
    pair.owner = pair.creator;
    pair.createdAtTimestamp = event.block.timestamp;
    pair.createdAtBlockNumber = event.block.number;

    pair.baseLpToken = event.params.dvm.toHexString();
    pair.quoteLpToken = event.params.dvm.toHexString();
    createLpToken(event.params.dvm, pair as Pair);
    log.info("handleNewDVM 2, {}", [event.params.dvm.toHexString()]);
    pair.lastTradePrice = ZERO_BD;
    pair.txCount = ZERO_BI;
    pair.volumeBaseToken = ZERO_BD;
    pair.volumeQuoteToken = ZERO_BD;
    pair.liquidityProviderCount = ZERO_BI;
    pair.untrackedBaseVolume = ZERO_BD;
    pair.untrackedQuoteVolume = ZERO_BD;
    pair.feeBase = ZERO_BD;
    pair.feeQuote = ZERO_BD;
    pair.traderCount = ZERO_BI;
    pair.isTradeAllowed = true;
    pair.isDepositBaseAllowed = true;
    pair.isDepositQuoteAllowed = true;
    pair.volumeUSD = ZERO_BD;
    pair.feeUSD = ZERO_BD;

    let dvm = DVM.bind(event.params.dvm);
    let pmmState = dvm.try_getPMMState();
    log.info("handleNewDVM 3, {}", [event.params.dvm.toHexString()]);
    if (pmmState.reverted == false) {
      createPairDetail(pair, pmmState.value, event.block.timestamp);
      pair.i = pmmState.value.i;
      pair.k = pmmState.value.K;
      pair.baseReserve = convertTokenToDecimal(
        pmmState.value.B,
        baseToken.decimals
      );
      pair.quoteReserve = convertTokenToDecimal(
        pmmState.value.Q,
        quoteToken.decimals
      );
      pair.lpFeeRate = convertTokenToDecimal(
        dvm._LP_FEE_RATE_(),
        BigInt.fromI32(18)
      );
      pair.mtFeeRateModel = dvm._MT_FEE_RATE_MODEL_();
      pair.maintainer = dvm._MAINTAINER_();
    } else {
      pair.i = ZERO_BI;
      pair.k = ZERO_BI;
      pair.baseReserve = ZERO_BD;
      pair.quoteReserve = ZERO_BD;
      pair.lpFeeRate = ZERO_BD;
      pair.mtFeeRateModel = Address.fromString(ADDRESS_ZERO);
      pair.maintainer = Address.fromString(ADDRESS_ZERO);
    }
    pair.mtFeeRate = ZERO_BI;
    pair.mtFeeBase = ZERO_BD;
    pair.mtFeeQuote = ZERO_BD;
    pair.mtFeeUSD = ZERO_BD;

    pair.updatedAt = event.block.timestamp;
    pair.save();

    let worldes = getWorldes();
    worldes.pairCount = worldes.pairCount.plus(ONE_BI);
    worldes.updatedAt = event.block.timestamp;
    worldes.save();
  }

  DVMTemplate.create(event.params.dvm);
}

export function handleNewDSP(event: NewDSP): void {
  createUser(event.params.creator, event);
  //1、获取token schema信息
  let baseToken = createToken(event.params.baseToken, event);
  let quoteToken = createToken(event.params.quoteToken, event);
  let pair = Pair.load(event.params.DSP.toHexString());

  if (pair == null) {
    pair = new Pair(event.params.DSP.toHexString());
    pair.baseToken = event.params.baseToken.toHexString();
    pair.type = TYPE_DSP_POOL;
    pair.quoteToken = event.params.quoteToken.toHexString();
    pair.baseSymbol = baseToken.symbol;
    pair.quoteSymbol = quoteToken.symbol;
    pair.creator = event.params.creator;
    pair.owner = pair.creator;
    pair.createdAtTimestamp = event.block.timestamp;
    pair.createdAtBlockNumber = event.block.number;

    pair.baseLpToken = event.params.DSP.toHexString();
    pair.quoteLpToken = event.params.DSP.toHexString();
    createLpToken(event.params.DSP, pair as Pair);

    pair.lastTradePrice = ZERO_BD;
    pair.txCount = ZERO_BI;
    pair.volumeBaseToken = ZERO_BD;
    pair.volumeQuoteToken = ZERO_BD;
    pair.liquidityProviderCount = ZERO_BI;
    pair.untrackedBaseVolume = ZERO_BD;
    pair.untrackedQuoteVolume = ZERO_BD;
    pair.feeBase = ZERO_BD;
    pair.feeQuote = ZERO_BD;
    pair.traderCount = ZERO_BI;
    pair.isTradeAllowed = true;
    pair.isDepositBaseAllowed = true;
    pair.isDepositQuoteAllowed = true;
    pair.volumeUSD = ZERO_BD;
    pair.feeUSD = ZERO_BD;

    let dsp = DSP.bind(event.params.DSP);
    let pmmState = dsp.try_getPMMState();
    if (pmmState.reverted == false) {
      createPairDetail(pair, pmmState.value, event.block.timestamp);
      pair.i = pmmState.value.i;
      pair.k = pmmState.value.K;
      pair.baseReserve = convertTokenToDecimal(
        pmmState.value.B,
        baseToken.decimals
      );
      pair.quoteReserve = convertTokenToDecimal(
        pmmState.value.Q,
        quoteToken.decimals
      );
      pair.lpFeeRate = convertTokenToDecimal(
        dsp._LP_FEE_RATE_(),
        BigInt.fromI32(18)
      );
      pair.mtFeeRateModel = dsp._MT_FEE_RATE_MODEL_();
      pair.maintainer = dsp._MAINTAINER_();
    } else {
      pair.i = ZERO_BI;
      pair.k = ZERO_BI;
      pair.baseReserve = ZERO_BD;
      pair.quoteReserve = ZERO_BD;
      pair.lpFeeRate = ZERO_BD;
      pair.mtFeeRateModel = Address.fromString(ADDRESS_ZERO);
      pair.maintainer = Address.fromString(ADDRESS_ZERO);
    }
    pair.mtFeeRate = ZERO_BI;
    pair.mtFeeBase = ZERO_BD;
    pair.mtFeeQuote = ZERO_BD;
    pair.mtFeeUSD = ZERO_BD;
    pair.updatedAt = event.block.timestamp;

    pair.save();

    let worldes = getWorldes();
    worldes.pairCount = worldes.pairCount.plus(ONE_BI);
    worldes.updatedAt = event.block.timestamp;
    worldes.save();
  }

  DSPTemplate.create(event.params.DSP);
}

export function handleRemoveDVM(event: RemoveDVM): void {
  store.remove("Pair", event.params.dvm.toHexString());
}

export function handleRemoveDSP(event: RemoveDSP): void {
  store.remove("Pair", event.params.DSP.toHexString());
}
