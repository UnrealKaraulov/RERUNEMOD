#if defined _RUNEMOD_RELOAD
  #endinput
#endif

#define _RUNEMOD_RELOAD

#define RUNEMOD_VERSION "3.5.1"


#define HUD_CHANNEL_ID 3
#define HUD_CHANNEL_ID_2 2

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

// Maкcимaльнoe кoличecтвo pyн - плaгинoв
#define MAX_REGISTER_RUNES 128

#define RUNEMODE_DEFAULT_HIGHLIGHT_POWER 100

#define SPAWN_SEARCH_TASK_ID 10000
#define UPDATE_RUNE_DESCRIPTION_HUD_ID 10002
#define UPDATE_RUNE_DESCRIPTION_HUD_TIME 1.0

#define RUNE_PICKUP_SUCCESS 1
#define NO_RUNE_PICKUP_SUCCESS 2

#define TSC_Vector_MA(%1,%2,%3,%4)	(%4[0] = %2[0] * %3 + %1[0], %4[1] = %2[1] * %3 + %1[1])


/*
* Регистрации новой руны
*
* @param RuneName		Название руны
* @param RuneDesc		Описание руны
* @param RuneColor		Цвет руны(подсветка игрока, экрана и модели)
* @param rModel			Путь к модели, иначе используется стандартная
* @param rSound			Путь к звуку, иначе используется стандартный
* @param rModelID		Индекс модели из прекеша (только если указана rModel)
* @param RuneGiveName	Название руны для выдачи или покупки
*
* @noreturn
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

/*
* Регистрации нового ланг файла (словарь)
*
* @param dictname		Название файла словаря
*
* @noreturn
*/
public rm_register_dictionary(const dictname[])
{
	register_dictionary(dictname);
	new BasePluginIndex = rm_base_plugin_id();
	new BasePluginRegFunc = get_func_id("rm_register_dictionary_api",BasePluginIndex);
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
	callfunc_push_str(dictname);
	return callfunc_end();
}

/*
* Вызывается когда игрок поднимает руну
*
* @param id				Индекс игрока
* @param ent			Руна
* 
* @return RUNE_PICKUP_SUCCESS/NO_RUNE_PICKUP_SUCCESS или ничего
*/
stock rm_give_rune_callback(OwnIndex, id, ent)
{
	new PluginReqFunc = get_func_id("rm_give_rune",OwnIndex);
	if(PluginReqFunc == -1)
	{
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(PluginReqFunc,OwnIndex);
	if(Temp != 1)
	{
		log_amx("rm_give_rune error");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(id);
	callfunc_push_int(ent);
	return callfunc_end();
}

/*
* Вызывается когда руна появляется на карте
*
* @param ent				Руна
* 
* @noreturn
*/
stock rm_spawn_rune_callback(OwnIndex, ent)
{
	new PluginReqFunc = get_func_id("rm_spawn_rune",OwnIndex);
	if(PluginReqFunc == -1)
	{
		return PLUGIN_HANDLED;
	}
	new Temp = callfunc_begin_i(PluginReqFunc,OwnIndex);
	if(Temp != 1)
	{
		log_amx("rm_spawn_rune error");
		return PLUGIN_HANDLED;
	}
	callfunc_push_int(ent);
	return callfunc_end();
}

/*
* Вызывается когда руна удаляется с карты
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
* @param id				Индекс игрока
* 
* @noreturn
*/
stock rm_drop_rune_callback(OwnIndex, id)
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
	return callfunc_end();
}

/*
* Выбросить руну
*
* @param id				Индекс игрока
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
* @param id				Индекс игрока
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
* @param id				Индекс игрока
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
* @param id						Индекс игрока
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
* @param id				Индекс игрока
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
* @param id				Индекс игрока
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
* @param id				Индекс игрока
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
* Предупредить игрока о необходимости зарегистрироваться на сайте!
*
* @param id			Индекс игрока
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
* Дать руну игроку из внешнего плагина
*
* @param id				индекс игрока
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
* @param id				Индекс игрока
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
* @param id				Индекс игрока
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

// Пpoвepкa peaльный ли игpoк
stock bool:is_real_player( id )
{
	return id > 0 && id < 33;
}

// Фyнкция coxpaняeт ид pyны в руну
public rm_set_rune_runeid( id, rune_id )
{
	return set_entvar(id, var_fuser4, float(rune_id) );
}

// Фyнкция вoзвpaщaeт ид pyны из руны
public rm_get_rune_runeid( id )
{
	return floatround(get_entvar(id, var_fuser4));
}

// Фyнкция coxpaняeт ид спавна в руну
public rm_set_rune_spawnid( id, spawn_id )
{
	return set_entvar(id, var_fuser3, float(spawn_id) );
}

// Фyнкция вoзвpaщaeт ид спавна из руны
public rm_get_rune_spawnid( id )
{
	return floatround(get_entvar(id, var_fuser3));
}


// Фyнкция coxpaняeт число в руну
public rm_set_rune_num( id, num )
{
	return set_entvar(id, var_iuser4, num );
}

// Фyнкция вoзвpaщaeт число из руны
public rm_get_rune_num( id )
{
	return get_entvar(id, var_iuser4);
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


static g_hBasePlugin = -1;
	
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


static g_hCurrentPlugin = -1;

stock rm_current_plugin_id()
{
	if (g_hCurrentPlugin != -1)
		return g_hCurrentPlugin;
	g_hCurrentPlugin = get_plugin(-1);
	return g_hCurrentPlugin;
}

