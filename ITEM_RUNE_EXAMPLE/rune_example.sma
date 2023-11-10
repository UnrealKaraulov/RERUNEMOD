#include <rm_api>

public plugin_init()
{
	register_plugin("PLUGIN NAME", "1.0 VERSION", "AUTHOR");
	rm_register_rune("RUNE NAME","RUNE DESCRIPTION", /* RUNE COLOR */ Float:{0.0,100.0,0.0}, "path/to/rune.mdl", "path/to/runesound.wav", model_index_of_runemdl);
}


public rm_give_rune(id)
{
	// GIVE RUNE EFFECT FOR PLAYER
	return RUNE_PICKUP_SUCCESS;
}

public rm_drop_rune(id)
{
	// REMOVE RUNE EFFECT FOR PLAYER ID
	// WARNING PLAYER CAN BE DEAD OR DISCONNECTED
}
