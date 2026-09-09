//Сломанная декоративная модель
/obj/item/broken_missile/security
	icon = 'icons/obj/weapons/sec_missile.dmi'
	icon_state = "rocket_broken"

//Сам боеприпас
/obj/item/ammo_casing/caseless/security_missile
	name = "\improper ОФ-ракета \"VARS\""
	desc = "69-мм осколочно-фугасная ракета со встроенной радарной системой наведения. Выстрелил - и забыл, потому что лучше действительно забыть, что произошло, если случайно попал мимо ассистента."
	icon = 'icons/obj/weapons/sec_missile.dmi'
	icon_state = "rocket"
	caliber = "69mm"
	projectile_type = /obj/item/projectile/bullet/security_missile
	w_class = WEIGHT_CLASS_SMALL

//Хранилище для ракет. Не подтип ящика с боеприпасами - не хотим, чтобы СБ слишком легко пополнялся.
/obj/item/storage/box/security_missiles
	name = "ящик ОФ-ракет \"VARS\""
	desc = "Изящный прочный ящик для хранения ракет."
	icon = 'icons/obj/weapons/sec_missile.dmi'
	icon_state = "rocket_box"
	illustration = null

/obj/item/storage/box/security_missiles/PopulateContents()
	for(var/i in 1 to 7)
		new /obj/item/ammo_casing/caseless/security_missile(src)
