#if defined _RUNEMOD_RELOAD
  #endinput
#endif

#define _RUNEMOD_RELOAD

#define RUNEMOD_VERSION "3.7.11"


#define HUD_CHANNEL_ID 3
#define HUD_CHANNEL_ID_2 2

#define DHUD_POS_NOTIFY 1
#define DHUD_POS_RUNE 2
#define DHUD_POS_ITEM1 3
#define DHUD_POS_ITEM2 4
#define DHUD_POS_ITEM3 5
#define DHUD_POS_ITEM4 6
#define DHUD_POS_ITEM5 7
#define DHUD_POS_ITEM6 8

#define RUNE_CLASSNAME "rune_model"

#if !defined _engine_included
	#include <engine>
#endif

#if !defined _reapi_included
	#include <reapi>
#endif

#if !defined _fakemeta_included
	#include <fakemeta>
#endif

#if !defined _xs_included
	#include <xs>
#endif

#if !defined _screenfade_util_included
	#include <screenfade_util>
#endif

#define _easy_cfg_internal

#if !defined _easy_cfg_included
#define _easy_cfg_has_internal
#include <easy_cfg>
#endif

// Пpoвepкa peaльный ли игpoк
#define is_real_player(%0) (%0 > 0 && %0 <= MAX_PLAYERS)

// Maкcимaльнoe кoличecтвo pyн - плaгинoв
#define MAX_REGISTER_RUNES 1024

// Максимальное количество спавн точек
#define MAX_SPAWN_POINTS 256

#define RUNEMODE_DEFAULT_HIGHLIGHT_POWER 100

#define SPAWN_SEARCH_TASK_ID 10000
#define UPDATE_RUNE_DESCRIPTION_HUD_ID 10002
#define UPDATE_RUNE_DESCRIPTION_HUD_TIME 1.0

#define RUNE_PICKUP_SUCCESS 0
#define NO_RUNE_PICKUP_SUCCESS 255

#define PICKUP_SUCCESS RUNE_PICKUP_SUCCESS
#define PICKUP_ERROR NO_RUNE_PICKUP_SUCCESS

#define SPAWN_SUCCESS 0
#define SPAWN_ERROR 255

#define TSC_Vector_MA(%1,%2,%3,%4)	(%4[0] = %2[0] * %3 + %1[0], %4[1] = %2[1] * %3 + %1[1])


/*
* Регистрации нового предмета или руны
*
* @param RuneName		Название руны
* @param RuneDesc		Описание руны
* @param RuneColor		Цвет руны(подсветка игрока, экрана и модели)
* @param rModel			Путь к модели, иначе используется стандартная
* @param rSound			Путь к звуку, иначе используется стандартный
* @param rModelID		Номер модели из прекеша (только если указана rModel)
* @param RuneGiveName	Название руны для выдачи или покупки
*
* @return Номер руны или -1 если количество превышено допустимое количество рун (MAX_REGISTER_RUNES)
*/
stock rm_register_rune(RuneName[], RuneDesc[], Float:RuneColor[3], rModel[] = "", rSound[] = "", rModelID = -1,RuneGiveName[] = "")
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("RM_RegisterPlugin",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND");
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(rm_current_plugin_id());
	callfunc_push_str(RuneName);
	callfunc_push_str(RuneDesc);
	callfunc_push_float(RuneColor[0]);
	callfunc_push_float(RuneColor[1]);
	callfunc_push_float(RuneColor[2]);
	callfunc_push_str(rModel);
	callfunc_push_str(rSound);
	callfunc_push_int(rModelID);
	callfunc_push_str(RuneGiveName);
	return callfunc_end();
}

