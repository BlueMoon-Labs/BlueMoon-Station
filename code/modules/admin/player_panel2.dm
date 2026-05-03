GLOBAL_LIST_INIT(mute_bits, list(
	list(name = "IC", bitflag = MUTE_IC),
	list(name = "OOC", bitflag = MUTE_OOC),
	list(name = "Pray", bitflag = MUTE_PRAY),
	list(name = "Ahelp", bitflag = MUTE_ADMINHELP),
	list(name = "Deadchat", bitflag = MUTE_DEADCHAT)
))

GLOBAL_LIST_INIT(pp_limbs, list(
	"Head" 		= BODY_ZONE_HEAD,
	"Left leg" 	= BODY_ZONE_L_LEG,
	"Right leg" = BODY_ZONE_R_LEG,
	"Left arm" 	= BODY_ZONE_L_ARM,
	"Right arm" = BODY_ZONE_R_ARM
))

/proc/init_pp_martial_arts()
	var/list/arts = list()
	for(var/matype in subtypesof(/datum/martial_art))
		var/datum/martial_art/MA = matype
		var/ma_name = initial(MA.name)
		if(!ma_name || ma_name == "Martial Art")
			continue
		if(arts[ma_name])
			continue
		arts[ma_name] = matype
	return arts

GLOBAL_LIST_INIT(pp_martial_arts, init_pp_martial_arts())

/proc/init_pp_quirks()
	var/list/quirks = list()
	for(var/qtype in subtypesof(/datum/quirk))
		var/datum/quirk/Q = qtype
		var/q_name = initial(Q.name)
		if(!q_name)
			continue
		quirks[q_name] = qtype
	return quirks

GLOBAL_LIST_INIT(pp_quirks, init_pp_quirks())

/proc/init_pp_organs()
	var/list/organs = list()
	for(var/otype in subtypesof(/obj/item/organ))
		var/obj/item/organ/O = otype
		var/o_name = initial(O.name)
		var/o_slot = initial(O.slot)
		if(!o_name || o_name == "organ" || !o_slot)
			continue
		if(!organs[o_slot])
			organs[o_slot] = list()
		organs[o_slot] += list(list("name" = o_name, "path" = "[otype]"))
	return organs

GLOBAL_LIST_INIT(pp_organs, init_pp_organs())

/proc/init_pp_implants()
	var/list/implants = list()
	for(var/itype in subtypesof(/obj/item/implant))
		var/obj/item/implant/I = itype
		var/i_name = initial(I.name)
		if(!i_name || i_name == "implant")
			continue
		implants[i_name] = itype
	return implants

GLOBAL_LIST_INIT(pp_implants, init_pp_implants())

/datum/admins/proc/show_player_panel2(mob/M)
	if(!M)
		to_chat(owner, "You seem to be selecting a mob that doesn't exist anymore.")
		return

	// this is stupid, thanks byond
	if(istype(src, /client))
		var/client/C = src
		src = C.holder

	if(!check_rights())
		to_chat(owner, "Error: you are not an admin!")
		return

	log_admin("[key_name(usr)] checked the individual player panel for [key_name(M)][isobserver(usr)?"":" while in game"].")

	if(!M.mob_panel)
		M.create_player_panel()

	M.mob_panel.ui_interact(owner.mob)

/datum/player_panel
	var/mob/targetMob
	var/client/targetClient
	var/list/roleStatus // A list of each role and whether they are banned or not for this player.
	var/antagBanReason
	var/activeRoleBans
	var/mobSize // Because aparently there is no variable that tracks this on the mob??

/datum/player_panel/New(mob/target)
	. = ..()
	targetMob = target

	var/mob/living/L = targetMob
	if (istype(L))
		mobSize = L.mob_size

/datum/player_panel/Destroy(force, ...)
	targetMob = null
	targetClient = null
	roleStatus = null
	antagBanReason = null
	activeRoleBans = null
	mobSize = null

	SStgui.close_uis(src)
	return ..()

/datum/player_panel/ui_interact(mob/user, datum/tgui/ui)
	if(!targetMob)
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "PlayerPanel2", "[targetMob.name] Player Panel")
		ui.open()

