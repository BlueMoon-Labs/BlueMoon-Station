//A speedy, annoying and scaredy demon
/mob/living/simple_animal/hostile/asteroid/imp
	name = "lava imp"
	desc = "Lowest on the hierarchy of slaughter demons, this one is still nothing to sneer at."
	icon = 'modular_sand/icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "imp"
	icon_living = "imp"
	icon_aggro = "imp"
	icon_dead = "imp_dead"
	icon_gib = "syndicate_gib"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	move_to_delay = 4
	projectiletype = /obj/item/projectile/magic/impfireball
	projectilesound = 'modular_sand/sound/misc/impranged.wav'
	ranged = 1
	ranged_message = "shoots a fireball"
	ranged_cooldown_time = 70
	throw_message = "does nothing against the hardened skin of"
	vision_range = 5
	speed = 1
	maxHealth = 150
	health = 150
	harm_intent_damage = 15
	obj_damage = 60
	melee_damage_lower = 15
	melee_damage_upper = 15
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	a_intent = INTENT_HARM
	speak_emote = list("groans")
	attack_sound = 'modular_sand/sound/misc/impattacks.wav'
	aggro_vision_range = 15
	retreat_distance = 5
	gold_core_spawnable = HOSTILE_SPAWN
	crusher_loot = /obj/item/crusher_trophy/blaster_tubes/impskull
	loot = list()
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 2, /obj/item/stack/sheet/bone = 4, /obj/item/stack/sheet/leather = 2, /obj/item/stack/ore/plasma = 2)
	robust_searching = FALSE
	death_sound = 'modular_sand/sound/misc/impdies.wav'

/mob/living/simple_animal/hostile/asteroid/imp/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/glory_kill, \
		messages_unarmed = list("хватает импа за череп и вырывает его глаза, отбрасывая бездыханное тело в сторону!", "хватает импа за голову и сдавливает её голыми руками, словно скорлупу ореха!", "отрывает голову от тела импа голыми руками!"), \
		messages_pka = list("вонзает свой протокинетический ускоритель в рот импа и выстреливает из него, осыпая всё вокруг ошмётками его плоти!", "вдавливает голову импа в его корпус при помощи протокинетического ускорителя!", "отстреливает обе ноги импа, оставляя его умирать от обильной кровопотери!"), \
		messages_pka_bayonet = list("отсекает голову с плеч импа при помощи своего протокинетического ускорителя!", "многократно протыкает корпус импа, позволяя его органам вывалиться наружу!"), \
		messages_crusher = list("рассекает тело импа горизонтально на две части при помощи своего крашера!", "отсекает обе ноги импа своим крашером и пинает его в лицо, взрывая последующим выстрелом!", "хладнокровно отсекает обе руки импа при помощи своего крашера и пинком усаживает бездыханное тело на колени перед собой!"), \
		health_given = 7.5, \
		threshold = (maxHealth/10 * 1.5), \
		crusher_drop_mod = 2)

/mob/living/simple_animal/hostile/asteroid/imp/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	playsound(src, 'modular_sand/sound/misc/impinjured.wav', rand(25,100), -1) //HURT ME PLENTY

/mob/living/simple_animal/hostile/asteroid/imp/bullet_act(obj/item/projectile/P)
	. = ..()
	playsound(src, 'modular_sand/sound/misc/impinjured.wav', rand(25,100), -1)

/mob/living/simple_animal/hostile/asteroid/imp/Aggro()
	. = ..()
	playsound(src, pick('modular_sand/sound/misc/impsight.wav', 'modular_sand/sound/misc/impsight2.wav'), rand(50,75), -1)

/mob/living/simple_animal/hostile/asteroid/imp/LoseAggro()
	. = ..()
	playsound(src, pick('modular_sand/sound/misc/impnearby.wav', 'modular_sand/sound/misc/impnearby.wav'), rand(25, 60), -1)

/obj/item/projectile/magic/impfireball //bobyot y u no use child of fireball
	name = "demonic fireball" //because it fucking explodes and deals brute damage even when values are set to -1
	icon_state = "fireball"
	damage = 10
	damage_type = BURN
	nodamage = 0
	armour_penetration = 20
	var/firestacks = 5

/obj/item/projectile/magic/impfireball/on_hit(target)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		C.adjust_fire_stacks(firestacks)
		C.IgniteMob()
		if(C.stat != DEAD && C.stat != UNCONSCIOUS)
			playsound(C, 'modular_sand/sound/misc/doominjured.wav', 100, -1)
		else if(C.stat == DEAD)
			playsound(C, 'modular_sand/sound/misc/doomdies.wav', 100, -1)
		else
			playsound(C, pick('modular_sand/sound/misc/doomscream.wav', 'modular_sand/sound/misc/doomdies.wav'), 100, -1)
