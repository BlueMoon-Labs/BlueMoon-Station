/* Одна Жизнь - квирк и мутация.
 * Персонаж умирает окончательно: тело рассыпается в выбранную в настройках
 * квирков форму, а с него выпадает вообще всё снаряжение. */

GLOBAL_LIST_INIT(onelife_death_forms, init_onelife_death_forms())

/proc/init_onelife_death_forms()
	var/list/forms = list()
	for(var/type in typesof(/datum/onelife_death))
		var/datum/onelife_death/form = type
		forms[initial(form.name)] = type
	return forms

/// База форм рассыпания.
/datum/onelife_death
	var/name = "Пепел"
	/// Звук, проигрываемый при рассыпании.
	var/death_sound = 'sound/magic/Disintegrate.ogg'
	/// Сообщение окружению. %TARGET% заменяется на персонажа.
	var/message = "%TARGET% рассыпается в горсть пепла!"
	/// Оставить ли после себя кучку пепла (как при обычном dust).
	var/leave_ash = TRUE

/datum/onelife_death/proc/crumble(mob/living/carbon/human/H)
	if(death_sound)
		playsound(get_turf(H), death_sound, 80, TRUE)
	H.visible_message(span_danger(replacetext_char(message, "%TARGET%", "[H]")))
	if(leave_ash)
		new /obj/effect/decal/cleanable/ash(get_turf(H))

// Обычные останки - как если бы тело просто рассыпалось без пепла
/datum/onelife_death/remains
	name = "Останки"
	death_sound = 'sound/effects/wounds/crackandbleed.ogg'
	message = "%TARGET% рассыпается в кучку обескровленных останков!"
	leave_ash = FALSE

/datum/onelife_death/remains/crumble(mob/living/carbon/human/H)
	. = ..()
	new /obj/effect/decal/remains/human(get_turf(H))

// Череп и кости
/datum/onelife_death/bones
	name = "Череп и кости"
	death_sound = 'modular_citadel/sound/voice/scream_skeleton.ogg'
	message = "От %TARGET% остаётся лишь хрустящая груда костей!"
	leave_ash = FALSE

/datum/onelife_death/bones/crumble(mob/living/carbon/human/H)
	. = ..()
	new /obj/item/stack/sheet/bone(get_turf(H), rand(2, 4))

// Куча стекла (по мотивам стеклянного голема)
/datum/onelife_death/glass
	name = "Куча стекла"
	death_sound = 'sound/effects/Glassbr2.ogg'
	message = "%TARGET% разлетается на осколки!"
	leave_ash = FALSE

/datum/onelife_death/glass/crumble(mob/living/carbon/human/H)
	. = ..()
	for(var/i in 1 to rand(3, 5))
		new /obj/item/shard(get_turf(H))

// Куча арматуры
/datum/onelife_death/rods
	name = "Куча арматуры"
	death_sound = 'sound/weapons/smash.ogg'
	message = "%TARGET% с грохотом рассыпается в кучу арматуры!"
	leave_ash = FALSE

/datum/onelife_death/rods/crumble(mob/living/carbon/human/H)
	. = ..()
	new /obj/item/stack/rods(get_turf(H), rand(5, 10))

// Лужа воды (логика поломки reagent_dispensers - chem_splash)
/datum/onelife_death/water
	name = "Лужа воды"
	death_sound = 'sound/effects/splash.ogg'
	message = "%TARGET% растекается лужей воды!"

/datum/onelife_death/water/crumble(mob/living/carbon/human/H)
	. = ..()
	var/datum/reagents/R = new /datum/reagents(300)
	R.add_reagent(/datum/reagent/water, rand(200, 300))
	chem_splash(get_turf(H), 1, list(R))

// Лужа крови
/datum/onelife_death/blood
	name = "Лужа крови"
	death_sound = 'sound/effects/splash.ogg'
	message = "%TARGET% растекается большой лужей крови!"