/datum/player_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/player_panel/ui_data(mob/user)
	. = list()
	.["has_live_client"] = !!targetMob.client
	.["mob_name"] = targetMob.real_name
	// .["current_permissions"] = user.client?.holder?.rank.rights
	.["mob_type"] = targetMob.type
	.["admin_mob_type"] = user.client?.mob.type
	.["godmode"] = targetMob.status_flags & GODMODE

	var/mob/living/L = targetMob
	if (istype(L))
		.["is_frozen"] = L.admin_frozen
		.["is_slept"] = L.admin_sleeping
		.["mob_scale"] = mobSize

	var/resolved_ckey = resolve_mob_ban_ckey(targetMob)
	if(targetMob.client)
		targetClient = targetMob.client
		.["client_ckey"] = targetClient.ckey
		.["client_muted"] = targetClient.prefs.muted
		.["client_rank"] = targetClient.holder ? targetClient.holder.rank : "Player"
	else
		targetClient = null
		.["client_ckey"] = resolved_ckey
		.["client_muted"] = null
		.["client_rank"] = null

	if(resolved_ckey)
		if (!roleStatus)
			updateJobbanStatus()
		.["roles"] = roleStatus
		.["antag_ban_reason"] = antagBanReason
		.["active_role_ban_count"] = activeRoleBans
	else
		roleStatus = null
		antagBanReason = null
		activeRoleBans = null
		.["roles"] = null
		.["antag_ban_reason"] = null
		.["active_role_ban_count"] = null

	// Active martial art
	var/mob/living/carbon/pp_carbon = targetMob
	if(istype(pp_carbon) && pp_carbon.mind?.martial_art && pp_carbon.mind.martial_art.name != "Martial Art")
		.["active_martial_art"] = pp_carbon.mind.martial_art.name
	else
		.["active_martial_art"] = null

	// Active quirks
	var/list/active_quirks = list()
	if(isliving(targetMob))
		var/mob/living/pp_living = targetMob
		for(var/datum/quirk/Q in pp_living.roundstart_quirks)
			active_quirks += Q.name
	.["active_quirks"] = active_quirks

	// Has loadout data
	.["has_loadout"] = !!(targetMob.client?.prefs?.loadout_data)

	// Current organs
	var/list/current_organs = list()
	if(iscarbon(targetMob))
		var/mob/living/carbon/C = targetMob
		for(var/slot_name in C.internal_organs_slot)
			var/obj/item/organ/O = C.internal_organs_slot[slot_name]
			if(O)
				current_organs += list(list("slot" = slot_name, "name" = O.name, "type_path" = "[O.type]"))
	.["current_organs"] = current_organs

	// Current implants
	var/list/current_implants = list()
	if(isliving(targetMob))
		var/mob/living/imp_mob = targetMob
		for(var/obj/item/implant/I in imp_mob.implants)
			current_implants += list(list("name" = I.name, "ref" = REF(I), "type_path" = "[I.type]"))
	.["current_implants"] = current_implants

	// Current weight
	.["mob_weight"] = targetMob.mob_weight

