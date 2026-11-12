/// помечает в таблицах рыбы шанс промаха
#define FISHING_DUD "dud"
/// цели заданий, выпадающие случайно
#define FISHING_RANDOM_SEED "Random seed"
#define FISHING_RANDOM_ORGAN "Random organ"
#define FISHING_INFLUENCE "Influence"
#define FISHING_RANDOM_ARM "arm"

/// вероятность того, что автомат раздробит яйца покупателя
#define FISHING_VENDING_CHUCK "thinkfastchucklenuts"

// уровни сложности рыбалки
#define FISHING_DEFAULT_DIFFICULTY 15
#define FISHING_EASY_DIFFICULTY 10
#define FISHING_MINIMUM_DIFFICULTY 6

/// бонус от любимой прикормки
#define FAV_BAIT_DIFFICULTY_MOD -10
/// штраф от нелюбимой прикормки
#define DISLIKED_BAIT_DIFFICULTY_MOD 10
/// бонус от навыка эксперта
#define EXPERT_FISHER_DIFFICULTY_MOD -5

#define FISH_TRAIT_MINOR_DIFFICULTY_BOOST 5

/// слоты для удочки и её оснастки
#define ROD_SLOT_BAIT "bait"
#define ROD_SLOT_LINE "line"
#define ROD_SLOT_HOOK "hook"

#define ADDITIVE_FISHING_MOD "additive"
#define MULTIPLICATIVE_FISHING_MOD "multiplicative"

// Эти дефайны нужны, чтобы работать с крючками через
// удочку, а не через сам крючок. Вероятно, можно было бы
// сделать иначе, но пока работает так. Думайте, рыбачки.
/// трейт крючка, который уменьшает отскок от краёв полосы
#define FISHING_HOOK_WEIGHTED (1 << 0)
/// работает как FISHING_MINIGAME_RULE_BIDIRECTIONAL
#define FISHING_HOOK_BIDIRECTIONAL (1 << 1)
/// не даёт рыбе уйти и проиграть испытание
#define FISHING_HOOK_NO_ESCAPE (1 << 2)
/// урезает потерю прогресса, пока рыба вне зоны наживки
#define FISHING_HOOK_ENSNARE (1 << 3)
/// через время добивает рыбу, но и награда будет мёртвой
#define FISHING_HOOK_KILL (1 << 4)

/// снижает сложность мини-игры
#define FISHING_LINE_CLOAKED (1 << 0)
/// та же идея, что у FISHING_HOOK_ENSNARE, только для лески
#define FISHING_LINE_BOUNCY (1 << 1)
/// антипод FISHING_LINE_BOUNCY. Прогресс копится медленнее и теряется быстрее.
#define FISHING_LINE_STIFF (1 << 2)
/// пропускает поклёвку и сразу переходит к рыбалке
#define FISHING_LINE_AUTOREEL (1 << 3)
/// позволяет забрасывать леску сквозь плотные объекты и стены
#define FISHING_LINE_PHASE (1 << 4)

/// наживка не падает сама, её опускают правой кнопкой мыши
#define FISHING_MINIGAME_RULE_BIDIRECTIONAL (1 << 0)
/// не даёт проиграть, даже когда прогресс падает до нуля
#define FISHING_MINIGAME_RULE_NO_ESCAPE (1 << 1)
/// через время добивает рыбу, но и награда будет мёртвой
#define FISHING_MINIGAME_RULE_KILL (1 << 2)
/// отключает влияние навыка на мини-игру и начисление опыта
#define FISHING_MINIGAME_RULE_NO_EXP (1 << 3)
/// мини-игра время от времени переворачивает скорость наживки
#define FISHING_MINIGAME_RULE_ANTIGRAV (1 << 4)
/// на время эффекта переворачивает интерфейс мини-игры
#define FISHING_MINIGAME_RULE_FLIP (1 << 5)
/// пропускает поклёвку и сразу запускает мини-игру, без штрафа за медлительность
#define FISHING_MINIGAME_AUTOREEL (1 << 6)
/// рыба время от времени исчезает и появляется снова
#define FISHING_MINIGAME_RULE_CAMO (1 << 7)