/datum/onelife_death/blood/crumble(mob/living/carbon/human/H)
	. = ..()
	H.add_splatter_floor(get_turf(H))
	if(H.has_dna() && H.blood_volume > 0 && H.get_blood_id())
		var/datum/reagents/R = new /datum/reagents(300)
		R.add_reagent(H.get_blood_id(), rand(200, 300), H.get_blood_data())
		chem_splash(get_turf(H), 1, list(R))

// Лужа семени
/datum/onelife_death/semen
	name = "Лужа семени"
	death_sound = 'sound/effects/splash.ogg'
	message = "%TARGET% растекается лужей семени... Как это вообще возможно?!"

/datum/onelife_death/semen/crumble(mob/living/carbon/human/H)
	. = ..()
	var/datum/reagents/R = new /datum/reagents(300)
	R.add_reagent(/datum/reagent/consumable/semen, rand(200, 300))
	chem_splash(get_turf(H), 1, list(R))

// Остатки конструкта (по мотивам часового голема)
/datum/onelife_death/construct
	name = "Останки конструкта"
	death_sound = 'sound/magic/clockwork/anima_fragment_death.ogg'
	message = "%TARGET% с шелестом шестерёнок рассыпается в остатки древней конструкции!"
	leave_ash = FALSE

/datum/onelife_death/construct/crumble(mob/living/carbon/human/H)
	. = ..()
	new /obj/item/clockwork/alloy_shards/clockgolem_remains(get_turf(H))
	for(var/i in 1 to rand(3, 5))
		new /obj/item/clockwork/alloy_shards/small(get_turf(H))

// Гора песка (по мотивам песочного голема)
/datum/onelife_death/sand
	name = "Гора песка"
	death_sound = 'sound/weapons/thudswoosh.ogg'
	message = "%TARGET% осыпается горой песка!"
	leave_ash = FALSE

/datum/onelife_death/sand/crumble(mob/living/carbon/human/H)
	. = ..()
	for(var/i in 1 to rand(3, 5))
		new /obj/item/stack/ore/glass(get_turf(H)) //this is sand

// Куча угля
/datum/onelife_death/coal
	name = "Куча угля"
	death_sound = 'sound/effects/shovel_dig.ogg'
	message = "%TARGET% с шорохом осыпается кучей угля!"
	leave_ash = FALSE

/datum/onelife_death/coal/crumble(mob/living/carbon/human/H)
	. = ..()
	new /obj/item/stack/sheet/mineral/coal(get_turf(H), rand(3, 6))

// Кучка золота
/datum/onelife_death/gold
	name = "Кучка золота"
	death_sound = 'sound/effects/cashregister.ogg'
	message = "%TARGET% со звоном рассыпается горсткой золотых слитков!"
	leave_ash = FALSE

/datum/onelife_death/gold/crumble(mob/living/carbon/human/H)
	. = ..()
	new /obj/item/stack/sheet/mineral/gold(get_turf(H), rand(2, 4))

// Кучка фарша
/datum/onelife_death/meat
	name = "Кучка фарша"
	death_sound = 'sound/effects/meatslap.ogg'
	message = "%TARGET% шлёпается кучей сырого фарша!"
	leave_ash = FALSE

/datum/onelife_death/meat/crumble(mob/living/carbon/human/H)
	. = ..()
	H.add_splatter_floor(get_turf(H))
	for(var/i in 1 to rand(2, 4))
		new /obj/item/reagent_containers/food/snacks/meat/slab(get_turf(H))

// Груда железного лома
/datum/onelife_death/scrap
	name = "Железный лом"
	death_sound = 'sound/effects/clang.ogg'
	message = "%TARGET% с грохотом разваливается грудой железного лома!"
	leave_ash = FALSE

/datum/onelife_death/scrap/crumble(mob/living/carbon/human/H)
	. = ..()
	new /obj/effect/decal/remains/robot(get_turf(H))
	new /obj/item/stack/rods(get_turf(H), rand(3, 5))

/*
 * ОБЩАЯ МЕХАНИКА РАССЫПАНИЯ
 */

