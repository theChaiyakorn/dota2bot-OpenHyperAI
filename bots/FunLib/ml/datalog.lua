----------------------------------------------------------------------------------------------------
--- Outcome data logger for the hybrid ML experiments (generic, reusable across decisions).
---
--- The bot sandbox cannot write files, but print() output is captured by Dota's console.log
--- when the client is launched with  -condebug . So we emit structured, greppable lines and
--- parse them offline (ml/parse_console_log.py) into a labelled training set.
---
--- Each DECIDE event carries a per-record `resolver(entry, now) -> done, fields` closure, so a
--- caller decides how its OUTCOME is measured (a target dying, a last-hit count going up, ...).
---   OHA_ML|<task>|DECIDE |id=..|t=..|feat=f1,..,fN
---   OHA_ML|<task>|OUTCOME|id=..|t=..|<field>=..|<field>=..      (emitted later by Tick)
---
--- DISABLED by default so normal play stays quiet. Set the global OHA_ML_LOG=true before load.
----------------------------------------------------------------------------------------------------

local DataLog = {}

DataLog.ENABLED   = true
DataLog.PREFIX    = 'OHA_ML'
DataLog.WINDOW    = 6.0    -- default outcome timeout (Assassinate)
DataLog.CS_WINDOW = 1.5    -- short timeout for last-hit / deny outcomes

local pending = {}

local function num(x) return string.format('%.4g', x) end

local function emitDecide(task, id, features)
	local fstr = {}
	for i = 1, #features do fstr[i] = num(features[i]) end
	print(DataLog.PREFIX..'|'..task..'|DECIDE|id='..id..'|t='..num(DotaTime())
		..'|feat='..table.concat(fstr, ','))
end

local function emitOutcome(task, id, now, fields)
	local keys = {}
	for k in pairs(fields) do keys[#keys + 1] = k end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do parts[#parts + 1] = k..'='..num(fields[k]) end
	print(DataLog.PREFIX..'|'..task..'|OUTCOME|id='..id..'|t='..num(now)..'|'..table.concat(parts, '|'))
end

--- Low-level: log a decision and register a resolver that produces its outcome fields later.
function DataLog.Record(task, bot, features, resolver)
	if not DataLog.ENABLED or bot == nil then return end
	local id = string.format('%d_%.2f', bot:GetPlayerID(), DotaTime())
	emitDecide(task, id, features)
	table.insert(pending, { id = id, task = task, t0 = DotaTime(), bot = bot, resolver = resolver })
end

--- Call once per frame. Cheap when nothing is pending.
function DataLog.Tick()
	if not DataLog.ENABLED or #pending == 0 then return end
	local now = DotaTime()
	for i = #pending, 1, -1 do
		local e = pending[i]
		local done, fields = e.resolver(e, now)
		if done then
			emitOutcome(e.task, e.id, now, fields or {})
			table.remove(pending, i)
		end
	end
end

----------------------------------------------------------------------------------------------------
--- Assassinate (Sniper): outcome = did the target die before we did / before timeout.
----------------------------------------------------------------------------------------------------
local function targetAlive(t) return t ~= nil and t:IsAlive() and t:GetHealth() > 0 end

function DataLog.RecordUltFire(task, bot, target, features)
	if not DataLog.ENABLED then return end
	local tMaxHp = math.max(1, target:GetMaxHealth())
	DataLog.Record(task, bot, features, function(e, now)
		local dt = now - e.t0
		if not targetAlive(target) then
			return true, { targetDied = 1, ttd = dt, selfDied = (bot:IsAlive() and 0 or 1), tEnd = 0 }
		end
		if not bot:IsAlive() then
			return true, { targetDied = 0, ttd = dt, selfDied = 1, tEnd = target:GetHealth() / tMaxHp }
		end
		if dt >= DataLog.WINDOW then
			return true, { targetDied = 0, ttd = dt, selfDied = 0, tEnd = target:GetHealth() / tMaxHp }
		end
		return false
	end)
end

----------------------------------------------------------------------------------------------------
--- Creep score (last-hit / deny): outcome = did our last-hit/deny tally increase shortly after.
--- kind = 'lasthit' | 'deny'
----------------------------------------------------------------------------------------------------
function DataLog.RecordCS(task, bot, features, kind)
	if not DataLog.ENABLED then return end
	local function tally() return (kind == 'deny') and bot:GetDenies() or bot:GetLastHits() end
	local baseline = tally()
	local hpStart  = bot:GetHealth() / math.max(1, bot:GetMaxHealth())
	DataLog.Record(task, bot, features, function(e, now)
		local dt = now - e.t0
		if tally() > baseline then
			local hpEnd = bot:GetHealth() / math.max(1, bot:GetMaxHealth())
			return true, { success = 1, dt = dt, hpLost = math.max(0, hpStart - hpEnd) }
		end
		if dt >= DataLog.CS_WINDOW then
			local hpEnd = bot:GetHealth() / math.max(1, bot:GetMaxHealth())
			return true, { success = 0, dt = dt, hpLost = math.max(0, hpStart - hpEnd) }
		end
		return false
	end)
end

----------------------------------------------------------------------------------------------------
--- HP trade (harass): outcome = net HP fraction we took off the enemy minus what we lost,
--- measured over a short window. net > 0 means the trade went in our favour.
----------------------------------------------------------------------------------------------------
DataLog.TRADE_WINDOW = 2.5

function DataLog.RecordTrade(task, bot, target, features)
	if not DataLog.ENABLED then return end
	local selfStart = bot:GetHealth() / math.max(1, bot:GetMaxHealth())
	local enemyMax  = math.max(1, target:GetMaxHealth())
	local enemyStart = target:GetHealth() / enemyMax

	DataLog.Record(task, bot, features, function(e, now)
		local dt = now - e.t0
		local selfDied = bot:IsAlive() and 0 or 1
		local enemyValid = (target ~= nil and target:IsAlive() and target:CanBeSeen())
		local enemyDead  = (target ~= nil and not target:IsAlive())

		if dt < DataLog.TRADE_WINDOW and selfDied == 0 and not enemyDead then
			return false
		end

		local selfEnd  = bot:GetHealth() / math.max(1, bot:GetMaxHealth())
		local enemyEnd = enemyDead and 0 or (enemyValid and (target:GetHealth() / enemyMax) or enemyStart)
		local dSelf  = math.max(0, selfStart - selfEnd)
		local dEnemy = math.max(0, enemyStart - enemyEnd)
		return true, { dSelf = dSelf, dEnemy = dEnemy, net = dEnemy - dSelf, selfDied = selfDied }
	end)
end

return DataLog
