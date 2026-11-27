// The two habits every Team Deathmatch fighter picks up, whatever kit the round
// hands out: they can slip a bullet mid-jump, and their wind comes back quickly.
//
// Both belong to the mode rather than to a kit, which is why they are handed out
// by the lobby alongside the rotation instead of living in a loadout. A round is
// decided by who uses the arena better, and a crossing that cannot be contested
// would turn every round into a camp no matter which weapon the round is about.

#define DEATHMATCH_STAMINA_RECOVERY 6
#define DEATHMATCH_BUFFER_RECOVERY 5

//
// Bullet dodging, in the air only.
//

/// Reflexes that let a fighter slip a shot while jumping.
///
/// The hook is /mob/living/carbon/human/bullet_act(), which asks the owner's
/// martial art before it lets a projectile land and stops the hit on anything
/// but BULLET_ACT_HIT. BULLET_ACT_FORCE_PIERCE is the value the codebase already
/// uses for "this shot went through the person instead of into them", which is
/// exactly what the shooter sees when the target slips it.
///
/// TRAIT_JUMPING is the whole gate. /datum/component/jump adds it for the length
/// of the leap and takes it back when the mob lands, so the check is exactly
/// "is this fighter airborne right now". A dodge costs action stamina, so it is
/// something a fighter spends rather than something that happens to them, and a
/// duel at range does not turn into a coin flip.
/datum/martial_art/deathmatch_reflex
	name = "Deathmatch Reflexes"
	// No verb: the perk has nothing to toggle, and the base art adds a "help"
	// verb to the mob's panel if one is set.
	help_verb = null

/datum/martial_art/deathmatch_reflex/on_projectile_hit(mob/living/carbon/human/defender, obj/item/projectile/projectile, def_zone)
	. = ..()
	if(. != BULLET_ACT_HIT)
		return .
	// The gate is the jump trait: /datum/component/jump holds it for the length
	// of the leap and takes it back on landing, so this is exactly "airborne".
	if(!HAS_TRAIT(defender, TRAIT_JUMPING))
		return BULLET_ACT_HIT
	// Cheap sanity checks taken from the sleeping carp style, which is the only
	// other thing in the codebase that dodges shots: no dodging while stunned,
	// on the floor, or inside something that is not a turf.
	if(defender.incapacitated(FALSE, TRUE))
		return BULLET_ACT_HIT
	if(!CHECK_ALL_MOBILITY(defender, MOBILITY_USE|MOBILITY_STAND))
		return BULLET_ACT_HIT
	if(!isturf(defender.loc))
		return BULLET_ACT_HIT
	if(!defender.UseStaminaBuffer(STAMINA_COST_DODGE_PROJECTILE, warn = TRUE))
		return BULLET_ACT_HIT
	// The shot is thrown off rather than stopped, same as a carp deflect: the
	// projectile keeps flying, but not at anybody the dodger was covering.
	playsound(get_turf(defender), pick('sound/weapons/bulletflyby.ogg', 'sound/weapons/bulletflyby2.ogg', 'sound/weapons/bulletflyby3.ogg'), 75, TRUE)
	projectile.firer = defender
	projectile.setAngle(rand(0, 360))
	defender.balloon_alert_to_viewers("slips the shot", "you slip the shot")
	return BULLET_ACT_FORCE_PIERCE

//
// Fast, constant stamina regeneration.
//

/// The Team Deathmatch recovery perk.
///
/// The stock rules restore action stamina on Life()'s two-second pulse and cut
/// the stamina buffer to a quarter for five seconds after every stamina action,
/// which is how the base game makes sprinting and jumping cost something. This
/// restores a flat amount on every processing tick regardless of that
/// punishment, which is what "constant" means here: a TDM round is a series of
/// sprints between pieces of cover, and a fighter who cannot afford the next
/// sprint is a fighter who is already out of the round.
///
/// Both meters are covered. Jumps spend action stamina
/// (`adjustStaminaLoss()`), dodges spend the stamina buffer (`UseStaminaBuffer()`),
/// and a perk that only refilled one of them would leave half the mode's movement
/// gated for no reason a player could see.
/datum/status_effect/deathmatch_stamina
	id = "deathmatch_stamina"
	// No screen alert: this effect never ends while the body is alive and there is
	// nothing for a player to do about it, so an alert would be permanent clutter.
	alert_type = null
	duration = -1
	tick_interval = 1 SECONDS

/datum/status_effect/deathmatch_stamina/tick()
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	owner.adjustStaminaLoss(-DEATHMATCH_STAMINA_RECOVERY)
	owner.RechargeStaminaBuffer(DEATHMATCH_BUFFER_RECOVERY)

#undef DEATHMATCH_STAMINA_RECOVERY
#undef DEATHMATCH_BUFFER_RECOVERY
