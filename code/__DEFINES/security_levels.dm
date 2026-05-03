/// Engineering Override Access manual toggle
//#define COMSIG_GLOB_FORCE_AIRLOCK_OVERRIDE "force_airlock_override"

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

//Macro helpers.
#define SECLEVEL2NUM(text)	(GLOB.all_security_levels.Find(text))
#define NUM2SECLEVEL(num)	(ISINRANGE(num, 1, length(GLOB.all_security_levels)) ? GLOB.all_security_levels[num] : null)
