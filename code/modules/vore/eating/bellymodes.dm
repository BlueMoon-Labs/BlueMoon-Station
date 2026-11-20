// Process the predator's effects upon the contents of its belly (i.e digestion/transformation etc)
/obj/belly/proc/process_belly(var/times_fired,var/wait) //Passed by controller
	// Производство жидкости не зависит от наличия добычи
	if(show_liquids && owner && liquids && world.time >= next_liquid)
		next_liquid = world.time + 6 SECONDS
		if(owner.nutrition >= 50 && liquids.total_volume + liquid_rate <= liquids.maximum_volume)
			var/reagent_path = text2path(liquid_reagent)
			if(reagent_path)
				liquids.add_reagent(reagent_path, liquid_rate)
				owner.adjust_nutrition(-liquid_rate)

	if((times_fired < next_process) || !length(contents))
		recent_sound = FALSE
		return SSBELLIES_IGNORED

	if(!owner)
		qdel(src)
		SSbellies.belly_list -= src
		return SSBELLIES_PROCESSED

	if(loc != owner)
		if(isliving(owner)) //we don't have machine based bellies. (yet :honk:)
			forceMove(owner)
		else
			SSbellies.belly_list -= src
			qdel(src)
			return SSBELLIES_PROCESSED

	next_process = times_fired + (6 SECONDS/wait/(("TURBO MODE" in mode_addons) ? 6 : 1)) //Set up our next process time.
	var/play_sound //Potential sound to play at the end to avoid code duplication.
	var/to_update = FALSE //Did anything update worthy happen?

/////////////////////////// Auto-Emotes ///////////////////////////
	if(emote_active && contents.len && next_emote <= times_fired)
		next_emote = times_fired + round(emote_time/wait,1)
		var/list/EL = emote_lists[digest_mode]
		if(LAZYLEN(EL))
			for(var/mob/living/M in contents)
				if((M.vore_flags & DIGESTABLE) || !(digest_mode == DM_DIGEST)) // don't give digesty messages to indigestible people
					to_chat(M,"<span class='notice'>[pick(EL)]</span>")

///////////////////// Prey Loop Refresh/hack //////////////////////
	for(var/mob/living/M in contents)
		if(M && isbelly(M.loc))
			if(world.time > M.next_preyloop)
				if(is_wet && wet_loop)
					if(!M.client)
						continue
					M.stop_sound_channel(CHANNEL_PREYLOOP) // sanity just in case
					if(M.client.prefs.cit_toggles & DIGESTION_NOISES)
						var/sound/preyloop = sound('sound/vore/prey/loop.ogg')
						M.playsound_local(get_turf(src),preyloop, 80,0, channel = CHANNEL_PREYLOOP)
						M.next_preyloop = (world.time + 52 SECONDS)


/////////////////////////// Exit Early ////////////////////////////
	var/list/touchable_items = contents - items_preserved
	if(!length(touchable_items))
		return SSBELLIES_PROCESSED

//////////////////////// Absorbed Handling ////////////////////////
	for(var/mob/living/M in contents)
		if(M.vore_flags & ABSORBED)
			M.Stun(5)

	// Режим удержания не касается ни одного из четырёх звуков ниже, а SSbellies
	// проходит по каждому животу раз в секунду: на удержании это четыре /sound в
	// секунду на живот, построенных прямо в мусор. Ветка DM_HOLD в switch оставлена
	// как была - она теперь недостижима, но остаётся верной, если этот выход уедет.
	if(digest_mode == DM_HOLD)
		return SSBELLIES_PROCESSED

