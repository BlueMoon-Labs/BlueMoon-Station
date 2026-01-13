#define TRAIT_BLUEMOON_DEVOURER				"giant_body"
#define TRAIT_BLUEMOON_CLEARLY_AUDIBLE		"clearly_audible"
#define TRAIT_BLUEMOON_ANTI_NORMALIZER		"anti_normalizer"
#define TRAIT_BLUEMOON_HIGH_PAIN_THRESHOLD	"high_pain_threshold"
#define TRAIT_BLUEMOON_FEAR_OF_SURGEONS		"fear_of_surgeons"
#define TRAIT_BLUEMOON_SHRIEK				"shriek"
#define TRAIT_BLUEMOON_SHOWER_NEED			"shower_need"
#define TRAIT_BLUEMOON_COMPLEX_MAINTENANCE	"high_quality_maintenance"
#define TRAIT_BLUEMOON_RESTORATIVE_NANOBOTS	"restorative_nanobots_trait"
#define TRAIT_BLUEMOON_SYSCLEANER			"syscleaner_trait"
#define TRAIT_BLUEMOON_POWERSAVING			"robotic_powersaving"
#define TRAIT_BLUEMOON_POWERSHARING			"robotic_powersharing"
#define TRAIT_BLUEMOON_COOLANT_GENERATOR	"coolant_generator"
#define TRAIT_BLUEMOON_WATER_VULNERABILITY	"robotic_water_vulnerability"
#define TRAIT_BLUEMOON_EMP_VULNERABILITY	"robotic_emp_vulnerability"
#define TRAIT_LEWD_JOB						"lewd_job"
#define TRAIT_LEWD_SUMMON					"Призываемый"
#define TRAIT_LEWD_SUMMONED					"lewd_summoned"
#define TRAIT_SPIKY							"spiky"
#define TRAIT_SHY							"shy"
#define TRAIT_COMMON_PREGNANCY				"common_pregnancy"
#define TRAIT_BONDAGED						"bondaged"
#define TRAIT_IMAGINARYFRIEND				"imaginaryfriend"
#define TRAIT_TK_POTENTIAL					"TK_potential"

// Отдельные наименования для квирков, чтобы не повторять их в настройках
#define BLUEMOON_TRAIT_NAME_SHRIEK				"Крикун"
#define BLUEMOON_TRAIT_NAME_SHOWER_NEED			"Потребность в душе"
#define BLUEMOON_TRAIT_NAME_COMPLEX_MAINTENANCE "Сложное обслуживание"
#define BLUEMOON_TRAIT_NAME_RESTORATIVE_NANOBOTS "Восстановительные Наноботы"
#define BLUEMOON_TRAIT_NAME_SYSCLEANER			"Система Бэкапов"
#define BLUEMOON_TRAIT_NAME_POWERSAVING			"Эффективное Энергопотребление"
#define BLUEMOON_TRAIT_NAME_POWERSHARING		"Двусторонняя Зарядка"
#define BLUEMOON_TRAIT_NAME_COOLANT_GENERATOR	"Генератор Хладагента"
#define BLUEMOON_TRAIT_NAME_WATER_VULNERABILITY	"Уязвимость к Воде"
#define BLUEMOON_TRAIT_NAME_EMP_VULNERABILITY	"Некачественное Экранирование"

// Трейты для рас
#define CAN_BE_OPERATED_WITHOUT_PAIN		"can_be_operated_without_pain"

// Трейты для профессий
#define TRAIT_QUALIFIED_ROBOTIC_MAINTER		"qualified_robotic_mainter"
#define TRAIT_GUIDED_ROBOTIC_MAINTER		"guided_robotic_mainter"
#define TRAIT_REAGENT_EXPERT				"reagent_expert"
#define TRAIT_MECHA_EXPERT 					"mecha_expert"
#define TRAIT_FENCER		 				"fencer"

// Названия для мудов от квирков
#define QMOOD_BONDAGE		"mood_bondage"
/// Mob does not remember its death, due to one of DEATH_FORGETFULLNESS_REASONs
#define TRAIT_BLUEMOON_DEATH_FORGETFULNESS	"bm_death_forget"


/// Chasms will be safe to cross while they've this trait.
/// Этот трейт не работает "в полном объеме" как на новотг/парадизе и является заплаткой, которая может иметь ограниченный функционал.
/// На данный момент присваивается атому (турфу). После снятия этого трейта желательно запустить процесс обработки падения предметов в чазм или вызвать /drop_stuff().
#define TRAIT_CHASM_STOPPED "chasm_stopped"

#define TRAIT_MOB_IN_AURA_HEALING "mob_in_aura_healing"

/// Whether nanobots from TRAIT_BLUEMOON_RESTORATIVE_NANOBOTS are working RIGHT NOW
#define TRAIT_NANOBOT_REPAIR_IN_PROGRESS "nanobot_repair_in_progress"

/// Whether syscorruption cleaner from TRAIT_BLUEMOON_SYSCLEANER is working RIGHT NOW
#define TRAIT_SYSCLEANER_IN_PROGRESS "nanobot_syscleaner_in_progress"
