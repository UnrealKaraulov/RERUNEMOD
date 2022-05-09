#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_model_id = -1;

new max_hp_available_cvar;

public plugin_init()
{
	register_plugin("RM_MEDKIT","2.4","Karaulov"); 
	rm_register_rune("rm_medkit_item_name","rm_medkit_item_desc",Float:{255.0,255.0,255.0}, "models/rm_reloaded/w_medkit.mdl",_,rune_model_id);
	rm_base_use_rune_as_item( );
	
	max_hp_available_cvar = get_cvar_pointer("runemod_max_hp");
	
	rm_base_set_rune_cost(4000);
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/w_medkit.mdl");
}

public rm_give_rune(id)
{
	new Float:hp = get_entvar(id,var_health);
	if (hp < get_pcvar_float(max_hp_available_cvar))
	{
		set_entvar(id,var_health,floatclamp(hp + 50.0,100.0,get_pcvar_float(max_hp_available_cvar)));
		return RUNE_PICKUP_SUCCESS;
	}
	else 
		return NO_RUNE_PICKUP_SUCCESS;
}