/datum/player_panel/ui_static_data()
	. = list()

	.["transformables"] = GLOB.pp_transformables
	.["glob_limbs"] = GLOB.pp_limbs
	.["glob_mute_bits"] = GLOB.mute_bits
	.["current_time"] = time2text(world.timeofday, "YYYY-MM-DD hh:mm:ss")

	.["initial_scale"] = 1

	if(targetClient)
		var/byond_version = "Unknown"
		if(targetClient.byond_version)
			byond_version = "[targetClient.byond_version].[targetClient.byond_build ? targetClient.byond_build : "xxx"]"
		.["data_byond_version"] = byond_version
		.["data_player_join_date"] = targetClient.player_join_date
		.["data_account_join_date"] = targetClient.account_join_date
		.["data_related_cid"] = targetClient.related_accounts_cid
		.["data_related_ip"] = targetClient.related_accounts_ip

		.["initial_scale"] = targetClient.prefs.features["body_size"]

		if(CONFIG_GET(flag/use_exp_tracking))
			.["playtimes_enabled"] = TRUE
			.["playtime"] = targetMob.client.get_exp_living()

	// Smites list
	var/list/smite_names = list()
	for(var/sname in GLOB.smites)
		smite_names += sname
	.["smites_list"] = smite_names

	// Martial arts list
	var/list/ma_data = list()
	for(var/ma_name in GLOB.pp_martial_arts)
		ma_data += list(list("name" = ma_name))
	.["martial_arts_list"] = ma_data

	// Quirks list
	var/list/quirks_data = list()
	for(var/q_name in GLOB.pp_quirks)
		var/datum/quirk/Q = GLOB.pp_quirks[q_name]
		var/q_value = initial(Q.value)
		var/q_type_str = QUIRK_NEUTRAL
		if(q_value > 0)
			q_type_str = QUIRK_POSITIVE
		else if(q_value < 0)
			q_type_str = QUIRK_NEGATIVE
		quirks_data += list(list("name" = q_name, "value_type" = q_type_str, "desc" = initial(Q.desc)))
	.["quirks_list"] = quirks_data

	// Organs by slot
	.["organ_slots"] = GLOB.pp_organs

	// Implants list
	var/list/implants_data = list()
	for(var/imp_name in GLOB.pp_implants)
		implants_data += list(list("name" = imp_name))
	.["implants_list"] = implants_data

	// Weight options
	.["weight_options"] = list(\
		list("name" = NAME_WEIGHT_LIGHT, "value" = MOB_WEIGHT_LIGHT),\
		list("name" = NAME_WEIGHT_NORMAL, "value" = MOB_WEIGHT_NORMAL),\
		list("name" = NAME_WEIGHT_HEAVY, "value" = MOB_WEIGHT_HEAVY),\
		list("name" = NAME_WEIGHT_HEAVY_SUPER, "value" = MOB_WEIGHT_HEAVY_SUPER)\
	)

