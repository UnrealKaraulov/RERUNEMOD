#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fun>

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_MEDKIT","2.0","Karaulov"); 
	rm_register_rune("Аптечка","Восполняет здоровье.",Float:{255.0,255.0,255.0}, "models/rm_reloaded/w_medkit.mdl",_,rune_model_id);
	rm_base_use_rune_as_item( );
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/w_medkit.mdl");
}

public rm_give_rune(id)
{
	new Float:hp = get_entvar(id,var_health);
	if (hp < 150.0)
		set_entvar(id,var_health,floatclamp(hp + 50.0,100.0,150.0));
}
