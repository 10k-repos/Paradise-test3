#define VEST_STEALTH 1
#define VEST_COMBAT 2
#define GIZMO_SCAN 1
#define GIZMO_MARK 2
#define MIND_DEVICE_MESSAGE 1
#define MIND_DEVICE_CONTROL 2

//AGENT VEST
/obj/item/clothing/suit/armor/abductor/vest
	name = "agent vest"
	desc = "A vest outfitted with advanced stealth technology. It has two modes - combat and stealth."
	icon = 'icons/obj/abductor.dmi'
	icon_state = "vest_stealth"
	item_state = "armor"
	blood_overlay_type = "armor"
	origin_tech = "magnets=7;biotech=4;powerstorage=4;abductor=4"
	armor = list("melee" = 15, "bullet" = 15, "laser" = 15, "energy" = 15, "bomb" = 15, "bio" = 15, "rad" = 15, "fire" = 70, "acid" = 70)
	actions_types = list(/datum/action/item_action/hands_free/activate)
	allowed = list(/obj/item/abductor, /obj/item/abductor_baton, /obj/item/melee/baton, /obj/item/gun/energy, /obj/item/restraints/handcuffs)
	var/mode = VEST_STEALTH
	var/stealth_active = 0
	var/combat_cooldown = 10
	var/datum/icon_snapshot/disguise
	var/stealth_armor = list("melee" = 15, "bullet" = 15, "laser" = 15, "energy" = 15, "bomb" = 15, "bio" = 15, "rad" = 15, "fire" = 70, "acid" = 70)
	var/combat_armor = list("melee" = 50, "bullet" = 50, "laser" = 50, "energy" = 50, "bomb" = 50, "bio" = 50, "rad" = 50, "fire" = 90, "acid" = 90)
	sprite_sheets = null

/obj/item/clothing/suit/armor/abductor/vest/Initialize(mapload)
	. = ..()
	stealth_armor = getArmor(arglist(stealth_armor))
	combat_armor = getArmor(arglist(combat_armor))


/obj/item/clothing/suit/armor/abductor/vest/proc/toggle_nodrop()
	var/prev_has = HAS_TRAIT_FROM(src, TRAIT_NODROP, ABDUCTOR_VEST_TRAIT)
	if(prev_has)
		REMOVE_TRAIT(src, TRAIT_NODROP, ABDUCTOR_VEST_TRAIT)
	else
		ADD_TRAIT(src, TRAIT_NODROP, ABDUCTOR_VEST_TRAIT)
	if(ismob(loc))
		to_chat(loc, span_notice("Your vest is now [prev_has ? "unlocked" : "locked"]."))


/obj/item/clothing/suit/armor/abductor/vest/update_icon_state()
	switch(mode)
		if(VEST_STEALTH)
			icon_state = "vest_stealth"
		if(VEST_COMBAT)
			icon_state = "vest_combat"


/obj/item/clothing/suit/armor/abductor/vest/proc/flip_mode()
	switch(mode)
		if(VEST_STEALTH)
			mode = VEST_COMBAT
			DeactivateStealth()
			armor = combat_armor
		if(VEST_COMBAT)// TO STEALTH
			mode = VEST_STEALTH
			armor = stealth_armor
	update_icon(UPDATE_ICON_STATE)
	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		H.update_inv_wear_suit()
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/item/clothing/suit/armor/abductor/vest/item_action_slot_check(slot, mob/user)
	if(slot == ITEM_SLOT_CLOTH_OUTER) //we only give the mob the ability to activate the vest if he's actually wearing it.
		return TRUE

/obj/item/clothing/suit/armor/abductor/vest/proc/SetDisguise(datum/icon_snapshot/entry)
	disguise = entry

/obj/item/clothing/suit/armor/abductor/vest/proc/ActivateStealth()
	if(disguise == null)
		return
	stealth_active = 1
	if(ishuman(loc))
		var/mob/living/carbon/human/M = loc
		new /obj/effect/temp_visual/dir_setting/ninja/cloak(get_turf(M), M.dir)
		M.name_override = disguise.name
		M.icon = disguise.icon
		M.icon_state = disguise.icon_state
		M.cut_overlays()
		M.add_overlay(disguise.overlays)
		M.update_inv_hands()

/obj/item/clothing/suit/armor/abductor/vest/proc/DeactivateStealth()
	if(!stealth_active)
		return
	stealth_active = 0
	if(ishuman(loc))
		var/mob/living/carbon/human/M = loc
		new /obj/effect/temp_visual/dir_setting/ninja(get_turf(M), M.dir)
		M.name_override = null
		M.regenerate_icons()

