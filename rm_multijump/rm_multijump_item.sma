#include <amxmodx>
#include <amxmisc>
#include <rm_api>

new const MULTIJUMP_COUNT = 10;

new g_bHasMultiJump[MAX_PLAYERS + 1] = {0,...};


new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_JUMP","1.3","Karaulov");
	rm_register_dictionary("runemod_mj_item.txt");
	rm_register_rune("rm_multijump_item_name","rm_multijump_item_desc",Float:{0.0,255.0,0.0}, "models/rm_reloaded/w_multijump.mdl", _,rune_model_id);
	rm_base_use_rune_as_item( );
	
	RegisterHookChain(RG_CBasePlayer_Jump, "HC_CBasePlayer_Jump_Pre", .post = false);
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/w_multijump.mdl");
}

public client_putinserver(id)
{
	g_bHasMultiJump[id] = 0;
	if (task_exists(id))
		remove_task(id);
}

public client_disconnected(id)
{
	g_bHasMultiJump[id] = 0;
	if (task_exists(id))
		remove_task(id);
}

public rm_give_rune(id)
{
	if (g_bHasMultiJump[id] > 0)
		return NO_RUNE_PICKUP_SUCCESS;
	if (task_exists(id))
		remove_task(id);
	g_bHasMultiJump[id] = MULTIJUMP_COUNT;
	set_task(0.5,"update_jump_state",id, _, _, "b");
	return RUNE_PICKUP_SUCCESS;
}

public update_jump_state(id)
{
	set_dhudmessage(255, 150, 0, -1.0, 0.60, 0, 0.0, 0.55, 0.0, 0.0);
	show_dhudmessage(id, "JUMP: [ %d / %d ]", g_bHasMultiJump[id],MULTIJUMP_COUNT);
	
		
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "bch" );
	for( new i = 0; i < iNum; i++ )
	{
		new spec_id = iPlayers[ i ];
		new specTarget = get_entvar(spec_id, var_iuser2);
		if (specTarget == id)
		{
			set_dhudmessage(255, 150, 0, -1.0, 0.60, 0, 0.0, 0.55, 0.0, 0.0);
			show_dhudmessage(spec_id, "JUMP: [ %d / %d ]", g_bHasMultiJump[id],MULTIJUMP_COUNT);
		}
	}
}

public HC_CBasePlayer_Jump_Pre(id) 
{
	if (g_bHasMultiJump[id] > 0)
	{
		new iFlags = get_entvar(id,var_flags);
		if (iFlags & FL_WATERJUMP)
		{
			return HC_CONTINUE;
		}
		
		if (iFlags & FL_ONGROUND)
		{
			return HC_CONTINUE;
		}
		
		if (get_entvar(id,var_waterlevel) >= 2)
		{
			return HC_CONTINUE;
		}
		
		if (!(get_member(id,m_afButtonPressed) & IN_JUMP))
		{
			return HC_CONTINUE;
		}
		
		new Float:fVelocity[3];
		get_entvar(id, var_velocity, fVelocity);
		
		
		fVelocity[0] *= 1.25;
		fVelocity[1] *= 1.25;
		fVelocity[2] = 350.0;
		
		set_entvar(id, var_velocity, fVelocity);
		
	
		g_bHasMultiJump[id] -= 1;
		
		if (g_bHasMultiJump[id] == 0)
		{
			if (task_exists(id))
				remove_task(id);
			rm_base_drop_item_notice(id);
		}
		return HC_BREAK;
	}
	return HC_CONTINUE;
}