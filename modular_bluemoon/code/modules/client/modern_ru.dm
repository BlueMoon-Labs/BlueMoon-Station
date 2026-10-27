/// Перенесите нормальные листы пж, все дам кроме жопы
var/list/ru_strings = list(
	"hair_style" = "Стиль волос",
	"facial_hair_style" = "Стиль бороды",
	"hair_gradient" = "Градиент волос",
	"taur" = "Тело тавра",
	"tail_lizard" = "Хвост ящера",
	"tail_human" = "Хвост человека",
	"mam_tail" = "Хвост",
	"snout" = "Морда",
	"frills" = "Жабры",
	"spines" = "Шипы",
	"mam_body_markings" = "Отметины вида",
	"mam_ears" = "Уши",
	"ears" = "Уши",
	"mam_snouts" = "Морда",
	"legs" = "Ноги",
	"deco_wings" = "Декоративные крылья",
	"insect_wings" = "Крылья насекомого",
	"insect_fluff" = "Шея и позвоночник",
	"insect_markings" = "Отметины насекомого",
	"wings" = "Крылья",
	"arachnid_legs" = "Ноги паука",
	"arachnid_spinneret" = "Прядильный аппарат",
	"arachnid_mandibles" = "Челюсти",
	"xenohead" = "Глава касты",
	"xenotail" = "Хвост",
	"xenodorsal" = "Спинные шипы",
	"ipc_screen" = "Экран",
	"ipc_antenna" = "Антенна",
	"meat_type" = "Тип мяса",
	"horns" = "Рога",
)

// Global translation dictionaries for modern UI - ENGLISH
var/list/en_strings = list(
	"hair_style" = "Hair Style",
	"facial_hair_style" = "Facial Hair Style",
	"hair_gradient" = "Hair Gradient",
)

/// Get translated text from global dictionaries
/proc/get_modern_text(text_key, datum/preferences/prefs = null)
	if(!text_key)
		return ""

	var/result = ""
	if(prefs?.modern_ui_language == 1)
		result = ru_strings[text_key]
	else
		result = en_strings[text_key]

	return result ? result : text_key
