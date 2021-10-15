
#if defined _RUNEMOD_RELOAD
  #endinput
#endif
#define _RUNEMOD_RELOAD


#define HUD_CHANNEL_ID 3
#define HUD_CHANNEL_ID_2 2

#if !defined _engine_included
	#include <engine>
#endif

#if !defined _reapi_included
	#include <reapi>
#endif

stock rm_register_rune(RuneName[], RuneDesc[], Float:RuneColor[3], rModel[] = "", rSound[] = "")
{
	new BasePluginIndex = rm_base_plugin_id()
	new BasePluginRegFunc = get_func_id("RM_RegisterPlugin",BasePluginIndex)
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND")
		return PLUGIN_HANDLED	
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex)
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR")
		return PLUGIN_HANDLED		
	}
	callfunc_push_int(rm_current_plugin_id())
	callfunc_push_str(RuneName)
	callfunc_push_str(RuneDesc)
	callfunc_push_float(RuneColor[0])
	callfunc_push_float(RuneColor[1])
	callfunc_push_float(RuneColor[2])
	callfunc_push_str(rModel)
	callfunc_push_str(rSound)
	return callfunc_end()
}


public rm_base_plugin_id()
{
	static pluginid = -1;
	
	/*if (pluginid != -1)
	{	
		log_amx("USE STATIC! %d", pluginid); 
		return pluginid;
	}*/
	
	new num_of_plugins = get_pluginsnum()
	for (new i = 0; i < num_of_plugins; ++i)
	{
		if (get_func_id("RM_RegisterPlugin",i) >= 0)
		{
			pluginid = i;
			break;
		}
	}
	
 	return pluginid;
}

stock rm_current_plugin_id()
{
	return get_plugin(-1)
}

stock rm_give_rune_callback(OwnIndex, id)
{
	new PluginReqFunc = get_func_id("rm_give_rune",OwnIndex)
	if(PluginReqFunc == -1)
	{
		return PLUGIN_HANDLED		
	}
	new Temp = callfunc_begin_i(PluginReqFunc,OwnIndex)
	if(Temp != 1)
	{
		log_amx("rm_give_rune error")
		return PLUGIN_HANDLED		
	}
	callfunc_push_int(id)
	return callfunc_end();
}

stock rm_drop_rune_callback(OwnIndex, id)
{
	new PluginReqFunc = get_func_id("rm_drop_rune",OwnIndex)
	if(PluginReqFunc == -1)
	{
		return PLUGIN_HANDLED		
	}
	new Temp = callfunc_begin_i(PluginReqFunc,OwnIndex)
	if(Temp != 1)
	{
		log_amx("rm_drop_rune error")
		return PLUGIN_HANDLED		
	}
	callfunc_push_int(id)
	return callfunc_end();
}

stock rm_base_drop_plugin(id)
{
	new BasePluginIndex = rm_base_plugin_id()
	new BasePluginRegFunc = get_func_id("rm_drop_rune_api",BasePluginIndex)
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 2")
		return PLUGIN_HANDLED	
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex)
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 2")
		return PLUGIN_HANDLED		
	}
	callfunc_push_int(rm_current_plugin_id())
	callfunc_push_int(id)
	return callfunc_end()
}

stock rm_use_rune_as_item( )
{
	new BasePluginIndex = rm_base_plugin_id()
	new BasePluginRegFunc = get_func_id("rm_rune_set_item",BasePluginIndex)
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 3")
		return PLUGIN_HANDLED	
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex)
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 3")
		return PLUGIN_HANDLED		
	}
	callfunc_push_int(rm_current_plugin_id())
	return callfunc_end()
}

stock rm_base_highlight_player(id)
{
	new BasePluginIndex = rm_base_plugin_id()
	new BasePluginRegFunc = get_func_id("rm_highlight_player",BasePluginIndex)
	if (BasePluginRegFunc == -1)
	{
		log_amx("NO BASE FUNC FOUND 4")
		return PLUGIN_HANDLED	
	}
	new Temp = callfunc_begin_i(BasePluginRegFunc,BasePluginIndex)
	if(Temp != 1)
	{
		log_amx("CALL BASE FUNC ERROR 4")
		return PLUGIN_HANDLED		
	}
	callfunc_push_int(rm_current_plugin_id())
	callfunc_push_int(id)
	
	return callfunc_end()
}


// Функция проверяет не находится ли игрок на земле
stock bool:is_user_onground( id )
{
	new flags = entity_get_int(id, EV_INT_flags);
	if( flags & FL_ONGROUND )
	{
		return true;
	}
	return false;
}


// Пpoвepкa peaльный ли игpoк
stock bool:is_real_player( id )
{
	return id > 0 && id < 33;
}

stock rg_set_rendering(const pEntity, const fx = kRenderFxNone, const Float:flColor[] = {0.0, 0.0, 0.0}, const Float:iAmount = 0.0)
{
	set_entvar(pEntity, var_renderfx, fx)
	set_entvar(pEntity, var_rendercolor, flColor)
	set_entvar(pEntity, var_renderamt, iAmount)
}