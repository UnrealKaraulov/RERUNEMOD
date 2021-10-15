#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fun>

public plugin_init()
{
	register_plugin("Medkit_rune","1.1","Karaulov"); 
	rm_register_rune("Аптечка","Восполняет здоровье.",Float:{255.0,255.0,255.0}, "models/w_medkit.mdl",_);
	rm_use_rune_as_item( );
}

public plugin_precache()
{
	precache_model("models/w_medkit.mdl");
}

public rm_give_rune(id)
{
	set_user_health(id,100);
}
