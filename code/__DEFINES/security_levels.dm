//Security levels
#define SEC_LEVEL_GREEN	1
#define SEC_LEVEL_BLUE	2
#define SEC_LEVEL_ORANGE 3
#define SEC_LEVEL_VIOLET 4
#define SEC_LEVEL_AMBER 5
#define SEC_LEVEL_RED	6
#define SEC_LEVEL_LAMBDA 7
#define SEC_LEVEL_GAMMA 8
#define SEC_LEVEL_EPSILON 9
#define SEC_LEVEL_DELTA 10

/// Security levels at or above lambda require keycard auth to set or change.
#define IS_HIGH_SECURITY_LEVEL(L) ((L) >= SEC_LEVEL_LAMBDA)

GLOBAL_VAR_INIT(security_level, SEC_LEVEL_GREEN)
/// Lowest level that cannot be lowered/changed without keycard auth (or bypass). 0 = unlocked.
GLOBAL_VAR_INIT(keycard_secured_level, 0)

/*
* All security levels, per ascending alert. Nothing too fancy, really.
* Their positions should also match their numerical values.
*/
GLOBAL_LIST_INIT(all_security_levels, list(
	"green",
	"blue",
	"orange",
	"violet",
	"amber",
	"red",
	"lambda",
	"gamma",
	"epsilon",
	"delta",
))

GLOBAL_LIST_INIT(all_security_levels_ru, list(
	"зелёный",
	"синий",
	"оранжевый",
	"фиолетовый",
	"янтарный",
	"красный",
	"лямбда",
	"гамма",
	"эпсилон",
	"дельта",
))

GLOBAL_LIST_INIT(sec_level_colors, list(
    "#b2ff59",
    "#99ccff",
    "#fc7d15",
    "#a059fe",
    "#ffae42",
    "#ff3f34",
    "#ffae42",
    "#7f7f7f",
    "#ffffff",
    "#aa00ff",
))

//Macro helpers.
#define SECLEVEL2NUM(text)	(GLOB.all_security_levels.Find(text))
#define NUM2SECLEVEL(num)	(ISINRANGE(num, 1, length(GLOB.all_security_levels)) ? GLOB.all_security_levels[num] : null)

#define SECURITY_LEVEL_NAME(sec_level) (GLOB.all_security_levels[sec_level])
#define SECURITY_LEVEL_NAME_RU(sec_level) (GLOB.all_security_levels_ru[sec_level])

#define SECURITY_LEVEL_COLOR(sec_level) (GLOB.sec_level_colors[sec_level] || "#ffffff")

#define SECURITY_LEVEL_COLOR_TEXT(sec_level, text_to_color) "<font color=[SECURITY_LEVEL_COLOR(sec_level)]>[text_to_color]</font>"
#define SECURITY_LEVEL_COLORED(sec_level) SECURITY_LEVEL_COLOR_TEXT(sec_level, SECURITY_LEVEL_NAME_RU(sec_level) || "неизвестно")
#define SECURITY_LEVEL_COLORED_UPPERTEXT(sec_level) SECURITY_LEVEL_COLOR_TEXT(sec_level, uppertext(SECURITY_LEVEL_NAME_RU(sec_level)) || "НЕИЗВЕСТНО")
#define SECURITY_LEVEL_COLORED_CAPITALIZE(sec_level) SECURITY_LEVEL_COLOR_TEXT(sec_level, capitalize(SECURITY_LEVEL_NAME_RU(sec_level)) || "Неизвестно")

/// Engineering Override Access manual toggle
//#define COMSIG_GLOB_FORCE_AIRLOCK_OVERRIDE "force_airlock_override"

/proc/set_security_level(level, secret_variant_override = null, bypass_keycard_lock = FALSE)
	SSsecurity_level.set_level(level, secret_variant_override, bypass_keycard_lock)

/proc/get_security_level_notice_theme(level)
	if(!isnum(level))
		level = SECLEVEL2NUM(level)

	return "code-[SECURITY_LEVEL_NAME(level) || SECURITY_LEVEL_NAME(SEC_LEVEL_AMBER)]"

/proc/get_security_level_notice_name(level)
	if(!isnum(level))
		level = SECLEVEL2NUM(level)

	return uppertext(SECURITY_LEVEL_NAME_RU(level)) || "НЕИЗВЕСТНО"
