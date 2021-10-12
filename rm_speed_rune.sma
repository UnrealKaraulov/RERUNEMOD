#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <rm_api>
#include <fakemeta>
#include <reapi>

new bool:g_iSpeed[MAX_PLAYERS + 1] = {false,...};
const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

#define RUNE_SPEED_MULT 1.2

public plugin_init()
{
	register_plugin("Speed_rune","1.1","Karaulov"); // Thanks for Hawk552 original code
	rm_register_rune(rm_current_plugin_id(),"Ускорение","Увеличивает скорость игрока",Float:{0.0,0.0,255.0}, "DEFAULT MODEL");
	RegisterHookChain(RG_PM_Move, "PM_Move", .post=false)
}
public PM_Move(const id)
{
	if( is_user_connected(id) && g_iSpeed[id] && entity_get_int(id, EV_INT_button) & MovingBits )
	{
		new cmdx = get_pmove( pm_cmd );
		new Float:forwardmove = get_ucmd(cmdx, ucmd_forwardmove)
		new Float:sidemove = get_ucmd(cmdx, ucmd_sidemove)
		
		forwardmove *= 1.1;
		sidemove *= 1.1;
			
		set_pev(id, pev_maxspeed, 650.0);
		set_pmove(pm_maxspeed, 700.0)
		set_pmove(pm_clientmaxspeed, 625.0)
		
		set_ucmd(cmdx, ucmd_forwardmove,forwardmove);
		set_ucmd(cmdx, ucmd_sidemove,sidemove);
		
	}
}

public rm_give_rune(id)
{
	g_iSpeed[id] = true;
}

public rm_drop_rune(id)
{
	g_iSpeed[id] = false;
	if (is_user_connected(id))
		set_pev(id, pev_maxspeed, 0.0);
}

/*public client_PreThink(id)
{
	if( g_iSpeed[id] && is_user_connected(id) && !(entity_get_int(id, EV_INT_button) & MovingBits) )
	{
		if (!is_user_onground(id))
		{
			new Float:vel[3];
			entity_get_vector(id,EV_VEC_velocity,vel);
			
			if (vel[2] < -100.0 )
				vel[2] = -100.0;
			
			entity_set_vector(id,EV_VEC_velocity,vel);
		}
	}

	return PLUGIN_CONTINUE;
}*/