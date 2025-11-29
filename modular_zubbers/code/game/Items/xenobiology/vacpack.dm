/obj/item/xenobio_vacpack
	name = "slime vacpack"
	desc = "Slime rancher time"
	icon = 'icons/obj/service/hydroponics/equipment.dmi'
	icon_state = "waterbackpackatmos"
	inhand_icon_state = "waterbackpackatmos"
	lefthand_file = 'icons/mob/inhands/equipment/backpack_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/backpack_righthand.dmi'
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BACK
	slowdown = 1
	actions_types = list(/datum/action/item_action/toggle_mister)
	max_integrity = 200
	armor_type = /datum/armor/item_watertank
	resistance_flags = FIRE_PROOF
	interaction_flags_mouse_drop = ALLOW_RESTING

	var/obj/item/xeno_noz
	var/volume = 500
	var/maxslots = 5

/datum/armor/item_watertank
	fire = 100
	acid = 30

/obj/item/xenobio_vacpack/Initialize(mapload)
	. = ..()
	xeno_noz = make_xeno_noz()
	RegisterSignal(xeno_noz, COMSIG_MOVABLE_MOVED, PROC_REF(xeno_noz_move))

/obj/item/xenobio_vacpack/Destroy()
	QDEL_NULL(xeno_noz)
	return ..()

/obj/item/xenobio_vacpack/ui_action_click(mob/user)
	toggle_mister(user)

/obj/item/xenobio_vacpack/proc/toggle_mister(mob/living/user)
	if(!istype(user))
		return
	if(user.get_item_by_slot(user.getBackSlot()) != src)
		to_chat(user, span_warning("The vacpack must be worn properly to use!"))
		return
	if(user.incapacitated)
		return

	if(QDELETED(xeno_noz))
		xeno_noz = make_xeno_noz()
		RegisterSignal(xeno_noz, COMSIG_MOVABLE_MOVED, PROC_REF(xeno_noz_move))
	if(xeno_noz in src)
		//Detach the xeno_nozzle into the user's hands
		if(!user.put_in_hands(xeno_noz))
			to_chat(user, span_warning("You need a free hand to hold the nozzle!"))
			return
	else
		//Remove from their hands and put back "into" the tank
		remove_xeno_noz()

/obj/item/xenobio_vacpack/verb/toggle_mister_verb()
	set name = "Toggle Nozzle"
	set category = "Object"
	toggle_mister(usr)

/obj/item/xenobio_vacpack/proc/make_xeno_noz()
	return new /obj/item/vacpack_nozzle(src)

/obj/item/xenobio_vacpack/proc/xeno_noz_move(atom/movable/mover, atom/oldloc, direction)
	if(mover.loc == src || mover.loc == loc)
		return
	balloon_alert(loc, "Vacpack nozzle snaps back")
	mover.forceMove(src)

/obj/item/xenobio_vacpack/equipped(mob/user, slot)
	..()
	if(!(slot & ITEM_SLOT_BACK))
		remove_xeno_noz()

/obj/item/xenobio_vacpack/proc/remove_xeno_noz()
	if(!QDELETED(xeno_noz))
		if(ismob(xeno_noz.loc))
			var/mob/M = xeno_noz.loc
			M.temporarilyRemoveItemFromInventory(xeno_noz, TRUE)
		xeno_noz.forceMove(src)

/obj/item/xenobio_vacpack/attack_hand(mob/user, list/modifiers)
	if (user.get_item_by_slot(user.getBackSlot()) == src)
		toggle_mister(user)
	else
		return ..()

/obj/item/xenobio_vacpack/mouse_drop_dragged(atom/over_object)
	var/mob/M = loc
	if(istype(M) && istype(over_object, /atom/movable/screen/inventory/hand))
		var/atom/movable/screen/inventory/hand/H = over_object
		M.putItemFromInventoryInHandIfPossible(src, H.held_index)

/obj/item/xenobio_vacpack/attackby(obj/item/attacking_item, mob/user, list/modifiers, list/attack_modifiers)
	if(attacking_item == xeno_noz)
		remove_xeno_noz()
		return TRUE
	else
		return ..()

/obj/item/xenobio_vacpack/dropped(mob/user)
	..()
	remove_xeno_noz()

// The nozzle for picking mobs up
/obj/item/vacpack_nozzle
	name = "Vacpack nozzle"
	desc = "Just point and hold trigger to either suck something in or to spit it out."
	w_class = WEIGHT_CLASS_SMALL
	icon = 'icons/obj/service/hydroponics/equipment.dmi'
	icon_state = "atmos_nozzle"
	inhand_icon_state = "nozzleatmos"
	lefthand_file = 'icons/mob/inhands/equipment/mister_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/mister_righthand.dmi'
	///traits we give and remove from the mob on exit and entry
	var/static/list/traits_on_transfer = list(
		TRAIT_IMMOBILIZED,
		TRAIT_HANDS_BLOCKED,
		TRAIT_AI_PAUSED,
	)

/datum/action/item_action/toggle_mister
	name = "Toggle Nozzle"

/obj/item/vacpack_nozzle/ranged_interact_with_atom(atom/target, mob/user)
	if(contents.len)
		to_chat(user, span_notice("You shoot with the vacpack!"))
		release(target, user)
	else
		to_chat(user, span_warning("The device is empty..."))

/obj/item/vacpack_nozzle/interact_with_atom_secondary(atom/target, mob/living/user, list/modifiers)
	store_check(target, user)

/obj/item/vacpack_nozzle/proc/store_check(mob/living/vac_target, mob/living/user)
	//var/mob/living/vac_target = vac_target
	if(contents.len >= 3)
		to_chat(user, span_warning("The vacpack is full!"))
		return
	if(!isanimal_or_basicmob(vac_target))
		to_chat(user, span_warning("The vacpack only works on simple creatures."))
		return
	if(vac_target.mind)
		to_chat(user, span_warning("Vacpack can't store intelligent creatures."))
		return
	else if(!(FACTION_NEUTRAL in vac_target.faction))
		to_chat(user, span_warning("This creature is too aggressive to capture."))
		return
	to_chat(user, span_notice("You store [vac_target] in the vacpack."))
	store(vac_target, user)

/obj/item/vacpack_nozzle/proc/store(mob/living/vac_target, mob/living/user)
	vac_target.forceMove(src)
	vac_target.add_traits(traits_on_transfer, ABSTRACT_ITEM_TRAIT)
	vac_target.cancel_camera()

/datum/status_effect/vacpack_toss
	id = "vacpacktoss"
	duration = 5  //temp value for tests, turn back down before PRing
	alert_type = /atom/movable/screen/alert/status_effect/crucible_soul

/datum/status_effect/vacpack_toss/on_apply()
	owner.pass_flags |= PASSMOB

/datum/status_effect/vacpack_toss/on_remove()
	owner.pass_flags &= ~(PASSMOB)

/obj/item/vacpack_nozzle/proc/release(atom/target, mob/user)
	var/mob/living/vac_target = contents[contents.len]
	vac_target.forceMove(get_turf(loc))
	vac_target.remove_traits(traits_on_transfer, ABSTRACT_ITEM_TRAIT)
	vac_target.cancel_camera()
	vac_target.apply_status_effect(/datum/status_effect/vacpack_toss)  //So you can toss slimes into pens even if theres another slime in the way
	vac_target.throw_at(target, 5 , 2 , user)