////////////////////////// Sound vars /////////////////////////////
	var/sound/prey_digest = sound(get_sfx("digest_prey"))
	var/sound/prey_death = sound(get_sfx("death_prey"))
	var/sound/pred_digest = sound(get_sfx("digest_pred"))
	var/sound/pred_death = sound(get_sfx("death_pred"))

	switch(digest_mode)
		if(DM_HOLD)
			return SSBELLIES_PROCESSED

		if(DM_DIGEST)
			if(HAS_TRAIT(owner, TRAIT_PACIFISM)) //obvious.
				digest_mode = DM_NOISY
				return

			for (var/mob/living/M in contents)
				if(prob(25))
					if(M && M.client && M.client.prefs.cit_toggles & DIGESTION_NOISES)
						SEND_SOUND(M,prey_digest)
					play_sound = pick(pred_digest)

				//Pref protection!
				if (!(M.vore_flags & DIGESTABLE) || M.vore_flags & ABSORBED)
					continue

				//Person just died in guts!
				if(M.stat == DEAD)
					var/list/owner_pool = ((M.vore_flags & ABSORBED) && LAZYLEN(absorbed_messages["dmo"])) ? absorbed_messages["dmo"] : digest_messages_owner
					var/list/prey_pool = ((M.vore_flags & ABSORBED) && LAZYLEN(absorbed_messages["dmp"])) ? absorbed_messages["dmp"] : digest_messages_prey
					var/digest_alert_owner = apply_message_vars(pick(owner_pool), M)
					var/digest_alert_prey = apply_message_vars(pick(prey_pool), M)

					//Send messages
					to_chat(owner, "<span class='warning'>[digest_alert_owner]</span>")
					to_chat(M, "<span class='warning'>[digest_alert_prey]</span>")
					M.visible_message("<span class='notice'>Все видят, как [owner] теряет очертания - живот заметно опадает.</span>")

					owner.adjust_nutrition(400 * (nutrition_percent / 100)) // so eating dead mobs gives you *something*.
					play_sound = pick(pred_death)
					if(M && M.client && M.client.prefs.cit_toggles & DIGESTION_NOISES)
						SEND_SOUND(M,prey_death)
					M.stop_sound_channel(CHANNEL_PREYLOOP)
					digestion_death(M)
					owner.update_icons()
					to_update = TRUE
					continue


				// Deal digestion damage (and feed the pred)
				if(!(M.status_flags & GODMODE))
					//BLUEMOON EDIT STARTS
					var/damage_mod = 1
					if(M.maxHealth < 100) //big guy перевариваются дольше
						damage_mod = M.maxHealth * 0.01 //1 процент от максимума хп при хп меньше 100
					M.adjustBruteLoss(digest_brute * damage_mod)
					M.adjustFireLoss(digest_burn * damage_mod)
					if(digest_oxy)
						M.adjustOxyLoss(digest_oxy * damage_mod)
					if(digest_tox)
						M.adjustToxLoss(digest_tox * damage_mod)
					if(digest_clone)
						M.adjustCloneLoss(digest_clone * damage_mod)
					if(temperature_damage && !(M.vore_flags & NO_TEMPERATURE) && (M.vore_flags & DIGESTABLE))
						var/temp_c = belly_temperature - T0C
						if(temp_c > 40)
							M.adjustFireLoss((temp_c - 40) * 0.1 * damage_mod)
						else if(temp_c < 10)
							M.adjustBruteLoss((10 - temp_c) * 0.1 * damage_mod)
					//BLUEMOON EDIT ENDS
					owner.adjust_nutrition(1 * (nutrition_percent / 100))

		if(DM_HEAL)
			for (var/mob/living/M in contents)
				if(prob(25))
					if(M && M.client && M.client.prefs.cit_toggles & DIGESTION_NOISES)
						SEND_SOUND(M,prey_digest)
					play_sound = pick(pred_digest)
				if(M.stat != DEAD && !(M.vore_flags & NO_HEALBELLY))
					if(owner.nutrition >= NUTRITION_LEVEL_STARVING && (M.health < M.maxHealth))
						M.adjustBruteLoss(-3)
						M.adjustFireLoss(-3)
						owner.adjust_nutrition(-5)

	//for when you just want people to squelch around
		if(DM_NOISY)
			if(prob(35))
				for(var/mob/M in contents)
					if(M && M.client && M.client.prefs.cit_toggles & DIGESTION_NOISES)
						SEND_SOUND(M,prey_digest)
					play_sound = pick(pred_digest)


		if(DM_ABSORB)

			for (var/mob/living/M in contents)

				if(prob(10))//Less often than gurgles. People might leave this on forever.
					if(M && M.client && M.client.prefs.cit_toggles & DIGESTION_NOISES)
						SEND_SOUND(M,prey_digest)
					play_sound = pick(pred_digest)

				if(M.vore_flags & ABSORBED || !(M.vore_flags & ABSORBABLE)) //Negative.
					continue

				if(M.nutrition >= 100) //Drain them until there's no nutrients left. Slowly "absorb" them.
					var/oldnutrition = (M.nutrition * 0.05)
					M.set_nutrition(M.nutrition * 0.95)
					owner.adjust_nutrition(oldnutrition * (nutrition_percent / 100))
				else if(M.nutrition < 100) //When they're finally drained.
					if(drain_mode == "Release")
						release_specific_contents(M)
					else
						absorb_living(M)
					to_update = TRUE

		if(DM_UNABSORB)

			for (var/mob/living/M in contents)
				if(M.vore_flags & ABSORBED && owner.nutrition >= 100)
					M.vore_flags &= ~(ABSORBED)
					restore_absorbed_name(M)
					to_chat(M,"<span class='notice'>Ты вдруг снова чувствуешь себя плотным.</span>")
					to_chat(owner,"<span class='notice'>Тебе кажется, что части тебя больше нет.</span>")
					owner.adjust_nutrition(-100)
					to_update = TRUE

	//because dragons need snowflake guts
		if(DM_DRAGON)
			if(HAS_TRAIT(owner, TRAIT_PACIFISM)) //imagine var editing this when you're a pacifist. smh
				digest_mode = DM_NOISY
				return

			for (var/mob/living/M in contents)
				if(prob(55)) //if you're hearing this, you're a vore ho anyway.
					if((world.time + NORMIE_HEARCHECK) > last_hearcheck)
						LAZYCLEARLIST(hearing_mobs)
						for(var/mob/living/H in get_hearers_in_view(3, owner))
							if(!H.client || !(H.client.prefs.cit_toggles & DIGESTION_NOISES))
								continue
							LAZYADD(hearing_mobs, H)
						last_hearcheck = world.time
					for(var/mob/living/H in hearing_mobs)
						if(H && H.client && (isturf(H.loc) || (H.loc != src.contents)))
							SEND_SOUND(H,pred_digest)
						else if(H?.client && (H in contents))
							SEND_SOUND(H,prey_digest)

			//No digestion protection for megafauna.

			//Person just died in guts!
				if(M.stat == DEAD)
					var/list/owner_pool = ((M.vore_flags & ABSORBED) && LAZYLEN(absorbed_messages["dmo"])) ? absorbed_messages["dmo"] : digest_messages_owner
					var/list/prey_pool = ((M.vore_flags & ABSORBED) && LAZYLEN(absorbed_messages["dmp"])) ? absorbed_messages["dmp"] : digest_messages_prey
					var/digest_alert_owner = apply_message_vars(pick(owner_pool), M)
					var/digest_alert_prey = apply_message_vars(pick(prey_pool), M)

					//Send messages
					to_chat(owner, "<span class='warning'>[digest_alert_owner]</span>")
					to_chat(M, "<span class='warning'>[digest_alert_prey]</span>")
					M.visible_message("<span class='notice'>Все слышат, как живот [owner] громко урчит, заканчивая трапезу.</span>")
					play_sound = pick(pred_death)
					if(M && M.client && M.client.prefs.cit_toggles & DIGESTION_NOISES)
						SEND_SOUND(M,prey_death)
					M.spill_organs(FALSE,TRUE,TRUE)
					M.stop_sound_channel(CHANNEL_PREYLOOP)
					digestion_death(M)
					owner.update_icons()
					to_update = TRUE
					continue


				// Deal digestion damage (and feed the pred)
				if(!(M.status_flags & GODMODE))
					M.adjustFireLoss(digest_burn)
					M.adjustToxLoss(2, toxins_type = TOX_OMNI) // something something plasma based acids // BLUEMOON CHANGES - TOX_OMNI для урона системам синтетика
					if(!HAS_TRAIT(M, TRAIT_ROBOTIC_ORGANISM)) // BLUEMOON ADD START - у роботов не должно быть клон-урона
						M.adjustCloneLoss(1) // eventually this'll kill you if you're healing everything else, you nerds.

	// Предметы item_mode == Digest всегда, Follow - как режим нутра, Hold - никогда
	var/items_digest = (item_mode == DM_DIGEST) || (item_mode == "Follow" && digest_mode == DM_DIGEST)
	if(items_digest && length(touchable_items))
		var/obj/item/T = pick(touchable_items)
		if(istype(T) && (istype(T,/obj/item/reagent_containers/food) || istype(T,/obj/item/organ)))
			digest_item(T)

	/////////////////////////// Make any noise ///////////////////////////
	if(play_sound)
		if((world.time + NORMIE_HEARCHECK) > last_hearcheck)
			LAZYCLEARLIST(hearing_mobs)
			for(var/mob/M in hearers(VORE_SOUND_RANGE, owner))
				if(!M.client || !(M.client.prefs.cit_toggles & DIGESTION_NOISES))
					continue
				LAZYADD(hearing_mobs, M)
				last_hearcheck = world.time
			for(var/mob/M in hearing_mobs) //so we don't fill the whole room with the sound effect
				if(M && M.client && (isturf(M.loc) || (M.loc != src.contents))) //to avoid people on the inside getting the outside sounds and their direct sounds + built in sound pref check
					M.playsound_local(owner.loc, play_sound, 75, TRUE)
					//these are all external sound triggers now, so it's ok.
	if(to_update)
		for(var/mob/living/M in contents)
			if(M.client)
				M.updateVRPanel()
		if(owner.client)
			owner.updateVRPanel()

	return SSBELLIES_PROCESSED
