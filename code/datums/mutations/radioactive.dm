/datum/mutation/human/radioactive
	name = "Radioactivity"
	desc = "Нестабильная мутация, из-за которой носитель излучает смертельную бета-радиацию. Это влияет как на самого носителя, так и на окружающую обстановку."
	quality = NEGATIVE
	text_gain_indication = "<span class='warning'>You can feel it in your bones!</span>"
	time_coeff = 5
	instability = 5
	difficulty = 8

/datum/mutation/human/radioactive/on_life()
	radiation_pulse(owner, 20)

/datum/mutation/human/radioactive/New(class_ = MUT_OTHER, timer, datum/mutation/human/copymut)
	..()
	if(!(type in visual_indicators))
		visual_indicators[type] = list(mutable_appearance('icons/effects/genetics.dmi', "radiation", -MUTATIONS_LAYER))

/datum/mutation/human/radioactive/get_visual_indicator()
	return visual_indicators[type][1]