/// все активные эффекты, что держатся несколько секунд, а потом уходят на перезарядку
#define FISHING_MINIGAME_ACTIVE_EFFECTS (FISHING_MINIGAME_RULE_ANTIGRAV|FISHING_MINIGAME_RULE_FLIP|FISHING_MINIGAME_RULE_CAMO)

/// обычный аддитивный бонус для модификаторов веса улова крючка
#define FISHING_DEFAULT_HOOK_BONUS_ADDITIVE 0
/// обычный мультипликативный бонус для модификаторов веса улова крючка
#define FISHING_DEFAULT_HOOK_BONUS_MULTIPLICATIVE 1

// дефайны иконок рыбы для мини-игры
#define FISH_ICON_DEF "fish"
#define FISH_ICON_HOSTILE "hostile"
#define FISH_ICON_STAR "star"
#define FISH_ICON_CHUNKY "chunky"
#define FISH_ICON_SLIME "slime"
#define FISH_ICON_COIN "coin"
#define FISH_ICON_GEM "gem"
#define FISH_ICON_CRAB "crab"
#define FISH_ICON_JELLYFISH "jellyfish"
#define FISH_ICON_BOTTLE "bottle"
#define FISH_ICON_BONE "bone"
#define FISH_ICON_ELECTRIC "electric"
#define FISH_ICON_WEAPON "weapon"
#define FISH_ICON_CRITTER "critter"
#define FISH_ICON_SEED "seed"
#define FISH_ICON_ORGAN "organ"

#define AQUARIUM_ANIMATION_FISH_SWIM "fish"
#define AQUARIUM_ANIMATION_FISH_DEAD "dead"

// стандартные дефайны слоёв для аквариумов

/// шаг между слоями аквариума
#define AQUARIUM_LAYER_STEP 0.01
/// смещения слоёв содержимого аквариума
#define AQUARIUM_MIN_OFFSET 0.02
#define AQUARIUM_MAX_OFFSET 1
/// слой стекла
#define AQUARIUM_GLASS_LAYER 0.02
/// слой рамок аквариума
#define AQUARIUM_BORDERS_LAYER AQUARIUM_MAX_OFFSET + AQUARIUM_LAYER_STEP
/// слой для объектов под стеклом
#define AQUARIUM_BELOW_GLASS_LAYER 0.01

#define AQUARIUM_LAYER_MODE_BOTTOM "bottom"
#define AQUARIUM_LAYER_MODE_TOP "top"
#define AQUARIUM_LAYER_MODE_AUTO "auto"
#define AQUARIUM_LAYER_MODE_BEHIND_GLASS "behind_glass"

#define FISH_ALIVE "alive"
#define FISH_DEAD "dead"

/// пороги размера рыбы для w_class
#define FISH_SIZE_TINY_MAX 30
#define FISH_SIZE_SMALL_MAX 50
#define FISH_SIZE_NORMAL_MAX 80
#define FISH_SIZE_BULKY_MAX 120
/// с этого размера рыбу носят двумя руками
#define FISH_SIZE_TWO_HANDS_REQUIRED 135
#define FISH_SIZE_HUGE_MAX 165

/// насколько вес и размер могут отклониться от средних значений
#define MAX_FISH_DEVIATION_COEFF 2.5

// Базовый множитель разницы между текущим размером и весом и их максимумами,
// он вместе с голодом, размером и весом задаёт прирост рыбы за каждое кормление.
// Крупная рыба, само собой, растёт заметно медленнее

#define FISH_GROWTH_MULT 0.38
/// пик роста держится на 45% голода, а дальше резко падает
#define FISH_GROWTH_PEAK 0.45
/// часть делителя, что замедляет рост крупной рыбы
#define FISH_SIZE_WEIGHT_GROWTH_MALUS 0.5

/// объём фарша умножается на вес рыбы и делится на это
#define FISH_GRIND_RESULTS_WEIGHT_DIVISOR 500
/// число филе умножается на размер рыбы и делится на это
#define FISH_FILLET_NUMBER_SIZE_DIVISOR 30

