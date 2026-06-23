//Clockwork Obelisk: Can broadcast a message at a small power cost or outright open a spatial gateway at a massive power cost.
/obj/structure/destructible/clockwork/powered/clockwork_obelisk
	name = "clockwork obelisk"
	desc = "A large brass obelisk hanging in midair."
	clockwork_desc = "A powerful obelisk that can send a message to all servants, open a gateway to a target servant or clockwork obelisk, \
	and slowly proselytize nearby tiles and structures into their clockwork equivalents."
	icon_state = "obelisk_inactive"
	active_icon = "obelisk"
	inactive_icon = "obelisk_inactive"
	unanchored_icon = "obelisk_unwrenched"
	construction_value = 20
	max_integrity = 150
	break_message = "<span class='warning'>The obelisk falls to the ground, undamaged!</span>"
	debris = list(/obj/item/clockwork/alloy_shards/small = 4, \
	/obj/item/clockwork/alloy_shards/medium = 2, \
	/obj/item/clockwork/component/hierophant_ansible/obelisk = 1)
	var/hierophant_cost = MIN_CLOCKCULT_POWER //how much it costs to broadcast with large text
	var/gateway_cost = 2000 //how much it costs to open a gateway
	var/conversion_delay = 50
	var/last_conversion = 0
	var/conversion_range = 5

/obj/structure/destructible/clockwork/powered/clockwork_obelisk/Initialize(mapload)
	. = ..()
	toggle(1)

/obj/structure/destructible/clockwork/powered/clockwork_obelisk/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		. += "<span class='nzcrentr_small'>It requires <b>[DisplayPower(hierophant_cost)]</b> to broadcast over the Hierophant Network, and <b>[DisplayPower(gateway_cost)]</b> to open a Spatial Gateway.</span>"
		. += "<span class='brass'>While powered and secured, it slowly converts nearby tiles and structures into clockwork within <b>[conversion_range]</b> tiles.</span>"

/obj/structure/destructible/clockwork/powered/clockwork_obelisk/can_be_unfasten_wrench(mob/user, silent)
	if(active)
		if(!silent)
			to_chat(user, "<span class='warning'>[src] is currently sustaining a gateway!</span>")
		return FAILED_UNFASTEN
	return ..()

/obj/structure/destructible/clockwork/powered/clockwork_obelisk/forced_disable(bad_effects)
	var/affected = 0
	for(var/obj/effect/clockwork/spatial_gateway/SG in loc)
		SG.ex_act(EXPLODE_DEVASTATE)
		affected++
	if(bad_effects)
		affected += try_use_power(MIN_CLOCKCULT_POWER*4)
	return affected

/obj/structure/destructible/clockwork/powered/clockwork_obelisk/Destroy()
	for(var/obj/effect/clockwork/spatial_gateway/SG in loc)
		SG.ex_act(EXPLODE_DEVASTATE)
	return ..()

/obj/structure/destructible/clockwork/powered/clockwork_obelisk/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(!is_servant_of_ratvar(user) || !can_access_clockwork_power(src, hierophant_cost) || !anchored)
		to_chat(user, "<span class='warning'>You place your hand on [src], but it doesn't react.</span>")
		return
	var/choice = alert(user,"You place your hand on [src]...",,"Hierophant Broadcast","Spatial Gateway","Cancel") //Will create a stable gateway instead if between two obelisks one of which is onstation and the other on reebe
	switch(choice)
		if("Hierophant Broadcast")
			if(active)
				to_chat(user, "<span class='warning'>[src] is sustaining a gateway and cannot broadcast!</span>")
				return
			if(!user.can_speak_vocal())
				to_chat(user, "<span class='warning'>You cannot speak through [src]!</span>")
				return
			var/input = stripped_input(usr, "Please choose a message to send over the Hierophant Network.", "Hierophant Broadcast", "")
			if(!is_servant_of_ratvar(user) || !input || !user.canUseTopic(src, !issilicon(user)))
				return
			if(!anchored)
				to_chat(user, "<span class='warning'>[src] is no longer secured!</span>")
				return FALSE
			if(active)
				to_chat(user, "<span class='warning'>[src] is sustaining a gateway and cannot broadcast!</span>")
				return
			if(!user.can_speak_vocal())
				to_chat(user, "<span class='warning'>You cannot speak through [src]!</span>")
				return
			if(!try_use_power(hierophant_cost))
				to_chat(user, "<span class='warning'>[src] lacks the power to broadcast!</span>")
				return
			clockwork_say(user, text2ratvar("Hierophant Broadcast, activate! [html_decode(input)]"))
			titled_hierophant_message(user, input, "big_brass", "large_brass")
		if("Spatial Gateway")
			if(active)
				to_chat(user, "<span class='warning'>[src] is already sustaining a gateway!</span>")
				return
			if(!user.can_speak_vocal())
				to_chat(user, "<span class='warning'>You need to be able to speak to open a gateway!</span>")
				return
			if(!try_use_power(gateway_cost))
				to_chat(user, "<span class='warning'>[src] lacks the power to open a gateway!</span>")
				return
			if(procure_gateway(user, round(100 * get_efficiency_mod(), 1), round(5 * get_efficiency_mod(), 1), 1))
				process()
				if(!active) //we won't be active if nobody has sent a gateway to us
					active = TRUE
					clockwork_say(user, text2ratvar("Spatial Gateway, activate!"))
					return
			adjust_clockwork_power(gateway_cost) //if we didn't return above, ie, successfully create a gateway, we give the power back

/obj/structure/destructible/clockwork/powered/clockwork_obelisk/process()
	if(!anchored)
		return
	var/obj/effect/clockwork/spatial_gateway/SG = locate(/obj/effect/clockwork/spatial_gateway) in loc
	if(SG && (SG.timerid || SG.is_stable)) //it's a valid gateway, we're active
		icon_state = active_icon
		density = FALSE
		active = TRUE
	else
		icon_state = inactive_icon
		density = TRUE
		active = FALSE
	proselytize_nearby()

/obj/structure/destructible/clockwork/powered/clockwork_obelisk/proc/proselytize_nearby()
	if(!can_access_clockwork_power(src) || last_conversion > world.time)
		return
	var/list/valid_turfs = list()
	var/list/clockwork_turfs = list()
	var/static/list/blacklisted_obelisk_turfs = typecacheof(list(
		/turf/open/floor/clockwork,
		/turf/closed/wall/clockwork,
		/turf/open/space,
		/turf/open/lava,
		/turf/open/chasm,
	))
	for(var/turf/T in circleviewturfs(src, conversion_range))
		if(is_type_in_typecache(T, blacklisted_obelisk_turfs))
			if(istype(T, /turf/open/floor/clockwork))
				clockwork_turfs |= T
			continue
		valid_turfs |= T

	last_conversion = world.time + conversion_delay

	var/turf/convert_target = safepick(valid_turfs)
	if(convert_target)
		convert_target.ratvar_act(TRUE, TRUE)
		return
	var/turf/clockwork_floor = safepick(clockwork_turfs)
	if(clockwork_floor)
		new /obj/effect/temp_visual/ratvar/floor(clockwork_floor)
	else
		last_conversion = world.time + conversion_delay * 2
