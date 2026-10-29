/datum/language/modular_bluemoon/cetria
	name = LANGUAGE_CETRIA
	desc = "Редкий язык, на котором говорят абсолютно все кеткрины. Он родственен немецкому и латинскому и представляет собой смесь шипения, мурлыканья и изредка рычания. (Используйте русскую букву для префикса)."
	icon = 'modular_bluemoon/icons/misc/language.dmi'
	icon_state = "cetria"
	speech_verb = "mrowls"
	ask_verb = "snarls"
	exclaim_verb = "growls"
	key = "к"
	space_chance = 65
	default_priority = 90
	restricted = FALSE


	complex_language = TRUE

	syllables = list(
	"äurr", "öii", "ëirr",
	"mrps", "mreow", "hiss", "mgrr", "ocde", "tön",
	"net", "shprr", "räha", "sarv", "lum", "met", "rum",
	"somis", "ieda","mrühd", "catr", "reïch", "lar", "ren", "of",
	"ache", "air", "ieten", "dier", "mrdi", "ich", "nigh",
	"ntier", "ter", "ion", "tarr"
	)
	apostrophe_chance = 55
	apostrophe_prefix = list(
	"ïch","düir","wïrr","nad", "ki", "pi"
	)
	apostrophe_ending = list(
	"grr","ië","ür", "u", "hür", "hie","gr", "hi"
	)
	syllables_additions_chance = 80
	syllables_endings = list(
	"wiss","hïess","rrïa","ht", "zu", "bh","nk","wi"
	)

