//Technically the same as /datum/action/small_sprite but for our macro players (I'm one of them)

#define SIZECODE_ALTAPP_KEY "smallsprite_sizecode"

/datum/action/sizecode_smallsprite
	name = "Toggle Giant Sprite"
	desc = "Остальные продолжат видеть вас гигантом."
	icon_icon = 'icons/mob/screen_gen_old.dmi'
	button_icon_state = "health1"
	background_icon_state = "bg_alien"
	var/small = FALSE
	var/datum/weakref/smallsprite_WR

/datum/action/sizecode_smallsprite/Trigger()
	. = ..()
	if(QDELETED(owner))
		return

	if(!small)
		var/image/I = image(icon = owner.icon, icon_state = owner.icon_state, loc = owner, layer = owner.layer, pixel_x = owner.pixel_x, pixel_y = owner.pixel_y)
		I.override = TRUE
		var/datum/atom_hud/alternate_appearance/basic/small_sprite/smallsprite = owner.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/small_sprite, SIZECODE_ALTAPP_KEY, I)
		smallsprite?.update_appearance()
		smallsprite_WR = WEAKREF(smallsprite)
	else
		owner.remove_alt_appearance(SIZECODE_ALTAPP_KEY)
		smallsprite_WR = null

	small = !small
	return TRUE

/datum/action/sizecode_smallsprite/Remove(mob/remove_from)
	owner?.remove_alt_appearance(SIZECODE_ALTAPP_KEY)
	smallsprite_WR = null
	small = FALSE
	return ..()

#undef SIZECODE_ALTAPP_KEY
