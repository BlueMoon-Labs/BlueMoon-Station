// Лески в катушках, крючки и наживки.

// ---- Рыболовные лески ----
/obj/item/fishing_line
	name = "fishing line reel"
	desc = "Рыболовная леска. Несмотря на простоту, дополнительная длина заметно облегчает ловлю."
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "reel_blue"
	w_class = WEIGHT_CLASS_SMALL
	var/fishing_line_traits = NONE
	var/line_color = COLOR_GRAY
	var/cast_range = 2

/obj/item/fishing_line/reinforced
	name = "reinforced fishing line reel"
	desc = "Необходима для рыбалки в экстремальных условиях."
	icon_state = "reel_green"
	line_color = "#2aae34"
	resistance_flags = FIRE_PROOF | LAVA_PROOF

/obj/item/fishing_line/cloaked
	name = "cloaked fishing line reel"
	desc = "Ещё незаметнее, чем обычная."
	icon_state = "reel_white"
	fishing_line_traits = FISHING_LINE_CLOAKED
	line_color = "#82cfdd"

/obj/item/fishing_line/bouncy
	name = "flexible fishing line reel"
	desc = "Эта специальная леска гораздо прочнее обычной."
	icon_state = "reel_red"
	fishing_line_traits = FISHING_LINE_BOUNCY
	line_color = "#af221f"
	cast_range = 3

/obj/item/fishing_line/sinew
	name = "fishing sinew"
	desc = "Полностью натуральная леска из растянутых сухожилий."
	icon_state = "reel_sinew"
	fishing_line_traits = FISHING_LINE_STIFF
	line_color = "#d1cca3"
	resistance_flags = FIRE_PROOF | LAVA_PROOF

/obj/item/fishing_line/auto_reel
	name = "fishing line auto-reel"
	desc = "Леска с автоподсечкой: сама подматывает и начинает вываживание при поклёвке."
	icon_state = "reel_auto"
	fishing_line_traits = FISHING_LINE_AUTOREEL
	line_color = "#F88414"

/obj/item/fishing_line/bluespace
	name = "bluespace fishing line"
	icon_state = "reel_bluespace"
	desc = "Леска, способная проходить сквозь ткань реальности."
	fishing_line_traits = FISHING_LINE_PHASE
	line_color = COLOR_BLUE
	cast_range = 6

// ---- Крючки и крюки ----
/obj/item/fishing_hook
	name = "simple fishing hook"
	desc = "Простой рыболовный крючок. Без него ничего не поймать."
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "hook"
	w_class = WEIGHT_CLASS_TINY
	var/fishing_hook_traits = NONE
	var/rod_overlay_icon_state = "hook_overlay"
	var/chasm_detritus_type = /datum/chasm_detritus

/obj/item/fishing_hook/proc/get_hook_bonus_additive(fish_type)
	return FISHING_DEFAULT_HOOK_BONUS_ADDITIVE

/obj/item/fishing_hook/proc/get_hook_bonus_multiplicative(fish_type)
	return FISHING_DEFAULT_HOOK_BONUS_MULTIPLICATIVE

/// Высота спрайта грубо намекает на поверхность или глубину. По ней крючок считает свои бонусы.
/obj/item/fishing_hook/proc/get_fish_sprite_height(fish_type)
	if(ispath(fish_type, /obj/item/fish))
		var/obj/item/fish/fish_path = fish_type
		return initial(fish_path.sprite_height)
	if(isfish(fish_type))
		var/obj/item/fish/fish = fish_type
		return fish.sprite_height
	return 0

/obj/item/fishing_hook/proc/can_be_hooked(atom/target)
	if(isliving(target))
		var/mob/living/mob = target
		return (mob.mob_biotypes & MOB_AQUATIC)
	return isitem(target)

/obj/item/fishing_hook/proc/hook_attached(atom/target, obj/item/fishing_rod/rod)
	return

/obj/item/fishing_hook/proc/reason_we_cant_fish(datum/fish_source/target_fish_source)
	return null

