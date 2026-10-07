/mob/living/simple_animal/hostile/headcrab
	name = "Headcrab"
	desc = "A small parasitic creature that would like to connect with your brain stem."
	icon = 'icons/mob/headcrab.dmi'
	icon_state = "headcrab"
	icon_living = "headcrab"
	icon_dead = "headcrab_dead"
	health = 60
	maxHealth = 60
	melee_damage_lower = 10
	melee_damage_upper = 15
	ranged = 1
	ranged_message = "leaps"
	ranged_cooldown_time = 40
	var/jumpdistance = 4
	var/jumpspeed = 1
	attack_verb_continuous = "грызёт"
	attack_verb_simple = "грызёт"
	attack_sound = 'sound/creatures/headcrab_attack.ogg'
	speak_emote = list("hisses")
	var/is_zombie = 0
	robust_searching = 1
	// софткрит (UNCONSCIOUS) остаётся валидной целью: краб догоняет и прыгает на
	// лежащую жертву, после чего BiologicalLife захватывает её без проверки статуса.
	stat_attack = UNCONSCIOUS
	/// Шанс (0-100) того, что краб отцепится от павшего зомби живым и удерёт
	var/detach_chance = 25
	/// Труп носителя, с которого краб только что сорвался: обратно не перепрыгиваем
	var/mob/living/carbon/human/ex_host
	var/host_species = ""
	var/list/human_overlays = list()

/mob/living/simple_animal/hostile/headcrab/BiologicalLife(seconds, times_fired)
	if(..() && !stat)
		if(!is_zombie && isturf(src.loc))
			for(var/mob/living/carbon/human/H in oview(src, 1)) //Only for corpse right next to/on same tile
				if(H == ex_host) // со свежесорвавшегося трупа не захватываемся повторно
					continue
				if(!H.get_item_by_slot(ITEM_SLOT_HEAD) && prob(50) || H.IsUnconscious())
					visible_message("<span class='danger'>[src] запрыгивает на голову [H], вгрызясь своими лапками в затылок жертвы!</span>", "<span class='danger'>[src] запрыгивает на голову [H], вгрызясь своими лапками в затылок жертвы!</span>")
					H.death(FALSE)
					Zombify(H)
					break
		var/feeding_phase = client ? times_fired : times_fired + life_periodic_phase
		if(feeding_phase % 4 == 0)
			for(var/mob/living/simple_animal/K in oview(src, 1)) //Only for corpse right next to/on same tile
				if(K.stat == DEAD)
					visible_message("<span class='danger'>[src] пожирает [K]!</span>")
					if(health < maxHealth)
						health += 10
					qdel(K)
					break

/mob/living/simple_animal/hostile/headcrab/OpenFire(atom/A)
	if(check_friendly_fire)
		for(var/turf/T in getline(src,A)) // Not 100% reliable but this is faster than simulating actual trajectory
			for(var/mob/living/L in T)
				if(L == src || L == A)
					continue
				if(faction_check_mob(L) && !attack_same)
					return
	visible_message("<span class='danger'><b>[src]</b> [ranged_message] at [A]!</span>")
	throw_at(A, jumpdistance, jumpspeed, spin = FALSE, diagonals_first = TRUE)
	ranged_cooldown = world.time + ranged_cooldown_time

/mob/living/simple_animal/hostile/headcrab/proc/Zombify(mob/living/carbon/human/H)
	is_zombie = TRUE
	ex_host = H
	if(H.wear_suit)
		var/obj/item/clothing/suit/armor/A = H.wear_suit
		if(A.armor && A.armor.getRating("melee"))
			maxHealth += A.armor.getRating("melee") //That zombie's got armor, I want armor!
	maxHealth += 200
	health = maxHealth
	name = "zombie"
	desc = "A corpse animated by the alien being on its head."
	melee_damage_lower += 10
	melee_damage_upper += 15
	AddComponent(/datum/component/lifesteal, 10) // зомби восстанавливает ОЗ за каждый укус
	ranged = 0
	stat_attack = CONSCIOUS // Disables their targeting of dead mobs once they're already a zombie
	icon = H.icon
	speak = list('sound/creatures/zombie_idle1.ogg','sound/creatures/zombie_idle2.ogg','sound/creatures/zombie_idle3.ogg')
	speak_chance = 50
	speak_emote = list("groans")
	attack_verb_continuous = "грызёт"
	attack_verb_simple = "грызёт"
	attack_sound = 'sound/creatures/zombie_attack.ogg'
	icon_state = "zombie2_s"
	H.hair_style = null
	H.update_hair()
	host_species = H.dna.species.name
	human_overlays = H.overlays
	update_icons()
	H.forceMove(src)
	visible_message("<span class='warning'>[H.name] восстаёт из мёртвых!</span>")

