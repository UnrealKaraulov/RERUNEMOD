#include <amxmodx>
#include <amxmisc>
#include <rm_api>


/**
* Изменение баланса кошелька зарегистрированного игрока (добавить / отнять)
* 
* @param id				id игрока
* @param Float:fAmmount	Добавить значение к балансу
*
* @return				1 в случае успеха
* 						0 в случае неудачи
*/
native cmsapi_add_user_money(id, Float:fAmmount);


new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_GAMECMS_CASH","2.2","Karaulov"); 
	rm_register_rune("rm_gamecms_money_item_name","rm_gamecms_money_item_desc",Float:{255.0,255.0,255.0}, "models/rm_reloaded/w_rubel.mdl",_,rune_model_id);
	rm_base_use_rune_as_item( );
	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	rm_base_set_max_count( 1 );
	// Предмет может поднять только зарегистрированный в GAMECMS
	rm_need_gamecms_register( );
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/w_rubel.mdl");
}

public rm_give_rune(id)
{
	cmsapi_add_user_money(id, 5.0);
}

public plugin_natives() 
{
	set_native_filter("native_filter")
}

public native_filter(const name[], index, trap) 
{
	if (trap)
		return PLUGIN_CONTINUE;
	if(equal(name, "cmsapi_add_user_money"))
	{
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}