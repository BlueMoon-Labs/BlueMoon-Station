/datum/component/size_normalized
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/obj/item/clothing/attached_wear
	var/normal_resize = RESIZE_NORMAL
	var/natural_size //The value of the wearer's body_size var in prefs. Unused for now.
	var/recorded_size //the user's height prior to equipping

//Set up the linked clothing
/datum/component/size_normalized/Initialize(obj/item/clothing/wear, size_to_use)
	. = ..()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	if(size_to_use)
		normal_resize = size_to_use
	attached_wear = wear

//Normalize the mob on add in case it's necessary
/datum/component/size_normalized/RegisterWithParent()
	. = ..()
	var/mob/living/wearer = parent
	recorded_size = get_size(wearer)
	if(recorded_size != normal_resize)
		playsound(wearer, 'sound/effects/magic.ogg', 50, 1)
		wearer.flash_lighting_fx(3, 3, LIGHT_COLOR_PURPLE)
		wearer.visible_message("<span class='warning'>A flash of purple light engulfs \the [wearer], before [wearer.ru_who()] jump[wearer.p_s()] to a more average size!</span>","<span class='notice'>You feel warm for a moment, before everything scales to your size...</span>")
		wearer.update_size(normal_resize)
	RegisterSignal(wearer, COMSIG_MOB_RESIZED, PROC_REF(normalize_size))
	// Компонент живёт на МОБЕ, а attached_wear - жёсткая ссылка на одежду, которая его
	// завела. Пока компонент висит, нормализатор не собирается сборщиком даже после qdel:
	// в прод-раундах 9829 и 9830 "normalizer wristband" оба раза оказывался среди
	// незакрытых hard delete - уже после того, как owner на самой одежде перевели на
	// weakref. Снимаем компонент по удалению одежды, иначе он ещё и продолжает
	// нормализовать носителя предметом, которого больше нет.
	if(attached_wear)
		RegisterSignal(attached_wear, COMSIG_PARENT_QDELETING, PROC_REF(on_wear_deleted))

//Denormalize the mob when the component is destroyed (if needed)
/datum/component/size_normalized/UnregisterFromParent()
	. = ..()
	var/mob/living/wearer = parent
	UnregisterSignal(wearer, COMSIG_MOB_RESIZED)
	if(attached_wear)
		UnregisterSignal(attached_wear, COMSIG_PARENT_QDELETING)
	if(recorded_size == normal_resize)
		return
	playsound(wearer,'sound/weapons/emitter2.ogg', 50, 1)
	wearer.flash_lighting_fx(3, 3, LIGHT_COLOR_YELLOW)
	wearer.visible_message("<span class='warning'>Golden light engulfs \the [wearer], and [wearer.ru_who()] shoot[wearer.p_s()] back to [wearer.ru_ego()] default height!</span>","<span class='notice'>Energy rushes through your body, and you return to normal.</span>")
	wearer.update_size(recorded_size)

/datum/component/size_normalized/Destroy()
	attached_wear = null
	return ..()

/datum/component/size_normalized/proc/on_wear_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

//Make sure the size stays normalized while worn and add the change to the recorded size
/datum/component/size_normalized/proc/normalize_size(mob/living/source, new_size, cur_size)
	SIGNAL_HANDLER

	. = TRUE
	if(get_size(source) == normal_resize)
		return FALSE

	recorded_size += new_size - cur_size
	if(recorded_size > RESIZE_MACRO || recorded_size < RESIZE_MICRO)
		recorded_size -= new_size - cur_size

	source.update_size(normal_resize)
