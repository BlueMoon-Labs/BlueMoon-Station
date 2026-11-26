/// Ступени пути, после которых меняется облик еретика: первая примета вблизи, вторая - на открытых кистях и лице. Третья ступень облика - вознесение.
#define HERETIC_EVOLUTION_FIRST_STAGE 4
#define HERETIC_EVOLUTION_SECOND_STAGE 7
/// Сдвиг кадра из листа облика <id>_64.dmi, чтобы 64x64 стоял по центру тела.
#define HERETIC_EVOLUTION_BIG_OFFSET -16
/// Кисти облика лежат над кистями тела (HANDS_PART_LAYER) и под перчатками.
#define HERETIC_EVOLUTION_HANDS_LAYER 27.5
/// Лицо облика лежит над волосами (HAIR_LAYER) и под рогами, маской и головным убором.
#define HERETIC_EVOLUTION_FACE_LAYER 11.5
/// С какого расстояния в клетках осмотр замечает приметы первой и второй ступени; вознесённого видно всегда.
#define HERETIC_EVOLUTION_FIRST_RANGE 1
#define HERETIC_EVOLUTION_SECOND_RANGE 2
#define HERETIC_EVOLUTION_BURST_TIME (2 SECONDS)
#define HERETIC_EVOLUTION_BURST_COOLDOWN (6 SECONDS)
/// Части тела для строк осмотра: глаза прячут ещё и очки, ANY видна всегда.
#define HERETIC_EVOLUTION_EYES "eyes"
#define HERETIC_EVOLUTION_FACE "face"
/// Макушка и то, что над ней: прячет только убор, закрывающий волосы, а противогаз - нет.
#define HERETIC_EVOLUTION_HAIR "hair"
#define HERETIC_EVOLUTION_HANDS "hands"
#define HERETIC_EVOLUTION_ANY "any"
/// Голова или маска сменили то, что закрывают: надеты, сняты, поднято забрало или сдвинута маска.
#define COMSIG_CARBON_FACE_COVER_UPDATED "carbon_face_cover_updated"
