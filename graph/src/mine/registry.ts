import {MinePool, RewardDetail} from "../../types/mine/schema"
import {NewMine} from "../../types/mine/DODOMineV3Registry/DODOMineV3Registry"

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
