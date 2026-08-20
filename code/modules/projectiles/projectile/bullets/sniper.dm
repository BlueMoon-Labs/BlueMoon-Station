// .50 (Sniper)

#define SNIPER_HEAD_GIB_CLOSE_RANGE 2
#define SNIPER_HEAD_GIB_CHANCE 50

/obj/item/projectile/bullet/p50
	name = ".50 bullet"
	pixels_per_second = TILES_TO_PIXELS(25)
	damage = 70
	knockdown = 100
	dismemberment = 50
	armour_penetration = BULLET_BR5   // BLUEMOON EDIT: было 50 → BR5(65)
	zone_accuracy_factor = 100
	var/breakthings = TRUE
	var/can_head_gib = TRUE
	wound_bonus = 20
	bare_wound_bonus = 10

/obj/item/projectile/bullet/p50/on_hit(atom/target, blocked = 0)
	if(isobj(target) && (blocked != 100) && breakthings)
		var/obj/O = target
		O.take_damage(80, BRUTE, BULLET, FALSE)
	. = ..()
	if(blocked >= 100)
		return .
	if(iscarbon(target) && can_head_gib)
		var/mob/living/carbon/C = target
		if(def_zone == BODY_ZONE_HEAD && starting && get_dist(starting, get_turf(C)) <= SNIPER_HEAD_GIB_CLOSE_RANGE && prob(SNIPER_HEAD_GIB_CHANCE))
			C.gib_head()
	return .

/obj/item/projectile/bullet/p50/soporific
	armour_penetration = BULLET_BR0
	damage = 0
	dismemberment = 0
	knockdown = 0
	breakthings = FALSE
	can_head_gib = FALSE
	wound_bonus = 5
	bare_wound_bonus = 0

/obj/item/projectile/bullet/p50/soporific/on_hit(atom/target, blocked = FALSE)
	if((blocked != 100) && isliving(target))
		var/mob/living/L = target
		L.Sleeping(400)
	return ..()

/obj/item/projectile/bullet/p50/penetrator
	name = "penetrator round"
	icon_state = "gauss"
	damage = 60
	armour_penetration = BULLET_BR6   // BLUEMOON EDIT: проникающий → BR6(80)
	projectile_piercing = PASSMOB
	projectile_phasing = (ALL & (~PASSMOB))
	dismemberment = 0
	knockdown = 0
	breakthings = FALSE

/obj/item/projectile/bullet/p50/penetrator/shuttle
	icon_state = "gaussstrong"
	damage = 25
	armour_penetration = BULLET_BR5   // чуть слабее основного
	pixels_per_second = TILES_TO_PIXELS(33.33)
	range = 16
