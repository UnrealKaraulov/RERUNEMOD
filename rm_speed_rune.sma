#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fakemeta>
#include <fun>

new g_iSpeed[MAX_PLAYERS + 1] = {0,...};
const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

#define RUNE_SPEED_MULT 1.2;

new rune_model_id = -1;

new rune_name[] = "rm_speed_rune_name";
new rune_descr[] = "rm_speed_rune_desc";

new rune_model_path[64] = "models/rm_reloaded/rune_skyblue.mdl";
new rune_sound_path[64] = "sound/rm_reloaded/speedup.wav";

new Float:g_fSpeed = 750.0;

new g_iCfgSpawnSecondsDelay = 0;

public plugin_init()
{
	register_plugin("RM_SPEED","2.7","Karaulov");
	rm_register_rune(rune_name,rune_descr,Float:{0.0,0.0,255.0}, rune_model_path, rune_sound_path,rune_model_id);
	RegisterHookChain(RG_PM_Move, "PM_Move", .post=false);
	
	/* Чтение конфигурации */
	new cost = 9000;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	/* Чтение конфигурации */
	rm_read_cfg_flt(rune_name,"SPEED",g_fSpeed,g_fSpeed);
	
	if (g_fSpeed < 400.0)
		g_fSpeed = 400.0;

	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	new max_count = 10;
	rm_read_cfg_int(rune_name,"MAX_COUNT_ON_MAP",max_count,max_count);
	rm_base_set_max_count( max_count );
	// Задержка между спавнами
	rm_read_cfg_int(rune_name,"DELAY_BETWEEN_NEXT_SPAWN",g_iCfgSpawnSecondsDelay,g_iCfgSpawnSecondsDelay);
}

new Float:flLastSpawnTime = 0.0;

public rm_spawn_rune(iEnt)
{
	if (floatround(floatabs(get_gametime() - flLastSpawnTime)) > g_iCfgSpawnSecondsDelay)
	{
		flLastSpawnTime = get_gametime();
		return SPAWN_SUCCESS;
	}
	
	return SPAWN_ERROR;
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

public PM_Move(const id)
{
	if( is_real_player(id) )
	{
		if (g_iSpeed[id] == 1 && get_entvar(id, var_button) & MovingBits )
		{
			new cmd = get_pmove( pm_cmd );
			set_movevar(mv_maxspeed, g_fSpeed);
			set_user_maxspeed(id,  g_fSpeed);
			set_pmove(pm_maxspeed, g_fSpeed);
			set_pmove(pm_clientmaxspeed, g_fSpeed);
			
			new Float:fmove = get_ucmd(cmd, ucmd_forwardmove);
			if (fmove > 20.0 && fmove < g_fSpeed)
				fmove = g_fSpeed;
			else if (fmove < -20.0 && fmove > -g_fSpeed)
				fmove = -g_fSpeed;
			set_ucmd(cmd, ucmd_forwardmove, fmove);
			
			fmove = get_ucmd(cmd, ucmd_sidemove);
			if (fmove > 20.0 && fmove < g_fSpeed)
				fmove = g_fSpeed;
			else if (fmove < -20.0 && fmove > -g_fSpeed)
				fmove = -g_fSpeed;
			set_ucmd(cmd, ucmd_sidemove, fmove);
		}
		else if (g_iSpeed[id] == 2)
		{
			set_user_maxspeed(id, 1.0)
			set_pmove(pm_maxspeed, 300.0)
			set_pmove(pm_clientmaxspeed, 240.0)
			g_iSpeed[id] = 0;
		}
		
	}
}

public rm_give_rune(id)
{
	if (task_exists(id))
		remove_task(id)
	g_iSpeed[id] = 1;
	rm_base_highlight_player(id);
	rm_base_highlight_screen(id);
}

public rm_drop_rune(id)
{
	g_iSpeed[id] = 0;
	reset_speed(id);
	set_task(1.0,"reset_speed",id);
}

public reset_speed(id)
{
	if (is_user_connected(id))
	{	
		set_user_maxspeed(id, 1.0)
		g_iSpeed[id] = 2;
	}
}