/// с этого веса переноска рыбы начинает замедлять
#define FISH_WEIGHT_SLOWDOWN 2100
/// замедление это вес, делённый на это и возведённый в степень меньше 1
#define FISH_WEIGHT_SLOWDOWN_DIVISOR 500
/// степень меньше единицы, которая задаёт итоговое замедление рыбы
#define FISH_WEIGHT_SLOWDOWN_EXPONENT 0.54
/// участвует в расчёте силы рыбы вместе с w_class, через логарифм от веса
#define FISH_WEIGHT_FORCE_DIVISOR 250
/// множитель для FISH_WEIGHT_BITE_DIVISOR
#define FISH_WEIGHT_GRIND_TO_BITE_MULT 0.4
/// задаёт, сколько укусов выдержит рыба, а значит и сколько в ней реагентов
#define FISH_WEIGHT_BITE_DIVISOR (FISH_GRIND_RESULTS_WEIGHT_DIVISOR * FISH_WEIGHT_GRIND_TO_BITE_MULT)

/// считает замедление рыбы от её веса
#define GET_FISH_SLOWDOWN(weighty) round(((weighty/FISH_WEIGHT_SLOWDOWN_DIVISOR)**FISH_WEIGHT_SLOWDOWN_EXPONENT)-1.3, 0.1)

/// ранг рыбы по весу
#define GET_FISH_WEIGHT_RANK(weighty) max(round(1 + log(2, max(weighty/FISH_WEIGHT_FORCE_DIVISOR, 1)), 1), 1)

/// на это умножается таймаут размножения у только что созданной рыбы
#define NEW_FISH_BREEDING_TIMEOUT_MULT 0.6
/// на это умножается время последнего кормления у новой рыбы
#define NEW_FISH_LAST_FEEDING_MULT 0.33 // шкала голода начинается с 33%

/// при get_hunger выше этого рыба голодает и потихоньку теряет здоровье
#define FISH_STARVING_THRESHOLD 1

/// рыба попадает в каталог и на вики (по сути баберовское автовики для рыбалки, кто-нибудь сделает похожее и у нас)
#define FISH_FLAG_SHOW_IN_CATALOG (1<<0)
/// у рыбы есть анимация трепыхания через матрицы
#define FISH_DO_FLOP_ANIM (1<<1)
/// рыбу гладили за последние 30 секунд
#define FISH_FLAG_PETTED (1<<2)
/// рыбу можно отсканировать для экспериментов по сканированию
#define FISH_FLAG_EXPERIMENT_SCANNABLE (1<<3)
/// говорит, что fish/update_size_and_weight() сейчас выполняется
#define FISH_FLAG_UPDATING_SIZE_AND_WEIGHT (1<<4)
/// ставится, когда популяция вида превышает стабильную для аквариума
#define FISH_FLAG_OVERPOPULATED (1<<5)
/// ставится, пока рыба в аквариуме с безопасной температурой
#define FISH_FLAG_SAFE_TEMPERATURE (1<<6)
/// ставится, пока рыба в аквариуме с подходящей жидкостью
#define FISH_FLAG_SAFE_FLUID (1<<7)

#define MIN_AQUARIUM_TEMP T0C
#define MAX_AQUARIUM_TEMP (T0C + 100)
#define DEFAULT_AQUARIUM_TEMP (T0C + 24)

/// насколько вероятно выпасть той или иной рыбе из случайного ящика
#define FISH_RARITY_BASIC 1000
#define FISH_RARITY_RARE 400
#define FISH_RARITY_VERY_RARE 200
#define FISH_RARITY_GOOD_LUCK_FINDING_THIS 50
#define FISH_RARITY_NOPE 0

/// типы жидкости аквариума. Жидкость должна совпадать с нужной рыбе, иначе та медленно умирает.
#define AQUARIUM_FLUID_FRESHWATER "Freshwater"
#define AQUARIUM_FLUID_SALTWATER "Saltwater"
#define AQUARIUM_FLUID_SULPHWATEVER "Sulfuric Water"
#define AQUARIUM_FLUID_AIR "Air"
#define AQUARIUM_FLUID_ANADROMOUS "Anadromous"
#define AQUARIUM_FLUID_ANY_WATER "Any Fluid"

/// флавор. Название фирмы, что делает аквариумы, показывается в каталоге рыбы
#define AQUARIUM_COMPANY "Aquatech Ltd."