/* Конфигурация */
stock rm_read_cfg_str(RuneName[], RuneParam[], DefaultValue[], outstr[], outlen)
{
	cfg_set_path("plugins/runemod_extended.ini");
	cfg_read_str(RuneName,RuneParam, DefaultValue, outstr, outlen);
}
stock rm_read_cfg_int(RuneName[], RuneParam[], DefaultValue, &outval)
{
	cfg_set_path("plugins/runemod_extended.ini");
	cfg_read_int(RuneName,RuneParam,DefaultValue,outval);
}

stock rm_read_cfg_flt(RuneName[], RuneParam[], Float:DefaultValue, &Float:outval)
{
	cfg_set_path("plugins/runemod_extended.ini");
	cfg_read_flt(RuneName,RuneParam,DefaultValue,outval);
}


/*
* Регистрации нового ланг файла (словарь)
*
* @param dictname		Название файла словаря
*
* @noreturn
*/
public rm_register_dictionary(const dictname[])
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_register_dictionary_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 2");
		return false;
	}
	register_dictionary(dictname);
	
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 2");
		return false;
	}
	
	callfunc_push_str(dictname);
	callfunc_end();
	return true;
}

/*
* Вызывается когда игрок поднимает предмет или руну
*
* @param id				Номер игрока
* @param ent			Руна или 0 если нет руны
* @param rune_id		Номер руны
* 
* @return RUNE_PICKUP_SUCCESS/NO_RUNE_PICKUP_SUCCESS
*/
stock bool:rm_give_rune_callback(OwnIndex, id, ent, rune_id)
{
	new PluginReqFunc = get_func_id("rm_give_rune",OwnIndex);
	if(PluginReqFunc == -1)
	{
		return false;
	}
	new Temp = callfunc_begin_i(PluginReqFunc,OwnIndex);
	if(Temp != 1)
	{
		log_amx("rm_give_rune error");
		return false;
	}
	callfunc_push_int(id);
	callfunc_push_int(ent);
	callfunc_push_int(rune_id);
	return callfunc_end() != NO_RUNE_PICKUP_SUCCESS;
}

/*
* Вызывается когда предмет или руна появляется на карте
*
* @param ent				Руна
* @param rune_id			Номер руны
* 
* @return SPAWN_SUCCESS/SPAWN_ERROR
*/
stock bool:rm_spawn_rune_callback(OwnIndex, ent, rune_id)
{
	new PluginReqFunc = get_func_id("rm_spawn_rune",OwnIndex);
	if(PluginReqFunc == -1)
	{
		return true;
	}
	new Temp = callfunc_begin_i(PluginReqFunc,OwnIndex);
	if(Temp != 1)
	{
		log_amx("rm_spawn_rune error");
		return false;
	}
	callfunc_push_int(ent);
	callfunc_push_int(rune_id);
	return callfunc_end() != SPAWN_ERROR;
}