/mob/living/simple_animal/hostile/headcrab/death(gibbed)
	..(gibbed)
	if(is_zombie)
		// С шансом detach_chance краб срывается с павшего зомби живым и удирает
		// искать нового носителя, а не погибает вместе с ним (на труп вывалится
		// тело бывшего хозяина - см. Destroy ниже).
		if(!gibbed && prob(detach_chance) && isturf(loc))
			var/mob/living/carbon/human/previous_host = locate(/mob/living/carbon/human) in contents
			var/mob/living/simple_animal/hostile/headcrab/hatchling = new(loc)
			hatchling.ex_host = previous_host
			visible_message("<span class='danger'>[src] выпрыгивает из павшего тела, отряхивается и шустро удирает искать новую жертву!</span>")
		qdel(src)

/mob/living/simple_animal/hostile/headcrab/handle_automated_speech() // This way they have different screams when attacking, sometimes. Might be seen as sphagetthi code though.
	if(speak_chance)
		if(rand(0,200) < speak_chance)
			if(speak && speak.len)
				playsound(get_turf(src), pick(speak), 200, 1)

/mob/living/simple_animal/hostile/headcrab/Destroy()
	if(contents)
		for(var/mob/M in contents)
			//именно forceMove: голое присваивание loc не зовёт Exited/Moved,
			//и наш же force_remove_from_grid ниже по ..() снёс бы жертву из
			//ячеек спатиал-грида (слух/радио) до пересечения границы 17х17
			M.forceMove(get_turf(src))
	return ..()

/mob/living/simple_animal/hostile/headcrab/update_icons()
	. = ..()
	if(is_zombie)
		overlays.Cut()
		overlays = human_overlays
		var/image/I = image('icons/mob/headcrab.dmi', icon_state = "headcrabpod")
		if(host_species == "Vox")
			I = image('icons/mob/headcrab.dmi', icon_state = "headcrabpod_vox")
		else if(host_species == "Gray")
			I = image('icons/mob/headcrab.dmi', icon_state = "headcrabpod_gray")
		overlays += I

/mob/living/simple_animal/hostile/headcrab/CanAttack(atom/the_target)
	if(stat_attack == DEAD && isliving(the_target) && !ishuman(the_target))
		var/mob/living/L = the_target
		if(L.stat == DEAD)
			// Override default behavior of stat_attack, to stop headcrabs targeting dead mobs they cannot infect, such as silicons.
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/headcrab/fast
	name = "Fast Headcrab"
	desc = "A fast parasitic creature that would like to connect with your brain stem."
	icon = 'icons/mob/headcrab.dmi'
	icon_state = "fast_headcrab"
	icon_living = "fast_headcrab"
	icon_dead = "fast_headcrab_dead"
	health = 40
	maxHealth = 40
	ranged_cooldown_time = 30
	jumpdistance = 8
	jumpspeed = 2
	speak_emote = list("screech")

/mob/living/simple_animal/hostile/headcrab/fast/update_icons()
	. = ..()
	if(is_zombie)
		overlays.Cut()
		overlays = human_overlays
		var/image/I = image('icons/mob/headcrab.dmi', icon_state = "fast_headcrabpod")
		if(host_species == "Vox")
			I = image('icons/mob/headcrab.dmi', icon_state = "fast_headcrabpod_vox")
		else if(host_species == "Gray")
			I = image('icons/mob/headcrab.dmi', icon_state = "fast_headcrabpod_gray")
		overlays += I

/mob/living/simple_animal/hostile/headcrab/fast/Zombify(mob/living/carbon/human/H)
	. = ..()
	speak = list('sound/creatures/fast_zombie_idle1.ogg','sound/creatures/fast_zombie_idle2.ogg','sound/creatures/fast_zombie_idle3.ogg')

/mob/living/simple_animal/hostile/headcrab/poison
	name = "Poison Headcrab"
	desc = "A poison parasitic creature that would like to connect with your brain stem."
	icon = 'icons/mob/headcrab.dmi'
	icon_state = "poison_headcrab"
	icon_living = "poison_headcrab"
	icon_dead = "poison_headcrab_dead"
	health = 80
	maxHealth = 80
	ranged_cooldown_time = 50
	jumpdistance = 3
	jumpspeed = 1
	melee_damage_lower = 10
	melee_damage_upper = 20
	attack_sound = 'sound/creatures/ph_scream1.ogg'
	speak_emote = list("screech")

/mob/living/simple_animal/hostile/headcrab/poison/update_icons()
	. = ..()
	if(is_zombie)
		overlays.Cut()
		overlays = human_overlays
		var/image/I = image('icons/mob/headcrab.dmi', icon_state = "poison_headcrabpod")
		if(host_species == "Vox")
			I = image('icons/mob/headcrab.dmi', icon_state = "poison_headcrabpod_vox")
		else if(host_species == "Gray")
			I = image('icons/mob/headcrab.dmi', icon_state = "poison_headcrabpod_gray")
		overlays += I


/mob/living/simple_animal/hostile/headcrab/poison/AttackingTarget()
	. = ..()
	if(iscarbon(target) && target.reagents)
		var/inject_target = pick("chest", "head")
		var/mob/living/carbon/C = target
		if(C.IsStun() || C.can_inject(null, FALSE, inject_target, FALSE))
			if(C.eye_blurry < 120 SECONDS)
				C.eye_blurry = 20 SECONDS
				visible_message("<span class='danger'>[src] buries its fangs deep into the [inject_target] of [target]!</span>")
