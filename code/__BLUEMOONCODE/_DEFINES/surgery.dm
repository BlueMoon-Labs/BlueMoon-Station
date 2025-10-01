// Дефайны хирургических операций

// пациент должен быть в сознании
#define OPERATION_MUST_BE_PERFORMED_AWAKE	"operation_must_be_performed_awake"
// требуется полная анестезия (пациент спит)
#define OPERATION_NEED_FULL_ANESTHETIC		"operation_need_full_anesthetic"
// знание операций для mind докторов
#define KNOW_MED_SURGERY_OPERATIONS list( \
	/datum/surgery/healing/brute/upgraded, \
	/datum/surgery/healing/burn/upgraded, \
	/datum/surgery/advanced/toxichealing \
	)

// Все базовые операции с описанием (используется для показа описаний в мониторе операций)
#define BASE_MED_SURGERY_OPERATIONS list( \
	/datum/surgery/coronary_bypass, \
	/datum/surgery/lobectomy, \
	/datum/surgery/hepatectomy, \
	/datum/surgery/gastrectomy, \
	/datum/surgery/debride, \
	/datum/surgery/cardioversion, \
	/datum/surgery/eye_surgery, \
	/datum/surgery/brain_surgery, \
	/datum/surgery/organ_manipulation, \
	/datum/surgery/repair_bone_hairline, \
	/datum/surgery/repair_puncture, \
	/datum/surgery/healing/brute/basic, \
	/datum/surgery/healing/burn/basic, \
	/datum/surgery/blood_filter, \
	/datum/surgery/graft_synthtissue, \
	/datum/surgery/embalming, \
	/datum/surgery/lipoplasty \
	)

/// Priority for sorting the radial operations menu. Lower number = higher position
#define SURGERY_RADIAL_PRIORITY 99

// For healing operations (is_healing = TRUE)
#define SURGERY_RADIAL_PRIORITY_HEAL_BASE_COMBO  0.9    // For Healing damage
#define SURGERY_RADIAL_PRIORITY_HEAL_BASE        1      // For Healing damage
#define SURGERY_RADIAL_PRIORITY_HEAL_EXTRA       1.1    // For Healing secondary damage (like tox)
#define SURGERY_RADIAL_PRIORITY_HEAL_STATIC      2      // For operations, like organ manipulation
#define SURGERY_RADIAL_PRIORITY_HEAL_EMERGENCY   3      // For temporary operations, like revival
#define SURGERY_RADIAL_PRIORITY_HEAL_WOUND       4      // For fix wounds
#define SURGERY_RADIAL_PRIORITY_HEAL_ORGAN       5      // For operations to heal organs
#define SURGERY_RADIAL_PRIORITY_HEAL_ADDITIONAL  6

// For other operations (is_healing = FALSE)
#define SURGERY_RADIAL_PRIORITY_OTHER_FIRST  1
#define SURGERY_RADIAL_PRIORITY_OTHER_SECOND 2
#define SURGERY_RADIAL_PRIORITY_OTHER_THIRD  3
#define SURGERY_RADIAL_PRIORITY_OTHER_FOURTH 4
