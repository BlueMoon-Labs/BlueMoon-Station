// Уровни согласия быть целью заданий антагонистов. Каждый следующий включает предыдущие.
#define ANTAG_OPT_IN_NOT_TARGET 0
#define ANTAG_OPT_IN_TEMPORARY 1
#define ANTAG_OPT_IN_KILL 2
#define ANTAG_OPT_IN_ROUND_REMOVE 3

/// Жертва охоты еретика возвращается в раунд, поэтому хватает согласия на убийство.
#define ANTAG_OPT_IN_HERETIC_HUNT ANTAG_OPT_IN_KILL