/obj/item/clothing/suit/armor/abductor/vest/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	DeactivateStealth()

/obj/item/clothing/suit/armor/abductor/vest/IsReflect()
	DeactivateStealth()
	return 0

/obj/item/clothing/suit/armor/abductor/vest/ui_action_click()
	switch(mode)
		if(VEST_COMBAT)
			Adrenaline()
		if(VEST_STEALTH)
			if(stealth_active)
				DeactivateStealth()
			else
				ActivateStealth()

/obj/item/clothing/suit/armor/abductor/vest/proc/Adrenaline()
	if(ishuman(loc))
		if(combat_cooldown != initial(combat_cooldown))
			to_chat(loc, "<span class='warning'>Combat injection is still recharging.</span>")
			return
		var/mob/living/carbon/human/M = loc
		M.adjustStaminaLoss(-75)
		M.SetParalysis(0)
		M.SetStunned(0)
		M.SetWeakened(0)
		combat_cooldown = 0
		START_PROCESSING(SSobj, src)

/obj/item/clothing/suit/armor/abductor/vest/process()
	combat_cooldown++
	if(combat_cooldown==initial(combat_cooldown))
		STOP_PROCESSING(SSobj, src)

/obj/item/clothing/suit/armor/abductor/Destroy()
	STOP_PROCESSING(SSobj, src)
	for(var/obj/machinery/abductor/console/C in GLOB.machines)
		if(C.vest == src)
			C.vest = null
			break
	return ..()

/obj/item/abductor
	icon = 'icons/obj/abductor.dmi'

/obj/item/abductor/proc/AbductorCheck(user)
	if(isabductor(user))
		return TRUE
	to_chat(user, "<span class='warning'>You can't figure how this works!</span>")
	return FALSE

/obj/item/abductor/proc/ScientistCheck(user)
	if(!AbductorCheck(user))
		return FALSE

	var/mob/living/carbon/human/H = user
	var/datum/species/abductor/S = H.dna.species
	if(S.scientist)
		return TRUE
	to_chat(user, "<span class='warning'>You're not trained to use this!</span>")
	return FALSE

/obj/item/abductor/gizmo
	name = "science tool"
	desc = "A dual-mode tool for retrieving specimens and scanning appearances. Scanning can be done through cameras."
	icon_state = "gizmo_scan"
	item_state = "gizmo"
	origin_tech = "engineering=7;magnets=4;bluespace=4;abductor=3"
	var/mode = GIZMO_SCAN
	var/mob/living/marked = null
	var/obj/machinery/abductor/console/console


/obj/item/abductor/gizmo/update_icon_state()
	switch(mode)
		if(GIZMO_SCAN)
			icon_state = "gizmo_scan"
		if(GIZMO_MARK)
			icon_state = "gizmo_mark"


/obj/item/abductor/gizmo/attack_self(mob/user)
	if(!ScientistCheck(user))
		return
	if(!console)
		to_chat(user, "<span class='warning'>The device is not linked to a console!</span>")
		return

	if(mode == GIZMO_SCAN)
		mode = GIZMO_MARK
	else
		mode = GIZMO_SCAN
	update_icon(UPDATE_ICON_STATE)
	to_chat(user, "<span class='notice'>You switch the device to [mode==GIZMO_SCAN? "SCAN": "MARK"] MODE</span>")

/obj/item/abductor/gizmo/attack(mob/living/M, mob/user)
	if(!ScientistCheck(user))
		return
	if(!console)
		to_chat(user, "<span class='warning'>The device is not linked to console!</span>")
		return

	switch(mode)
		if(GIZMO_SCAN)
			scan(M, user)
		if(GIZMO_MARK)
			mark(M, user)


/obj/item/abductor/gizmo/afterattack(atom/target, mob/living/user, flag, params)
	if(flag)
		return
	if(!ScientistCheck(user))
		return
	if(!console)
		to_chat(user, "<span class='warning'>The device is not linked to console!</span>")
		return

	switch(mode)
		if(GIZMO_SCAN)
			scan(target, user)
		if(GIZMO_MARK)
			mark(target, user)

/obj/item/abductor/gizmo/proc/scan(atom/target, mob/living/user)
	if(ishuman(target))
		console.AddSnapshot(target)
		to_chat(user, "<span class='notice'>You scan [target] and add [target.p_them()] to the database.</span>")