/// ручной режим, где еду, жидкость и температуру держишь на себе, иначе рыба не выживет
#define AQUARIUM_MODE_MANUAL "Manual"
/// код сам подбирает жидкость и температуру. Стоит по умолчанию.
#define AQUARIUM_MODE_AUTO "Assisted"
/// рыба не гибнет от температуры, жидкости и голода, зато перестаёт расти
#define AQUARIUM_MODE_SAFE "Stasis"

/// сколько времени проходит между разрядами электрогенеза
#define ELECTROGENESIS_DURATION 40 SECONDS
/// случайный разброс перезарядки электрогенеза
#define ELECTROGENESIS_VARIANCE (rand(-10 SECONDS, 10 SECONDS))

#define FISH_BEAUTY_DISGUSTING -500
#define FISH_BEAUTY_UGLY -300
#define FISH_BEAUTY_BAD -200
#define FISH_BEAUTY_NULL 0
#define FISH_BEAUTY_GENERIC 250
#define FISH_BEAUTY_GOOD 450
#define FISH_BEAUTY_GREAT 600
#define FISH_BEAUTY_EXCELLENT 700

// размножение останавливается, когда рыб становится больше этого
#define AQUARIUM_MAX_BREEDING_POPULATION 20

// дефайны мини-игры
/// высота ползунка мини-игры, причём в единицах игры, а не в пикселях
#define FISHING_MINIGAME_AREA 1000

/// минимум времени готовки, после которого рыбу безопасно есть
#define FISH_SAFE_COOKING_DURATION 30 SECONDS

/// свойства рыбы, которые собирает collect_fish_properties
#define FISH_PROPERTIES_FAV_BAIT "fav_bait"
#define FISH_PROPERTIES_BAD_BAIT "bad_bait"
#define FISH_PROPERTIES_TRAITS "fish_traits"
#define FISH_PROPERTIES_BEAUTY_SCORE "beauty_score"
#define FISH_PROPERTIES_EVOLUTIONS "evolutions"

/// дефайн для любимых и нелюбимых наживок, что не сводятся к путям типов предметов
#define FISH_BAIT_TYPE "Type"
#define FISH_BAIT_FOODTYPE "Foodtype"
#define FISH_BAIT_REAGENT "Reagent"
#define FISH_BAIT_VALUE "Value"
#define FISH_BAIT_AMOUNT "Amount"


/// на это умножается вес рыбы в таблице добычи, если рыбачить без наживки
#define FISH_WEIGHT_MULT_WITHOUT_BAIT 0.15


/**
 * Флаг для источников рыбы. Крупные взрывы хуже спавнят рыбу.
 * Нужен для ''ленивых'' мест, что охватывают несколько тайлов
 */
#define FISH_SOURCE_FLAG_EXPLOSIVE_MALUS (1<<0)
/// такое место не годится для случайных наград блюспейс-удочек
#define FISH_SOURCE_FLAG_NO_BLUESPACE_ROD (1<<1)
/// при осмотре с нужным навыком покажет и рыбу без FISH_FLAG_SHOW_IN_CATALOG
#define FISH_SOURCE_FLAG_IGNORE_HIDDEN_ON_CATALOG (1<<2)
/// это место не спавнит рыбу от взрывов
#define FISH_SOURCE_FLAG_EXPLOSIVE_NONE (1<<3)

/**
 * Макрос делает имена файлов иконок уникальными для викимедиа, ведь есть рыбы
 * с неоднозначными именами и icon_state вроде "checkered" или "pike"
 */
#define FISH_AUTOWIKI_FILENAME(fish) SANITIZE_FILENAME("[initial(fish.icon_state)]_wiki_fish")

/// ключи списка для autowiki источников рыбы
#define FISH_SOURCE_AUTOWIKI_NAME "name"
#define FISH_SOURCE_AUTOWIKI_ICON "icon"
#define FISH_SOURCE_AUTOWIKI_WEIGHT "weight"
#define FISH_SOURCE_AUTOWIKI_WEIGHT_SUFFIX "weight_suffix"
#define FISH_SOURCE_AUTOWIKI_NOTES "notes"

