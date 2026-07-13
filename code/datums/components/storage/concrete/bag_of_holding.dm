/datum/component/storage/concrete/bluespace/bag_of_holding/handle_item_insertion(obj/item/W, prevent_warning = FALSE, mob/living/user)
	var/atom/A = parent
	if(A == W)		//don't put yourself into yourself.
		return
	var/list/obj/item/storage/backpack/holding/matching = typecache_filter_list(W.GetAllContents(), typecacheof(/obj/item/storage/backpack/holding))
	matching -= A
	if(istype(W, /obj/item/storage/backpack/holding) || matching.len)
		var/safety = alert(user, "Это действие будет иметь крайне серьёзные последствия для станции и её экипажа. Убедитесь, что вы знаете, что делаете.", "Засунуть это в [A.name]?", "Не делать это", "Сделать это")
		if(safety != "Сделать это" || QDELETED(A) || QDELETED(W) || QDELETED(user) || !user.canUseTopic(A, BE_CLOSE, iscarbon(user)))
			return

		var/final_safety = alert(user, "ПОСЛЕДНЕЕ ПРЕДУПРЕЖДЕНИЕ!\n\nСоздание сингулярности приведёт к уничтожению станции и гибели всего экипажа.\nВы уверены, что хотите сделать это? ЭТО НЕЛЬЗЯ ОТМЕНИТЬ!", "ФИНАЛЬНОЕ ПОДТВЕРЖДЕНИЕ", "НЕТ, НЕ ДЕЛАТЬ!", "ДА, УНИЧТОЖИТЬ ВСЁ!")

		if(final_safety == "НЕТ, НЕ ДЕЛАТЬ!" || QDELETED(A) || QDELETED(W) || QDELETED(user) || !user.canUseTopic(A, BE_CLOSE, iscarbon(user)))
			to_chat(user, span_notice("Вы вовремя остановились. Катастрофа предотвращена."))
			return

		var/turf/loccheck = get_turf(A)
		if(is_reebe(loccheck.z))
			user.visible_message("<span class='warning'>An unseen force knocks [user] to the ground!</span>", "<span class='big_brass'>\"I think not!\"</span>")
			user.DefaultCombatKnockdown(60)
			return
		if(istype(loccheck.loc, /area/fabric_of_reality))
			to_chat(user, "<span class='danger'>You can't do that here!</span>")
		// BLUEMOO ADD START - в зоне госткафе нельзя устраивать разломы
		if(istype(get_area(loccheck), /area/centcom/holding))
			user.visible_message(span_warning("[user] tried to open a tear in fabric and reality... So will be punished for this."),span_big_warning("You ough to be ashamed for what you have tried to do, little grief slut."))
			if(ishuman(user))
				sleep(2 SECONDS)
				var/mob/living/carbon/human/H = user
				H.DefaultCombatKnockdown(1400)
				H.cum()
			return
		// BLUEMOON ADD END
		to_chat(user, "<span class='danger'>The Bluespace interfaces of the two devices catastrophically malfunction!</span>")
		qdel(W)
		playsound(loccheck,'sound/effects/supermatter.ogg', 200, 1)
		// user.gib(TRUE, TRUE, TRUE)

		// for(var/turf/T in range(1,loccheck))
		// 	if(istype(T, /turf/open/space/transit))
		// 		continue
		// 	for(var/mob/living/M in T)
		// 		if(M.movement_type & FLYING)
		// 			M.visible_message("<span class='danger'>The bluespace collapse crushes the air towards it, pulling [M] towards the ground...</span>")
		// 			M.DefaultCombatKnockdown(5, TRUE, TRUE)		//Overrides stun absorbs.
		// 	T.TerraformTurf(/turf/open/chasm/magic, /turf/open/chasm/magic)

		var/obj/singularity/gravitational/singulo = new /obj/singularity/gravitational (get_turf(A)) // Теперь БОХ в БОХ - это Сингулярность.
		singulo.energy = 300 //should make it a bit bigger~

		for (var/obj/structure/ladder/unbreakable/binary/ladder in GLOB.ladders)
			ladder.ActivateAlmonds()
		message_admins("[ADMIN_LOOKUPFLW(user)] detonated a bag of holding at [ADMIN_VERBOSEJMP(loccheck)].")
		log_game("[key_name(user)] detonated a bag of holding at [loc_name(loccheck)].")
		qdel(A)
		singulo.process()
		return
	. = ..()

/datum/component/storage/concrete/bluespace/bag_of_holding/can_be_inserted(obj/item/I, stop_messages = FALSE, mob/M)
	if(I.GetComponent(/datum/component/storage/concrete/bluespace/bag_of_holding))
		return TRUE
	return ..()