/datum/player_panel/ui_act(action, params, datum/tgui/ui)
	if(..())
		return

	var/client/admin = usr.client

	if (!check_rights(R_ADMIN))
		message_admins("<span class='adminhelp'>WARNING: NON-ADMIN [ADMIN_LOOKUPFLW(admin)] ACCESSING ADMIN PANEL. WARN Casper#3044.</span>")
		to_chat(admin, "Error: you are not an admin!")
		return

	switch(action)
		if ("edit_rank")
			if (!targetMob.client?.ckey)
				return

			var/list/context = list()

			context["key"] = targetMob.client.ckey

			if (GLOB.admin_datums[targetMob.client.ckey] || GLOB.deadmins[targetMob.client.ckey])
				context["editrights"] = "rank"
			else
				context["editrights"] = "add"

			admin.holder.edit_rights_topic(context)

		if ("access_variables")
			admin.debug_variables(targetMob)

		if ("access_playtimes")
			if (targetMob.client)
				admin.holder.cmd_show_exp_panel(targetMob.client)

		if ("private_message")
			admin.cmd_admin_pm_context(targetMob)

		if ("subtle_message")
			admin.cmd_admin_subtle_headset_message(targetMob)

		if ("set_name")
			targetMob.vv_auto_rename(params["name"])

		if ("heal")
			admin.cmd_admin_rejuvenate(targetMob)

		if ("light_heal")
			if(!isliving(targetMob))
				return
			var/mob/living/L = targetMob
			L.adjustBruteLoss(-20)
			L.adjustFireLoss(-20)
			L.adjustToxLoss(-20)
			L.adjustOxyLoss(-20)
			log_admin("[key_name(admin)] light-healed [key_name(targetMob)] (20 HP all types).")
			message_admins("<span class='notice'>[key_name_admin(admin)] light-healed [key_name_admin(targetMob)] (20 HP all types).</span>")

		if ("ghost")
			if(targetMob.client)
				log_admin("[key_name(admin)] ejected [key_name(targetMob)] from their body.")
				message_admins("[key_name_admin(admin)] ejected [key_name_admin(targetMob)] from their body.")
				to_chat(targetMob, "<span class='danger'>An admin has ejected you from your body.</span>")
				targetMob.ghostize(FALSE)

		if ("offer_control")
			offer_control(targetMob)

		if ("take_control")
			var/mob/adminMob = admin.mob

			// Disassociates observer mind from the body mind
			if(targetMob.client)
				targetMob.ghostize(FALSE)
			else
				for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
					if(targetMob.mind == ghost.mind)
						ghost.mind = null

			targetMob.ckey = adminMob.ckey
			qdel(adminMob)

			message_admins("<span class='adminnotice'>[key_name_admin(usr)] took control of [targetMob].</span>")
			log_admin("[key_name(usr)] took control of [targetMob].")
			addtimer(CALLBACK(targetMob.mob_panel, TYPE_PROC_REF(/datum, ui_interact), targetMob), 0.1 SECONDS)

		if ("smite")
			admin.smite(targetMob)

		if ("bring")
			admin.Getmob(targetMob)

		if ("orbit")
			if(!isobserver(admin.mob))
				admin.admin_ghost()
			var/mob/dead/observer/O = admin.mob
			O.ManualFollow(targetMob)

		if ("jump_to")
			admin.jumptomob(targetMob)

		if ("freeze")
			var/mob/living/L = targetMob
			if (istype(L))
				L.toggle_admin_freeze(admin)

		if ("sleep")
			var/mob/living/L = targetMob
			if (istype(L))
				L.toggle_admin_sleep(admin)

		if ("lobby")
			if(!isobserver(targetMob))
				to_chat(usr, "<span class='notice'>You can only send ghost players back to the Lobby.</span>")
				return

			if(!targetMob.client)
				to_chat(usr, "<span class='warning'>[targetMob] doesn't seem to have an active client.</span>")
				return

			log_admin("[key_name(usr)] has sent [key_name(targetMob)] back to the Lobby.")
			message_admins("[key_name(usr)] has sent [key_name(targetMob)] back to the Lobby.")

			var/mob/dead/new_player/NP = new()
			NP.ckey = targetMob.ckey
			qdel(targetMob)
			if(GLOB.preferences_datums[NP.ckey])
				var/datum/preferences/P = GLOB.preferences_datums[NP.ckey]
				P.respawn_restrictions_active = FALSE

		if ("select_equipment")
			admin.cmd_select_equipment(targetMob)

		if ("strip")
			for(var/obj/item/I in targetMob)
				targetMob.dropItemToGround(I, TRUE) //The TRUE forces all items to drop, since this is an admin undress.

		if ("cryo")
			cryoMob(targetMob, effects = TRUE)

		if ("force_say")
			targetMob.say(params["to_say"], forced="admin")

		if ("force_emote")
			targetMob.emote("me", EMOTE_VISIBLE, params["to_emote"])

		if ("prison")
			if(isAI(targetMob))
				to_chat(usr, "This cannot be used on instances of type /mob/living/silicon/ai.")
				return

			targetMob.forceMove(pick(GLOB.prisonwarp))
			to_chat(targetMob, "<span class='userdanger'>You have been sent to Prison!</span>")

			log_admin("[key_name(admin)] has sent [key_name(targetMob)] to Prison!")
			message_admins("[key_name_admin(admin)] has sent [key_name_admin(targetMob)] to Prison!")

		if ("kick")
			admin.holder.kick(targetMob)

		if ("ban")
			admin.holder.newBan(targetMob)

		if ("sticky_ban")
			var/tckey = resolve_mob_ban_ckey(targetMob)
			if(!tckey)
				to_chat(usr, "<span class='warning'>Cannot resolve ckey for sticky ban.</span>")
				return
			var/list/ban_settings = list("ckey" = tckey)
			admin.holder.stickyban("add", ban_settings)

		if ("notes")
			var/note_ckey = resolve_mob_ban_ckey(targetMob)
			if(note_ckey)
				browse_messages(target_ckey = note_ckey)

		if ("logs")
			var/source = LOGSRC_MOB
			if (targetMob.client)
				source = LOGSRC_CLIENT

			show_individual_logging_panel(targetMob, source)

		if ("job_ban")
			if(resolve_mob_ban_ckey(targetMob))
				process_banlist(params["selected_role"], params["is_category"], params["want_to_ban"])

		if ("mute")
			if(!targetMob.client)
				return

			targetMob.client.prefs.muted = text2num(params["mute_flag"])
			log_admin("[key_name(admin)] set the mute flags for [key_name(targetMob)] to [targetMob.client.prefs.muted].")

		if ("mute_all")
			if(!targetMob.client)
				return

			for(var/bit in GLOB.mute_bits)
				targetMob.client.prefs.muted |= bit["bitflag"]

			log_admin("[key_name(admin)] mass-muted [key_name(targetMob)].")

		if ("unmute_all")
			if(!targetMob.client)
				return

			for(var/bit in GLOB.mute_bits)
				targetMob.client.prefs.muted &= ~bit["bitflag"]

			log_admin("[key_name(admin)] mass-unmuted [key_name(targetMob)].")

		if ("related_accounts")
			if(targetMob.client)
				var/related_accounts
				if (params["related_thing"] == "CID")
					related_accounts = targetMob.client.related_accounts_cid
				else
					related_accounts = targetMob.client.related_accounts_ip

				related_accounts = splittext(related_accounts, ", ")

				var/list/dat = list("Related accounts by [params["related_thing"]]:")
				dat += related_accounts
				var/datum/browser/popup = new(usr, "related_[targetMob.client]", "Related Accounts", 420, 300)
				popup.set_content(dat.Join("<br>"))
				popup.open(FALSE)

		if ("transform")
			var/choice = params["newType"]
			if (choice == "/mob/living")
				choice = tgui_input_list(usr, "What should this mob transform into", "Mob Transform", subtypesof(choice))
				if (!choice)
					return

			admin.holder.transformMob(targetMob, admin.mob, choice, params["newTypeName"])

		if ("toggle_godmode")
			admin.cmd_admin_godmode(targetMob)

		if ("spell")
			admin.toggle_spell(targetMob)

		if ("martial_art")
			admin.teach_martial_art(targetMob)

		if ("quirk")
			admin.toggle_quirk(targetMob)

		if ("species")
			admin.set_species(targetMob)

		if ("limb")
			if(!params["limbs"] || !ishuman(targetMob))
				return

			var/mob/living/carbon/human/H = targetMob

			for(var/limb in params["limbs"])
				if (!limb)
					continue

				if (params["delimb_mode"])
					var/obj/item/bodypart/L = H.get_bodypart(limb)
					if (!L)
						continue
					L.dismember(harmless = TRUE)
					playsound(H, 'modular_splurt/sound/effects/cartoon_pop.ogg', 70)
				else
					H.regenerate_limb(limb)

		if ("scale")
			var/mob/living/L = targetMob
			if(!isnull(params["new_scale"]) && istype(L))
				L.vv_edit_var("resize", params["new_scale"])
				mobSize = params["new_scale"]

		if ("set_weight")
			var/new_weight = text2num(params["weight"])
			if(!isnull(new_weight) && isliving(targetMob))
				var/mob/living/L = targetMob
				L.mob_weight = new_weight
				L.update_weight(new_weight)
				log_admin("[key_name(usr)] set [key_name(targetMob)]'s weight to [new_weight].")
				message_admins("[ADMIN_LOOKUPFLW(usr)] set [ADMIN_LOOKUPFLW(targetMob)]'s weight to [new_weight].")

		if ("explode")
			var/power = text2num(params["power"])
			var/empMode = text2num(params["emp_mode"])
			var/extinguishMode = text2num(params["extinguish_mode"])
			var/chosen_mode = ""

			if(empMode)
				chosen_mode += " EMP"
				empulse_using_range(usr, power, TRUE)
			if(extinguishMode)
				chosen_mode += " extinguish"
				var/turf/usr_turf = get_turf(usr)
				var/list/z_level_turfs = list(usr_turf)
				var/turf/neighbour_z_turf = SSmapping.get_turf_above(usr_turf)
				while(neighbour_z_turf)
					z_level_turfs += neighbour_z_turf
					neighbour_z_turf = SSmapping.get_turf_above(neighbour_z_turf)
				neighbour_z_turf = SSmapping.get_turf_below(usr_turf)
				while(neighbour_z_turf)
					z_level_turfs += neighbour_z_turf
					neighbour_z_turf = SSmapping.get_turf_below(neighbour_z_turf)
				for(var/turf/zT in z_level_turfs)
					for(var/turf/T in range(power, zT))
						if(istype(T, /turf/open))
							var/turf/open/O = T
							if(O.air)
								O.air.set_temperature(T20C)
								O.air_update_turf()
						for(var/obj/Ob in T)
							if(istype(Ob, /obj/effect/hotspot))
								qdel(Ob)
							else
								Ob.extinguish()
						for(var/mob/living/L in T)
							L.ExtinguishMob()
			if(!(empMode || extinguishMode))
				chosen_mode = " explosion"
				explosion(usr, power / 3, power / 2, power, power, ignorecap = TRUE)

			var/turf/T = get_turf(usr)
			message_admins("[ADMIN_LOOKUPFLW(usr)] created an admin[chosen_mode] at [ADMIN_VERBOSEJMP(T)].")
			log_admin("[key_name(usr)] created an admin[chosen_mode] at [usr.loc].")

		if ("narrate")
			var/list/stylesRaw = params["classes"]

			var/styles = ""
			for(var/style in stylesRaw)
				styles += "[style]:[stylesRaw[style]];"

			if (params["mode_global"])
				to_chat(world, "<span style='[styles]'>[params["message"]]</span>")
				log_admin("GlobalNarrate: [key_name(usr)] : [params["message"]]")
				message_admins("<span class='adminnotice'>[key_name_admin(usr)] Sent a global narrate</span>")
			else
				for(var/mob/M in view(params["range"], usr))
					to_chat(M, "<span style='[styles]'>[params["message"]]</span>")

				log_admin("LocalNarrate: [key_name(usr)] at [AREACOORD(usr)]: [params["message"]]")
				message_admins("<span class='adminnotice'><b> LocalNarrate: [key_name_admin(usr)] at [ADMIN_VERBOSEJMP(usr)]:</b> [params["message"]]<BR></span>")

		if ("languages")
			var/datum/language_holder/H = targetMob.get_language_holder()
			H.open_language_menu(usr)

		if ("ambitions")
			var/datum/mind/requesting_mind = targetMob.mind
			if(!istype(requesting_mind) || QDELETED(requesting_mind))
				to_chat(usr, "<span class='warning'>This mind reference is no longer valid. It has probably since been destroyed.</span>")
				return
			requesting_mind.do_edit_objectives_ambitions()

		if("makementor")
			admin.holder.makeMentor(ckey = targetMob.ckey)

		if("removementor")
			admin.holder.removeMentor(ckey = targetMob.ckey)

		if ("traitor_panel")
			admin.holder.show_traitor_panel(targetMob)

		if ("smite_direct")
			if(!isliving(targetMob))
				return
			var/smite_name = params["smite_name"]
			if(!smite_name || !(smite_name in GLOB.smites))
				return
			var/smite_path = GLOB.smites[smite_name]
			var/datum/smite/S = new smite_path
			var/config_ok = S.configure(admin)
			if(config_ok == FALSE)
				return
			S.effect(admin, targetMob)

		if ("set_martial_art")
			if(!ishuman(targetMob))
				return
			var/mob/living/carbon/human/H = targetMob
			if(!H.mind)
				return
			var/ma_name = params["ma_name"]
			if(!ma_name || !(ma_name in GLOB.pp_martial_arts))
				return
			var/ma_path = GLOB.pp_martial_arts[ma_name]
			var/datum/martial_art/MA = new ma_path
			if(!MA.teach(H))
				to_chat(usr, "<span class='warning'>Failed to teach [ma_name] to [H]!</span>")
				qdel(MA)
				return
			to_chat(H, "<span class='userdanger'>You have been granted the martial art: [ma_name]!</span>")
			log_admin("[key_name(admin)] has taught [ma_name] to [key_name(targetMob)].")
			message_admins("<span class='notice'>[key_name_admin(admin)] has taught [ma_name] to [key_name_admin(targetMob)].</span>")

		if ("remove_martial_art")
			if(!ishuman(targetMob))
				return
			var/mob/living/carbon/human/H = targetMob
			if(!H.mind?.martial_art)
				return
			var/ma_name = H.mind.martial_art.name
			H.mind.martial_art.remove(H)
			to_chat(H, "<span class='userdanger'>Your martial art [ma_name] has been removed!</span>")
			log_admin("[key_name(admin)] removed martial art [ma_name] from [key_name(targetMob)].")
			message_admins("<span class='notice'>[key_name_admin(admin)] removed martial art [ma_name] from [key_name_admin(targetMob)].</span>")

		if ("toggle_quirk_direct")
			if(!ishuman(targetMob))
				return
			var/mob/living/carbon/human/H = targetMob
			var/q_name = params["quirk_name"]
			if(!q_name || !(q_name in GLOB.pp_quirks))
				return
			var/q_path = GLOB.pp_quirks[q_name]
			if(H.has_quirk(q_path))
				H.remove_quirk(q_path)
				log_admin("[key_name(admin)] removed quirk [q_name] from [key_name(targetMob)].")
			else
				H.add_quirk(q_path, TRUE)
				log_admin("[key_name(admin)] added quirk [q_name] to [key_name(targetMob)].")

		if ("clear_quirks")
			if(!ishuman(targetMob))
				return
			var/mob/living/carbon/human/H = targetMob
			for(var/datum/quirk/Q in H.roundstart_quirks.Copy())
				H.remove_quirk(Q.type)
			log_admin("[key_name(admin)] cleared all quirks from [key_name(targetMob)].")
			message_admins("<span class='notice'>[key_name_admin(admin)] cleared all quirks from [key_name_admin(targetMob)].</span>")

		if ("apply_loadout")
			if(!ishuman(targetMob) || !targetMob.client?.prefs)
				return
			SSjob.equip_loadout(null, targetMob, bypass_prereqs = TRUE)
			log_admin("[key_name(admin)] applied loadout to [key_name(targetMob)].")
			message_admins("<span class='notice'>[key_name_admin(admin)] applied loadout to [key_name_admin(targetMob)].</span>")

		if ("set_organ")
			if(!iscarbon(targetMob))
				return
			var/organ_path = text2path(params["organ_path"])
			if(!organ_path || !ispath(organ_path, /obj/item/organ))
				return
			var/obj/item/organ/new_organ = new organ_path
			new_organ.Insert(targetMob, special = TRUE, drop_if_replaced = TRUE)
			log_admin("[key_name(admin)] gave organ [new_organ.name] to [key_name(targetMob)].")
			message_admins("<span class='notice'>[key_name_admin(admin)] gave organ [new_organ.name] to [key_name_admin(targetMob)].</span>")

		if ("remove_organ")
			if(!iscarbon(targetMob))
				return
			var/mob/living/carbon/C = targetMob
			var/slot_name = params["organ_slot"]
			if(!slot_name)
				return
			var/obj/item/organ/O = C.internal_organs_slot[slot_name]
			if(!O)
				return
			var/organ_name = O.name
			O.Remove(special = TRUE)
			O.forceMove(get_turf(C))
			log_admin("[key_name(admin)] removed organ [organ_name] from [key_name(targetMob)].")
			message_admins("<span class='notice'>[key_name_admin(admin)] removed organ [organ_name] from [key_name_admin(targetMob)].</span>")

		if ("set_implant")
			if(!isliving(targetMob))
				return
			var/imp_name = params["implant_name"]
			if(!imp_name)
				return
			var/imp_path = GLOB.pp_implants[imp_name]
			if(!imp_path)
				return
			var/obj/item/implant/new_imp = new imp_path
			if(!new_imp.implant(targetMob, usr, TRUE, TRUE))
				to_chat(usr, "<span class='warning'>Failed to implant [imp_name] into [targetMob]!</span>")
				qdel(new_imp)
				return
			to_chat(targetMob, "<span class='userdanger'>You feel something being implanted into you: [imp_name]!</span>")
			log_admin("[key_name(admin)] implanted [imp_name] into [key_name(targetMob)].")
			message_admins("<span class='notice'>[key_name_admin(admin)] implanted [imp_name] into [key_name_admin(targetMob)].</span>")

		if ("remove_implant")
			if(!isliving(targetMob))
				return
			var/mob/living/imp_mob = targetMob
			var/imp_ref = params["implant_ref"]
			if(!imp_ref)
				return
			var/obj/item/implant/target_imp = locate(imp_ref) in imp_mob.implants
			if(!target_imp)
				return
			var/imp_name = target_imp.name
			target_imp.removed(imp_mob, TRUE)
			qdel(target_imp)
			to_chat(targetMob, "<span class='userdanger'>An implant has been removed from you: [imp_name]!</span>")
			log_admin("[key_name(admin)] removed implant [imp_name] from [key_name(targetMob)].")
			message_admins("<span class='notice'>[key_name_admin(admin)] removed implant [imp_name] from [key_name_admin(targetMob)].</span>")