/// особое значение name, что всегда идёт первым при сортировке, независимо от веса
#define FISH_SOURCE_AUTOWIKI_DUD "Nothing"
/// особое значение name, что всегда идёт последним
#define FISH_SOURCE_AUTOWIKI_OTHER "Other Stuff"
/// имя файла иконки для ''прочего'', что не расписываем в autowiki
#define FISH_SOURCE_AUTOWIKI_QUESTIONMARK "questionmark"

// псевдонимы DCS и сигналы, которых у нас нет
#ifndef COMSIG_QDELETING
#define COMSIG_QDELETING COMSIG_PARENT_QDELETING
#endif
#define COMSIG_ATOM_TEMPORARY_ANIMATION_START "atom_temporary_animation_start"
#define COMSIG_MOVABLE_PRE_IMPACT "movable_pre_impact"
#define COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON "atom_after_successful_initialized_on"
#define COMSIG_MULTITOOL_REMOVE_BUFFER "multitool_remove_buffer"
#define COMSIG_LIVING_HANDLE_BREATHING "living_handle_breathing"
#define COMSIG_ITEM_FRIED "item_fried"
#define COMSIG_ITEM_BARBEQUE_GRILLED "item_barbeque_grilled"
#define COMSIG_ATOM_ON_LAZARUS_INJECTOR "atom_on_lazarus_injector"
#define COMSIG_GENERATE_REAGENTS_TO_ADD "generate_reagents_to_add"
#define COMSIG_OBJECT_PRE_BANING "object_pre_baning"
#define COMSIG_OBJECT_ON_BANING "object_on_baning"

// ключи звуков
#ifndef SFX_DEFAULT_FISH_SLAP
#define SFX_DEFAULT_FISH_SLAP "default_fish_slap"
#define SFX_ALT_FISH_SLAP "alt_fish_slap"
#define SFX_FISH_PICKUP "fish_pickup"
#endif

// результат заброса удочки
#define FISHING_ROD_CAST_HANDLED (1<<0)

// сигналы рыбалки
#define COMSIG_FISHING_ROD_CAST "fishing_rod_cast"
#define COMSIG_FISHING_ROD_HOOKED_ITEM "fishing_rod_hooked_item"
#define COMSIG_FISHING_ROD_CAUGHT_FISH "fishing_rod_caught_fish"
#define COMSIG_FISH_SOURCE_REWARD_DISPENSED "fish_source_reward_dispensed"
#define COMSIG_FISHING_SOURCE_INTERRUPT_CHALLENGE "fishing_source_interrupt_challenge"
#define COMSIG_FISHING_CHALLENGE_ROLL_REWARD "fishing_challenge_roll_reward"
#define COMSIG_ITEM_FISHING_ROD_SLOTTED "item_fishing_rod_slotted"
#define COMSIG_ITEM_FISHING_ROD_UNSLOTTED "item_fishing_rod_unslotted"
#define COMSIG_ROD_BEGIN_FISHING "rod_begin_fishing"
#define COMSIG_MOB_BEGIN_FISHING "mob_begin_fishing"
#define COMSIG_MOB_BEGIN_FISHING_MINIGAME "mob_begin_fishing_minigame"
#define COMSIG_MOB_COMPLETE_FISHING "mob_complete_fishing"
#define COMSIG_FISHING_CHALLENGE_MOVER_INITIALIZED "fishing_challenge_mover_initialized"

// сигналы рыбы
#define COMSIG_FISH_STATUS_CHANGED "fish_status_changed"
#define COMSIG_FISH_LIFE "fish_life"
#define COMSIG_FISH_UPDATE_SIZE_AND_WEIGHT "fish_update_size_and_weight"
#define COMSIG_FISH_FORCE_UPDATED "fish_force_updated"
#define COMSIG_FISH_RELEASED_INTO "fish_released_into"
#define COMSIG_FISH_EATEN_BY_OTHER_FISH "fish_eaten_by_other_fish"
#define COMSIG_FISH_ANALYZER_ANALYZE_STATUS "fish_analyzer_analyze_status"
#define COMSIG_FISH_BEFORE_GROWING "fish_before_growing"
#define COMSIG_FISH_FINISH_GROWING "fish_finish_growing"

