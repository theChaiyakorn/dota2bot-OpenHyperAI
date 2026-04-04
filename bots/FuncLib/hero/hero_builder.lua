--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
local ____exports = {}
local Fu = require(GetScriptDirectory().."/FuncLib/func_utils")
local DEFAULT_TALENT_TREE = {t25 = {0, 10}, t20 = {10, 0}, t15 = {0, 10}, t10 = {10, 0}}
--- Build hero configuration — resolves role-specific builds.
function ____exports.buildHeroConfig(bot, config)
    local Item = require(GetScriptDirectory() .. "/FuncLib/systems/item")
    local role = Item.GetRoleItemsBuyList(bot)
    local abilities = Fu.Skill.GetAbilityList(bot)
    local talents = Fu.Skill.GetTalentList(bot)
    local defaultSkill = {}
    local skillBuilds = config.skills or ({})
    if skillBuilds.default then
        defaultSkill = skillBuilds.default
    else
        for key in pairs(skillBuilds) do
            if key ~= "default" then
                defaultSkill = skillBuilds[key]
                break
            end
        end
    end
    local skillBuild = skillBuilds[role] or defaultSkill
    local talentBuilds = config.talents or ({})
    local talentTree = talentBuilds[role] or talentBuilds.default or DEFAULT_TALENT_TREE
    local talentBuild = Fu.Skill.GetTalentBuild(talentTree)
    local defaultItems = {}
    local itemBuilds = config.items or ({})
    if itemBuilds.default then
        defaultItems = itemBuilds.default
    else
        for key in pairs(itemBuilds) do
            if key ~= "default" then
                defaultItems = itemBuilds[key]
                break
            end
        end
    end
    local itemBuild = itemBuilds[role] or defaultItems
    local fullSkillBuild = Fu.Skill.GetSkillList(abilities, skillBuild, talents, talentBuild)
    return {role = role, skillBuild = fullSkillBuild, itemBuild = itemBuild, sellList = config.sell or ({})}
end
--- Create the final export object for ability_item_usage_generic.
function ____exports.buildHeroExport(builds, skillsComplement, minionThink)
    return {
        sSkillList = builds.skillBuild,
        sBuyList = builds.itemBuild,
        sSellList = builds.sellList,
        SkillsComplement = skillsComplement,
        MinionThink = minionThink
    }
end
return ____exports