/obj/item/abductor/gizmo/proc/mark(atom/target, mob/living/user)
	if(marked == target)
		to_chat(user, "<span class='warning'>This specimen is already marked!</span>")
		return
	if(ishuman(target))
		if(isabductor(target))
			marked = target
			to_chat(user, "<span class='notice'>You mark [target] for future retrieval.</span>")
		else
			prepare(target,user)
	else
		prepare(target,user)

/obj/item/abductor/gizmo/proc/prepare(atom/target, mob/living/user)
	if(get_dist(target,user)>1)
		to_chat(user, "<span class='warning'>You need to be next to the specimen to prepare it for transport!</span>")
		return
	to_chat(user, "<span class='notice'>You begin preparing [target] for transport...</span>")
	if(do_after(user, 10 SECONDS, target))
		marked = target
		to_chat(user, "<span class='notice'>You finish preparing [target] for transport.</span>")

/obj/item/abductor/gizmo/Destroy()
	if(console)
		console.gizmo = null
	return ..()


/obj/item/abductor/silencer
	name = "abductor silencer"
	desc = "A compact device used to shut down communications equipment."
	icon_state = "silencer"
	item_state = "silencer"
	origin_tech = "materials=4;programming=7;abductor=3"

/obj/item/abductor/silencer/attack(mob/living/M, mob/user)
	if(!AbductorCheck(user))
		return
	radio_off(M, user)

/obj/item/abductor/silencer/afterattack(atom/target, mob/living/user, flag, params)
	if(flag)
		return
	if(!AbductorCheck(user))
		return
	radio_off(target, user)

/obj/item/abductor/silencer/proc/radio_off(atom/target, mob/living/user)
	if(!(user in (viewers(7, target))))
		return

	var/turf/targloc = get_turf(target)

	var/mob/living/carbon/human/M
	for(M in view(2,targloc))
		if(M == user)
			continue
		to_chat(user, "<span class='notice'>You silence [M]'s radio devices.</span>")
		radio_off_mob(M)

/obj/item/abductor/silencer/proc/radio_off_mob(mob/living/carbon/human/M)
	var/list/all_items = M.GetAllContents()

	for(var/obj/I in all_items)
		if(isradio(I))
			var/obj/item/radio/R = I
			R.listening = 0 // Prevents the radio from buzzing due to the EMP, preserving possible stealthiness.
			R.emp_act(1)

/obj/item/abductor/mind_device
	name = "mental interface device"
	desc = "A dual-mode tool for directly communicating with sentient brains. It can be used to send a direct message to a target, or to send a command to a test subject with a charged gland."
	icon_state = "mind_device_message"
	item_state = "silencer"
	var/mode = MIND_DEVICE_MESSAGE


/obj/item/abductor/mind_device/update_icon_state()
	switch(mode)
		if(MIND_DEVICE_MESSAGE)
			icon_state = "mind_device_message"
		if(MIND_DEVICE_CONTROL)
			icon_state = "mind_device_control"


/obj/item/abductor/mind_device/attack_self(mob/user)
	if(!ScientistCheck(user))
		return

	if(mode == MIND_DEVICE_MESSAGE)
		mode = MIND_DEVICE_CONTROL
	else
		mode = MIND_DEVICE_MESSAGE
	update_icon(UPDATE_ICON_STATE)
	to_chat(user, "<span class='notice'>You switch the device to [mode == MIND_DEVICE_MESSAGE ? "TRANSMISSION" : "COMMAND"] MODE</span>")

/obj/item/abductor/mind_device/afterattack(atom/target, mob/living/user, flag, params)
	if(!ScientistCheck(user))
		return

	switch(mode)
		if(MIND_DEVICE_CONTROL)
			mind_control(target, user)
		if(MIND_DEVICE_MESSAGE)
			mind_message(target, user)

/obj/item/abductor/mind_device/proc/mind_control(atom/target, mob/living/user)
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		var/obj/item/organ/internal/heart/gland/G = C.get_organ_slot(INTERNAL_ORGAN_HEART)
		if(!istype(G))
			to_chat(user, "<span class='warning'>Your target does not have an experimental gland!</span>")
			return
		if(!G.mind_control_uses)
			to_chat(user, "<span class='warning'>Your target's gland is spent!</span>")
			return
		if(G.active_mind_control)
			to_chat(user, "<span class='warning'>Your target is already under a mind-controlling influence!</span>")
			return

		var/command = stripped_input(user, "Enter the command for your target to follow. Uses Left: [G.mind_control_uses], Duration: [DisplayTimeText(G.mind_control_duration)]", "Enter command")

		if(!command)
			return

		if(QDELETED(user) || user.get_active_hand() != src || loc != user)
			return

		if(QDELETED(G))
			return

		G.mind_control(command, user)
		to_chat(user, "<span class='notice'>You send the command to your target.</span>")