// process_banlist: Gets all jobs in a job category
// Input:
// 	query (string): The name of the role / department you want to jobban.
//	is_category (boolean): Is the query a department / role category? e.g. query "Engineering" needs TRUE
//	want_to_ban (boolean): Should we ban or should we unban the job we just supplied.
//
// Output:A list of strings with the names of each role the INPUT covers.
/datum/player_panel/proc/process_banlist(query, is_category, want_to_ban)
	if(!SSjob)
		to_chat(usr, "Jobs subsystem not initialized yet!")
		return

	var/mob/M = targetMob
	var/list/jobs_to_set = list() // All the roles relating to the clicked button

	if (is_category)
		for(var/list/role_category in roleStatus) // For every department / antag category
			if (role_category["category_name"] == query) // If this is the selected category

				for(var/list/role in role_category["category_roles"])
					jobs_to_set += role["name"]
				break

	else
		jobs_to_set += query

	var/list/jobs_to_set_trimmed = list() // The roles from jobs_to_set that aren't already banned / unbanned
	for(var/role in jobs_to_set)

		// If we are in ban mode and this role is unbanned OR if we are in unban mode and this role is banned
		// (We don't want to ban / unban roles that are already banned / unbanned)
		if ((want_to_ban && !jobban_isbanned(M, role)) || (!want_to_ban && jobban_isbanned(M, role)))
			jobs_to_set_trimmed += role

	for(var/role in jobs_to_set_trimmed)

	if (jobs_to_set_trimmed.len) // At least one role to get banned / unbanned
		if (want_to_ban)
			usr.client.holder.Jobban(M, jobs_to_set_trimmed)
		else
			usr.client.holder.UnJobban(M, jobs_to_set_trimmed)

	updateJobbanStatus() // Update TGUI data to reflect new ban statuses

// Updates the jobban status of this client's jobban panel.
/datum/player_panel/proc/updateJobbanStatus()
	var/list/roles = list()
	var/active_role_bans = 0

	for(var/list/role_category in GLOB.jobban_panel_data) // For every department / antag category
		var/list/category_roles = list()
		category_roles["category_name"] = role_category["name"]
		category_roles["category_color"] = role_category["color"]
		category_roles["category_roles"] = list()

		for(var/role in role_category["roles"]) // For every job / antag
			var/list/roles_instance = list()
			roles_instance["name"] = role
			var/reason = jobban_isbanned(targetMob, role)
			if(reason)
				roles_instance["ban_reason"] = reason
				active_role_bans++

			category_roles["category_roles"] += list(roles_instance)

		roles += list(category_roles)

	roleStatus = roles
	antagBanReason = jobban_isbanned(targetMob, ROLE_INTEQ)
	activeRoleBans = active_role_bans
