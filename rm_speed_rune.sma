#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fakemeta>
#include <fun>

new g_iSpeed[MAX_PLAYERS + 1] = {0,...};
const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

#define RUNE_SPEED_MULT 1.2;

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_SPEED","2.4","Karaulov");
	rm_register_rune("rm_speed_rune_name","rm_speed_rune_desc",Float:{0.0,0.0,255.0}, "models/rm_reloaded/rune_skyblue.mdl", "rm_reloaded/speedup.wav",rune_model_id);
	RegisterHookChain(RG_PM_Move, "PM_Move", .post=false);
	set_task(30.0, "update_server_speed", 1, _, _, "b");
	update_server_speed(1);
	
	rm_base_set_rune_cost(9000);
}

public update_server_speed(id)
{
	server_cmd("sv_maxspeed 9999")
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/rune_skyblue.mdl");
	if (file_exists("sound/rm_reloaded/speedup.wav"))
	{
		precache_generic("sound/rm_reloaded/speedup.wav");
	}
}

public PM_Move(const id)
{
	if( is_real_player(id) )
	{
		if (g_iSpeed[id] == 1 && get_entvar(id, var_button) & MovingBits )
		{
			set_user_maxspeed(id,  750.0)
			set_pmove(pm_maxspeed, 750.0)
			set_pmove(pm_clientmaxspeed, 750.0)
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
