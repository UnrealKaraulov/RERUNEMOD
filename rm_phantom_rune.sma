#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new Float:g_Phantom[MAX_PLAYERS + 1] = {0.0,...};
new Float:g_Phantom_origins[MAX_PLAYERS + 1][3];
new bool:g_Phantom_activated[MAX_PLAYERS + 1] = {false, ...};

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_PHANTOM","2.4","Karaulov"); 
	rm_register_rune("rm_phantom_rune_name","rm_phantom_rune_desc",Float:{255.0,0.0,255.0}, "models/rm_reloaded/rune_magenta.mdl", "rm_reloaded/phantom.wav",rune_model_id);
	RegisterHookChain(RG_PM_Move, "PM_Move", .post=false);
	
	rm_base_set_rune_cost(10000);
}

public PM_Move(const id)
{
	if( is_real_player(id) )
	{
		if (g_Phantom_activated[id])
		{
			set_entvar(id, var_speed, 500.0);
			set_entvar(id, var_maxspeed, 240.0);
			set_pmove(pm_maxspeed, 300.0)
			set_pmove(pm_clientmaxspeed, 240.0)
		}
	}
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/rune_magenta.mdl");
	if (file_exists("sound/rm_reloaded/phantom.wav"))
	{
		precache_generic("sound/rm_reloaded/phantom.wav");
	}
}

public reset_origins(id)
{
	g_Phantom_origins[id][0] = g_Phantom_origins[id][1] = g_Phantom_origins[id][2] = 0.0;
}

public rm_give_rune(id)
{
	g_Phantom[id] = 1.0;
	rm_base_highlight_player(id);
	reset_origins(id);
	if (task_exists(id))
		remove_task(id);
	set_task(0.1,"phantom_think",id, _, _, "b");
}

public rm_drop_rune(id)
{
	g_Phantom[id] = 0.0;
	if (g_Phantom_activated[id] && is_user_alive(id))
	{
		if (!rm_unstuck_player(id) && !is_empty_origin(id))
		{
			engfunc(EngFunc_SetOrigin, id, g_Phantom_origins[id]);
		}
	}
	g_Phantom_activated[id] = false;
	reset_origins(id);
	deactivate_phantom_mode(id);
	if (task_exists(id))
		remove_task(id);
}

public is_empty_origin(id)
{
	return g_Phantom_origins[id][0] == 0.0 && 
	g_Phantom_origins[id][1] == 0.0 && g_Phantom_origins[id][2] == 0.0;
}

public activate_phantom_mode(id)
{
	UTIL_ScreenFade(id,{0,0,255},1.0,6.0,240,FFADE_MODULATE,true,true);
	set_entvar(id, var_movetype, MOVETYPE_NOCLIP);
	g_Phantom_activated[id] = true;
	set_entvar(id, var_speed, 500.0);
	set_entvar(id, var_maxspeed, 240.0);
}

public deactivate_phantom_mode(id)
{
	if (is_user_connected(id))
	{
		UTIL_ScreenFade(id, _, _, _,_,true,true);
		set_entvar(id, var_movetype, MOVETYPE_WALK);
		g_Phantom_activated[id] = false;
		reset_origins(id);
	}
}

public phantom_think(id)
{
	if (g_Phantom[id] > 0.0 )
	{
		if (!g_Phantom_activated[id])
		{
			if (get_entvar(id, var_button) & IN_FORWARD)
			{
				if (get_gametime() - g_Phantom[id] > 0.2)
				{
					if (is_empty_origin(id))
					{
						get_entvar(id, var_origin, g_Phantom_origins[id])
					}
					else 
					{
						new Float:Origin[3]
						get_entvar(id, var_origin, Origin)
						if ( get_distance_f(Origin,g_Phantom_origins[id]) < 5.0 )
						{
							activate_phantom_mode(id);
						}
						else 
						{
							reset_origins(id);
						}
					}
					g_Phantom[id] = get_gametime();
				}
			}
			else 
			{
				reset_origins(id);
			}
		}
		else 
		{
			if (get_gametime() - g_Phantom[id] > 5.0)
			{
				if (!rm_unstuck_player(id) && !is_empty_origin(id))
				{
					engfunc(EngFunc_SetOrigin, id, g_Phantom_origins[id]);
				}
				deactivate_phantom_mode(id);
				g_Phantom[id] = get_gametime() + 2.0;
			}
		}
	}
}