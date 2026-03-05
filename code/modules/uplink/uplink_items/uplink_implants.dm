
/*
	Uplink Items:
	Unlike categories, uplink item entries are automatically sorted alphabetically on server init in a global list,
	When adding new entries to the file, please keep them sorted by category.
*/

// Implants

/datum/uplink_item/implants/adrenal
	name = "Adrenal Implant"
	desc = "Имплант, вводимый в тело и активируемый по желанию. Впрыскивает химический коктейль, \
			снимающий все обездвиживающие эффекты, ускоряющий бег и слегка лечащий."
	item = /obj/item/storage/box/syndie_kit/imp_adrenal
	cost = 8
	player_minimum = 25

/datum/uplink_item/implants/antistun
	name = "CNS Rebooter Implant"
	desc = "Этот имплант поможет быстрее встать на ноги после оглушения. Поставляется с автохирургом."
	item = /obj/item/autosurgeon/syndicate/anti_stun
	cost = 12
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/implants/antistun
	name = "Anti-Drop Implant"
	desc = "Кибернетический мозговой имплант, позволяющий принудительно сжимать мышцы рук, предотвращая выпадение предметов. Дёрните ухом для переключения."
	item = /obj/item/autosurgeon/syndicate/anti_drop
	cost = 12
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/implants/deathrattle
	name = "Box of Deathrattle Implants"
	desc = "Набор имплантов (и многоразовый имплантер) для команды. Когда один из членов команды \
	умирает, все остальные носители получают ментальное сообщение с именем и местом смерти. \
	В отличие от большинства имплантов, совместимы с любыми существами — биологическими или механическими."
	item = /obj/item/storage/box/syndie_kit/imp_deathrattle
	cost = 4
	surplus = 0
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/implants/freedom
	name = "Freedom Implant"
	desc = "Имплант, вводимый в тело и активируемый по желанию. Попытается освободить \
			пользователя от стандартных средств удержания, таких как наручники."
	item = /obj/item/storage/box/syndie_kit/imp_freedom
	cost = 5

/datum/uplink_item/implants/warp
	name = "Warp Implant"
	desc = "Имплант, вводимый в тело и активируемый по желанию. Телепортирует туда, где вы были 10 секунд назад. Кулдаун 10 секунд."
	item = /obj/item/storage/box/syndie_kit/imp_warp
	cost = 6
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS)

/datum/uplink_item/implants/hijack
	name = "Hijack Implant"
	desc = "Имплант, позволяющий взламывать APC на станции, управлять ими и оборудованием в этих комнатах по своей воле."
	item = /obj/item/implanter/hijack
	cost = 14
	surplus = 0
	restricted = TRUE

/datum/uplink_item/implants/radio
	name = "Internal Illegal Radio Implant"
	desc = "Имплант, позволяющий использовать внутреннее нелегальное радио. \
			Работает как обычная гарнитура, но можно отключить для использования внешней гарнитуры и избежания обнаружения."
	item = /obj/item/storage/box/syndie_kit/imp_radio
	cost = 4
	restricted = TRUE

/datum/uplink_item/implants/microbomb
	name = "Microbomb Implant"
	desc = "Имплант, активируемый вручную или автоматически при смерти. \
			Чем больше имплантов внутри вас — тем сильнее взрыв. \
			Но ваше тело будет уничтожено навсегда."
	item = /obj/item/storage/box/syndie_kit/imp_microbomb
	cost = 2
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/implants/macrobomb
	name = "Macrobomb Implant"
	desc = "Имплант, активируемый вручную или автоматически при смерти. \
			При смерти вызывает массивный взрыв, уничтожающий всё поблизости."
	item = /obj/item/storage/box/syndie_kit/imp_macrobomb
	cost = 20
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE
	restricted = TRUE

