import { BooleanLike } from "common/react";

export type LangKeys = Record<string, string>;

export type Data = {

};
// Содержимое живота
export type belly_contents = {
  name : string,
  health_percent : number,
  stat : number,
  absorbed : BooleanLike,
  outside : BooleanLike,
  icon : string,

};
// Упрощенное представление живота хищника
export type pred_belly = {
  belly_name : string,
  belly_mode : string,
  desc : string,
  ref : string,
  contents : belly_contents[],
};

