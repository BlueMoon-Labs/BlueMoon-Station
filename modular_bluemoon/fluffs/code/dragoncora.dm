/obj/item/clothing/head/helmet/dragoncora
	name = "Agent Headgear"
	desc = "Abduct with style - spiky style."
	icon_state = "alienhelmet"
	item_state = "alienhelmet"
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)

/obj/item/clothing/suit/armor/dragoncora
	name = "Agent Vest"
	desc = "A vest outfitted with advanced stealth technology. It has two modes - combat and stealth."
	icon = 'icons/obj/abductor.dmi'
	icon_state = "vest_stealth"
	item_state = "armor"
	blood_overlay_type = "armor"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)

/obj/item/clothing/head/helmet/skull/ftu
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 0)

/obj/item/clothing/suit/armor/vest/dragoncora
	name = "FTU Security Armor"
	desc = "Стандартный бронежилет охраны свободных торговцев без бронепластин. Обеспечивает оптимальную защиту жизненно важных органов в тесных коридорах кораблей и трюмов."
	icon_state = "epic_bp_armor"
	item_state = "epic_bp_armor"
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	body_parts_covered = CHEST|GROIN|ARMS
	cold_protection = CHEST|GROIN|ARMS
	heat_protection = CHEST|GROIN|ARMS
	armor = list(MELEE = 20, BULLET = 20, LASER = 25, ENERGY = 20, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50, WOUND = 10)

/obj/item/clothing/gloves/color/black/dragoncora
	name = "SpecOps Guerrilla Gloves"
	desc = "Боевые перчатки предназначенные для усиления навыков владельца. Встроенные наночипы напрямую посылают сигналы в нервные окончания рук, доводя движения владельца до идеала, что позволяет укладывать жертв на землю и перетаскивать их с максимальной эффективностью."
	icon_state = "infiltrator_g"
	item_state = "infiltrator_g"
	icon = 'modular_bluemoon/Ren/Icons/Obj/infiltrator.dmi'
	mob_overlay_icon = 'modular_bluemoon/Ren/Icons/Mob/clothing.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Ren/Icons/Mob/clothing_digi.dmi'

/obj/item/clothing/shoes/dragoncora
	name = "Combat Boots"
	desc = "High speed, low drag combat boots."
	icon_state = "combat"
	item_state = "jackboots"
	lefthand_file = 'icons/mob/inhands/equipment/security_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/security_righthand.dmi'

/obj/item/storage/backpack/dragoncora
	name = "Tactical Backpack"
	icon_state = "ert_engineering"

/obj/item/clothing/suit/det_suit/lanyard/dragoncora
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 0, ACID = 0, WOUND = 0)

/obj/item/radio/headset/dragoncora
	name = "Alien Headset"
	desc = "An advanced alien headset designed to monitor communications of human space stations. Why does it have a microphone? No one knows."
	icon = 'icons/obj/abductor.dmi'
	icon_state = "abductor_headset"
	item_state = "abductor_headset"
