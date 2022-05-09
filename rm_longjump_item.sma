#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_LONGJUMP","2.3","Karaulov"); 
	rm_register_rune("rm_longjump_item_name","rm_longjump_item_desc",Float:{255.0,255.0,255.0}, "models/w_longjump.mdl",_,rune_model_id);
	rm_base_use_rune_as_item( );
	
	rm_base_set_rune_cost(800);
}

public plugin_precache()
{
	rune_model_id = precache_model("models/w_longjump.mdl");
}

public rm_give_rune(id)
{
	if (!rg_has_item_by_name(id,"item_longjump"))
	{
		rg_give_item(id, "item_longjump" );
		return RUNE_PICKUP_SUCCESS;
	}
	else 
		return NO_RUNE_PICKUP_SUCCESS;
}