/*
* Вызывается когда предмет или руна удаляется с карты
*
* @param ent				Руна
* 
* @noreturn
*/
stock rm_remove_rune_callback(OwnIndex, ent)
{
	new PluginReqFunc = get_func_id("rm_remove_rune",OwnIndex);
	if(PluginReqFunc == -1)
	{
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(PluginReqFunc,OwnIndex);
	if(Temp != 1)
	{
		log_amx("rm_remove_rune error");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(ent);
	return callfunc_end();
}

/*
* Вызывается когда игрок теряет руну
*
* @param id				Номер игрока
* @param rune_id		Номер руны
* 
* @noreturn
*/
stock rm_drop_rune_callback(OwnIndex, id, rune_id)
{
	new PluginReqFunc = get_func_id("rm_drop_rune",OwnIndex);
	if(PluginReqFunc == -1)
	{
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(PluginReqFunc,OwnIndex);
	if(Temp != 1)
	{
		log_amx("rm_drop_rune error");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(id);
	callfunc_push_int(rune_id);
	return callfunc_end();
}

/*
* Выбросить руну
*
* @param id				Номер игрока
*
* @noreturn
*/
stock rm_base_drop_rune(id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_drop_rune_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 2");
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 2");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(rm_current_plugin_id());
	callfunc_push_int(id);
	return callfunc_end();
}

/*
* Прервано дейтсвие предмета
*
* @param id				Номер игрока
*
* @noreturn
*/
stock rm_base_drop_item_notice(id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_drop_item_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 2");
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 2");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(rm_current_plugin_id());
	callfunc_push_int(id);
	return callfunc_end();
}


/*
* Прервано дейтсвие предмета по номеру предмета (руны)
*
* @param rune_id		Номер руны
* @param id				Номер игрока
*
* @noreturn
*/
stock rm_base_drop_item_by_rune_id_notice(rune_id,id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_drop_item_api_by_rune_id",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 2");
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 2");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(rune_id);
	callfunc_push_int(id);
	return callfunc_end();
}

/*
* Указать класс руны : предмет
*
* @noreturn
*/
stock rm_base_use_rune_as_item( )
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_rune_set_item",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 3");
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 3");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(rm_current_plugin_id());
	return callfunc_end();
}

/*
* Активировать свечение модели игрока
*
* @param id				Номер игрока
*
* @noreturn
*/
stock rm_base_highlight_player(id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_highlight_player",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(rm_current_plugin_id());
	callfunc_push_int(id);
	
	return callfunc_end();
}

/*
* Активировать подсветку экрана игрока
*
* @param id						Номер игрока
* @param hpower(optional)		Сила подсветки
*
* @noreturn
*/
stock rm_base_highlight_screen(id, hpower = RUNEMODE_DEFAULT_HIGHLIGHT_POWER)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_highlight_screen",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(rm_current_plugin_id());
	callfunc_push_int(id);
	callfunc_push_int(hpower);
	
	return callfunc_end();
}

/*
* Сбросить подсветку игрока
*
* @param id				Номер игрока
*
* @noreturn
*/
stock rm_base_disable_highlight(id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_reset_highlight",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(id);
	
	return callfunc_end();
}

/*
* Заблокиовать игрок возможность поднимать руны и предметы
*
* @param id				Номер игрока
* @param iBlock			1 что бы заблокировать, 0 для разблокировки
*
* @noreturn
*/
stock rm_base_lock_pickup(id, iBlock)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_lock_pickup",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(id);
	callfunc_push_int(iBlock);
	return callfunc_end();
}


/*
* Заменить лежащую на земле руну другой
*
* @param ent 				Руна
* @param new_rune_id 		Новый номер руны
*
* @noreturn
*/
stock rm_base_swap_rune_id(ent, new_rune_id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_swap_rune_id",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(ent);
	callfunc_push_int(new_rune_id);
	return callfunc_end();
}

/*
* Есть ли у игрока активная руна?
*
* @param id				Номер игрока
* 
* @return true / false 
*/

stock bool:rm_base_player_has_rune(id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_is_player_has_rune",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return false;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return false;
	}
	callfunc_push_int(id);
	return callfunc_end() > 0;
}


/*
* Какая у игрока активная руна?
*
* @param id				Номер игрока
* 
* @return -1 или номер руны
*/

stock rm_base_player_get_rune(id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_player_active_rune",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return false;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return false;
	}
	callfunc_push_int(id);
	return callfunc_end();
}

/*
* Предупредить игрока о необходимости зарегистрироваться на сайте!
*
* @param id			Номер игрока
*
* @noreturn
*
* Можно вызывать часто, обновление надписи 1 раз в секунду внутри базового плагина.
*/
stock rm_print_need_register(id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_print_register_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return false;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return false;
	}
	callfunc_push_int(id);
	return callfunc_end();
}


/*
* Запрет поднятия руны незарегистрированному в GAMECMS игроку
*
* @noreturn
*/
stock rm_need_gamecms_register()
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_need_gamecms_register_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return false;
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return false;
	}
	callfunc_push_int(rm_current_plugin_id());
	return callfunc_end();
}

