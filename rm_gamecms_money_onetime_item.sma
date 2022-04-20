#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <gamecms5>

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_GAMECMS_CASH","2.0","Karaulov"); 
	rm_register_rune("Деньги","Дает 5 рублей на счет сайта^nИли 5000$ в игре!",Float:{255.0,255.0,255.0}, "models/rm_reloaded/w_rubel.mdl",_,rune_model_id);
	rm_base_use_rune_as_item( );
	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	rm_base_set_max_count( 1 );
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/w_rubel.mdl");
}

public rm_give_rune(id)
{
	if (!cmsapi_add_user_money(id, 1.0))
	{
		rg_add_account(id,5000);
	}
}
