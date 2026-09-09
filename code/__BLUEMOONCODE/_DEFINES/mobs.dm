// Weights of mobs, used by mob/living/var/mob_weight
//#define MOB_WEIGHT_LIGHT_SUPER_DUPER 1 //PLACEHOLDER на случай если кто-то чего-то придумает с этим
//#define MOB_WEIGHT_LIGHT_SUPER 2 //PLACEHOLDER на случай если кто-то чего-то придумает с этим
#define MOB_WEIGHT_LIGHT 3
#define MOB_WEIGHT_NORMAL 4
#define MOB_WEIGHT_HEAVY 5
#define MOB_WEIGHT_HEAVY_SUPER 6

// Замедление за вес задаётся в тиках, а не в децисекундах.
//
// Цена шага выравнивается по тику (см. movement_step_delay), поэтому добавка
// меньше четверти тика пропадает целиком, а всё что больше превращается в
// целый тик. Лестница в долях децисекунды после такого выравнивания
// становится случайной, лестница в тиках - предсказуемой.
//
// Обе величины масштабируются конфигом BODY_SIZE_SLOWDOWN_MULTIPLIER, который
// по умолчанию равен нулю: механика выключена.
#define MOB_WEIGHT_HEAVY_SLOWDOWN_TICKS 1
#define MOB_WEIGHT_HEAVY_SUPER_SLOWDOWN_TICKS 2

// Рост, на котором вес перестаёт мешать: тело достаточно велико, чтобы масса
// была оправдана. Значения сохранены от исходной механики.
#define MOB_WEIGHT_HEAVY_CANCEL_SIZE 1.2
#define MOB_WEIGHT_HEAVY_SUPER_CANCEL_SIZE 1.7

/// Ниже этого роста сверхтяжёлому не ужаться: необъятный вес некуда девать.
#define MOB_WEIGHT_HEAVY_SUPER_MIN_SIZE 0.8

/// Нижняя граница цены шага для сверхтяжёлых, в децисекундах.
///
/// Само значение по тику не выравнивается - его и не надо: это пол для
/// cached_multiplicative_slowdown, а тот проходит через movement_step_delay()
/// в /client/Move() и выравнивается уже там, вместе со всем остальным.
#define MOB_WEIGHT_HEAVY_SUPER_FLOOR 3

//#define NAME_WEIGHT_LIGHT_SUPER_DUPER "супердуперлёгкий" //PLACEHOLDER на случай если кто-то чего-то придумает с этим
//#define NAME_WEIGHT_LIGHT_SUPER "суперлёгкий" //PLACEHOLDER на случай если кто-то чего-то придумает с этим
#define NAME_WEIGHT_LIGHT "лёгкий"
#define NAME_WEIGHT_NORMAL "средний"
#define NAME_WEIGHT_HEAVY "тяжёлый"
#define NAME_WEIGHT_HEAVY_SUPER "сверхтяжёлый"

//#define COST_WEIGHT_LIGHT_SUPER_DUPER 0 //PLACEHOLDER на случай если кто-то чего-то придумает с этим
//#define COST_WEIGHT_LIGHT_SUPER 0 //PLACEHOLDER на случай если кто-то чего-то придумает с этим
//#define COST_WEIGHT_LIGHT 0 //PLACEHOLDER на случай если кто-то чего-то придумает с этим
//#define COST_WEIGHT_NORMAL 0 //PLACEHOLDER на случай если кто-то чего-то придумает с этим
#define COST_WEIGHT_HEAVY 1
#define COST_WEIGHT_HEAVY_SUPER 2