// сигналы аквариума
#define COMSIG_AQUARIUM_CAN_INSERT "aquarium_can_insert"
#define COMSIG_CAN_INSERT_IN_AQUARIUM "can_insert_in_aquarium"
#define COMSIG_CANNOT_INSERT_IN_AQUARIUM "cannot_insert_in_aquarium"
#define COMSIG_AQUARIUM_FLUID_CHANGED "aquarium_fluid_changed"
#define COMSIG_AQUARIUM_GET_REPRODUCTION_CANDIDATES "aquarium_get_reproduction_candidates"
#define COMSIG_AQUARIUM_CHECK_EVOLUTION_CONDITIONS "aquarium_check_evolution_conditions"
#define COMSIG_AQUARIUM_CONTENT_DO_ANIMATION "aquarium_content_do_animation"
#define COMSIG_AQUARIUM_CONTENT_GENERATE_APPEARANCE "aquarium_content_generate_appearance"
#define COMSIG_AQUARIUM_CONTENT_RANDOMIZE_POSITION "aquarium_content_randomize_position"
#define COMSIG_MOVABLE_GET_AQUARIUM_BEAUTY "movable_get_aquarium_beauty"

// трейты рыбы для эволюции
#define TRAIT_FISHING_BAIT "fishing_bait"
#define TRAIT_FISH_EATER "fish_eater"
#define TRAIT_FISH_AMPHIBIOUS "fish_amphibious"
#define TRAIT_FISH_CROSSBREEDER "fish_crossbreeder"
#define TRAIT_FISH_ELECTROGENESIS "fish_electrogenesis"
#define TRAIT_FISH_FLOPPING "fish_flopping"
#define TRAIT_FISH_GENEGUNNED "fish_genegunned"
#define TRAIT_FISH_INK_ON_COOLDOWN "fish_ink_on_cooldown"
#define TRAIT_FISH_JUST_SPAWNED "fish_just_spawned"
#define TRAIT_FISH_LOW_PRICE "fish_low_price"
#define TRAIT_FISH_NO_HUNGER "fish_no_hunger"
#define TRAIT_FISH_NO_MATING "fish_no_mating"
#define TRAIT_FISH_ON_TESLIUM "fish_on_teslium"
#define TRAIT_FISH_QUICK_GROWTH "fish_quick_growth"
#define TRAIT_FISH_RECESSIVE "fish_recessive"
#define TRAIT_FISH_SELF_REPRODUCE "fish_self_reproduce"
#define TRAIT_FISH_SHOULD_TWOHANDED "fish_should_twohanded"
#define TRAIT_FISH_STASIS "fish_stasis"
#define TRAIT_FISH_STINGER "fish_stinger"
#define TRAIT_FISH_SURVIVE_COOKING "fish_survive_cooking"
#define TRAIT_FISH_TOXIN_IMMUNE "fish_toxin_immune"
#define TRAIT_FISH_WELL_COOKED "fish_well_cooked"
#define TRAIT_FISH_YUCKY "fish_yucky"
#define TRAIT_STOP_FISH_FLOPPING "stop_fish_flopping"
#define TRAIT_STOP_FISH_REPRODUCTION_AND_GROWTH "stop_fish_reproduction_and_growth"
#define TRAIT_NO_FISHING_ACHIEVEMENT "no_fishing_achievement"

