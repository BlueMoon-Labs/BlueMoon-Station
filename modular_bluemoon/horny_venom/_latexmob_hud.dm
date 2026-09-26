/datum/hud/dextrous/latexmob
	ui_style = 'modular_bluemoon/horny_venom/icons/latex_hud.dmi'

/datum/hud/dextrous/latexmob/New(mob/owner)
	..()

	action_intent = new /atom/movable/screen/act_intent(null, src)
	action_intent.icon_state = mymob.a_intent
	static_inventory += action_intent
