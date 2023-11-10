#include <rm_api>

public plugin_init()
{
	register_plugin("PLUGIN NAME", "1.0 VERSION", "AUTHOR");
	rm_register_rune("ITEM NAME","ITEM DESCRIPTION", /* ITEM COLOR */ Float:{0.0,100.0,0.0}, "path/to/item.mdl", "path/to/itempickup/sound.wav", model_index_of_item_mdl);
}


public rm_give_rune(id)
{
	// GIVE ITEM FOR PLAYER
	return RUNE_PICKUP_SUCCESS;
}


/*
OPTIONAL!

public rm_drop_rune(id)
{
	// REMOVE ITEM FOR PLAYER ID
	// WARNING PLAYER CAN BE DEAD OR DISCONNECTED
}
*/