/*
* Ограничить количество рун
*
* @param num			Максимальное количество данного типа рун.
*
* @noreturn
*/
stock rm_base_set_max_count(num = MAX_REGISTER_RUNES)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("RM_MaxRunesAtOneTime",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	
	callfunc_push_int(rm_current_plugin_id());
	callfunc_push_int(num);
	
	return callfunc_end();
}


/*
* Добавить в магазин рун
*
* @param imoney			Стоимость руны
*
* @noreturn
*/
stock rm_base_set_rune_cost(imoney = 16000)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_set_rune_cost_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	
	callfunc_push_int(rm_current_plugin_id());
	callfunc_push_int(imoney);
	
	return callfunc_end();
}


/*
* Добавить в магазин рун по номеру руны
*
* @param rune_id		Номер руны
* @param imoney			Стоимость руны
*
* @noreturn
*/
stock rm_base_set_rune_cost_by_rune_id(rune_id, imoney = 16000)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_set_rune_cost_api_by_rune_id",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	
	callfunc_push_int(rune_id);
	callfunc_push_int(imoney);
	
	return callfunc_end();
}

/*
* Дать руну игроку из внешнего плагина
*
* @param id				Номер игрока
* @param rune_id		номер руны
*
* * @return true/false (успешно или руну нельзя выдать)
*/
stock bool:rm_give_rune_to_player(player_id, rune_id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_give_rune_to_player_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return false;
	}
	
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return false;
	}
	
	callfunc_push_int(player_id);
	callfunc_push_int(rune_id);
	
	return callfunc_end() > 0;
}

/*
* Узнать по номеру руны что это, руна или предмет
*
* @param rune_id 		Номер руны
*
* * @return bool (Предмет или нет)
*/
stock bool:rm_is_rune_item(rune_id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_is_rune_item_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return true;
	}
	
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return true;
	}
	
	callfunc_push_int(rune_id);
	
	return callfunc_end() > 0;
}


/*
* Получить количество зарегистрированных рун
*
* * @return количество рун.
*/
stock rm_get_runes_count()
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_get_runes_count_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	
	return callfunc_end();
}

/*
* Выключить появление руны на карте принудительно
*
* @param rune_id		номер руны
*
* * @noreturn 
*/
stock rm_disable_rune(rune_id, bool:disable=true)
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_disable_rune_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	
	callfunc_push_int(rune_id);
	callfunc_push_int(disable ? 1 : 0);
	
	return callfunc_end();
}


/*
* Получить номер руны по названию руны. 
*
* @param rune_name				название руны
*
* * @return номер руны или -1
*/
stock rm_get_rune_by_name(rune_name[])
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_get_rune_by_name_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	
	callfunc_push_str(rune_name);
	
	return callfunc_end();
}


/*
* Купить руну за игровые деньги по названию
*
* @param rune_name				название руны
*
* * @return true/false
*/
stock rm_buy_rune_by_name(id,rune_name[])
{
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_buy_rune_api",BasePluginIndex);
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4");
		return PLUGIN_HANDLED;
	}
	
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4");
		return PLUGIN_HANDLED;
	}
	
	callfunc_push_int(id);
	callfunc_push_str(rune_name);
	
	return callfunc_end();
}


