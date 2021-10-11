#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <rm_api>

new bool:g_iSpeed[MAX_PLAYERS + 1] = {false,...};
const MovingBits = ( IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT );

#define RUNE_SPEED_MULT 2.0

public plugin_init()
{
	register_plugin("Speed_rune","1.1","Karaulov"); // Thanks for Hawk552 original code
	rm_register_rune(rm_current_plugin_id(),"Ускорение","Увеличивает скорость игрока",Float:{255.0,0.0,0.0}, "DEFAULT MODEL");
}

public rm_give_rune(id)
{
	g_iSpeed[id] = true;
}

public rm_drop_rune(id)
{
	g_iSpeed[id] = false;
}

public client_PreThink(id)
{
	if( g_iSpeed[id] && is_user_onground(id) && entity_get_int(id, EV_INT_button) & MovingBits )
	{
		new Float:iSpeed = RUNE_SPEED_MULT;
		new vTargetOrigin[3],vUserOrigin[3];
		new Float:vTargetOrigin_fl[3];
		get_user_origin(id, vUserOrigin, Origin_Client);
		get_user_origin(id, vTargetOrigin, Origin_AimEndClient);
		IVecFVec(vTargetOrigin,vTargetOrigin_fl);
		vTargetOrigin_fl[0] -= vUserOrigin[0];
		vTargetOrigin_fl[0] *= iSpeed;
		vTargetOrigin_fl[1] -= vUserOrigin[1];
		vTargetOrigin_fl[1] *= iSpeed;
		vTargetOrigin_fl[2] = floatclamp(vTargetOrigin_fl[2],-20.0,0.0);
		entity_set_vector(id,EV_VEC_velocity,vTargetOrigin_fl);
	}

	return PLUGIN_CONTINUE;
}