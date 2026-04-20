

// TRAIT_DEATHCOMA -  Activate this when you're in your coffin to simulate sleep/death.


// Coffins...
//	-heal all wounds, and quickly.
//	-restore limbs & organs
//

// Without Coffins...
//	-
//	-limbs stay lost



// To put to sleep:  use 		owner.current.fakedeath("bloodsucker") but change name to "bloodsucker_coffin" so you continue to stay fakedeath despite healing in the main thread!


/datum/antagonist/bloodsucker/proc/ClaimCoffin(obj/structure/closet/crate/claimed) // NOTE: This can be any "closet" that you are resting AND inside of.
	// ALREADY CLAIMED
	if(claimed.resident)
		if(claimed.resident == owner.current)
			to_chat(owner, "Это ваш [src].")
		else
			to_chat(owner, "[src] уже занят кем-то другим.")
		return FALSE
	// Bloodsucker Learns new Recipes!
	owner.teach_crafting_recipe(/datum/crafting_recipe/bloodsucker/vassalrack)
	owner.teach_crafting_recipe(/datum/crafting_recipe/bloodsucker/candelabrum)
	// This is my Lair
	coffin = claimed
	lair = get_area(claimed)
	// DONE
	to_chat(owner, "<span class='userdanger'>Вы заняли [claimed] как место для вашего бессмертного отдыха! Ваше логово теперь [lair].</span>")
	to_chat(owner, "<span class='danger'>Вы выучили новые рецепты построек, чтобы улучшить своё логово.</span>")
	to_chat(owner, "<span class='announce'>Совет вампира: Найдите новые рецепты для логова во вкладке \"Misc\" в <i>Crafting Menu</i> снизу вашего экрана, включая <i>Persuasion Rack</i> для превращения экипажа в Вассалов.</span><br><br>")
	RunLair() // Start
	return TRUE

// crate.dm
/obj/structure/closet/crate
	var/mob/living/resident	// This lets bloodsuckers claim any "closet" as a Coffin, so long as they could get into it and close it. This locks it in place, too.

/obj/structure/closet/crate/coffin/blackcoffin
	name = "black coffin"
	desc = "Для тех ушедших, кто не так дорог."
	icon_state = "coffin"
	icon = 'icons/obj/vamp_obj.dmi'
	open_sound = 'sound/bloodsucker/coffin_open.ogg'
	close_sound = 'sound/bloodsucker/coffin_close.ogg'
	breakout_time = 600
	pryLidTimer = 400
	resistance_flags = NONE
	max_integrity = 100
	integrity_failure = 0.5
	armor = list(MELEE = 20, BULLET = 10, LASER = 15, ENERGY = 0, BOMB = 35, BIO = 0, RAD = 0, FIRE = 50, ACID = 60)

/obj/structure/closet/crate/coffin/meatcoffin
	name = "meat coffin"
	desc = "Когда вы будете готовы к приготовлению мяса, стейки никогда не получатся слишком жирными."
	icon_state = "meatcoffin"
	icon = 'icons/obj/vamp_obj.dmi'
	open_sound = 'sound/effects/footstep/slime1.ogg'
	close_sound = 'sound/effects/footstep/slime1.ogg'
	breakout_time = 200
	pryLidTimer = 200
	resistance_flags = NONE
	material_drop = /obj/item/reagent_containers/food/snacks/meat/slab
	material_drop_amount = 3
	integrity_failure = 0.57
	armor = list(MELEE = 40, BULLET = 5, LASER = 5, ENERGY = 0, BOMB = 50, BIO = 0, RAD = 0, FIRE = 50, ACID = 100)

/obj/structure/closet/crate/coffin/metalcoffin
	name = "metal coffin"
	desc = "Большая металлическая банка из-под сардин внутри другой большой металлической банки из-под сардин в космосе."
	icon_state = "metalcoffin"
	icon = 'icons/obj/vamp_obj.dmi'
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	open_sound = 'sound/effects/pressureplate.ogg'
	close_sound = 'sound/effects/pressureplate.ogg'
	breakout_time = 300
	pryLidTimer = 200
	material_drop = /obj/item/stack/sheet/metal
	material_drop_amount = 5
	max_integrity = 200
	integrity_failure = 0.25
	armor = list(MELEE = 25, BULLET = 10, LASER = 25, ENERGY = 0, BOMB = 10, BIO = 0, RAD = 0, FIRE = 50, ACID = 60)

//////////////////////////////////////////////

/obj/structure/closet/crate/proc/ClaimCoffin(mob/living/claimant) // NOTE: This can be any "closet" that you are resting AND inside of.
	// Bloodsucker Claim
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = claimant.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
	if(bloodsuckerdatum)
		// Vamp Successfuly Claims Me?
		if(bloodsuckerdatum.ClaimCoffin(src))
			resident = claimant
			anchored = 1					// No moving this

/obj/structure/closet/crate/coffin/Destroy()
	UnclaimCoffin()
	return ..()

