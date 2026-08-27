// Дизайн протолата для ракет «VARS». Технология - та же стартовая, что у прочего
// летального боеприпаса СБ (узел "base"), но печать требует код Оранж и стоит дорого.

/datum/design/security_missile_box
	name = "\"VARS\" HE Missile Box"
	desc = "Ящик из семи 69-мм осколочно-фугасных ракет \"выстрелил - и забудь\" со встроенной системой активного радара. Не для использования в помещениях."
	id = "sec_missiles"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 20000, /datum/material/plasma = 6000)
	build_path = /obj/item/storage/box/security_missiles
	category = list("Ammo")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_AMBER //как у прочего летального боеприпаса СБ
