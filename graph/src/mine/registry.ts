import {MinePool, RewardDetail} from "../../../generated/schema"
import {NewMine} from "../../../generated/WorldesMineRegistry/WorldesMineRegistry"

export function handleNewMine(event: NewMine): void {
    let minePool = MinePool.load(event.params.mine.toHexString());

    if (minePool == null) {
        minePool = new MinePool(event.params.mine.toHexString());
    }
    minePool.pool = event.params.mine;
    minePool.isLpToken = event.params.isLpToken;
    minePool.updatedAt = event.block.timestamp;
    minePool.save();
}