/obj/item/abductor/mind_device/proc/mind_message(atom/target, mob/living/user)
	if(isliving(target))
		var/mob/living/L = target
		if(L.stat == DEAD)
			to_chat(user, "<span class='warning'>Your target is dead!</span>")
			return
		var/message = stripped_input(user, "Write a message to send to your target's brain.", "Enter message")
		if(!message)
			return
		if(QDELETED(L) || L.stat == DEAD)
			return

		to_chat(L, "<span class='italics'>You hear a voice in your head saying: </span><span class='abductor'>[message]</span>")
		to_chat(user, "<span class='notice'>You send the message to your target.</span>")
		add_say_logs(user, message, L, "Mind device")

/obj/item/gun/energy/alien
	name = "alien pistol"
	desc = "A complicated gun that fires bursts of high-intensity radiation."
	ammo_type = list(/obj/item/ammo_casing/energy/declone)
	restricted_species = list(/datum/species/abductor)
	icon_state = "alienpistol"
	item_state = "alienpistol"
	origin_tech = "combat=4;magnets=7;powerstorage=3;abductor=3"
	trigger_guard = TRIGGER_GUARD_ALLOW_ALL

/obj/item/paper/abductor
	name = "Dissection Guide"
	icon_state = "alienpaper_words"
	info = {"<b>Dissection for Dummies</b><br>
<br>
 1.Acquire fresh specimen.<br>
 2.Put the specimen on operating table.<br>
 3.Apply scalpel to the chest, preparing for experimental dissection.<br>
 4.Apply scalpel to specimen's torso.<br>
 5.Clamp bleeders on specimen's torso with a hemostat.<br>
 6.Retract skin of specimen's torso with a retractor.<br>
 7.Saw through the specimen's torso with a saw.<br>
 8.Apply retractor again to specimen's torso.<br>
 9.Search through the specimen's torso with your hands to remove any superfluous organs.<br>
 10.Insert replacement gland (Retrieve one from gland storage).<br>
 11.Apply bone gel to mend the ribcage.<br>
 12.Use the bone setter to finish mending the ribcage.<br>
 13.Apply bone gel to mend the ribcage once more.<br>
 14.Cauterize the patient's torso with a cautery.<br>
 15.Consider dressing the specimen back to not disturb the habitat.<br>
 16.Put the specimen in the experiment machinery.<br>
 17.Choose one of the machine options. The target will be analyzed and teleported to the selected drop-off point.<br>
 18.You will receive one supply credit, and the subject will be counted towards your quota.<br>
<br>
Congratulations! You are now trained for invasive xenobiology research!"}

/obj/item/paper/abductor/update_icon_state()
	return

/obj/item/paper/abductor/AltClick()
	return

#define BATON_STUN 0
#define BATON_SLEEP 1
#define BATON_CUFF 2
#define BATON_PROBE 3
#define BATON_MODES 4

/obj/item/abductor_baton
	name = "advanced baton"
	desc = "A quad-mode baton used for incapacitation and restraining of specimens."
	var/mode = BATON_STUN
	icon = 'icons/obj/abductor.dmi'
	icon_state = "wonderprodStun"
	item_state = "wonderprod"
	slot_flags = ITEM_SLOT_BELT
	origin_tech = "materials=4;combat=4;biotech=7;abductor=4"
	force = 7
	w_class = WEIGHT_CLASS_NORMAL
	actions_types = list(/datum/action/item_action/toggle_mode)

/obj/item/abductor_baton/proc/toggle(mob/living/user = usr)
	mode = (mode+1)%BATON_MODES
	var/txt
	switch(mode)
		if(BATON_STUN)
			txt = "stunning"
		if(BATON_SLEEP)
			txt = "sleep inducement"
		if(BATON_CUFF)
			txt = "restraining"
		if(BATON_PROBE)
			txt = "probing"

	to_chat(usr, "<span class='notice'>You switch the baton to [txt] mode.</span>")
	update_icon(UPDATE_ICON_STATE)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/item/abductor_baton/update_icon_state()
	switch(mode)
		if(BATON_STUN)
			icon_state = "wonderprodStun"
			item_state = "wonderprodStun"
		if(BATON_SLEEP)
			icon_state = "wonderprodSleep"
			item_state = "wonderprodSleep"
		if(BATON_CUFF)
			icon_state = "wonderprodCuff"
			item_state = "wonderprodCuff"
		if(BATON_PROBE)
			icon_state = "wonderprodProbe"
			item_state = "wonderprodProbe"

/obj/item/abductor_baton/attack(mob/target, mob/living/user)
	if(!isabductor(user))
		return

	if(isrobot(target))
		..()
		return

	if(!isliving(target))
		return

	var/mob/living/L = target

	user.do_attack_animation(L)

	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		if(H.check_shields(src, 0, "[user]'s [name]", MELEE_ATTACK))
			playsound(L, 'sound/weapons/genhit.ogg', 50, 1)
			return 0

	switch(mode)
		if(BATON_STUN)
			StunAttack(L,user)
		if(BATON_SLEEP)
			SleepAttack(L,user)
		if(BATON_CUFF)
			CuffAttack(L,user)
		if(BATON_PROBE)
			ProbeAttack(L,user)

/obj/item/abductor_baton/attack_self(mob/living/user)
	toggle(user)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.update_inv_l_hand()
		H.update_inv_r_hand()

/obj/item/abductor_baton/proc/StunAttack(mob/living/L,mob/living/user)
	L.lastattacker = user.real_name
	L.lastattackerckey = user.ckey

	L.Weaken(14 SECONDS)
	L.Stun(14 SECONDS)
	L.Stuttering(14 SECONDS)

	L.visible_message("<span class='danger'>[user] has stunned [L] with [src]!</span>", \
							"<span class='userdanger'>[user] has stunned you with [src]!</span>")
	playsound(loc, 'sound/weapons/egloves.ogg', 50, 1, -1)

	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		H.forcesay(GLOB.hit_appends)

	add_attack_logs(user, L, "Stunned with [src]")

/obj/item/abductor_baton/proc/SleepAttack(mob/living/L,mob/living/user)
	if(HAS_TRAIT(L, TRAIT_INCAPACITATED))
		L.visible_message("<span class='danger'>[user] has induced sleep in [L] with [src]!</span>", \
							"<span class='userdanger'>You suddenly feel very drowsy!</span>")
		playsound(loc, 'sound/weapons/egloves.ogg', 50, 1, -1)
		L.Sleeping(120 SECONDS)
		add_attack_logs(user, L, "Put to sleep with [src]")
	else
		L.AdjustDrowsy(2 SECONDS)
		to_chat(user, "<span class='warning'>Sleep inducement works fully only on stunned specimens!</span>")
		L.visible_message("<span class='danger'>[user] tried to induce sleep in [L] with [src]!</span>", \
							"<span class='userdanger'>You suddenly feel drowsy!</span>")

/obj/item/abductor_baton/proc/CuffAttack(mob/living/L,mob/living/user)
	if(!iscarbon(L))
		return
	var/mob/living/carbon/C = L
	if(C.has_organ_for_slot(ITEM_SLOT_HANDCUFFED) && !C.handcuffed)
		playsound(loc, 'sound/weapons/cablecuff.ogg', 30, 1, -2)
		C.visible_message("<span class='danger'>[user] begins restraining [C] with [src]!</span>", \
								"<span class='userdanger'>[user] begins shaping an energy field around your hands!</span>")
		if(do_after(user, 3 SECONDS, C, NONE))
			if(C.handcuffed)
				return

			C.apply_restraints(new /obj/item/restraints/handcuffs/cable/zipties/used(null), ITEM_SLOT_HANDCUFFED, TRUE)

			to_chat(user, "<span class='notice'>You handcuff [C].</span>")
			add_attack_logs(user, C, "Handcuffed ([src])")
		else
			to_chat(user, "<span class='warning'>You fail to handcuff [C].</span>")

/obj/item/abductor_baton/proc/ProbeAttack(mob/living/L,mob/living/user)
	L.visible_message("<span class='danger'>[user] probes [L] with [src]!</span>", \
						"<span class='userdanger'>[user] probes you!</span>")

	var/species = "<span class='warning'>Unknown species</span>"
	var/helptext = "<span class='warning'>Species unsuitable for experiments.</span>"

	if(ishuman(L))
		var/mob/living/carbon/human/H = L
		species = "<span clas=='notice'>[H.dna.species.name]</span>"
		if(ischangeling(L))
			species = "<span class='warning'>Changeling lifeform</span>"
		var/obj/item/organ/internal/heart/gland/temp = locate() in H.internal_organs
		if(temp)
			helptext = "<span class='warning'>Experimental gland detected!</span>"
		else
			helptext = "<span class='notice'>Subject suitable for experiments.</span>"

	to_chat(user,"<span class='notice'>Probing result: </span>[species]")
	to_chat(user, "[helptext]")

/obj/item/restraints/handcuffs/energy
	name = "hard-light energy field"
	desc = "A hard-light field restraining the hands."
	icon_state = "cuff_white" // Needs sprite
	breakouttime = 450
	trashtype = /obj/item/restraints/handcuffs/energy/used
	origin_tech = "materials=4;magnets=5;abductor=2"

/obj/item/restraints/handcuffs/energy/used
	desc = "energy discharge"
	item_flags = DROPDEL

/obj/item/restraints/handcuffs/energy/used/dropped(mob/user, slot, silent = FALSE)
	user.visible_message("<span class='danger'>[src] restraining [user] breaks in a discharge of energy!</span>", \
							"<span class='userdanger'>[src] restraining [user] breaks in a discharge of energy!</span>")
	do_sparks(4, 0, user.loc)
	. = ..()

/obj/item/abductor_baton/examine(mob/user)
	. = ..()
	switch(mode)
		if(BATON_STUN)
			. += "<span class='notice'>The baton is in stun mode.</span>"
		if(BATON_SLEEP)
			. += "<span class='notice'>The baton is in sleep inducement mode.</span>"
		if(BATON_CUFF)
			. += "<span class='notice'>The baton is in restraining mode.</span>"
		if(BATON_PROBE)
			. += "<span class='notice'>The baton is in probing mode.</span>"

/obj/item/radio/headset/abductor
	name = "alien headset"
	desc = "An advanced alien headset designed to monitor communications of human space stations. Why does it have a microphone? No one knows."
	item_flags = BANGPROTECT_MINOR
	origin_tech = "magnets=2;abductor=3"
	icon = 'icons/obj/abductor.dmi'
	icon_state = "abductor_headset"
	item_state = "abductor_headset"
	ks2type = /obj/item/encryptionkey/heads/captain

/obj/item/radio/headset/abductor/New()
	..()
	make_syndie()

/obj/item/radio/headset/abductor/screwdriver_act()
	return// Stops humans from disassembling abductor headsets.

/obj/item/scalpel/alien
	name = "alien scalpel"
	desc = "It's a gleaming sharp knife made out of silvery-green metal."
	icon = 'icons/obj/abductor.dmi'
	origin_tech = "materials=2;biotech=2;abductor=2"
	toolspeed = 0.25

/obj/item/hemostat/alien
	name = "alien hemostat"
	desc = "You've never seen this before."
	icon = 'icons/obj/abductor.dmi'
	origin_tech = "materials=2;biotech=2;abductor=2"
	toolspeed = 0.25

/obj/item/retractor/alien
	name = "alien retractor"
	desc = "You're not sure if you want the veil pulled back."
	icon = 'icons/obj/abductor.dmi'
	origin_tech = "materials=2;biotech=2;abductor=2"
	toolspeed = 0.25

/obj/item/circular_saw/alien
	name = "alien saw"
	desc = "Do the aliens also lose this, and need to find an alien hatchet?"
	icon = 'icons/obj/abductor.dmi'
	item_state = "alien_saw"
	origin_tech = "materials=2;biotech=2;abductor=2"
	toolspeed = 0.25

/obj/item/surgicaldrill/alien
	name = "alien drill"
	desc = "Maybe alien surgeons have finally found a use for the drill."
	icon = 'icons/obj/abductor.dmi'
	origin_tech = "materials=2;biotech=2;abductor=2"
	toolspeed = 0.25

/obj/item/cautery/alien
	name = "alien cautery"
	desc = "Why would bloodless aliens have a tool to stop bleeding? Unless..."
	icon = 'icons/obj/abductor.dmi'
	origin_tech = "materials=2;biotech=2;abductor=2"
	toolspeed = 0.25

/obj/item/bonegel/alien
	name = "alien bone gel"
	desc = "It smells like duct tape."
	icon = 'icons/obj/abductor.dmi'
	origin_tech = "materials=2;biotech=2;abductor=2"
	toolspeed = 0.25

/obj/item/FixOVein/alien
	name = "alien FixOVein"
	desc = "Bloodless aliens would totally know how to stop internal bleeding...right?"
	icon = 'icons/obj/abductor.dmi'
	origin_tech = "materials=2;biotech=2;abductor=2"
	toolspeed = 0.25

/obj/item/bonesetter/alien
	name = "alien bone setter"
	desc = "You're not sure you want to know whether or not aliens have bones."
	icon = 'icons/obj/abductor.dmi'
	origin_tech = "materials=2;biotech=2;abductor=2"
	toolspeed = 0.25

/obj/item/clothing/head/helmet/abductor
	name = "agent headgear"
	desc = "Abduct with style - spiky style. Prevents digital tracking."
	icon_state = "alienhelmet"
	item_state = "alienhelmet"
	blockTracking = 1
	origin_tech = "materials=7;magnets=4;abductor=3"
	flags_inv = HIDEMASK|HIDEHEADSETS|HIDEGLASSES|HIDENAME|HIDEHAIR
	flags_cover = HEADCOVERSMOUTH|HEADCOVERSEYES

// Operating Table / Beds / Lockers

/obj/structure/bed/abductor
	name = "resting contraption"
	desc = "This looks similar to contraptions from earth. Could aliens be stealing our technology?"
	icon = 'icons/obj/abductor.dmi'
	buildstacktype = /obj/item/stack/sheet/mineral/abductor
	icon_state = "bed"

/obj/structure/table_frame/abductor
	name = "alien table frame"
	desc = "A sturdy table frame made from alien alloy."
	icon_state = "alien_frame"
	framestack = /obj/item/stack/sheet/mineral/abductor
	framestackamount = 1
	density = TRUE

/obj/structure/table_frame/abductor/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/mineral/abductor))
		var/obj/item/stack/sheet/P = I
		if(P.get_amount() < 1)
			to_chat(user, "<span class='warning'>You need one alien alloy sheet to do this!</span>")
			return
		to_chat(user, "<span class='notice'>You start adding [P] to [src]...</span>")
		if(do_after(user, 5 SECONDS, src))
			P.use(1)
			new /obj/structure/table/abductor(loc)
			qdel(src)
		return
	if(istype(I, /obj/item/stack/sheet/mineral/silver))
		var/obj/item/stack/sheet/P = I
		if(P.get_amount() < 1)
			to_chat(user, "<span class='warning'>You need one sheet of silver to do	this!</span>")
			return
		to_chat(user, "<span class='notice'>You start adding [P] to [src]...</span>")
		if(do_after(user, 5 SECONDS, src))
			P.use(1)
			new /obj/machinery/optable/abductor(loc)
			qdel(src)
		return
	return ..()

