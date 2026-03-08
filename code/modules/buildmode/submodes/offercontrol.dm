/datum/buildmode_mode/offercontrol
	key = "offercontrol"

/datum/buildmode_mode/offercontrol/get_button_icon()
	return 'icons/misc/buildmode_offer.dmi'

/datum/buildmode_mode/offercontrol/get_button_iconstate()
	return "buildmode_offercontrol"

/datum/buildmode_mode/offercontrol/show_help(c)
	to_chat(c, "<span class='notice'>***********************************************************</span>")
	to_chat(c, "<span class='notice'>Left Mouse Button on mob/living = Offer control to ghosts.</span>")
	to_chat(c, "<span class='notice'>***********************************************************</span>")

/datum/buildmode_mode/offercontrol/handle_click(c, params, object)
	if(!istype(object, /mob/living))
		return

	var/mob/living/mob_to_offer = object

	if(mob_to_offer.key)
		var/response = tgui_alert(c, "This mob already has a ckey attached, continue?", "Mob already possessed!", list("Continue", "Cancel"))
		if(response != "Continue")
			return

	offer_control(mob_to_offer)

