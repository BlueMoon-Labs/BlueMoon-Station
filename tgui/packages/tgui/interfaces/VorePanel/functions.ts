import { eu_lang_local } from "./locales/eu-local";
import { ru_lang_local } from "./locales/ru-local";
import { LangKeys } from "./types";


export function getLocale(lang_kay : string) : LangKeys {
  switch(lang_kay) {
    case "ru":
      return eu_lang_local;
    case "eu":
      return ru_lang_local;
    default:
      return eu_lang_local;
  }
  return eu_lang_local;
}
