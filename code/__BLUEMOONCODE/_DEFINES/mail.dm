// BLUEMOON ADDED - переработка писем

#define MAIL_CATEGORY_MISC "misc"
#define MAIL_CATEGORY_ANTAG "antag"
#define MAIL_CATEGORY_MONEY "money"
#define MAIL_CATEGORY_FAMILY "family"
#define MAIL_CATEGORY_JOB "job"
#define MAIL_CATEGORY_SHOP "shop"
#define MAIL_CATEGORY_SPAM "spam"
#define MAIL_CATEGORY_LEWD "lewd"

#define MAIL_ALL_CATEGORIES "ВСЕ"

/// How much mail the Mail SS will create per fire
#define MAX_MAIL_PER_FIRE 50
/// Maximum of mails on station, which was not opened yet
#define MAX_SEALED_MESSAGES 80
/// Amount of time, after which sealed mail will disappear
#define MAIL_DISAPPEAR_TIME 20 MINUTES

/// Small letter
#define MAIL_TYPE_ENVELOPE "envelope"
/// Big package
#define MAIL_TYPE_PACKAGE "package"

#define MAIL_WEIGHT_EXTREMELY_RARE 5
#define MAIL_WEIGHT_RARE 20
#define MAIL_WEIGHT_UNCOMMON 60
#define MAIL_WEIGHT_DEFAULT 100
#define MAIL_WEIGHT_FREQUENT 200

#define MAIL_SENDER_RANDOM_NAME "random_name"
#define MAIL_SENDER_RANDOM_FEMALE "random_female"
#define MAIL_SENDER_RANDOM_MALE "random_male"
#define MAIL_SENDER_CENTCOM "Центральное Командование"

#define MAIL_GENITALS_MALE list(ORGAN_SLOT_PENIS)
#define MAIL_GENITALS_MALE_FULL list(ORGAN_SLOT_PENIS, ORGAN_SLOT_TESTICLES)
#define MAIL_GENITALS_FEMALE list(ORGAN_SLOT_VAGINA)
#define MAIL_GENITALS_FEMALE_FULL list(ORGAN_SLOT_PENIS, ORGAN_SLOT_WOMB)

#define MAIL_MOOD "mail"

#define MAIL_RECIPIENT_SYNTH list( \
		/datum/species/mammal/synthetic, \
		/datum/species/ipc, \
		/datum/species/synthliz)
