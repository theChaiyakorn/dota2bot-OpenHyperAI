local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')
local U = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/utils')

local X = {}

function X.Think(bot, hMinionUnit)
	-- Use the minion's own attack range. Owner's GetAttackRange() collapses to
	-- 200 via the override when the owner is not visible (glimmer, dead-fade,
	-- smoke), which would shrink the ward's search radius and starve it of
	-- targets even though the ward itself is fine.
	local thisMinionAttackRange = hMinionUnit:GetAttackRange()
	if thisMinionAttackRange == nil or thisMinionAttackRange < 400 then
		thisMinionAttackRange = 500
	end

	local target = U.GetWeakestHero(thisMinionAttackRange, hMinionUnit)
	if target == nil then
		target = U.GetWeakestCreep(thisMinionAttackRange, hMinionUnit)
		if target == nil then
			target = U.GetWeakestTower(thisMinionAttackRange, hMinionUnit)
		end
	end

	if target == nil or U.IsNotAllowedToAttack(target) then
		return
	end

	-- Don't re-issue the same target every tick — that cancels the ward's
	-- attack windup and it ends up never landing a hit. Only issue when the
	-- target actually changes.
	if hMinionUnit._lastWardTarget == target and hMinionUnit:GetAttackTarget() == target then
		return
	end
	hMinionUnit._lastWardTarget = target
	hMinionUnit:Action_AttackUnit(target, false)
end

return X