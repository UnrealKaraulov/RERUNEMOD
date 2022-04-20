#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_CASH","2.0","Karaulov"); 
	rm_register_rune("Деньги","Дает 5000$",Float:{255.0,255.0,255.0}, "models/rm_reloaded/w_dollar.mdl",_,rune_model_id);
	// Класс руны: предмет
	rm_base_use_rune_as_item( );
	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	rm_base_set_max_count( 1 );
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/w_dollar.mdl");
}

public rm_give_rune(id)
{
	rg_add_account(id,5000)
}
