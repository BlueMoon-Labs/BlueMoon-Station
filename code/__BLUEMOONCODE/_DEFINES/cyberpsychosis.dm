// Киберпсихоз BlueMoon: дефайны модуля. Сама система - в
// modular_bluemoon/code/modules/cyberpsychosis/*.dm
// (включается до unit_tests по той же причине, что и psychosis.dm).

// Стадии киберпсихоза. Значения 1..3 совпадают с PSYCHOSIS_TIER_*, но
// семантически это отдельная шкала - нагрузки имплантов, не времени.
#define CYBERPSYCHOSIS_TIER_NONE     0
#define CYBERPSYCHOSIS_TIER_MILD     1
#define CYBERPSYCHOSIS_TIER_MODERATE 2
#define CYBERPSYCHOSIS_TIER_CRITICAL 3

// Пороги "кибернагрузки" (сумма cyber_load роботизированных кибераугментов
// в internal_organs). Шкала перегрузки - 20 единиц. Значении порогов зависят
// от назначения импланта (см. cyber_load в cyberpsychosis_organ.dm).
// По образцу /datum/dna/update_instability(): состояние каждый раз
// пересчитывается заново из установленных имплантов.
#define CYBERPSYCHOSIS_MILD_LOAD     8
#define CYBERPSYCHOSIS_MODERATE_LOAD 15
#define CYBERPSYCHOSIS_CRITICAL_LOAD 20

// Смещение порогов у квирка «Совместимость с имплантами»: тело и разум
// переносят на 12/20/27 единиц нагрузки соответственно (MILD/MODERATE/CRITICAL).
// Оффсеты не constant'ные: по мере роста стадии симптомы накапливаются,
// поэтому устойчивость квирка даёт всё больше запаса.
#define CYBERPSYCHOSIS_MILD_COMPATIBLE_OFFSET     4
#define CYBERPSYCHOSIS_MODERATE_COMPATIBLE_OFFSET 5
#define CYBERPSYCHOSIS_CRITICAL_COMPATIBLE_OFFSET 7

// Трейт квирка «Совместимость с имплантами».
#define TRAIT_IMPLANT_COMPATIBILITY "implant_compatibility"

// Радиус, в котором на высоких стадиях все люди выглядят как "Unknown" в блюре.
#define CYBERPSYCHOSIS_OTHER_VIEW_RANGE 7

// Фильтр "критического срыва" - аналог BM_FILTER_HARDCRIT (хардкрит у живых
// персонажей, см. code/modules/mob/living/carbon/carbon.dm), но темнее/шире.
#define CYBERPSYCHOSIS_CRITICAL_FILTER list(type = "drop_shadow", x = 0, y = 0, size = -4, color = "#07070B")

// Временная кибер-перегрузка от ЭМИ: столько добавляется к нагрузке за каждый
// роботизированный орган/кибераугмент, получивший emp_act(). Совмещается с
// постоянной нагрузкой (суммой cyber_load) и подталкивает стадию вверх.
#define CYBERPSYCHOSIS_EMP_OVERLOAD_PER_IMPLANT 0.5

// Время самостоятельного спада всей перегрузки от одного ЭМИ (в СЕКУНДАХ,
// время передаётся в process(delta_time) целыми секундами): 0.5 "весят" один
// имплант, т.е. стэк из N порций полностью уходит за 60 секунд.
#define CYBERPSYCHOSIS_EMP_OVERLOAD_DECAY_TIME 60