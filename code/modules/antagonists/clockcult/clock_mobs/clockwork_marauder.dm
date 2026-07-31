#define MARAUDER_SLOWDOWN_PERCENTAGE 0.40 //Below this percentage of health, marauders will become slower
#define MARAUDER_SHIELD_REGEN_TIME 200 //In deciseconds, how long it takes for shields to regenerate after breaking
#define MARAUDER_SPACE_FULL_DAMAGE 6		//amount of damage per life tick while inside space
#define MARAUDER_SPACE_NEAR_DAMAGE 4			//amount of damage taking per Life() tick from being next to space.

//Clockwork marauder: A well-rounded frontline construct. Only one can exist for every two human servants.
/mob/living/simple_animal/hostile/clockwork/marauder
	name = "clockwork marauder"
	desc = "Внушительный призрак солдата, озаренный багровым пламенем. Он вооружен гладиусом и щитом."
	icon_state = "clockwork_marauder"
	mob_biotypes = MOB_HUMANOID
	health = 120
	maxHealth = 120
	force_threshold = 8
	speed = 0
	obj_damage = 40
	melee_damage_lower = 12
	melee_damage_upper = 12
	attack_verb_continuous = "режет"
	attack_verb_simple = "резать"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	weather_immunities = list("lava")
	movement_type = FLYING
	a_intent = INTENT_HARM
	loot = list(/obj/item/clockwork/component/geis_capacitor/fallen_armor)
	light_range = 3
	light_power = 1.7
	playstyle_string = "<span class='big bold'><span class='neovgre'>Вы часовой мародёр,</span></span><b> универсальный конструкт Ратвара, предназначенный для ведения боя на передовой. Хотя у вас нет \
	уникальных способностей, вы грозный боец в поединках один на один, а ваш щит защищает от снарядов!<br><br>Подчиняйтесь Слугам и делайте то, что они \
	вам скажут. Твоя главная цель защитить Ковчег от разрушения; они твои союзники в этом деле, и их нужно оберегать от вреда.</b> \
	<span class='danger big'>Однако имей в виду: вблизи космической пустоты ты начнёшь быстро разлагаться.</span>"
	empower_string = "<span class='neovgre'>Сила Бастиона Анимы течёт через тебя! Ваше оружие будет наносить более сильные удары, ваша броня станет прочнее, а щит — более устойчивым.</span>"
	var/default_speed = 0
	var/max_shield_health = 3
	var/shield_health = 3 //Amount of projectiles that can be deflected within
	var/shield_health_regen = 0 //When world.time equals this, shield health will regenerate
	var/true_name = "Meme Master 69" //Required to call forth the guardian
	var/global/list/possible_true_names = list("Слуга", "Страж", "Крепостной", "Паж", "Глашатай", "Плут", "Вассал", "Спутник")
	var/mob/living/host //The mob that the guardian is living inside of
	var/recovering = FALSE //If the guardian is recovering from recalling
	var/blockchance = 17 //chance to block attacks entirely
	var/counterchance = 30 //chance to counterattack after blocking
	var/static/list/damage_heal_order = list(OXY, BURN, BRUTE, TOX) //we heal our host's damage in this order

/mob/living/simple_animal/hostile/clockwork/marauder/examine_info()
	if(!shield_health)
		return "<span class='warning'>Щит уничтожен!</span>"

