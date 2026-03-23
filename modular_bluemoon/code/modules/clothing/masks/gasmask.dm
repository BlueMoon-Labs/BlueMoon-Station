/obj/item/clothing/mask/gas/syndicate/fir22
	name = "FIR-22 full-face rebreather"
	desc = "A full-face respirator designed by Forestfel Intersystem Industries and originally meant for Tajarans, the FIR-22 Rebreather is a snout-covering variant often seen used by Tajaran Military Personnel and Civilian Personnel alike. It reeks of militarism."
	icon_state = "fir22"
	item_state = "fir22"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/////////////////////////////////////////////////////

/obj/item/clothing/mask/gas/syndicate/hahun_mask
	name = "MI13 infiltrator mask"
	desc = "High-quality mask made of expensive materials, has a filtration system, as well as improved scanning of the environment. There are three lenses that shimmer red."
	icon = 'modular_bluemoon/icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/masks.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_righthand.dmi'
	icon_state = "hahun_mask"
	item_state = "hahun_mask"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	actions_types = list(/datum/action/item_action/masktakedown)

/datum/action/item_action/masktakedown
	name = "TAKING DOWN!"

/obj/item/clothing/mask/gas/syndicate/hahun_mask/verb/masktakedown()
	set category = "Object"
	set name = "TAKING DOWN!"
	set src in usr
	if(!isliving(usr))
		return
	if(!can_use(usr))
		return

	var/frase
	frase = input("Какую фразу вы хотите сказать через преобразователь в маске?","") as text

	if(frase)
		usr.audible_message("<b>[usr]</b> halting, \"<font color='red' size='4'><b>[frase]</b></font>\"")
		switch(rand(0,3))
			if(0)
				playsound(src.loc, 'modular_bluemoon/sound/effects/hahun_halt.ogg', 100, 0)
			if(1)
				playsound(src.loc, 'modular_bluemoon/sound/effects/hahun_dontmove.ogg', 100, 0)
			if(2)
				playsound(src.loc, 'modular_bluemoon/sound/effects/hahun_hold.ogg', 100, 0)
			if(3)
				playsound(src.loc, 'modular_bluemoon/sound/effects/hahun_verdict.ogg', 100, 0)

/obj/item/clothing/mask/gas/syndicate/hahun_mask/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/masktakedown))
		masktakedown()

/obj/item/clothing/mask/gas/syndicate/hahun_mask/eidovox
	name = "EIDOVOX Type-3"
	desc = "A sealed, seamless shell with no visible apertures. The visor is a solid, matte surface — almost alive — reacting to light and movement, concealing the operator’s gaze behind a mirror \
			of void. Lateral filtration conduits connect to a rear-mounted respiratory capsule, integrated directly into the cervical interface. The soft hum within isn’t the sound of filters — it’s the presence of active neural scanning. \
			On the left side, the Eidolon insignia is etched into pseudo-osseous polymer. Fine strands of bioluminescent tracer lines arc across the surface, responding to the wearer’s vitals."
	icon_state = "hahun_eidovox"
	item_state = "hahun_eidovox"

/////////////////////////////////////////////////////

/obj/item/clothing/mask/gas/syndicate/legion_mask_frank
	name = "Frank mask"
	desc = "A mad smile that haunts its victims in their nightmares."
	icon_state = "frank"
	item_state = "frank"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	unique_reskin = list(
		"Snout" = list(
			RESKIN_ICON_STATE = "frank_snout",
			RESKIN_ITEM_STATE = "frank_snout"
		),
		"Basic" = list(
			RESKIN_ICON_STATE = "frank",
			RESKIN_ITEM_STATE = "frank"
		),
	)

/obj/item/clothing/mask/gas/syndicate/legion_mask_julie
	name = "Julie mask"
	desc = "A mad smile that haunts its victims in their nightmares."
	icon_state = "julie"
	item_state = "julie"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	unique_reskin = list(
		"Snout" = list(
			RESKIN_ICON_STATE = "julie_snout",
			RESKIN_ITEM_STATE = "julie_snout"
		),
		"Basic" = list(
			RESKIN_ICON_STATE = "julie",
			RESKIN_ITEM_STATE = "julie"
		),
	)

/obj/item/clothing/mask/gas/syndicate/legion_mask_joey
	name = "Joey mask"
	desc = "A mad smile that haunts its victims in their nightmares."
	icon_state = "joey"
	item_state = "joey"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	unique_reskin = list(
		"Snout" = list(
			RESKIN_ICON_STATE = "joey_snout",
			RESKIN_ITEM_STATE = "joey_snout"
		),
		"Basic" = list(
			RESKIN_ICON_STATE = "joey",
			RESKIN_ITEM_STATE = "joey"
		),
	)

/obj/item/clothing/mask/gas/syndicate/legion_mask_susie
	name = "Susie mask"
	desc = "A mad smile that haunts its victims in their nightmares."
	icon_state = "susie"
	item_state = "susie"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	unique_reskin = list(
		"Snout" = list(
			RESKIN_ICON_STATE = "susie_snout",
			RESKIN_ITEM_STATE = "susie_snout"
		),
		"Basic" = list(
			RESKIN_ICON_STATE = "susie",
			RESKIN_ITEM_STATE = "susie"
		),
	)

/obj/item/clothing/mask/gas/syndicate/horror_mask
	name = "Зловещая маска"
	desc = "Серо-бледное лицо с потускневшими блондинистыми волосами. Чёрные прорези на месте глаз смотрят прямиком в душу."
	icon_state = "horror_mask"
	item_state = "horror_mask"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	flags_inv = HIDEHAIR|HIDEFACIALHAIR
