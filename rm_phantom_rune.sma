#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fun>

new Float:g_Phantom[MAX_PLAYERS + 1] = {0.0,...};
new Float:g_Phantom_origins[MAX_PLAYERS + 1][3];
new g_Phantom_activated[MAX_PLAYERS + 1] = {0, ...};

new rune_model_id = -1;

new rune_name[] = "rm_phantom_rune_name";
new rune_descr[] = "rm_phantom_rune_desc";

new rune_model_path[64] = "models/rm_reloaded/rune_magenta.mdl";
new rune_sound_path[64] = "sound/rm_reloaded/phantom.wav";

new Float:g_flNoclipSpeed = 500.0;
new Float:g_flMaxDistance = 1300.0;

public plugin_init()
{
	register_plugin("RM_PHANTOM","3.0","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{255.0,0.0,255.0}, rune_model_path, rune_sound_path, rune_model_id);
	RegisterHookChain(RG_PM_Move, "PM_Move", .post=false);
	
	/* Чтение конфигурации */
	new cost = 7700;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);

	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	new max_count = 10;
	rm_read_cfg_int(rune_name,"MAX_COUNT_ON_MAP",max_count,max_count);
	rm_base_set_max_count( max_count );
	
	// Скорость в призрачном режиме
	rm_read_cfg_flt(rune_name,"NOCLIP_SPEED",g_flNoclipSpeed,g_flNoclipSpeed);
	
	// Возврат обратно при превышении дистанции
	rm_read_cfg_flt(rune_name,"NOCLIP_DISTANCE",g_flMaxDistance,g_flMaxDistance);
}

public PM_Move(const id)
{
	if( is_real_player(id) )
	{
		if (g_Phantom_activated[id] == 1)
		{
			new cmd = get_pmove( pm_cmd );
			set_movevar(mv_maxspeed, g_flNoclipSpeed);
			set_user_maxspeed(id,  g_flNoclipSpeed);
			set_pmove(pm_maxspeed, g_flNoclipSpeed);
			set_pmove(pm_clientmaxspeed, g_flNoclipSpeed);
			new Float:fmove = get_ucmd(cmd, ucmd_forwardmove);
			if (fmove > 20.0 && fmove < g_flNoclipSpeed)
				fmove = g_flNoclipSpeed;
			else if (fmove < -20.0 && fmove > -g_flNoclipSpeed)
				fmove = -g_flNoclipSpeed;
			set_ucmd(cmd, ucmd_forwardmove, fmove);
			
			
			fmove = get_ucmd(cmd, ucmd_sidemove);
			if (fmove > 20.0 && fmove < g_flNoclipSpeed)
				fmove = g_flNoclipSpeed;
			else if (fmove < -20.0 && fmove > -g_flNoclipSpeed)
				fmove = -g_flNoclipSpeed;
			set_ucmd(cmd, ucmd_sidemove, fmove);
		}
		else if (g_Phantom_activated[id] == 2)
		{
			set_user_maxspeed(id, 1.0)
			set_pmove(pm_maxspeed, 300.0)
			set_pmove(pm_clientmaxspeed, 240.0)
			g_Phantom_activated[id] = 0;
		}
	}
}

public plugin_precache()
{
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"model",rune_model_path,rune_model_path,charsmax(rune_model_path));
	rm_read_cfg_str(rune_name,"sound",rune_sound_path,rune_sound_path,charsmax(rune_sound_path));

	rune_model_id = precache_model(rune_model_path);
	
	if (file_exists(rune_sound_path,true))
	{
		precache_generic(rune_sound_path);
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
	if (g_Phantom_activated[id] == 1 && is_user_alive(id))
	{
		if (!rm_unstuck_player(id) && !is_empty_origin(id))
		{
			engfunc(EngFunc_SetOrigin, id, g_Phantom_origins[id]);
		}
	}
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
	g_Phantom_activated[id] = 1;
}

public deactivate_phantom_mode(id)
{
	if (is_user_connected(id))
	{
		UTIL_ScreenFade(id, _, _, _,_,true,true);
		set_entvar(id, var_movetype, MOVETYPE_WALK);
		g_Phantom_activated[id] = 2;
		reset_origins(id);
	}
}

public phantom_think(id)
{
	if (g_Phantom[id] > 0.0 )
	{
		if (g_Phantom_activated[id] == 0)
		{
			if (get_entvar(id, var_button) & IN_FORWARD)
			{
				if (get_gametime() - g_Phantom[id] > 0.2)
				{
					if (is_empty_origin(id))
					{
						get_entvar(id, var_origin, g_Phantom_origins[id]);
					}
					else 
					{
						new Float:Origin[3];
						get_entvar(id, var_origin, Origin);
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
			new Float:Origin[3];
			get_entvar(id, var_origin, Origin);
			if (get_gametime() - g_Phantom[id] > 3.5 || get_distance_f(Origin,g_Phantom_origins[id]) > g_flMaxDistance)
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