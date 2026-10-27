/datum/asset/simple/blood_brothers
	assets = list(
		"blood_brothers_cloth.png" = 'tgui/packages/tgui/assets/blood_brothers/blood_brothers_cloth.png',
		"blood_brothers_smear.png" = 'tgui/packages/tgui/assets/blood_brothers/blood_brothers_smear.png',
		"blood_brothers_seal_empty.png" = 'tgui/packages/tgui/assets/blood_brothers/blood_brothers_seal_empty.png',
		"blood_brothers_seal_fresh.png" = 'tgui/packages/tgui/assets/blood_brothers/blood_brothers_seal_fresh.png',
		"blood_brothers_seal_smeared.png" = 'tgui/packages/tgui/assets/blood_brothers/blood_brothers_seal_smeared.png',
	)

/datum/antagonist/brother/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/blood_brothers))