/// Возвращает форму рассыпания Одной Жизни, выбранную носителем в настройках квирков,
/// или null, если рассыпать нужно обычным образом. Вызывается из /mob/living/dust().
/proc/onelife_get_death_form(mob/living/H)
	if(!istype(H) || QDELETED(H) || !ishuman(H) || !HAS_TRAIT(H, TRAIT_ONELIFE))
		return null
	var/chosen_form_name = H.client?.prefs?.onelife_death_type || "Пепел"
	var/form_type = GLOB.onelife_death_forms[chosen_form_name] || GLOB.onelife_death_forms["Пепел"]
	if(!form_type)
		return null
	return new form_type()

/// Рассыпать носителя Одной Жизни в выбранную им форму смерти.
/// Всю механику (полный дроп вещей, анимацию, форму) выполняет dust(TRUE, TRUE):
/// полному дропу (включая застрявшее, импланты и проглоченное) служит
/// /mob/living/proc/dust_spill_everything(), форме - onelife_get_death_form().
/proc/onelife_crumble(mob/living/carbon/human/H)
	if(!istype(H) || QDELETED(H))
		return
	H.dust(TRUE, TRUE)

/mob/living/gib(no_brain, no_organs, no_bodyparts, datum/explosion/was_explosion)
	if(HAS_TRAIT(src, TRAIT_ONELIFE))
		onelife_crumble(src)
		return
	return ..()

/obj/item/bodypart/drop_limb(special, dismembered)
	var/destroy_limb = FALSE
	if(!special && owner && HAS_TRAIT(owner, TRAIT_ONELIFE) && !is_pseudopart)
		destroy_limb = TRUE
	. = ..()
	if(destroy_limb && !QDELETED(src))
		qdel(src)
	return .

/// Снять с цели источник Одной Жизни: и квирк, и мутацию.
/proc/remove_onelife_source(mob/living/target, message)
	if(!target || !HAS_TRAIT(target, TRAIT_ONELIFE))
		return FALSE
	target.remove_quirk(/datum/quirk/onelife)
	var/mob/living/carbon/carbon_target = target
	if(istype(carbon_target) && carbon_target.dna)
		carbon_target.dna.remove_mutation(/datum/mutation/human/bm/onelife)
	if(message)
		to_chat(target, message)
	return TRUE

/*
 * КВИРК
 */

/datum/preferences
	var/onelife_death_type = "Пепел" // форма рассыпания для квирка "Одна Жизнь"

/datum/quirk/onelife
	name = "Одна Жизнь"
	desc = "С вас буквально сыпется песок. И... кажется, если вы погибнете (даже если это будет шуткой) - никто этот песок собрать воедино больше не сможет."
	mob_trait = TRAIT_ONELIFE
	value = -6
	gain_text = "<span class='danger'>Вы чувствуете, что вам нельзя умирать.</span>"
	lose_text = "<span class='notice'>Жизнь для вас снова ничто.</span>" //if only it were that easy!
	medical_record_text = "Пациент не сможет восстановиться после смерти."
	processing_quirk = TRUE

/datum/quirk/onelife/add()
	RegisterSignal(quirk_holder, COMSIG_MOB_DEATH, PROC_REF(get_rid_of_them))
	RegisterSignal(quirk_holder, COMSIG_MOB_EMOTE, PROC_REF(get_rid_of_them_emote))

/datum/quirk/onelife/remove()
	remove_signals()

/datum/quirk/onelife/proc/remove_signals()
	if(!QDELETED(quirk_holder))
		UnregisterSignal(quirk_holder, list(COMSIG_MOB_DEATH, COMSIG_MOB_EMOTE))

/datum/quirk/onelife/proc/get_rid_of_them(mob/user, gibbed)
	if(gibbed) // при dust()/gib() рассыпанием управляет сам dust()
		return
	if(quirk_holder.stat == DEAD)
		remove_signals()
		onelife_crumble(quirk_holder)

/datum/quirk/onelife/proc/get_rid_of_them_emote(mob/user, datum/emote/emote)
	var/key = emote.key
	if(key == "deathgasp")
		remove_signals()
		onelife_crumble(quirk_holder)