/mob/living/simple_animal/hostile/clockwork/marauder/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		return
	var/turf/T = get_turf(src)
	var/turf/open/space/S = isspaceturf(T)? T : null
	var/less_space_damage
	if(!istype(S))
		var/turf/open/space/nearS = locate() in oview(1)
		if(nearS)
			S = nearS
			less_space_damage = TRUE
	if(S)
		to_chat(src, "<span class='userdanger'>Космическая пустота высасывает из тебя Свет Ратвара! Ты чувствуешь, как быстро теряешь силы. Лучше бы тебе вернуться внутрь!</span>")
		adjustBruteLoss(less_space_damage? MARAUDER_SPACE_NEAR_DAMAGE : MARAUDER_SPACE_FULL_DAMAGE)
	if(!GLOB.ratvar_awakens && health / maxHealth <= MARAUDER_SLOWDOWN_PERCENTAGE)
		speed = default_speed + 1 //Yes, this slows them down
	else
		speed = default_speed
	if(shield_health < max_shield_health && world.time >= shield_health_regen)
		shield_health_regen = world.time + MARAUDER_SHIELD_REGEN_TIME
		to_chat(src, "<span class='neovgre'>Ваш щит восстановился, <b>[shield_health]</b> блоков осталось!</span>")
		playsound_local(src, "shatter", 75, TRUE, frequency = -1)
		shield_health++

/mob/living/simple_animal/hostile/clockwork/marauder/update_values()
	if(GLOB.ratvar_awakens) //Massive attack damage bonuses and health increase, because Ratvar
		health = 300
		maxHealth = 300
		melee_damage_upper = 25
		melee_damage_lower = 25
		attack_verb_continuous = "опустошает"
		attack_verb_simple = "опустошить"
		speed = -1
		obj_damage = 100
		max_shield_health = INFINITY
	else if(GLOB.ratvar_approaches) //Hefty health bonus and slight attack damage increase
		melee_damage_upper = 15
		melee_damage_lower = 15
		attack_verb_continuous = "вырезает"
		attack_verb_simple = "вырезать"
		obj_damage = 50
		max_shield_health = 4

/mob/living/simple_animal/hostile/clockwork/marauder/death(gibbed)
	visible_message("<span class='danger'>Снаряжение [src] безжизненно с грохотом падает на землю, а красные языки пламени внутри него гаснут.</span>", \
	"<span class='userdanger'>Помятая и поцарапанная, твоя броня спадает, и без её защиты твоя хрупкая фигура распадается на части.</span>")
	. = ..()

/mob/living/simple_animal/hostile/clockwork/marauder/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return TRUE

/mob/living/simple_animal/hostile/clockwork/marauder/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(amount > 0)
		for(var/mob/living/L in view(2, src))
			if(L.is_holding_item_of_type(/obj/item/nullrod))
				to_chat(src, "<span class='userdanger'>Наличие священного артефакта, который держат на виду, ослабляет вашу броню!</span>")
				amount *= 4 //if a wielded null rod is nearby, it takes four times the health damage
				break
	. = ..()

/mob/living/simple_animal/hostile/clockwork/marauder/bullet_act(obj/item/projectile/P)
	if(deflect_projectile(P))
		return BULLET_ACT_BLOCK
	return ..()

/mob/living/simple_animal/hostile/clockwork/marauder/proc/deflect_projectile(obj/item/projectile/P)
	if(!shield_health)
		return
	var/energy_projectile = istype(P, /obj/item/projectile/energy) || istype(P, /obj/item/projectile/beam)
	visible_message("<span class='danger'>[src] отражает [P] с [ru_ego()] помощью щита!</span>", \
	"<span class='danger'>Вы блокируете [P] своим щитом! <i>Оставшиеся блоки:</i> <b>[shield_health - 1]</b></span>")
	if(energy_projectile)
		playsound(src, 'sound/weapons/effects/searwall.ogg', 50, TRUE)
	else
		playsound(src, "ricochet", 50, TRUE)
	shield_health--
	if(!shield_health)
		visible_message("<span class='warning'>Щит [src] ломается от отражения атаки!</span>", "<span class='boldwarning'>Твой щит сломался! Подожди немного, пока он восстановится...</span>")
		playsound(src, "shatter", 100, TRUE)
	shield_health_regen = world.time + MARAUDER_SHIELD_REGEN_TIME
	return TRUE

#undef MARAUDER_SLOWDOWN_PERCENTAGE
#undef MARAUDER_SHIELD_REGEN_TIME