/obj/structure/table/abductor
	name = "alien table"
	desc = "Advanced flat surface technology at work!"
	icon = 'icons/obj/smooth_structures/alien_table.dmi'
	icon_state = "alien_table"
	buildstack = /obj/item/stack/sheet/mineral/abductor
	framestack = /obj/item/stack/sheet/mineral/abductor
	buildstackamount = 1
	framestackamount = 1
	canSmoothWith = null
	can_be_flipped = FALSE
	frame = /obj/structure/table_frame/abductor

/obj/machinery/optable/abductor
	icon = 'icons/obj/abductor.dmi'
	icon_state = "bed"
	no_icon_updates = 1 //no icon updates for this; it's static.
	injected_reagents = list("corazone","spaceacillin")
	reagent_target_amount = 31 //the patient needs at least 30u of spaceacillin to prevent necrotization.
	inject_amount = 10

/obj/structure/closet/abductor
	name = "alien locker"
	desc = "Contains secrets of the universe."
	icon_state = "abductor"
	material_drop = /obj/item/stack/sheet/mineral/abductor
	material_drop_amount = 1

/obj/structure/door_assembly/door_assembly_abductor
	name = "alien airlock assembly"
	icon = 'icons/obj/doors/airlocks/abductor/abductor_airlock.dmi'
	base_name = "alien airlock"
	overlays_file = 'icons/obj/doors/airlocks/abductor/overlays.dmi'
	airlock_type = /obj/machinery/door/airlock/abductor
	material_type = /obj/item/stack/sheet/mineral/abductor
	noglass = TRUE

