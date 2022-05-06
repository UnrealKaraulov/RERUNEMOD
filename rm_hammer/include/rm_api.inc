#if defined _RUNEMOD_RELOAD
  #endinput
#endif

#define _RUNEMOD_RELOAD

#define RUNEMOD_VERSION "3.1.4"


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

// Магическое число для быстрого детекта руны
#define RUNEMODE_MAGIC_NUMBER 14343390

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
*
* @noreturn
*/
stock rm_register_rune(RuneName[], RuneDesc[], Float:RuneColor[3], rModel[] = "", rSound[] = "", rModelID = -1)
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
* 
* @return RUNE_PICKUP_SUCCESS/NO_RUNE_PICKUP_SUCCESS или ничего
*/
stock rm_give_rune_callback(OwnIndex, id)
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
	new retval = callfunc_end();
	return retval;
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
	return callfunc_end() == RUNEMODE_MAGIC_NUMBER;
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

// Функция проверяет не находится ли игрок на земле
stock bool:is_user_onground( id )
{
	new flags = get_entvar(id, var_flags);
	if( flags & FL_ONGROUND )
	{
		return get_entvar(id,var_groundentity) == 0;
	}
	return false;
}

// Пpoвepкa peaльный ли игpoк
stock bool:is_real_player( id )
{
	return id > 0 && id < 33;
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
	new g_pCommonTr = create_tr2();
	new Float:Origin[3];
	get_entvar(id, var_origin, Origin);
	
	new iHull, iSpawnPoint, i;
	iHull = (get_entvar(id, var_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN;
	
	// fast unstuck 
	if(!rm_is_hull_vacant(id,Origin,iHull, g_pCommonTr))
	{
		Origin[2] -= 64.0;
	}
	else
	{
		engfunc(EngFunc_SetOrigin, id, Origin);
		free_tr2(g_pCommonTr);
		return true;
	}
	if(!rm_is_hull_vacant(id,Origin,iHull, g_pCommonTr))
	{
		Origin[2] += 128.0;
	}
	else
	{
		engfunc(EngFunc_SetOrigin, id, Origin);
		free_tr2(g_pCommonTr);
		return true;
	}
	
	if(!rm_is_hull_vacant(id,Origin,iHull, g_pCommonTr))
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
				if (rm_is_hull_vacant(id, flOriginFinal, iHull, g_pCommonTr))
				{
					i = iSpawnPoint;
					engfunc(EngFunc_SetOrigin, id, flOriginFinal);
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
		free_tr2(g_pCommonTr);
		return true;
	}
	
	free_tr2(g_pCommonTr);
	return false;
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

