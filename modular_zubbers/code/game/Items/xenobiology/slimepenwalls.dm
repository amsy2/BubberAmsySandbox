/obj/structure/window/slimepen
	name = "window"
	desc = "A directional window."
	icon_state = "window"

/obj/structure/window/slimepen/CanAllowThrough(atom/movable/mover, border_dir)
	..()
	if(.)
		return

	if(fulltile)
		return FALSE

	if(istype(mover, /obj/structure/window))
		var/obj/structure/window/moved_window = mover
		return valid_build_direction(loc, moved_window.dir, is_fulltile = moved_window.fulltile)

	if(istype(mover, /obj/structure/windoor_assembly) || istype(mover, /obj/machinery/door/window))
		return valid_build_direction(loc, mover.dir, is_fulltile = FALSE)

	return TRUE

/obj/structure/window/slimepen/Initialize(mapload, direct)
	AddElement(/datum/element/blocks_explosives)
	..()
	if(direct)
		setDir(direct)
	if(reinf && anchored)
		state = RWINDOW_SECURE

	if(!reinf && anchored)
		state = WINDOW_SCREWED_TO_FRAME

	air_update_turf(TRUE, TRUE)

	if(fulltile)
		setDir()
		obj_flags &= ~BLOCKS_CONSTRUCTION_DIR
		obj_flags &= ~IGNORE_DENSITY
		AddElement(/datum/element/can_barricade)

	//windows only block while reinforced and fulltile
	if(!reinf || !fulltile)
		set_explosion_block(0)

	flags_1 |= ALLOW_DARK_PAINTS_1
	RegisterSignal(src, COMSIG_OBJ_PAINTED, PROC_REF(on_painted))
	AddElement(/datum/element/atmos_sensitive, mapload)
	AddComponent(/datum/component/simple_rotation, ROTATION_NEEDS_ROOM, post_rotation = CALLBACK(src, PROC_REF(post_rotation)))

	var/static/list/loc_connections = list(
		COMSIG_ATOM_EXIT = PROC_REF(on_exit_slimepen),
	)

	if (flags_1 & ON_BORDER_1)
		AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/window/slimepen/proc/on_exit_slimepen(datum/source, atom/movable/leaving, direction)
	SIGNAL_HANDLER

	if(leaving.movement_type & PHASING)
		return

	if(leaving == src)
		return // Let's not block ourselves.

	if (leaving.pass_flags & pass_flags_self)
		return

	if (fulltile)
		return

	if(direction == dir && density)
		if(!isanimal_or_basicmob(leaving))
			return
		leaving.Bump(src)
		return COMPONENT_ATOM_BLOCK_EXIT
