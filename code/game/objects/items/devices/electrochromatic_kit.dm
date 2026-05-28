/obj/item/electronics/electrochromatic_kit
	name = "electrochromatic kit"
	desc = "Retrofits electrochromatic smart-tint onto unanchored windows, interior windoors, or glass-paneled airlocks. Use in hand to set its ID to match an electrochromatic button channel."
	/// Electrochromatic ID
	var/id

/obj/item/electronics/electrochromatic_kit/attack_self(mob/user)
	. = ..()
	if(.)
		return
	var/new_id = input(user, "Set this kit's electrochromatic ID", "Set ID", id) as text|null
	if(isnull(new_id))
		return
	id = new_id