// Трейтовоедля снаряжения и мест для рыбалки
#define TRAIT_BAIT_ALLOW_FISHING_DUD "bait_allow_fishing_dud"
#define TRAIT_BAIT_UNCONSUMABLE "bait_unconsumable"
#define TRAIT_BASIC_QUALITY_BAIT "basic_quality_bait"
#define TRAIT_GOOD_QUALITY_BAIT "good_quality_bait"
#define TRAIT_GREAT_QUALITY_BAIT "great_quality_bait"
#define TRAIT_POISONOUS_BAIT "poisonous_bait"
#define TRAIT_OMNI_BAIT "omni_bait"
#define TRAIT_EXAMINE_FISH "examine_fish"
#define TRAIT_EXAMINE_DEEPER_FISH "examine_deeper_fish"
#define TRAIT_EXAMINE_FISHING_SPOT "examine_fishing_spot"
#define TRAIT_EXPERT_FISHER "expert_fisher"
#define TRAIT_PROFOUND_FISHER "profound_fisher"
#define TRAIT_CATCH_AND_RELEASE "catch_and_release"
#define TRAIT_MINOR_DIFFICULTY_BOOST "minor_difficulty_boost"
#define TRAIT_REVEAL_FISH "reveal_fish"
#define TRAIT_UNLINKABLE_FISHING_SPOT "unlinkable_fishing_spot"
#define TRAIT_FISHING_SPOT "fishing_spot"
#define TRAIT_ROD_ATTRACT_SHINY_LOVERS "rod_attract_shiny_lovers"
#define TRAIT_ROD_IGNORE_ENVIRONMENT "rod_ignore_environment"
#define TRAIT_ROD_LAVA_USABLE "rod_lava_usable"
#define TRAIT_ROD_MANSUS_INFUSED "rod_mansus_infused"
#define TRAIT_ROD_REMOVE_FISHING_DUD "rod_remove_fishing_dud"
#define TRAIT_AQUARIUM_PANEL_OPEN "aquarium_panel_open"
#define TRAIT_IS_AQUARIUM "is_aquarium"
#define TRAIT_UNIQUE_AQUARIUM_CONTENT "unique_aquarium_content"
#define AQUARIUM_TRAIT "aquarium"

// константы навыка
#define FISHING_SKILL_EXP_PER_SECOND 0.25
#define SKILL_LEVEL_LEGENDARY 4
#define FISHING_SKILL_DIFFIULTY_EXP_MULT 0.08

// возвращаемые значения компонентов из портированного кода рыбы
#define COMPONENT_ALLOW_EVOLUTION (1<<0)
#define COMPONENT_DONT_GROW (1<<1)
#define COMPONENT_NO_EXPOSE_REAGENTS (1<<2)

// разное
#ifndef span_boldnicegreen
#define span_boldnicegreen(str) span_nicegreen(str)
#endif
#ifndef span_boldred
#define span_boldred(str) span_danger(str)
#endif
#ifndef EAR_PROTECTION_VACUUM
#define EAR_PROTECTION_VACUUM (1<<0)
#endif
#define FISHING_RECOVERY_RATE 0.5
#define FISHING_MOD "fishing"
#define FISHING_BAG_FILE "fishing_bag"
#define FISHING_BAG_CARPSKIN_FILE "fishing_bag_carpskin"

