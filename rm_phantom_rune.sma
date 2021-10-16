#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fun>
#include <fakemeta>

#define TSC_Vector_MA(%1,%2,%3,%4)	(%4[0] = %2[0] * %3 + %1[0], %4[1] = %2[1] * %3 + %1[1])


new Float:g_Phantom[MAX_PLAYERS + 1] = {0.0,...};
new Float:g_Phantom_origins[MAX_PLAYERS + 1][3];
new bool:g_Phantom_activated[MAX_PLAYERS + 1] = {false, ...};

new g_pCommonTr

public plugin_init()
{
	register_plugin("Phantom_rune","1.1","Karaulov"); 
	rm_register_rune("Призрак","Игрок может ходить сквозь стены!",Float:{255.0,50.0,200.0}, _,"rm_reloaded/phantom.wav");
	g_pCommonTr = create_tr2()
}

public plugin_end()
{
	free_tr2(g_pCommonTr)
}

public plugin_precache()
{
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
	reset_origins(id);
}

public rm_drop_rune(id)
{
	g_Phantom[id] = 0.0;
	reset_origins(id);
	if (g_Phantom_activated[id] && is_user_alive(id))
	{
		end_phantom_mode(id);
		deactivate_phantom_mode(id);
	}
	g_Phantom_activated[id] = false;
}

public is_empty_origin(id)
{
	return g_Phantom_origins[id][0] == 0.0 && 
	g_Phantom_origins[id][1] == 0.0 && g_Phantom_origins[id][2] == 0.0;
}

public activate_phantom_mode(id)
{
	entity_set_int(id, EV_INT_movetype, MOVETYPE_NOCLIP);
	set_rendering(id,kRenderFxGlowShell,255,180,0,kRenderNormal,30);
	g_Phantom_activated[id] = true;
}

public deactivate_phantom_mode(id)
{
	reset_origins(id);
	entity_set_int(id, EV_INT_movetype, MOVETYPE_WALK);
	set_user_rendering(id, kRenderFxNone, 255, 255, 255, kRenderNormal, 255);
	g_Phantom_activated[id] = false;
}

public client_PostThink(id)
{
	if ( is_real_player(id) && g_Phantom[id] > 0.0 )
	{
		if (!g_Phantom_activated[id])
		{
			if (is_user_alive(id))
			{
				if (entity_get_int(id, EV_INT_button) & IN_FORWARD)
				{
					if (get_gametime() - g_Phantom[id] > 1.25)
					{
						if (is_empty_origin(id))
						{
							pev(id, pev_origin, g_Phantom_origins[id])
						}
						else 
						{
							new Float:Origin[3]
							pev(id, pev_origin, Origin)
							if ( get_distance_f(Origin,g_Phantom_origins[id]) < 5.0 )
							{
								activate_phantom_mode(id);
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
				reset_origins(id);
			}
		}
		else 
		{
			if (!is_user_alive(id))
			{
				deactivate_phantom_mode(id);
			}
			else 
			{
				if (get_gametime() - g_Phantom[id] > 5.0)
				{
					end_phantom_mode(id);
					deactivate_phantom_mode(id);
				}
			}
		}
	}
}


public bool:is_player_stuck(id,Float:originF[3], iHull)
{
	engfunc(EngFunc_TraceHull, originF, originF, 0, iHull, id, g_pCommonTr)
	
	if (get_tr2(g_pCommonTr, TR_StartSolid) || get_tr2(g_pCommonTr, TR_AllSolid) || !get_tr2(g_pCommonTr, TR_InOpen))
		return true
	
	return false
}

public bool:is_hull_vacant(id, Float:origin[3], iHull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, iHull, id, g_pCommonTr)
	
	if (!get_tr2(g_pCommonTr, TR_StartSolid) && !get_tr2(g_pCommonTr, TR_AllSolid) && get_tr2(g_pCommonTr, TR_InOpen))
		return true
	
	return false
}

public bool:end_phantom_mode(id)
{
	static Float:Origin[3]
	pev(id, pev_origin, Origin)
	static iHull, iSpawnPoint, i
	iHull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	// fast unstuck 
	if(is_player_stuck(id,Origin,iHull))
	{
		Origin[2] -= 64.0
	}
	else
	{
		engfunc(EngFunc_SetOrigin, id, Origin)	
		return true;
	}
	if(is_player_stuck(id,Origin,iHull))
	{
		Origin[2] += 128.0
	}
	else
	{
		engfunc(EngFunc_SetOrigin, id, Origin)	
		return true;
	}
	
	if(is_player_stuck(id,Origin,iHull))
	{
		Origin = g_Phantom_origins[id];
		if(is_player_stuck(id,Origin,iHull))
		{
			static const Float:RANDOM_OWN_PLACE[][3] =
			{
				{ -96.5,   0.0, 0.0 },
				{  96.5,   0.0, 0.0 },
				{   0.0, -96.5, 0.0 },
				{   0.0,  96.5, 0.0 },
				{ -96.5, -96.5, 0.0 },
				{ -96.5,  96.5, 0.0 },
				{  96.5,  96.5, 0.0 },
				{  96.5, -96.5, 0.0 }
			}
			
			new Float:flOrigin[3], Float:flOriginFinal[3], iSize
			pev(id, pev_origin, flOrigin)
			iSize = sizeof(RANDOM_OWN_PLACE)
			
			iSpawnPoint = random_num(0, iSize - 1)
			
			for (i = iSpawnPoint + 1; /*no condition*/; i++)
			{
				if (i >= iSize)
					i = 0
				
				flOriginFinal[0] = flOrigin[0] + RANDOM_OWN_PLACE[i][0]
				flOriginFinal[1] = flOrigin[1] + RANDOM_OWN_PLACE[i][1]
				flOriginFinal[2] = flOrigin[2]
				
				engfunc(EngFunc_TraceLine, flOrigin, flOriginFinal, IGNORE_MONSTERS, id, 0)
				
				new Float:flFraction
				get_tr2(0, TR_flFraction, flFraction)
				if (flFraction < 1.0)
				{
					new Float:vTraceEnd[3], Float:vNormal[3]
					get_tr2(0, TR_vecEndPos, vTraceEnd)
					get_tr2(0, TR_vecPlaneNormal, vNormal)
					
					TSC_Vector_MA(vTraceEnd, vNormal, 32.5, flOriginFinal)
				}
				flOriginFinal[2] -= 35.0
				
				new iZ = 0
				do
				{
					if (is_hull_vacant(id, flOriginFinal, iHull))
					{
						i = iSpawnPoint
						engfunc(EngFunc_SetOrigin, id, flOriginFinal)
						break
					}
					
					flOriginFinal[2] += 40.0
				}
				while (++iZ <= 2)
				
				if (i == iSpawnPoint)
					break
			}
		}
		else 
		{
			engfunc(EngFunc_SetOrigin, id, Origin)	
		}
	}
	else
	{
		engfunc(EngFunc_SetOrigin, id, Origin)	
		return true;
	}
	
	return false;
}
