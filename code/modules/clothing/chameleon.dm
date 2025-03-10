#define EMP_RANDOMISE_TIME 300

/datum/action/chameleon_outfit
	name = "Select Chameleon Outfit"
	button_icon_state = "chameleon_outfit"
	var/list/outfit_options //By default, this list is shared between all instances. It is not static because if it were, subtypes would not be able to have their own. If you ever want to edit it, copy it first.

/datum/action/chameleon_outfit/New()
	..()
	initialize_outfits()

/datum/action/chameleon_outfit/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/datum/action/chameleon_outfit/proc/initialize_outfits()
	var/static/list/standard_outfit_options
	if(!standard_outfit_options)
		standard_outfit_options = list()
		for(var/path in subtypesof(/datum/outfit/job))
			var/datum/outfit/O = path
			if(initial(O.can_be_admin_equipped))
				standard_outfit_options[initial(O.name)] = path
		sortTim(standard_outfit_options, cmp = /proc/cmp_text_asc)
	outfit_options = standard_outfit_options

/datum/action/chameleon_outfit/Trigger(left_click = TRUE)
	return select_outfit(owner)

/datum/action/chameleon_outfit/proc/select_outfit(mob/user)
	if(!user || !IsAvailable())
		return FALSE
	var/selected = tgui_input_list(user, "Select outfit to change into", "Chameleon Outfit", outfit_options)
	if(!IsAvailable() || QDELETED(src) || QDELETED(user))
		return FALSE
	var/outfit_type = outfit_options[selected]
	if(!outfit_type)
		return FALSE
	var/datum/outfit/job/O = new outfit_type()
	var/list/outfit_types = O.get_chameleon_disguise_info()

	for(var/V in user.chameleon_item_actions)
		var/datum/action/item_action/chameleon/change/A = V
		var/done = FALSE
		for(var/T in outfit_types)
			for(var/name in A.chameleon_list)
				if(A.chameleon_list[name] == T)
					A.update_look(user, T)
					outfit_types -= T
					done = TRUE
					break
			if(done)
				break
	//hardsuit helmets/suit hoods
	if(ispath(O.suit, /obj/item/clothing/suit/hooded) && ishuman(user))
		var/mob/living/carbon/human/H = user
		//make sure they are actually wearing the suit, not just holding it, and that they have a chameleon hat
		if(istype(H.wear_suit, /obj/item/clothing/suit/chameleon) && istype(H.head, /obj/item/clothing/head/chameleon))
			var/helmet_type
			var/obj/item/clothing/suit/hooded/hooded = O.suit
			helmet_type = initial(hooded.hoodtype)

			if(helmet_type)
				var/obj/item/clothing/head/chameleon/hat = H.head
				hat.chameleon_action.update_look(user, helmet_type)
	qdel(O)
	return TRUE


/datum/action/item_action/chameleon/change
	name = "Chameleon Change"
	var/list/chameleon_blacklist = list() //This is a typecache
	var/list/chameleon_list = list()
	var/chameleon_type = null
	var/chameleon_name = "Item"

	var/emp_timer

/datum/action/item_action/chameleon/change/Grant(mob/M)
	if(M && (owner != M))
		if(!M.chameleon_item_actions)
			M.chameleon_item_actions = list(src)
			var/datum/action/chameleon_outfit/O = new /datum/action/chameleon_outfit()
			O.Grant(M)
		else
			M.chameleon_item_actions |= src
	..()

/datum/action/item_action/chameleon/change/Remove(mob/M)
	if(M && (M == owner))
		LAZYREMOVE(M.chameleon_item_actions, src)
		if(!LAZYLEN(M.chameleon_item_actions))
			var/datum/action/chameleon_outfit/O = locate(/datum/action/chameleon_outfit) in M.actions
			qdel(O)
	..()

