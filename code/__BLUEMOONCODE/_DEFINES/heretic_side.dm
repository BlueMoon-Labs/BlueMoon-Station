#define HERETIC_PATRON_MECH_JAM_TIME (3 SECONDS)
/// Отсчёт с конца обездвиживания: один мех нельзя держать Дланью подряд.
#define HERETIC_PATRON_MECH_JAM_COOLDOWN (15 SECONDS)
#define HERETIC_PATRON_MECH_JAM_COLOR "#c0703f"

#define HERETIC_VEIL_DURATION (5 SECONDS)
#define HERETIC_VEIL_CHARGES 4
#define HERETIC_VEIL_COOLDOWN (45 SECONDS)
#define HERETIC_VEIL_COLOR "#cfcadc"
#define HERETIC_VEIL_FILTER "heretic_veil"
/// Ключ return_list в COMSIG_LIVING_RUN_BLOCK: удар уже погасил обработчик еретика, остальные его не трогают.
#define HERETIC_BLOCK_ABSORBED "heretic_absorbed"
#define HERETIC_VEIL_CAST_SOUND 'sound/magic/ForceWall.ogg'
#define HERETIC_VEIL_ABSORB_SOUND 'sound/magic/MM_Hit.ogg'
