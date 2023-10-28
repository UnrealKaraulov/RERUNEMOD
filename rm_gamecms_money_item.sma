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


new rune_name[] = "rm_gamecms_money_item_name";
new rune_descr[] = "rm_gamecms_money_item_desc";

new rune_model_path[64] = "models/rm_reloaded/w_rubel.mdl";

new rune_model_id = -1;

new Float:g_fMinMoney = 5.0;
new Float:g_fMaxMoney = 5.0;

new g_iMinMoney = 5;
new g_iMaxMoney = 5;

public plugin_init()
{
	register_plugin("RM_GAMECMS_CASH","2.4","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,255.0,255.0}, rune_model_path,_,rune_model_id);
	rm_base_use_rune_as_item( );
	// Предмет может поднять только зарегистрированный в GAMECMS
	rm_need_gamecms_register( );
	
	/* Чтение конфигурации */
	new cost = 0; // 0 знач незя купить по умолчанию!
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	rm_read_cfg_flt(rune_name,"MIN_MONEY",g_fMinMoney,g_fMinMoney);
	rm_read_cfg_flt(rune_name,"MAX_MONEY",g_fMaxMoney,g_fMaxMoney);
	
	// Прибегнуть к хитрости
	g_iMinMoney = floatround(g_fMinMoney * 10.0); // for example 1.55555 to 15 or 5.55555 to 55
	g_iMaxMoney = floatround(g_fMaxMoney * 10.0);
	

	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	new max_count = 1;
	rm_read_cfg_int(rune_name,"MAX_COUNT_ON_MAP",max_count,max_count);
	rm_base_set_max_count( max_count );
}

public plugin_precache()
{	
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"model",rune_model_path,rune_model_path,charsmax(rune_model_path));
	
	
	rune_model_id = precache_model(rune_model_path);
}

public rm_give_rune(id)
{
	cmsapi_add_user_money(id, float( random_num(g_iMinMoney,g_iMaxMoney) ) / 10.0 );
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