/obj/item/fishing_hook/magnet
	name = "magnetic hook"
	desc = "Не облегчит ловлю рыбы, но поможет найти другие вещи."
	icon_state = "treasure"
	rod_overlay_icon_state = "hook_treasure_overlay"

/obj/item/fishing_hook/magnet/get_hook_bonus_multiplicative(fish_type)
	if(fish_type == FISHING_DUD || ispath(fish_type, /obj/item/fish) || isfish(fish_type))
		return ..()
	return 5

/obj/item/fishing_hook/shiny
	name = "shiny lure hook"
	desc = "Позолоченный крючок, приманивающий рыбу из верхних и средних слоёв воды."
	icon_state = "gold_shiny"
	rod_overlay_icon_state = "hook_shiny_overlay"

/obj/item/fishing_hook/shiny/get_hook_bonus_multiplicative(fish_type)
	if(fish_type == FISHING_DUD)
		return ..()
	if(get_fish_sprite_height(fish_type) <= 4)
		return 2
	return ..()

/obj/item/fishing_hook/weighted
	name = "weighted hook"
	desc = "Тяжёлый крючок для ловли глубоководных тварей."
	icon_state = "weighted"
	fishing_hook_traits = FISHING_HOOK_WEIGHTED
	rod_overlay_icon_state = "hook_weighted_overlay"

/obj/item/fishing_hook/weighted/get_hook_bonus_multiplicative(fish_type)
	if(get_fish_sprite_height(fish_type) >= 6)
		return 2
	return ..()

/obj/item/fishing_hook/rescue
	name = "rescue hook"
	desc = "Неуклюжий крюк для спасения упавших в пропасть."
	icon_state = "rescue"
	rod_overlay_icon_state = "hook_rescue_overlay"
	chasm_detritus_type = /datum/chasm_detritus/restricted/bodies

/obj/item/fishing_hook/rescue/can_be_hooked(atom/target)
	return ..() || isliving(target)

/obj/item/fishing_hook/rescue/reason_we_cant_fish(datum/fish_source/target_fish_source)
	if(istype(target_fish_source, /datum/fish_source/chasm))
		return ..()
	return "The hook on your fishing rod wasn't meant for traditional fishing."

/obj/item/fishing_hook/bone
	name = "bone hook"
	desc = "Простой крючок из заточенной кости. Немного лучше обычного."
	icon_state = "hook_bone"

/obj/item/fishing_hook/bone/get_hook_bonus_multiplicative(fish_type)
	return 1.1

/obj/item/fishing_hook/stabilized
	name = "gyro-stabilized hook"
	desc = "Причудливый крючок, дающий лучший контроль над снастью."
	icon_state = "gyro"
	fishing_hook_traits = FISHING_HOOK_BIDIRECTIONAL
	rod_overlay_icon_state = "hook_gyro_overlay"

/obj/item/fishing_hook/jaws
	name = "jawed hook"
	desc = "Мрачный крючок, похожий на капкан. То, что попадёт в его пасть, не вырвется."
	icon_state = "jaws"
	w_class = WEIGHT_CLASS_NORMAL
	fishing_hook_traits = FISHING_HOOK_NO_ESCAPE|FISHING_HOOK_KILL
	rod_overlay_icon_state = "hook_jaws_overlay"

/obj/item/fishing_hook/jaws/can_be_hooked(atom/target)
	return ..() || isliving(target)

// ---- Наживки и приманки ----
/obj/item/bait
	name = "this is bait"
	desc = "вас подловили."
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	var/bait_quality = TRAIT_BASIC_QUALITY_BAIT
	var/rod_overlay_icon_state
	var/bait_foodtypes = NONE
	var/list/list_reagents

/obj/item/bait/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, bait_quality, INNATE_TRAIT)
	if(istype(src, /obj/item/fishing_lure))
		return
	create_reagents(20, INJECTABLE)
	if(list_reagents)
		reagents.add_reagent_list(list_reagents)