/obj/item/reagent_containers/applicator/abductor
	name = "alien mender"
	desc = "Hidden behind a high-tech look is a time-tested mechanism"
	origin_tech = "materials=2;biotech=3;abductor=2"
	icon_state = "alien_mender_empty"
	item_state = "alien_mender"
	icon = 'icons/obj/abductor.dmi'
	emagged = TRUE
	ignore_flags = TRUE
	var/base_icon = "alien_mender_brute"

/obj/item/reagent_containers/applicator/abductor/update_icon_state()
	var/reag_pct = round((reagents.total_volume / volume) * 100)
	switch(reag_pct)
		if(51 to 100)
			icon_state = "[base_icon]_full[applying ? "_active" : ""]"
		if(1 to 50)
			icon_state = "[base_icon][applying ? "_active" : ""]"
		if(0)
			icon_state = "alien_mender_empty"

/obj/item/reagent_containers/applicator/abductor/brute
	name = "alien brute mender"
	base_icon = "alien_mender_brute"
	list_reagents = list("styptic_powder" = 200)

/obj/item/reagent_containers/applicator/abductor/burn
	name = "alien burn mender"
	base_icon = "alien_mender_burn"
	list_reagents = list("silver_sulfadiazine" = 200)

/obj/item/reagent_containers/glass/bottle/abductor
	name = "alien bottle"
	desc = "A durable bottle, made from alien alloy"
	icon = 'icons/obj/abductor.dmi'
	origin_tech = "materials=4"
	icon_state = "alien_bottle"
	item_state = "alien_bottle"
	volume = 50

