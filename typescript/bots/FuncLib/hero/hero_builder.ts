/**
 * Hero Builder — reduces boilerplate for TS hero files.
 * Uses plain functions to avoid TSTL self/colon issues with classes.
 */

import * as Fu from "bots/FuncLib/func_utils";
import { BotSetup, BotRole, TalentTreeBuild } from "bots/ts_libs/bots";
import { Talent, Unit } from "bots/ts_libs/dota";

const DEFAULT_TALENT_TREE: TalentTreeBuild = {
    t25: [0, 10],
    t20: [10, 0],
    t15: [0, 10],
    t10: [10, 0],
};

interface HeroBuildConfig {
    skills?: Partial<Record<BotRole | "default", number[]>>;
    talents?: Partial<Record<BotRole | "default", TalentTreeBuild>>;
    items?: Partial<Record<BotRole | "default", string[]>>;
    sell?: string[];
}

export interface HeroBuildResult {
    role: BotRole;
    skillBuild: Array<Talent | any>;
    itemBuild: string[];
    sellList: string[];
}

/** Build hero configuration — resolves role-specific builds. */
export function buildHeroConfig(bot: Unit, config: HeroBuildConfig): HeroBuildResult {
    // Use require() directly to avoid TSTL colon-call on Fu.Item which adds wrong 'self'
    const Item = require(GetScriptDirectory() + "/FuncLib/systems/item");
    const role: BotRole = Item.GetRoleItemsBuyList(bot);
    const abilities: string[] = Fu.Skill.GetAbilityList(bot);
    const talents: Talent[] = Fu.Skill.GetTalentList(bot);

    // Resolve skill build
    let defaultSkill: number[] = [];
    const skillBuilds = config.skills || {};
    if ((skillBuilds as any).default) {
        defaultSkill = (skillBuilds as any).default;
    } else {
        for (const key in skillBuilds) {
            if (key !== "default") {
                defaultSkill = (skillBuilds as any)[key];
                break;
            }
        }
    }
    const skillBuild: number[] = (skillBuilds as any)[role] || defaultSkill;

    // Resolve talent build
    const talentBuilds = config.talents || {};
    const talentTree: TalentTreeBuild = (talentBuilds as any)[role] || (talentBuilds as any).default || DEFAULT_TALENT_TREE;
    const talentBuild = Fu.Skill.GetTalentBuild(talentTree);

    // Resolve item build
    let defaultItems: string[] = [];
    const itemBuilds = config.items || {};
    if ((itemBuilds as any).default) {
        defaultItems = (itemBuilds as any).default;
    } else {
        for (const key in itemBuilds) {
            if (key !== "default") {
                defaultItems = (itemBuilds as any)[key];
                break;
            }
        }
    }
    const itemBuild: string[] = (itemBuilds as any)[role] || defaultItems;

    // Build full skill list
    const fullSkillBuild = Fu.Skill.GetSkillList(abilities, skillBuild, talents, talentBuild);

    return {
        role,
        skillBuild: fullSkillBuild,
        itemBuild,
        sellList: config.sell || [],
    };
}

/** Create the final export object for ability_item_usage_generic. */
export function buildHeroExport(builds: HeroBuildResult, skillsComplement: (this: void) => void, minionThink: (this: void, hMinionUnit: any) => void): BotSetup {
    return {
        sSkillList: builds.skillBuild,
        sBuyList: builds.itemBuild,
        sSellList: builds.sellList,
        SkillsComplement: skillsComplement,
        MinionThink: minionThink,
    };
}