/obj/item/bait/proc/check_bait(obj/item/fish/fish)
	if(HAS_TRAIT(src, TRAIT_OMNI_BAIT))
		return 1.5
	var/multiplier = 1
	var/list/fish_properties = SSfishing.fish_properties[istype(fish) ? fish.type : fish]
	if(!fish_properties)
		return multiplier
	for(var/bait_identifier in fish_properties[FISH_PROPERTIES_FAV_BAIT])
		if(is_matching_bait(src, bait_identifier))
			multiplier *= 2
	for(var/bait_identifier in fish_properties[FISH_PROPERTIES_BAD_BAIT])
		if(is_matching_bait(src, bait_identifier))
			multiplier *= 0.5
	return multiplier

/obj/item/bait/worm
	name = "worm"
	desc = "Извивающийся червяк из банки с наживкой. Вы ведь не собираетесь его есть?"
	icon_state = "worm"
	w_class = WEIGHT_CLASS_TINY
	bait_quality = TRAIT_BASIC_QUALITY_BAIT
	rod_overlay_icon_state = "worm_overlay"
	bait_foodtypes = MEAT|BUGS|GROSS
	list_reagents = list(/datum/reagent/consumable/nutriment/protein = 1)

/obj/item/bait/worm/premium
	name = "extra slimy worm"
	desc = "Этот червяк выглядит очень утончённо."
	bait_quality = TRAIT_GOOD_QUALITY_BAIT

/obj/item/bait/doughball
	name = "doughball"
	desc = "Небольшой кусочек теста. Простая, но эффективная наживка."
	icon_state = "doughball"
	w_class = WEIGHT_CLASS_TINY
	bait_quality = TRAIT_BASIC_QUALITY_BAIT
	rod_overlay_icon_state = "dough_overlay"
	bait_foodtypes = GRAIN
	list_reagents = list(/datum/reagent/consumable/nutriment = 1)

/obj/item/bait/doughball/synthetic
	name = "synthetic doughball"
	icon_state = "doughball_blue"
	rod_overlay_icon_state = "dough_blue_overlay"

/obj/item/bait/doughball/synthetic/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_OMNI_BAIT, INNATE_TRAIT)

/obj/item/bait/doughball/synthetic/super
	name = "super-doughball"
	desc = "Ни травоядная, ни хищная рыба не устоит перед этим."
	bait_quality = TRAIT_GREAT_QUALITY_BAIT

/obj/item/bait/doughball/synthetic/unconsumable/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_BAIT_UNCONSUMABLE, INNATE_TRAIT)

/obj/item/bait/natural
	name = "natural bait"
	desc = "Рыба, кажется, не может этим насытиться!"
	icon_state = "worm"
	bait_quality = TRAIT_GREAT_QUALITY_BAIT
	bait_foodtypes = MEAT|GROSS
	list_reagents = list(/datum/reagent/drug/kronkaine = 2)

// Совместимость с апстримными путями видов рыб.
/obj/item/food/bait
	parent_type = /obj/item/bait
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "worm"

/obj/item/food/bait/worm
	parent_type = /obj/item/bait/worm
	icon_state = "worm"

/obj/item/food/bait/worm/premium
	parent_type = /obj/item/bait/worm/premium

/obj/item/food/bait/doughball
	parent_type = /obj/item/bait/doughball

/obj/item/food/bait/doughball/synthetic
	parent_type = /obj/item/bait/doughball/synthetic

/obj/item/food/bait/doughball/synthetic/super
	parent_type = /obj/item/bait/doughball/synthetic/super

/proc/is_matching_bait(obj/item/bait/bait_item, bait_identifier)
	if(ispath(bait_identifier))
		return istype(bait_item, bait_identifier)
	if(!islist(bait_identifier))
		return FALSE
	switch(bait_identifier[FISH_BAIT_TYPE])
		if(FISH_BAIT_FOODTYPE)
			return bait_item.bait_foodtypes & bait_identifier[FISH_BAIT_VALUE]
		if(FISH_BAIT_REAGENT)
			return bait_item.reagents?.has_reagent(bait_identifier[FISH_BAIT_VALUE], bait_identifier[FISH_BAIT_AMOUNT] || -1)
		if(FISH_BAIT_TYPE)
			return istype(bait_item, bait_identifier[FISH_BAIT_VALUE])
	return FALSE