/obj/item/reagent_containers/glass/bottle/abductor/rezadone
	name = "rezadone bottle"
	list_reagents = list("rezadone" = 50)

/obj/item/reagent_containers/glass/bottle/abductor/epinephrine
	name = "epinephrine bottle"
	list_reagents = list("epinephrine" = 50)

/obj/item/reagent_containers/glass/bottle/abductor/salgu
	name = "saline-glucose solution bottle"
	list_reagents = list("salglu_solution" = 50)

/obj/item/reagent_containers/glass/bottle/abductor/oculine
	name = "oculine bottle"
	list_reagents = list("oculine" = 50)

/obj/item/reagent_containers/glass/bottle/abductor/pen_acid
	name = "pentetic acid bottle"
	list_reagents = list("pen_acid" = 50)

/obj/item/healthanalyzer/abductor
	name = "alien health analyzer"
	icon = 'icons/obj/abductor.dmi'
	origin_tech = "materials=4;biotech=4;abductor=2"
	advanced = TRUE
	icon_state = "alien_hscanner"
	item_state = "alien_hscanner"
	desc = "Why its interface looks so familiar?"

/obj/item/storage/firstaid_abductor
	name = "alien medkit"
	desc = "Kit that contains some advanced alien medicine. Keep it away from alien-kids"
	icon = 'icons/obj/abductor.dmi'
	icon_state = "alien_medkit"
	item_state = "alien_medkit"
	throw_speed = 2
	throw_range = 8

