#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_model_id = -1;

new rune_name[] = "rm_medkit_item_name";
new rune_descr[] = "rm_medkit_item_desc";

new rune_model_path[64] = "models/rm_reloaded/w_medkit.mdl";

new Float:g_fMaxHP = 150.0;

new Float:g_fMedkitHP = 50.0;

public plugin_init()
{
	register_plugin("RM_MEDKIT","2.5","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,255.0,255.0}, rune_model_path,_,rune_model_id);
	rm_base_use_rune_as_item( );
	
	/* Чтение конфигурации */
	new cost = 3500;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	rm_read_cfg_flt("GENERAL","MAXIMUM_HP",g_fMaxHP,g_fMaxHP);
	rm_read_cfg_flt("GENERAL","HP_REGEN",g_fMedkitHP,g_fMedkitHP);
}

public plugin_precache()
{
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"model",rune_model_path,rune_model_path,charsmax(rune_model_path));
	
	rune_model_id = precache_model(rune_model_path);
}

public rm_give_rune(id)
{
	new Float:hp = get_entvar(id,var_health);
	if (hp < g_fMaxHP)
	{
		set_entvar(id,var_health,floatclamp(hp + g_fMedkitHP,50.0,g_fMaxHP));
		return RUNE_PICKUP_SUCCESS;
	}
	else 
		return NO_RUNE_PICKUP_SUCCESS;
}
