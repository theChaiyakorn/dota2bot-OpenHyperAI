require('bots/Buff/Helper')

if GPM == nil
then
    GPM = {}
end

-- Reasonable GPM (XPM later)
function GPM.TargetGPM(time)
    if time <= 10 * 60 then
        return 450
    elseif time <= 20 * 60 then
        return 600
    elseif time <= 30 * 60 then
        return 750
    else
        return RandomInt(900, 1000)
    end
end

function GPM.UpdateBotGold(bot)
    local gameTime = Helper.DotaTime() / 60
    local targetGPM = GPM.TargetGPM(gameTime)

    local currentGPM = PlayerResource:GetGoldPerMin(bot:GetPlayerID())
    local goldPerTick
    if currentGPM == nil or currentGPM == 0 then
        goldPerTick = 1
        log('[Buff][GPM] %s currentGPM=0 -- defaulting goldPerTick=1', tostring(bot:GetUnitName()))
    else
        goldPerTick = targetGPM / currentGPM
    end

    if goldPerTick < 1 then goldPerTick = 1 end

    if bot:IsAlive()
    and gameTime > 0
    then
        local amount = 1 + math.ceil(goldPerTick)
        bot:ModifyGold(amount, true, 0)
        log('[Buff][GPM] %s +%s gold (targetGPM=%s, currentGPM=%s, gameTime=%.1fmin)', tostring(bot:GetUnitName()), tostring(amount), tostring(targetGPM), tostring(currentGPM), gameTime)
    else
        log('[Buff][GPM] %s skipped (alive=%s, gameTime=%.1fmin)', tostring(bot:GetUnitName()), tostring(bot:IsAlive()), gameTime)
    end
end

return GPM