/datum/action/item_action/chameleon/change/proc/initialize_disguises()
	if(button)
		button.name = "Change [chameleon_name] Appearance"

	chameleon_blacklist |= typecacheof(target.type)
	for(var/V in typesof(chameleon_type))
		if(ispath(V) && ispath(V, /obj/item))
			var/obj/item/I = V
			if(chameleon_blacklist[V] || (initial(I.item_flags) & ABSTRACT) || !initial(I.icon_state))
				continue
			var/chameleon_item_name = "[initial(I.name)] ([initial(I.icon_state)])"
			var/copies = FALSE
			for(var/chameleon_item_index in chameleon_list)
				if(chameleon_item_index == chameleon_item_name)
					copies = TRUE
					break
			if(!copies)
				chameleon_list[chameleon_item_name] = I

/datum/action/item_action/chameleon/change/proc/select_look(mob/user)
	var/obj/item/picked_item
	var/picked_name
	picked_name = tgui_input_list(user, "Select [chameleon_name] to change into", "Chameleon [chameleon_name]", chameleon_list)
	if(!picked_name)
		return
	picked_item = chameleon_list[picked_name]
	if(!picked_item)
		return
	update_look(user, picked_item)

/datum/action/item_action/chameleon/change/proc/random_look(mob/user)
	var/picked_name = pick(chameleon_list)
	// If a user is provided, then this item is in use, and we
	// need to update our icons and stuff

	if(user)
		update_look(user, chameleon_list[picked_name])

	// Otherwise, it's likely a random initialisation, so we
	// don't have to worry

	else
		update_item(chameleon_list[picked_name])

/datum/action/item_action/chameleon/change/proc/update_look(mob/user, obj/item/picked_item)
	if(isliving(user))
		var/mob/living/C = user
		if(C.stat != CONSCIOUS)
			return

		update_item(picked_item)
		var/obj/item/thing = target
		thing.update_equipped_item()
	UpdateButtonIcon()

/datum/action/item_action/chameleon/change/proc/update_item(obj/item/picked_item)
	target.name = initial(picked_item.name)
	target.desc = initial(picked_item.desc)
	target.icon_state = initial(picked_item.icon_state)

	if(isitem(target))
		var/obj/item/I = target

		I.item_state = initial(picked_item.item_state)
		I.item_color = initial(picked_item.item_color)
		if(initial(picked_item.sprite_sheets))
			// Sprites-related variables are lists, which can not be retrieved using initial(). As such, we need to instantiate the picked item.
			var/obj/item/P = new picked_item(null)
			I.sprite_sheets = P.sprite_sheets
			I.onmob_sheets = P.onmob_sheets
			qdel(P)

		if(isclothing(I) && ispath(picked_item, /obj/item/clothing))
			var/obj/item/clothing/CL = I
			var/obj/item/clothing/PCL = picked_item
			CL.flags_cover = initial(PCL.flags_cover)

	target.icon = initial(picked_item.icon)

/datum/action/item_action/chameleon/change/Trigger(left_click = TRUE)
	if(!IsAvailable())
		return

	select_look(owner)
	return 1

/datum/action/item_action/chameleon/change/proc/emp_randomise(var/amount = EMP_RANDOMISE_TIME)
	START_PROCESSING(SSprocessing, src)
	random_look(owner)

	var/new_value = world.time + amount
	if(new_value > emp_timer)
		emp_timer = new_value

/datum/action/item_action/chameleon/change/process()
	if(world.time > emp_timer)
		STOP_PROCESSING(SSprocessing, src)
		return
	random_look(owner)