/obj/item/storage/firstaid_abductor/populate_contents()
	new /obj/item/reagent_containers/applicator/abductor/brute(src)
	new /obj/item/reagent_containers/applicator/abductor/burn(src)
	new /obj/item/reagent_containers/glass/bottle/abductor/rezadone(src)
	new /obj/item/reagent_containers/glass/bottle/abductor/epinephrine(src)
	new /obj/item/reagent_containers/glass/bottle/abductor/salgu(src)
	new /obj/item/reagent_containers/glass/bottle/abductor/oculine(src)
	new /obj/item/reagent_containers/glass/bottle/abductor/pen_acid(src)

/obj/item/clothing/gloves/abductor_agent
	desc = "These gloves seems to protect the wearer from electric shock."
	name = "high-tech insulated gloves"
	icon = 'icons/obj/abductor.dmi'
	icon_state = "gloves_agent"
	item_state = "abductor_gloves_agent"
	siemens_coefficient = 0
	permeability_coefficient = 0.05
	resistance_flags = NONE

/obj/item/clothing/gloves/abductor_science
	name = "high-tech science gloves"
	desc = "High-tech sterile gloves that are stronger than latex."
	icon = 'icons/obj/abductor.dmi'
	icon_state = "gloves_science"
	item_state = "abductor_gloves_science"
	siemens_coefficient = 0.30
	permeability_coefficient = 0.01
	resistance_flags = NONE