// ---- Блёсны и искусственные приманки ----
/obj/item/fishing_lure
	name = "fishing lure"
	desc = "Пластиковая рыболовная снасть, на которую рыба клюёт всем телом."
	parent_type = /obj/item/bait
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "minnow"
	w_class = WEIGHT_CLASS_SMALL
	bait_quality = TRAIT_GOOD_QUALITY_BAIT
	bait_foodtypes = MEAT|BUGS
	var/spin_frequency = list(2 SECONDS, 3 SECONDS)

/obj/item/fishing_lure/Initialize(mapload)
	. = ..()
	add_traits(list(TRAIT_FISHING_BAIT, TRAIT_BAIT_ALLOW_FISHING_DUD, TRAIT_OMNI_BAIT, TRAIT_BAIT_UNCONSUMABLE), INNATE_TRAIT)
	RegisterSignal(src, COMSIG_ITEM_FISHING_ROD_SLOTTED, PROC_REF(on_fishing_rod_slotted))
	RegisterSignal(src, COMSIG_ITEM_FISHING_ROD_UNSLOTTED, PROC_REF(on_fishing_rod_unslotted))

/obj/item/fishing_lure/proc/on_fishing_rod_slotted(datum/source, obj/item/fishing_rod/rod, slot)
	SIGNAL_HANDLER
	rod.spin_frequency = spin_frequency

/obj/item/fishing_lure/proc/on_fishing_rod_unslotted(datum/source, obj/item/fishing_rod/rod, slot)
	SIGNAL_HANDLER
	rod.spin_frequency = null

/obj/item/fishing_lure/proc/is_catchable_fish(obj/item/fish/fish, list/fish_properties)
	return TRUE

/obj/item/fishing_lure/check_bait(obj/item/fish/fish)
	var/multiplier = 1
	var/list/fish_properties = SSfishing.fish_properties[istype(fish) ? fish.type : fish]
	var/obj/item/fish/fish_instance = fish
	var/made_instance = FALSE
	if(!istype(fish))
		fish_instance = new fish(null, FALSE)
		made_instance = TRUE
	if(fish_properties && is_catchable_fish(fish_instance, fish_properties))
		multiplier += 4
	if(made_instance)
		qdel(fish_instance)
	return multiplier

/obj/item/fishing_lure/minnow
	name = "artificial minnow"
	desc = "Блесна, которая может привлечь мелкую рыбу."
	icon_state = "minnow"

/obj/item/fishing_lure/plug
	name = "artificial plug lure"
	desc = "Блесна покрупнее, которая может привлечь крупную рыбу."
	icon_state = "plug"

/obj/item/fishing_lure/plug/is_catchable_fish(obj/item/fish/fish)
	return fish.size > FISH_SIZE_SMALL_MAX

/obj/item/fishing_lure/dropping
	name = "plastic dropping"
	desc = "Блесна для всякой склизкой, крысиной, мерзкой и мусорной рыбы."
	icon_state = "dropping"
	spin_frequency = list(1.5 SECONDS, 2.8 SECONDS)

/obj/item/fishing_lure/spoon
	name = "\improper Indy spoon lure"
	desc = "Блестящий кусок металла, имитирующий рыбью чешую."
	icon_state = "spoon"
	spin_frequency = list(1.25 SECONDS, 2.25 SECONDS)

/obj/item/fishing_lure/artificial_fly
	name = "\improper Silkbuzz artificial fly"
	desc = "Блесна, похожая на крупную мохнатую мушку."
	icon_state = "artificial_fly"
	spin_frequency = list(1.1 SECONDS, 2 SECONDS)

