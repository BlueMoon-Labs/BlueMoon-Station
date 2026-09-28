///NIFSoft Remover. This is mostly here so that security and antags have a way to remove NIFSofts from someome
/obj/item/nifsoft_remover
	name = "Lopland 'Wrangler' NIF-Cutter"
	desc = "Небольшое устройство, позволяющее удалять NIFSoft у пользователя NIF. С учётом относительно недавнего и стремительного распространения NIF их использование в преступлениях — и мелких, и организованных — за последние годы резко возросло. \
	Существование основанной на наномашинах мгновенной коммуникации, которую невозможно эффективно отследить или взломать, дало большинству ЧВК достаточно поводов \
	разработать собственные устройства. Это «Wrangler»-модель NIF-Каттера, применяемая для грубого стирания программ прямо с Framework пользователя."
	icon = 'modular_bluemoon/code/modules/nif/icons/obj/devices.dmi'
	icon_state = "nifsoft_remover"

	///Is a disk with the corresponding NIFSoft created when said NIFSoft is removed?
	var/create_disk = FALSE

/obj/item/nifsoft_remover/attack(mob/living/carbon/human/target_mob, mob/living/user)
	. = ..()
	var/obj/item/organ/cyberimp/brain/nif/target_nif = target_mob.getorgan(/obj/item/organ/cyberimp/brain/nif)

	if(!target_nif || !length(target_nif.loaded_nifsofts))
		balloon_alert(user, "[target_mob] has no NIFSofts!")
		return

	var/list/installed_nifsofts = target_nif.loaded_nifsofts
	var/datum/nifsoft/nifsoft_to_remove = tgui_input_list(user, "Chose a NIFSoft to remove.", "[src]", installed_nifsofts)

	if(!nifsoft_to_remove)
		return FALSE

	user.visible_message(span_warning("[user] starts to use [src] on [target_mob]"), span_notice("You start to use [src] on [target_mob]"))
	if(!do_after(user, 5 SECONDS, target_mob))
		balloon_alert(user, "removal cancelled!")
		return FALSE

	if(!target_nif.remove_nifsoft(nifsoft_to_remove))
		balloon_alert(user, "removal failed!")
		return FALSE

	to_chat(user, span_notice("You successfully remove [nifsoft_to_remove]."))
	user.log_message("removed [nifsoft_to_remove] from [target_mob]" ,LOG_GAME)

	if(create_disk)
		var/obj/item/disk/nifsoft_uploader/new_disk = new
		new_disk.loaded_nifsoft = nifsoft_to_remove.type
		new_disk.name = "[nifsoft_to_remove] datadisk"

		user.put_in_hands(new_disk)

	qdel(nifsoft_to_remove)

	return TRUE

/obj/item/nifsoft_remover/syndie
	name = "Cybersun 'Scalpel' NIF-Cutter"
	desc = "Модифицированная версия устройства удаления NIFSoft: позволяет извлечь NIFSoft и сохранить чистую копию удалённого софта на диск. В верхних эшелонах корпоративного мира нанитовые имплант-каркасы встречаются повсюду. Ценные цели почти всегда поддерживают постоянную NIF-связь как минимум с одним-двумя контактами на случай чрезвычайной ситуации. Чтобы обойти эту досадную проблему, Cybersun Industries изобрели NIF-Каттер «Scalpel». Устройство размером не больше КПК — подарок для любителей нейрокраж — способно извлечь конкретную программу из цели за пять секунд или меньше. Вдобавок высококлассное программное обеспечение позволяет скопировать конкретный «софт» на диск для использования самим владельцем инструмента."
	icon_state = "nifsoft_remover_syndie"
	create_disk = TRUE

/datum/uplink_item/device_tools/nifsoft_remover
	name = "Cybersun 'Scalpel' NIF-Cutter"
	desc = "Модифицированная версия устройства удаления NIFSoft: позволяет извлечь NIFSoft и сохранить чистую копию удалённого софта на диск."
	item = /obj/item/nifsoft_remover/syndie
	cost = 3