/*
* Принудительно забрать руну у игрока.
*
* @param id				Номер игрока
* 
* @noreturn
*/
stock rm_force_drop_rune(id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new PluginReqFunc = get_func_id("rm_force_drop_rune_api",BasePluginIndex);
	if(PluginReqFunc == -1)
	{
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(PluginReqFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("rm_drop_rune error");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(id);
	return callfunc_end();
}


/*
* Принудительно забрать все предметы у игрока.
*
* @param id				Номер игрока
* 
* @noreturn
*/
stock rm_force_drop_items(id)
{
	new BasePluginIndex = rm_base_plugin_id();
	new PluginReqFunc = get_func_id("rm_force_drop_items_api",BasePluginIndex);
	if(PluginReqFunc == -1)
	{
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(PluginReqFunc,BasePluginIndex);
	if(Temp != 1)
	{
		log_amx("rm_drop_rune error");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(id);
	return callfunc_end();
}


// Функция проверяет не находится ли игрок на земле
stock bool:is_user_onground( id )
{
	new flags = get_entvar(id, var_flags);
	if( (flags & FL_ONGROUND) > 0 )
	{
		new igroundent = get_entvar(id,var_groundentity);
		if (igroundent == 0)
			return true;
		else if (!is_nullent(igroundent))
		{
			new classname[33];
			get_entvar(igroundent,var_classname,classname,charsmax(classname));
			return equali(classname,"func_wall") > 0;
		}
	}
	return false;
}

/*Использовать var_ для хранения данных в рунах*/

// Фyнкция coxpaняeт ид pyны в руну
public rm_set_rune_runeid( id, rune_id )
{
	return set_entvar(id, var_iuser1, float(rune_id) );
}
// Фyнкция вoзвpaщaeт ид pyны из руны
public rm_get_rune_runeid( id )
{
	return floatround(get_entvar(id, var_iuser1));
}

// Фyнкция вoзвpaщaeт число из руны
public rm_get_rune_num( id )
{
	return get_entvar(id, var_iuser2);
}

// Фyнкция coxpaняeт число в руну
public rm_set_rune_num( id, num )
{
	return set_entvar(id, var_iuser2, num );
}

// Фyнкция coxpaняeт ид спавна в руну
public rm_set_rune_spawnid( id, spawn_id )
{
	return set_entvar(id, var_iuser3, float(spawn_id) );
}

// Фyнкция вoзвpaщaeт ид спавна из руны
public rm_get_rune_spawnid( id )
{
	return floatround(get_entvar(id, var_iuser3));
}


stock rg_set_rendering(const pEntity, const fx = kRenderFxNone, mode = kRenderNormal, const Float:flColor[] = {0.0, 0.0, 0.0}, const Float:iAmount = 0.0)
{
	if (is_user_connected(pEntity))
	{
		set_entvar(pEntity, var_renderfx, fx);
		set_entvar(pEntity, var_rendermode, mode);
		set_entvar(pEntity, var_rendercolor, flColor);
		set_entvar(pEntity, var_renderamt, iAmount);
	}
}

stock bool:rm_is_hull_vacant(id, Float:origin[3], iHull, g_pCommonTr)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, iHull, id, g_pCommonTr);
	
	if (!get_tr2(g_pCommonTr, TR_StartSolid) && !get_tr2(g_pCommonTr, TR_AllSolid) && get_tr2(g_pCommonTr, TR_InOpen))
		return true;
	
	return false;
}

stock bool:rm_unstuck_player(id)
{
	new pCommonTr = create_tr2();
	new bool:bSuccess = false;
	new Float:Origin[3];
	get_entvar(id, var_origin, Origin);
	
	new iHull, iSpawnPoint, i;
	iHull = (get_entvar(id, var_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;
	
	// fast unstuck 
	if(!rm_is_hull_vacant(id,Origin,iHull, pCommonTr))
	{
		Origin[2] -= 64.0;
	}
	else
	{
		engfunc(EngFunc_SetOrigin, id, Origin);
		free_tr2(pCommonTr);
		return true;
	}
	if(!rm_is_hull_vacant(id,Origin,iHull, pCommonTr))
	{
		Origin[2] += 128.0;
	}
	else
	{
		engfunc(EngFunc_SetOrigin, id, Origin);
		free_tr2(pCommonTr);
		return true;
	}
	
	if(!rm_is_hull_vacant(id,Origin,iHull, pCommonTr))
	{
		new const Float:RANDOM_OWN_PLACE[][3] =
		{
			{ -96.5,   0.0, 0.0 },
			{  96.5,   0.0, 0.0 },
			{   0.0, -96.5, 0.0 },
			{   0.0,  96.5, 0.0 },
			{ -96.5, -96.5, 0.0 },
			{ -96.5,  96.5, 0.0 },
			{  96.5,  96.5, 0.0 },
			{  96.5, -96.5, 0.0 }
		};
		
		new Float:flOrigin[3], Float:flOriginFinal[3], iSize;
		get_entvar(id, var_origin, flOrigin);
		iSize = sizeof(RANDOM_OWN_PLACE);
		
		iSpawnPoint = random_num(0, iSize - 1);
		
		for (i = iSpawnPoint + 1; /*no condition*/; i++)
		{
			if (i >= iSize)
				i = 0;
			
			flOriginFinal[0] = flOrigin[0] + RANDOM_OWN_PLACE[i][0];
			flOriginFinal[1] = flOrigin[1] + RANDOM_OWN_PLACE[i][1];
			flOriginFinal[2] = flOrigin[2];
			
			engfunc(EngFunc_TraceLine, flOrigin, flOriginFinal, IGNORE_MONSTERS, id, 0);
			
			new Float:flFraction;
			get_tr2(0, TR_flFraction, flFraction);
			if (flFraction < 1.0)
			{
				new Float:vTraceEnd[3], Float:vNormal[3];
				get_tr2(0, TR_vecEndPos, vTraceEnd);
				get_tr2(0, TR_vecPlaneNormal, vNormal);
				
				TSC_Vector_MA(vTraceEnd, vNormal, 32.5, flOriginFinal);
			}
			flOriginFinal[2] -= 35.0;
			
			new iZ = 0;
			do
			{
				if (rm_is_hull_vacant(id, flOriginFinal, iHull, pCommonTr))
				{
					i = iSpawnPoint;
					engfunc(EngFunc_SetOrigin, id, flOriginFinal);
					bSuccess = true;
					break;
				}
				
				flOriginFinal[2] += 40.0;
			}
			while (++iZ <= 2)
			
			if (i == iSpawnPoint)
				break;
		}
	}
	else
	{
		engfunc(EngFunc_SetOrigin, id, Origin);
		free_tr2(pCommonTr);
		return true;
	}
	
	free_tr2(pCommonTr);
	return bSuccess;
}


stock g_hBasePlugin = -1;
	
stock rm_base_plugin_id()
{
	if (g_hBasePlugin != -1)
		return g_hBasePlugin;
	
	new i = get_plugin(-1);
	
	for (; i > 0; i--)
	{
		if (get_func_id("RM_RegisterPlugin",i) >= 0)
		{
			g_hBasePlugin = i;
			break;
		}
	}
	
 	return g_hBasePlugin;
}


stock g_hCurrentPlugin = -1;

stock rm_current_plugin_id()
{
	if (g_hCurrentPlugin != -1)
		return g_hCurrentPlugin;
	g_hCurrentPlugin = get_plugin(-1);
	return g_hCurrentPlugin;
}

stock rm_show_dhud_message(id, posid, color[3], Float:ftime,bool:specs, const formatstr[], any:...)
{
	static dhud_text[512];
	vformat(dhud_text, charsmax(dhud_text), formatstr, 7);
	
	set_dhudmessage(color[0], color[1], color[2], -1.0, 0.46 + posid * 0.045, 0, 0.0, ftime, 0.0, 0.0);
	show_dhudmessage(id, "%s", dhud_text);
	
	if (specs)
	{
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "bch" );
		for( new i = 0; i < iNum; i++ )
		{
			new spec_id = iPlayers[ i ];
			new specTarget = get_entvar(spec_id, var_iuser2);
			if (specTarget == id)
			{
				set_dhudmessage(color[0], color[1], color[2], -1.0,  0.51 + posid * 0.05, 0, 0.0, ftime, 0.0, 0.0);
				show_dhudmessage(spec_id, "%s", dhud_text);
			}
		}
	}
}