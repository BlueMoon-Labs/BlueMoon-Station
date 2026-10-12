// Уровни согласия быть целью заданий антагонистов. Каждый следующий включает предыдущие.
#define ANTAG_OPT_IN_NOT_TARGET 0
#define ANTAG_OPT_IN_TEMPORARY 1
#define ANTAG_OPT_IN_KILL 2
#define ANTAG_OPT_IN_ROUND_REMOVE 3

/// Живая жертва охоты еретика возвращается из Мансуса невредимой: это похищение, а не убийство.
#define ANTAG_OPT_IN_HERETIC_HUNT ANTAG_OPT_IN_TEMPORARY
/// Труп в жертву принимается только от согласных на убийство.
#define ANTAG_OPT_IN_HERETIC_HUNT_CORPSE ANTAG_OPT_IN_KILL
