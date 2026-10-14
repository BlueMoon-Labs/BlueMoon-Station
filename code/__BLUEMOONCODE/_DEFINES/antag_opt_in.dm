// Уровни согласия быть целью заданий антагонистов. Каждый следующий включает предыдущие.
#define ANTAG_OPT_IN_NOT_TARGET 0
#define ANTAG_OPT_IN_TEMPORARY 1
#define ANTAG_OPT_IN_KILL 2
#define ANTAG_OPT_IN_ROUND_REMOVE 3

/// Живая жертва охоты еретика возвращается из Мансуса невредимой: это похищение, а не убийство.
#define ANTAG_OPT_IN_HERETIC_HUNT ANTAG_OPT_IN_TEMPORARY
/// Труп в жертву принимается только от согласных на убийство.
#define ANTAG_OPT_IN_HERETIC_HUNT_CORPSE ANTAG_OPT_IN_KILL

// Стиль заданий, который игрок выбирает себе как антагонисту.
#define ANTAG_OBJECTIVE_STYLE_QUIET "quiet"
#define ANTAG_OBJECTIVE_STYLE_NORMAL "normal"
#define ANTAG_OBJECTIVE_STYLE_VIOLENT "violent"
/// Во сколько раз стиль "Больше убийств" поднимает шанс задания на убийство там, где режим не ограничивает его потолком.
#define ANTAG_OBJECTIVE_VIOLENT_KILL_MULT 1.5
/// На сколько процентных пунктов "Больше убийств" поднимает мягкий потолок (Медиум): убийство там остаётся разовым.
#define ANTAG_OBJECTIVE_VIOLENT_SOFT_BONUS 10