/obj/item/clothing/under/chameleon
	name = "black jumpsuit"
	icon_state = "black"
	item_state = "bl_suit"
	item_color = "black"
	desc = "It's a plain jumpsuit. It has a small dial on the wrist."
	sensor_mode = SENSOR_OFF //Hey who's this guy on the Syndicate Shuttle??
	random_sensor = FALSE
	resistance_flags = NONE
	armor = list("melee" = 10, "bullet" = 10, "laser" = 10, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/under/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/under
	chameleon_action.chameleon_name = "Jumpsuit"
	chameleon_action.chameleon_blacklist = typecacheof(list(/obj/item/clothing/under, /obj/item/clothing/under/color, /obj/item/clothing/under/rank), only_root_path = TRUE)
	chameleon_action.initialize_disguises()

/obj/item/clothing/under/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/under/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/clothing/under/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/clothing/suit/chameleon
	name = "armor"
	desc = "A slim armored vest that protects against most types of damage."
	icon_state = "armor"
	item_state = "armor"
	blood_overlay_type = "armor"
	resistance_flags = NONE
	armor = list("melee" = 10, "bullet" = 10, "laser" = 10, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)

	sprite_sheets = list(
		SPECIES_VOX = 'icons/mob/clothing/species/vox/suit.dmi',
		SPECIES_MONKEY = 'icons/mob/clothing/species/monkey/suit.dmi',
		SPECIES_FARWA = 'icons/mob/clothing/species/monkey/suit.dmi',
		SPECIES_WOLPIN = 'icons/mob/clothing/species/monkey/suit.dmi',
		SPECIES_NEARA = 'icons/mob/clothing/species/monkey/suit.dmi',
		SPECIES_STOK = 'icons/mob/clothing/species/monkey/suit.dmi'
	)

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/suit/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/suit
	chameleon_action.chameleon_name = "Suit"
	chameleon_action.chameleon_blacklist = typecacheof(list(/obj/item/clothing/suit/armor/abductor), only_root_path = TRUE)
	chameleon_action.initialize_disguises()

/obj/item/clothing/suit/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/suit/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/clothing/suit/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/clothing/glasses/chameleon
	name = "Optical Meson Scanner"
	desc = "Used by engineering and mining staff to see basic structural and terrain layouts through walls, regardless of lighting condition."
	icon_state = "meson"
	item_state = "meson"
	resistance_flags = NONE
	armor = list("melee" = 10, "bullet" = 10, "laser" = 10, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)

	sprite_sheets = list(
		SPECIES_VOX = 'icons/mob/clothing/species/vox/eyes.dmi',
		SPECIES_DRASK = 'icons/mob/clothing/species/drask/eyes.dmi',
		SPECIES_GREY = 'icons/mob/clothing/species/grey/eyes.dmi',
		SPECIES_MONKEY = 'icons/mob/clothing/species/monkey/eyes.dmi',
		SPECIES_FARWA = 'icons/mob/clothing/species/monkey/eyes.dmi',
		SPECIES_WOLPIN = 'icons/mob/clothing/species/monkey/eyes.dmi',
		SPECIES_NEARA = 'icons/mob/clothing/species/monkey/eyes.dmi',
		SPECIES_STOK = 'icons/mob/clothing/species/monkey/eyes.dmi'
	)

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/glasses/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/glasses
	chameleon_action.chameleon_name = "Glasses"
	chameleon_action.chameleon_blacklist = list()
	chameleon_action.initialize_disguises()

/obj/item/clothing/glasses/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/glasses/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/clothing/glasses/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/clothing/glasses/chameleon/thermal
	origin_tech = "magnets=3;syndicate=2"
	vision_flags = SEE_MOBS
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	flash_protect = -1
	prescription_upgradable = TRUE

/obj/item/clothing/glasses/chameleon/meson
	vision_flags = SEE_TURFS
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE

/obj/item/clothing/glasses/hud/security/chameleon
	flash_protect = 1

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/glasses/hud/security/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/glasses
	chameleon_action.chameleon_name = "HUD"
	chameleon_action.chameleon_blacklist = list()
	chameleon_action.initialize_disguises()

/obj/item/clothing/glasses/hud/security/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/glasses/hud/security/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/clothing/glasses/hud/security/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/clothing/gloves/chameleon
	desc = "These gloves will protect the wearer from electric shock."
	name = "insulated gloves"
	icon_state = "yellow"
	item_state = "ygloves"

	resistance_flags = NONE
	armor = list("melee" = 10, "bullet" = 10, "laser" = 10, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/gloves/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/gloves
	chameleon_action.chameleon_name = "Gloves"
	chameleon_action.chameleon_blacklist = typecacheof(list(/obj/item/clothing/gloves, /obj/item/clothing/gloves/color), only_root_path = TRUE)
	chameleon_action.initialize_disguises()

/obj/item/clothing/gloves/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/gloves/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/clothing/gloves/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/clothing/head/chameleon
	name = "grey cap"
	desc = "It's a baseball hat in a tasteful grey colour."
	icon_state = "greysoft"
	item_color = "grey"

	resistance_flags = NONE
	armor = list("melee" = 5, "bullet" = 5, "laser" = 5, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)

	sprite_sheets = list(
		SPECIES_VOX = 'icons/mob/clothing/species/vox/head.dmi',
		SPECIES_MONKEY = 'icons/mob/clothing/species/monkey/head.dmi',
		SPECIES_FARWA = 'icons/mob/clothing/species/monkey/head.dmi',
		SPECIES_WOLPIN = 'icons/mob/clothing/species/monkey/head.dmi',
		SPECIES_NEARA = 'icons/mob/clothing/species/monkey/head.dmi',
		SPECIES_STOK = 'icons/mob/clothing/species/monkey/head.dmi'
	)

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/head/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/head
	chameleon_action.chameleon_name = "Hat"
	chameleon_action.chameleon_blacklist = list()
	chameleon_action.initialize_disguises()

/obj/item/clothing/head/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/head/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/clothing/head/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/clothing/mask/chameleon
	name = "gas mask"
	desc = "A face-covering mask that can be connected to an air supply. While good for concealing your identity, it isn't good for blocking gas flow." //More accurate
	icon_state = "gas_alt"
	item_state = "gas_alt"
	resistance_flags = NONE
	armor = list("melee" = 5, "bullet" = 5, "laser" = 5, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)
	clothing_flags = AIRTIGHT|BLOCK_GAS_SMOKE_EFFECT
	flags_inv = HIDEMASK|HIDEHEADSETS|HIDEGLASSES|HIDENAME
	gas_transfer_coefficient = 0.01
	permeability_coefficient = 0.01
	flags_cover = MASKCOVERSEYES | MASKCOVERSMOUTH

	sprite_sheets = list(
		SPECIES_VOX = 'icons/mob/clothing/species/vox/mask.dmi',
		SPECIES_UNATHI = 'icons/mob/clothing/species/unathi/mask.dmi',
		SPECIES_ASHWALKER_BASIC = 'icons/mob/clothing/species/unathi/mask.dmi',
		SPECIES_ASHWALKER_SHAMAN = 'icons/mob/clothing/species/unathi/mask.dmi',
		SPECIES_DRACONOID = 'icons/mob/clothing/species/unathi/mask.dmi',
		SPECIES_TAJARAN = 'icons/mob/clothing/species/tajaran/mask.dmi',
		SPECIES_VULPKANIN = 'icons/mob/clothing/species/vulpkanin/mask.dmi',
		SPECIES_DRASK = 'icons/mob/clothing/species/drask/mask.dmi',
		SPECIES_GREY = 'icons/mob/clothing/species/grey/mask.dmi',
		SPECIES_MONKEY = 'icons/mob/clothing/species/monkey/mask.dmi',
		SPECIES_FARWA = 'icons/mob/clothing/species/monkey/mask.dmi',
		SPECIES_WOLPIN = 'icons/mob/clothing/species/monkey/mask.dmi',
		SPECIES_NEARA = 'icons/mob/clothing/species/monkey/mask.dmi',
		SPECIES_STOK = 'icons/mob/clothing/species/monkey/mask.dmi'
	)

	var/obj/item/voice_changer/voice_changer

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/mask/chameleon/Initialize(mapload)
	. = ..()

	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/mask
	chameleon_action.chameleon_name = "Mask"
	chameleon_action.chameleon_blacklist = list()
	chameleon_action.initialize_disguises()

	voice_changer = new(src)

/obj/item/clothing/mask/chameleon/Destroy()
	QDEL_NULL(voice_changer)
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/mask/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/clothing/mask/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/clothing/shoes/chameleon
	name = "black shoes"
	icon_state = "black"
	item_color = "black"
	desc = "A pair of black shoes."
	permeability_coefficient = 0.05
	resistance_flags = NONE
	armor = list("melee" = 10, "bullet" = 10, "laser" = 10, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 50, "acid" = 50)

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/shoes/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/shoes
	chameleon_action.chameleon_name = "Shoes"
	chameleon_action.chameleon_blacklist = list()
	chameleon_action.initialize_disguises()

/obj/item/clothing/shoes/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/shoes/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/clothing/shoes/chameleon/noslip
	name = "black shoes"
	icon_state = "black"
	item_color = "black"
	desc = "A pair of black shoes."
	clothing_traits = list(TRAIT_NO_SLIP_WATER)

/obj/item/clothing/shoes/chameleon/noslip/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/storage/backpack/chameleon
	name = "backpack"

	sprite_sheets = list(
		SPECIES_VOX = 'icons/mob/clothing/species/vox/back.dmi'
	)

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/storage/backpack/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/storage/backpack
	chameleon_action.chameleon_name = "Backpack"
	chameleon_action.initialize_disguises()

/obj/item/storage/backpack/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/storage/backpack/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/storage/backpack/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/storage/belt/chameleon
	name = "toolbelt"
	desc = "Holds tools."
	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/storage/belt/chameleon/Initialize(mapload)
	. = ..()

	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/storage/belt
	chameleon_action.chameleon_name = "Belt"
	chameleon_action.initialize_disguises()

/obj/item/storage/belt/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/storage/belt/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/storage/belt/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/radio/headset/chameleon
	name = "radio headset"
	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/radio/headset/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/radio/headset
	chameleon_action.chameleon_name = "Headset"
	chameleon_action.initialize_disguises()

/obj/item/radio/headset/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/radio/headset/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/radio/headset/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/pda/chameleon
	name = "PDA"
	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/pda/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/pda
	chameleon_action.chameleon_name = "PDA"
	chameleon_action.chameleon_blacklist = typecacheof(list(/obj/item/pda/heads), only_root_path = TRUE)
	chameleon_action.initialize_disguises()

/obj/item/pda/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/pda/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/pda/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/stamp/chameleon
	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/stamp/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/stamp
	chameleon_action.chameleon_name = "Stamp"
	chameleon_action.initialize_disguises()

/obj/item/stamp/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/stamp/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/clothing/under/plasmaman/chameleon
	name = "plasma envirosuit"
	desc = "A special containment suit that allows plasma-based lifeforms to exist safely in an oxygenated environment, and automatically extinguishes them in a crisis. Despite being airtight, it's not spaceworthy."
	armor = list("melee" = 10, "bullet" = 10, "laser" = 10, "energy" = 0, "bomb" = 0, "bio" = 100, "rad" = 0, "fire" = 95, "acid" = 95)
	sensor_mode = SENSOR_OFF
	random_sensor = FALSE

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/under/plasmaman/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/under
	chameleon_action.chameleon_name = "Envirosuit"
	chameleon_action.chameleon_blacklist = typecacheof(list(/obj/item/clothing/under, /obj/item/clothing/under/color, /obj/item/clothing/under/rank), only_root_path = TRUE)
	chameleon_action.initialize_disguises()

/obj/item/clothing/under/plasmaman/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/under/plasmaman/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/clothing/under/plasmaman/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)

/obj/item/clothing/head/helmet/space/plasmaman/chameleon
	gas_transfer_coefficient = 0.01
	permeability_coefficient = 0.01
	armor = list("melee" = 30, "bullet" = 20, "laser" = 20, "energy" = 20, "bomb" = 20, "bio" = 100, "rad" = 0, "fire" = 100, "acid" = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	actions_types = null

	var/datum/action/item_action/chameleon/change/chameleon_action

/obj/item/clothing/head/helmet/space/plasmaman/chameleon/Initialize(mapload)
	. = ..()
	chameleon_action = new(src)
	chameleon_action.chameleon_type = /obj/item/clothing/head
	chameleon_action.chameleon_name = "Envirohelm"
	chameleon_action.chameleon_blacklist = list()
	chameleon_action.initialize_disguises()

/obj/item/clothing/head/helmet/space/plasmaman/chameleon/Destroy()
	QDEL_NULL(chameleon_action)
	return ..()

/obj/item/clothing/head/helmet/space/plasmaman/chameleon/emp_act(severity)
	. = ..()
	chameleon_action.emp_randomise()

/obj/item/clothing/head/helmet/space/plasmaman/chameleon/broken/Initialize(mapload)
	. = ..()
	chameleon_action.emp_randomise(INFINITY)
