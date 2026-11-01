/datum/language/modular_bluemoon/felinid
	name = "Felinid"
	desc = "Естественный язык фелинидов: полно мягкого мурлыканья, мяуканья и шипения. Для фелинидов он строен и информативен, а для всех остальных - лишь бессмысленный хаотичный набор кошачьих звуков. Ня~"
	icon = 'modular_bluemoon/icons/misc/language.dmi'
	speech_verb = "meows"
	ask_verb = "mrowls"
	exclaim_verb = "yowls"
	key = "3"
	// flags = TONGUELESS_SPEECH bluemoon change
	space_chance = 100
	syllables = list("meow","mewoo","mewl","prrt","mew","mrow","meewr","hsss","meowr","growl","mrowl","rawr", \
					 "mrawr~","nya~","nya~","nya~","nyaw~","nyawr~","yaaaw~","mrrr~","rrr~","awwr~","purr~","mrrya~","rawr~")
	icon_state = "felinid"
	default_priority = 90
	restricted = FALSE
	spans = list(SPAN_FELINSPEAK)
