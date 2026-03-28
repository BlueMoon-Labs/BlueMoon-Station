import { BooleanLike } from "common/react";

export type LangKeys = Record<string, string>;

export type BellyMode = string;


export type my_belly_contents = {
  name : string,
  health_percent : number,
  stat : number,
  absorbed : BooleanLike,
  outside : BooleanLike,
  icon : string,
  prey_vore_flags : number,

};

// Содержимое живота
export type pred_belly_contents = {
  name : string,
  health_percent : number,
  stat : number,
  absorbed : BooleanLike,
  icon : string,
};
// Упрощенное представление живота хищника
export type pred_belly = {
  belly_name : string,
  belly_mode : BellyMode,
  desc : string,
  ref : string,
  contents : pred_belly_contents[],
};

export type ModeChance = {
  dm_mode : BellyMode,
  chance  : number
}

export type MyModeDescData = {
  dm_mode : BellyMode,
  mode_desc : string
};

export type DamageData = {
  damage_type : string,
  amount : number
};

export type VoreSoundData = {
  sound_type : string,
  sound_name : string,
};

export type MyBelly = {
    my_belly_contents : my_belly_contents[],
    dm_mode : BellyMode,
    dm_modifer_flags : number,
    dm_descs : MyModeDescData[],
    dm_main_descs : MyModeDescData[],
    auto_transfer_time : number,
    auto_transfer_chance : number,
    damages_data : DamageData[],
    vore_sounds : VoreSoundData[]



};


export type vore_panel_data = {
    pred_belly : pred_belly,

};

