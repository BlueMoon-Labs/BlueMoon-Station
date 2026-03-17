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