/obj/structure/closet/crate/proc/UnclaimCoffin()
	if (resident)
		// Vamp Un-Claim
		if (resident.mind)
			var/datum/antagonist/bloodsucker/bloodsuckerdatum = resident.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
			if (bloodsuckerdatum && bloodsuckerdatum.coffin == src)
				bloodsuckerdatum.coffin = null
				bloodsuckerdatum.lair = null
			to_chat(resident, "<span class='danger'><span class='italics'>Вы чувствуете, что связь с вашим гробом, вашим священным местом отдыха, оборвалась! Вам нужно будет поискать другой.</span></span>")
		resident = null // Remove resident. Because this object isnt removed from the game immediately (GC?) we need to give them a way to see they don't have a home anymore.

/obj/structure/closet/crate/coffin/can_open(mob/living/user)
	// You cannot lock in/out a coffin's owner. SORRY.
	if (locked)
		if(user == resident)
			if (welded)
				welded = FALSE
				update_icon()
			//to_chat(user, "<span class='notice'>You flip a secret latch and unlock [src].</span>") // Don't bother. We know it's unlocked.
			locked = FALSE
			return TRUE
		else
			playsound(get_turf(src), 'sound/machines/door_locked.ogg', 20, 1)
			to_chat(user, "<span class='notice'>[src] плотно заперт изнутри.</span>")
	return ..()

/obj/structure/closet/crate/coffin/close(mob/living/user)
	var/turf/Turf = get_turf(src)
	var/area/A = get_area(src)
	if (!..())
		return FALSE
	// Only the User can put themself into Torpor (if you're already in it, you'll start to heal)
	if((user in src))
		// Bloodsucker Only
		var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
		if(bloodsuckerdatum)
			LockMe(user)
			Turf = get_turf(user) //we may have moved. adjust as needed...
			A = get_area(src)
			// Claim?
			if(!bloodsuckerdatum.coffin && !resident && (is_station_level(Turf.z) || !A.map_name == "Space"))
				switch(alert(user,"Вы хотите занять данный гроб? [get_area(src)] станет вашим логовом.","Занять логово","Да", "Нет"))
					if("Да")
						ClaimCoffin(user)
			if (user.AmStaked()) // Stake? No Heal!
				to_chat(bloodsuckerdatum.owner.current, "<span class='userdanger'>Вы проткнуты колом! Уберите это опасное оружие от своего сердца перед сном.</span>")
				return
			// Heal
			if(bloodsuckerdatum.HandleHealing(0)) // Healing Mult 0 <--- We only want to check if healing is valid!
				to_chat(bloodsuckerdatum.owner.current, "<span class='notice'>Вы погружаетесь в ужасный сон бессмертного Торпора. Вы будете лечится, пока не восстановитесь.</span>")
				bloodsuckerdatum.Torpor_Begin()
			// Level Up?
			bloodsuckerdatum.SpendRank() // Auto-Fails if not appropriate
	return TRUE

/obj/structure/closet/crate/coffin/attackby(obj/item/W, mob/user, params)
	// You cannot weld or deconstruct an owned coffin. STILL NOT SORRY.
	if (resident != null && user != resident) // Owner can destroy their own coffin.
		if(opened)
			if(istype(W, cutting_tool))
				to_chat(user, "<span class='notice'>Это гораздо более сложная механическая конструкция, чем вы думали. Вы не знаете, где начать резать [src].</span>")
				return
		else if(anchored && W.tool_behaviour == TOOL_WRENCH) // Can't unanchor unless owner.
			to_chat(user, "<span class='danger'>Гроб не получается оторвать от пола.</span>")
			return

	if(locked && W.tool_behaviour == TOOL_CROWBAR)
		var/pry_time = pryLidTimer * W.toolspeed // Pry speed must be affected by the speed of the tool.
		user.visible_message("<span class='notice'>[user] пытается снять крышку с [src] с помощью [W].</span>", \
							  "<span class='notice'>Вы начинаете снимать крышку с [src] с помощью [W]. Это займёт примерно [DisplayTimeText(pry_time)].</span>")
		if (!do_mob(user,src,pry_time))
			return
		bust_open()
		user.visible_message("<span class='notice'>[user] резко открывает крышку [src] .</span>", \
							  "<span class='notice'>Крышка [src] резко открывается.</span>")
		return
	..()



/obj/structure/closet/crate/coffin/AltClick(mob/user)
	// Distance Check (Inside Of)
	if (user in src) // user.Adjacent(src)
		LockMe(user, !locked)

/obj/structure/closet/crate/proc/LockMe(mob/user, inLocked = TRUE)
		// Lock
	if (user == resident)
		if (!broken)
			locked = inLocked
			to_chat(user, "<span class='notice'>Вы поворачиваете секретную защелку и [locked?"":"раз"]блокируете себя внутри [src].</span>")
		else
			to_chat(resident, "<span class='notice'>Секретная защелка, чтобы заблокировать [src] изнутри сломалась. Вы возвращаете её на место...</span>")
			if (do_mob(resident, src, 50))//sleep(10)
				if (broken) // Spam Safety
					to_chat(resident, "<span class='notice'>Вы чините механизм и блокируете его.</span>")
					broken = FALSE
					locked = TRUE
