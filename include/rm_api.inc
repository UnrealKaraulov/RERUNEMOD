#if defined _RUNEMOD_RELOAD
  #endinput
#endif
#define _RUNEMOD_RELOAD

#include <engine>

stock rm_register_rune(OwnIndex, RuneName[], RuneDesc[], Float:RuneColor[3], Model[])
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
	callfunc_push_int(OwnIndex)
	callfunc_push_str(RuneName)
	callfunc_push_str(RuneDesc)
	callfunc_push_float(RuneColor[0])
	callfunc_push_float(RuneColor[1])
	callfunc_push_float(RuneColor[2])
	callfunc_push_str(Model)
	return callfunc_end()
}

stock rm_base_plugin_id()
{
	new num_of_plugins = get_pluginsnum()
	new name[64];
	for (new i = 0; i < num_of_plugins; ++i)
	{
		get_plugin(i, name, 63)
 		if(equal(name,"rm_base.amxx"))
 			return i;
	}
 	return -1;
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

stock rm_base_drop_plugin()
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