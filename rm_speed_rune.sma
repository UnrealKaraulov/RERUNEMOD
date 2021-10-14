#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <rm_api>
#include <fakemeta>
#include <reapi>

new g_iSpeed[MAX_PLAYERS + 1] = {0,...};
const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

#define RUNE_SPEED_MULT 1.2

public plugin_init()
{
	register_plugin("Speed_rune","1.1","Karaulov"); // Thanks for Hawk552 original code
	rm_register_rune("Уcкopeниe","Увeличивaeт cкopocть игpoкa",Float:{0.0,0.0,255.0}, _,"rm_reloaded/speedup.wav");
	RegisterHookChain(RG_PM_Move, "PM_Move", .post=false)
}

public plugin_precache()
{
	if (file_exists("sound/rm_reloaded/speedup.wav"))
	{
		precache_sound("rm_reloaded/speedup.wav");
	}
}

public PM_Move(const id)
{
	if( id > 0 && id < 33 )
	{
		if (g_iSpeed[id] == 1 && entity_get_int(id, EV_INT_button) & MovingBits )
		{
			set_pev(id, pev_maxspeed, 600.0);
			set_pmove(pm_maxspeed, 700.0)
			set_pmove(pm_clientmaxspeed, 800.0)
		}
		else if (g_iSpeed[id] == 2)
		{
			set_pev(id, pev_maxspeed, 240.0);
			set_pmove(pm_maxspeed, 300.0)
			set_pmove(pm_clientmaxspeed, 240.0)
			g_iSpeed[id] = 0;
		}
	}
}

public rm_give_rune(id)
{
	g_iSpeed[id] = 1;
}

public rm_drop_rune(id)
{
	g_iSpeed[id] = 0;
	if (is_user_connected(id))
	{	
		set_pev(id, pev_maxspeed, 240.0);
		if (is_user_alive(id))
		{
			g_iSpeed[id] = 2;
		}
	}
}