///NIF Repair Kit.
/obj/item/nif_repair_kit
	name = "Cerulean NIF Regenerator"
	desc = "Ремонтный набор, позволяющий чинить NIF без хирургии. Последствия капитализма и индустрии глубоки и проникли в том числе в индустрию нанитовых имплант-каркасов. \
	Framework, будучи сложными устройствами, обычно заблокированы на уровне прошивки под конкретные «одобренные» бренды ремонтной пасты или ремонтных доков. \
	Этот взломанный набор был разработан Ковеном Альтспейс как бесплатная альтернатива и широко распространился по всему внеземному пространству ради комфорта \
	пользователей, находящихся на периферии общества."
	icon = 'modular_bluemoon/code/modules/nif/icons/obj/devices.dmi'
	icon_state = "repair_paste"
	w_class = WEIGHT_CLASS_SMALL
	///How much does this repair each time it is used?
	var/repair_amount = 20
	///How many times can this be used?
	var/uses = 5

/obj/item/nif_repair_kit/attack(mob/living/carbon/human/mob_to_repair, mob/living/user)
	. = ..()

	var/obj/item/organ/cyberimp/brain/nif/installed_nif = mob_to_repair.getorgan(/obj/item/organ/cyberimp/brain/nif)
	if(!installed_nif)
		balloon_alert(user, "[mob_to_repair] lacks a NIF")
		return FALSE

	if(!do_after(user, 5 SECONDS, mob_to_repair))
		balloon_alert(user, "repair cancelled")
		return FALSE

	if(!installed_nif.adjust_durability(repair_amount))
		balloon_alert(user, "target NIF is at max duarbility")
		return FALSE

	to_chat(user, span_notice("You successfully repair [mob_to_repair]'s NIF"))
	to_chat(mob_to_repair, span_notice("[user] successfully repairs your NIF"))

	uses -= 1
	if(!uses)
		qdel(src)

/obj/item/nif_hud_adapter
	name = "Scrying Lens Adapter"
	desc = "Набор, модифицирующий избранные очки для отображения NIF-шлемов"
	icon = 'modular_bluemoon/code/modules/nif/icons/donator/obj/kits.dmi'
	icon_state = "partskit"

	/// Can this item be used multiple times? If not, it will delete itself after being used.
	var/multiple_uses = FALSE
	/// List containing all of the glasses that we want to work with this.
	var/static/list/glasses_whitelist = list(
		/obj/item/clothing/glasses/monocle,
		/obj/item/clothing/glasses/regular,
		/obj/item/clothing/glasses/osi,
		/obj/item/clothing/glasses/phantom,
		/obj/item/clothing/glasses/sunglasses/gar,
		/obj/item/clothing/glasses/heat,
		/obj/item/clothing/glasses/cold,
		/obj/item/clothing/glasses/orange,
		/obj/item/clothing/glasses/red,
	)

/obj/item/nif_hud_adapter/examine(mob/user)
	. = ..()
	var/list/compatible_glasses_names = list()
	for(var/obj/item/glasses_type as anything in glasses_whitelist)
		var/glasses_name = initial(glasses_type.name)
		if(!glasses_name)
			continue

		compatible_glasses_names += glasses_name

	if(length(compatible_glasses_names))
		. += span_blue("\n This item will work on the following glasses: [english_list(compatible_glasses_names)].")

	return .

/obj/item/nif_hud_adapter/afterattack(atom/target_atom, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		return

	var/obj/item/clothing/glasses/target_glasses = target_atom
	if(!istype(target_glasses) || !is_type_in_list(target_glasses, glasses_whitelist))
		balloon_alert(user, "incompatible!")
		return

	if(HAS_TRAIT(target_glasses, TRAIT_NIFSOFT_HUD_GRANTER))
		balloon_alert(user, "already upgraded!")
		return

	user.visible_message(span_notice("[user] upgrades [target_glasses] with [src]."), span_notice("You upgrade [target_glasses] to be NIF HUD compatible."))
	target_glasses.name = "\improper HUD-upgraded " + target_glasses.name
	target_glasses.AddElement(/datum/element/nifsoft_hud)
	playsound(target_glasses.loc, 'sound/weapons/circsawhit.ogg', 50, vary = TRUE)

	if(!multiple_uses)
		qdel(src)