// Дефайны совместимости для перенесённых рыболовных файлов.
// Недостающие дефайны
#ifndef GORE
#define GORE (1<<14)
#endif
#ifndef BUGS
#define BUGS (1<<15)
#endif
#ifndef MOB_AQUATIC
#define MOB_AQUATIC (1<<8)
#endif
#ifndef MOLES
#define MOLES (1<<2)
#endif
#ifndef DROP_ALL_REMAINS
#define DROP_ALL_REMAINS (DROP_ORGANS|DROP_BODYPARTS|DROP_ITEMS)
#endif
#ifndef DROP_ORGANS
#define DROP_ORGANS (1<<0)
#endif
#ifndef DROP_BODYPARTS
#define DROP_BODYPARTS (1<<1)
#endif
#ifndef DROP_ITEMS
#define DROP_ITEMS (1<<2)
#endif
#ifndef HEAL_ALL
#define HEAL_ALL (1<<0)
#endif
#ifndef MOB_VOMIT_MESSAGE
#define MOB_VOMIT_MESSAGE "vomit"
#endif
#ifndef VOMIT_CATEGORY_DEFAULT
#define VOMIT_CATEGORY_DEFAULT 0
#endif
#ifndef VOMIT_CATEGORY_BLOOD
#define VOMIT_CATEGORY_BLOOD 1
#endif
#ifndef MAGIC_RESISTANCE_MIND
#define MAGIC_RESISTANCE_MIND (1<<0)
#endif
#ifndef LANGUAGE_BABEL
#define LANGUAGE_BABEL "Babel"
#endif
#ifndef DELETE_IF_REPLACED
#define DELETE_IF_REPLACED (1<<0)
#endif
#ifndef ZAP_LOW_POWER_GEN
#define ZAP_LOW_POWER_GEN (1<<0)
#endif
#ifndef COLOR_NEARLY_ALL_BLACK
#define COLOR_NEARLY_ALL_BLACK "#101010"
#endif
#ifndef FOOD_COMPLEXITY_1
#define FOOD_COMPLEXITY_1 1
#define FOOD_COMPLEXITY_2 2
#define FOOD_COMPLEXITY_3 3
#define FOOD_COMPLEXITY_4 4
#define FOOD_COMPLEXITY_5 5
#endif
#ifndef LAVALAND_MAX_TEMPERATURE
#define LAVALAND_MAX_TEMPERATURE 2000
#endif
#ifndef ICEBOX_MIN_TEMPERATURE
#define ICEBOX_MIN_TEMPERATURE 100
#endif
#ifndef HEAD_EYESPRITES
#define HEAD_EYESPRITES 1
#endif
#ifndef LIMB_COLOR_CS_SOURCE_SUICIDE
#define LIMB_COLOR_CS_SOURCE_SUICIDE "suicide"
#endif
#ifndef TRAIT_WATER_ADAPTATION
#define TRAIT_WATER_ADAPTATION "water_adaptation"
#endif
#ifndef TRAIT_UNCOMPOSTABLE
#define TRAIT_UNCOMPOSTABLE "uncompostable"
#endif
#ifndef TRAIT_DUCT_TAPE_UNREPAIRABLE
#define TRAIT_DUCT_TAPE_UNREPAIRABLE "duct_tape_unrepairable"
#endif
#ifndef TRAIT_VALID_DNA_INFUSION
#define TRAIT_VALID_DNA_INFUSION "valid_dna_infusion"
#endif
#ifndef TRAIT_SPEED_POTIONED
#define TRAIT_SPEED_POTIONED "speed_potioned"
#endif
#ifndef TRAIT_BIOELECTRIC_GENERATOR
#define TRAIT_BIOELECTRIC_GENERATOR "bioelectric_generator"
#endif
#ifndef TRAIT_FISH_MADE_OF_BONE
#define TRAIT_FISH_MADE_OF_BONE "fish_made_of_bone"
#endif
#ifndef TRAIT_BYPASS_RANGED_ARMOR
#define TRAIT_BYPASS_RANGED_ARMOR "bypass_ranged_armor"
#endif
#ifndef TRAIT_IS_WET
#define TRAIT_IS_WET "is_wet"
#endif
#ifndef TRAIT_UNHUSKABLE
#define TRAIT_UNHUSKABLE "unhuskable"
#endif
#ifndef TRAIT_RESIST_PSYCHIC
#define TRAIT_RESIST_PSYCHIC "resist_psychic"
#endif
#ifndef TRAIT_STRENGTH
#define TRAIT_STRENGTH "strength"
#endif
#ifndef TRAIT_TOWER_OF_BABEL
#define TRAIT_TOWER_OF_BABEL "tower_of_babel"
#endif
#ifndef TRAIT_XRAY_HEARING
#define TRAIT_XRAY_HEARING "xray_hearing"
#endif
#ifndef TRAIT_GOOD_HEARING
#define TRAIT_GOOD_HEARING "good_hearing"
#endif
#ifndef TRAIT_VEGETARIAN
#define TRAIT_VEGETARIAN "vegetarian"
#endif
#ifndef TRAIT_WATER_ADAPTATION
#define TRAIT_WATER_ADAPTATION "water_adaptation"
#endif
#ifndef MANUAL_SUICIDE_NONLETHAL
#define MANUAL_SUICIDE_NONLETHAL 2
#endif
#ifndef LAZARUS_INJECTOR_USED
#define LAZARUS_INJECTOR_USED (1<<0)
#endif
#ifndef COMSIG_ATOM_EXAMINE
#define COMSIG_ATOM_EXAMINE COMSIG_PARENT_EXAMINE
#endif
#ifndef pick_weight
#define pick_weight(list) pickweight(list)
#endif
#ifndef full_capitalize
#define full_capitalize(str) capitalize(str)
#endif