/obj/item/fishing_lure/led
	name = "\improper LED fishing lure"
	desc = "Тяжёлая водонепроницаемая LED-палочка в форме рыбы для ночной рыбы."
	icon_state = "led"
	spin_frequency = list(3 SECONDS, 3.8 SECONDS)

/obj/item/fishing_lure/lucky_coin
	name = "\improper Maneki-Coin lure"
	desc = "Позолоченная блесна. Привлекает любителей блестящего."
	icon_state = "lucky_coin"
	spin_frequency = list(1.5 SECONDS, 2.7 SECONDS)

/obj/item/fishing_lure/algae
	name = "plastic algae lure"
	desc = "Мягкий комок искусственных водорослей. Травоядные его обожают."
	icon_state = "algae"
	spin_frequency = list(3 SECONDS, 5 SECONDS)

/obj/item/fishing_lure/grub
	name = "\improper Twister Worm lure"
	desc = "Мягкая пластиковая блесна с телом личинки и извивающимся хвостом."
	icon_state = "grub"
	spin_frequency = list(1 SECONDS, 2.7 SECONDS)

/obj/item/fishing_lure/buzzbait
	name = "\improper Electric-Buzz lure"
	desc = "Металлическая цветная побрякушка на тросах, привлекающая электрическую рыбу."
	icon_state = "buzzbait"
	spin_frequency = list(0.8 SECONDS, 1.7 SECONDS)

/obj/item/fishing_lure/spinnerbait
	name = "spinnerbait lure"
	desc = "Вращающаяся блесна для пресноводных хищников."
	icon_state = "spinnerbait"
	spin_frequency = list(2 SECONDS, 4 SECONDS)

/obj/item/fishing_lure/daisy_chain
	name = "daisy chain lure"
	desc = "Блесна, похожая на стайку мелких рыб."
	icon_state = "daisy_chain"
	spin_frequency = list(2 SECONDS, 4 SECONDS)

// ---- Банки с наживкой ----
/obj/item/bait_can
	name = "can o bait"
	desc = "Их там много, но доставать долго."
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "bait_can"
	base_icon_state = "bait_can"
	w_class = WEIGHT_CLASS_SMALL
	COOLDOWN_DECLARE(bait_removal_cooldown)
	var/obj/item/bait_type = /obj/item/bait
	var/cooldown_time = 5 SECONDS
	var/uses_left = 20

/obj/item/bait_can/attack_self(mob/user)
	. = ..()
	var/fresh_bait = retrieve_bait(user)
	if(fresh_bait)
		user.put_in_hands(fresh_bait)

/obj/item/bait_can/examine(mob/user)
	. = ..()
	. += span_info("It[uses_left ? " has got [uses_left] [bait_type::name] left" : "'s empty"].")

/obj/item/bait_can/update_icon_state()
	icon_state = base_icon_state
	if(uses_left <= initial(uses_left))
		if(!uses_left)
			icon_state = "[icon_state]_empty"
		else
			icon_state = "[icon_state]_open"
	return ..()

/obj/item/bait_can/proc/retrieve_bait(mob/user)
	if(!uses_left)
		user.balloon_alert(user, "пусто")
		return
	if(!COOLDOWN_FINISHED(src, bait_removal_cooldown))
		user.balloon_alert(user, "подождите немного")
		return
	COOLDOWN_START(src, bait_removal_cooldown, cooldown_time)
	update_icon()
	uses_left--
	return new bait_type(src)

/obj/item/bait_can/worm
	name = "can o' worm"
	desc = "В этой банке есть черви."
	bait_type = /obj/item/bait/worm

/obj/item/bait_can/worm/premium
	name = "can o' worm deluxe"
	desc = "В этой банке есть модные черви."
	bait_type = /obj/item/bait/worm/premium

/obj/item/bait_can/super_baits
	name = "can o' super-baits"
	desc = "В этой банке нектар богов."
	bait_type = /obj/item/bait/doughball/synthetic/super
	uses_left = 12
