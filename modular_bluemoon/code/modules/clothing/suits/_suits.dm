/obj/item/clothing/suit
	/**
	 * Одежда не будет вырезать или скрывать за собой тело тавров, а будет накладываться поверх.
	 * Подбирается индивидуально: конретные спрайты одежды под конкретные спрайты тел тавров.
	 * Ассоциативный список заполняется именами типов тавров через запятую: alist("_type_a" = list("Canine", "Feline"), "_type_b" = list("Naga")) .
	 *
	 * Применяется отдельно от taur_mob_worn_overlay когда принципиально важен каждый пиксель - одежда не подходит различным таврам
	 * даже с одинаковыми стилями/типами.
	 *
	 * Иконки добавляются в файл 'modular_bluemoon/icons/mob/clothing/taur_custom_clothing.dmi'.
	 * Для внедрения необходимо нарисовать все(!) стейты (icon_state) для предмета одежды для конкретного типа тавров, включая unique_reskin, так как алгоритм
	 * сделает слияние имён: "icon_state + whitelist_key_name". Имена предметов в файле должны частично соответствовать изначалным именам и
	 * в конце иметь приписку с именем ключа в вайтлисте: "armor_type_a".
	 */
	var/alist/taur_types_icon_whitelist = alist()

/obj/item/clothing/suit/apron/chef/AltClick()
	. = ..()
	body_parts_covered = body_parts_covered ? NONE : CHEST|GROIN
	to_chat(usr, "<span class='notice'>Your [src] is [body_parts_covered ? "now covering your chest and groin" : "no longer covering anything"].</span>")
	return TRUE