/datum/uplink_item/implants/reviver
	name = "Reviver Implant"
	desc = "Имплант попытается воскресить и подлатать вас, если потеряете сознание. Поставляется с автохирургом."
	item = /obj/item/autosurgeon/syndicate/inteq/reviver
	cost = 5
	purchasable_from = (~UPLINK_SYNDICATE)
	//purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/implants/revitilzer
	name = "Revitalizing Cortex Implant"
	desc = "Устанавливаемый на торс кортекс оптимизирует процессы организма для поддержания тела в рабочем состоянии. Обеспечивает базовое восстановление. Поставляется с автохирургом."
	item = /obj/item/autosurgeon/syndicate/inteq/revitilzer
	cost = 8
	purchasable_from = (~UPLINK_SYNDICATE)
	//purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/implants/stealthimplant
	name = "Stealth Implant"
	desc = "Уникальный имплант, делающий вас почти невидимым, пока вы не двигаетесь слишком активно. \
			При активации прячет вас в хамелеоновую коробку, которая обнаруживается только при столкновении."
	item = /obj/item/implanter/stealth
	cost = 8

/datum/uplink_item/implants/storage
	name = "Storage Implant"
	desc = "Имплант, активируемый по желанию. Открывает маленький блюспейс-карман, \
			вмещающий два предмета стандартного размера."
	item = /obj/item/storage/box/syndie_kit/imp_storage
	cost = 8

/datum/uplink_item/implants/thermals
	name = "Thermal Eyes"
	desc = "Кибернетические глаза с термозрением. В комплекте бесплатный автохирург."
	item = /obj/item/autosurgeon/syndicate/thermal_eyes
	cost = 8
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/implants/uplink
	name = "Uplink Implant"
	desc = "Имплант аплинка. Не имеет кредитов и должен быть пополнен физическими кредитами. \
			Необнаружим (кроме хирургии) — отлично подходит для побега из заключения."
	item = /obj/item/storage/box/syndie_kit/imp_uplink
	cost = 4
	surplus = 0
	purchasable_from = ~(UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE)
	restricted = TRUE

/datum/uplink_item/implants/xray
	name = "X-ray Vision Implant"
	desc = "Кибернетические глаза с рентгеновским зрением. В комплекте автохирург."
	item = /obj/item/autosurgeon/syndicate/xray_eyes
	cost = 15
	surplus = 0
	purchasable_from = UPLINK_NUKE_OPS | UPLINK_CLOWN_OPS | UPLINK_SYNDICATE

/datum/uplink_item/implants/biomorphedheart
	name = "Biomorphed Heart"
	desc = "Экспериментальный орган, что используется некоторыми отрядами супер-солдат в различных 'чёрных операциях'. Даёт усиленную регенерацию, и защиту от сердечного приступа."
	item = /obj/item/autosurgeon/syndicate/inteq/biomorphedheart
	cost = 5
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/implants/biomorphedheart/syndie
	item = /obj/item/autosurgeon/syndicate/biomorphedheart
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/implants/biomorphedliver/syndie
	name = "Biomorphed Liver"
	desc = "Экспериментальный орган, что используется некоторыми отрядами супер-солдат в различных 'чёрных операциях'. Даёт усиленное восстановление от токсинов и уменьшает изнурение."
	item = /obj/item/autosurgeon/syndicate/inteq/biomorphedliver
	cost = 5
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/implants/biomorphedliver/syndie
	item = /obj/item/autosurgeon/syndicate/biomorphedliver
	purchasable_from = UPLINK_SYNDICATE

/datum/uplink_item/implants/biomorphedlungs
	name = "Biomorphed Lungs"
	desc = "Экспериментальный орган, что используется некоторыми отрядами супер-солдат в различных 'чёрных операциях'. Даёт усиленное восстановление от изнурения и частичную защиту от атмосферных угроз для дыхания."
	item = /obj/item/autosurgeon/syndicate/inteq/biomorphedlungs
	cost = 5
	purchasable_from = (UPLINK_TRAITORS | UPLINK_NUKE_OPS)

/datum/uplink_item/implants/biomorphedlungs/syndie
	item = /obj/item/autosurgeon/syndicate/biomorphedlungs
	purchasable_from = UPLINK_SYNDICATE
