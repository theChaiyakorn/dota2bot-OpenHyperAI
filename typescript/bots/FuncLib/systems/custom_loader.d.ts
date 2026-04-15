interface CustomizeSettings {
    Enable: boolean;
    Localization: string;
    Ban: string[];
    Radiant_Heros: string[];
    Dire_Heros: string[];
    Allow_Repeated_Heroes: boolean;
    Weak_Hero_Cap: number;
    Weak_Penalty: { type: string; base?: number; k?: number };
    Strict_Ban_Match: boolean;
    Allow_Trash_Talk: boolean;
    Allow_AI_GPT_Response: boolean;
    Trash_Talk_Level: number;
    Radiant_Names: string[];
    Dire_Names: string[];
    Show_Team_Names: boolean;
    Radiant_Team_Name: string;
    Dire_Team_Name: string;
    Force_Group_Push_Level: number;
    Push_Frequency: number;
    Fretbots: {
        Default_Difficulty: number;
        Default_Ally_Scale: number;
        Allow_To_Vote: boolean;
        Play_Sounds: boolean;
        Player_Death_Sound: boolean;
    };
    ThinkLess: number;
}
declare const Customize: CustomizeSettings;
export = Customize;
