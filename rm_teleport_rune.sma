#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fun>
#include <fakemeta>
#include <xs>

new Float:g_Teleport[MAX_PLAYERS + 1] = {0.0,...};

new rune_name[] = "Телепорт";
new rune_descr[] = "Возьми нож и телепортируйся куда угодно! (+attack)";

new g_pCommonTr

public plugin_init()
{
	register_plugin("Teleport_rune","1.1","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{0.0,120.0,0.0}, _,"rm_reloaded/teleport.wav");
	g_pCommonTr = create_tr2()
}

public plugin_end()
{
	free_tr2(g_pCommonTr)
}

public plugin_precache()
{
	if (file_exists("sound/rm_reloaded/teleport.wav"))
	{
		precache_sound("rm_reloaded/teleport.wav");
	}
}

public rm_give_rune(id)
{
	g_Teleport[id] = 1.0;
	rm_base_highlight_player(id);
}

public rm_drop_rune(id)
{
	g_Teleport[id] = 0.0;
}


public bool:is_hull_vacant(id, Float:origin[3], iHull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, iHull, id, g_pCommonTr)
	
	if (!get_tr2(g_pCommonTr, TR_StartSolid) && !get_tr2(g_pCommonTr, TR_AllSolid) && get_tr2(g_pCommonTr, TR_InOpen))
		return true
	
	return false
}

public bool:is_player_stuck(id,Float:originF[3])
{
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, g_pCommonTr)
	
	if (get_tr2(g_pCommonTr, TR_StartSolid) || get_tr2(g_pCommonTr, TR_AllSolid) || !get_tr2(g_pCommonTr, TR_InOpen))
		return true
	
	return false
}


public bool:is_can_teleport(iPlayer)
{
	new iEyesOrigin[ 3 ];
	get_user_origin( iPlayer, iEyesOrigin, Origin_Eyes );
	
	new iEyesEndOrigin[ 3 ];
	get_user_origin( iPlayer, iEyesEndOrigin, Origin_AimEndEyes );
	
	new Float:vecEyesOrigin[ 3 ];
	IVecFVec( iEyesOrigin, vecEyesOrigin );
	
	new Float:vecEyesEndOrigin[ 3 ];
	IVecFVec( iEyesEndOrigin, vecEyesEndOrigin );
	
	new maxDistance = get_distance(iEyesOrigin,iEyesEndOrigin);
	
	new Float:vecDirection[ 3 ];
	velocity_by_aim( iPlayer, 32, vecDirection );
	
	new Float:vecAimOrigin[ 3 ];
	xs_vec_add( vecEyesOrigin, vecDirection, vecAimOrigin );

	new i = 0;
	while (i < maxDistance) {
		i+=32;
		
		if ( get_distance_f(vecAimOrigin,vecEyesEndOrigin) < 64.0 )
		{
			break;
		}
		
		xs_vec_add( vecAimOrigin, vecDirection, vecAimOrigin );
		if(!is_hull_vacant(iPlayer, vecAimOrigin, HULL_HEAD) )
			return false;
	}
	
	return true;
}

public client_PostThink(id)
{
	if (is_user_connected(id) && g_Teleport[id] > 0.0)
	{
		if ((entity_get_int(id, EV_INT_button) & IN_ATTACK) && get_user_weapon(id) == CSW_KNIFE)
		{
			if( get_gametime() - g_Teleport[id] > 0.5)
			{
				if (is_can_teleport(id))
				{
					teleportPlayer(id);
					g_Teleport[id] = get_gametime();
				}
				else 
				{
					set_hudmessage(220, 20, 20, -1.0, 0.80, 0, 0.1, 2.7, 0.02, 0.02, HUD_CHANNEL_ID_2);
					show_hudmessage(id, "%s: не могу телепороваться сюда!!",rune_name);
				}
			}
			else 
			{
				set_hudmessage(220, 20, 20, -1.0, 0.80, 0, 0.1, 2.7, 0.02, 0.02, HUD_CHANNEL_ID_2);
				show_hudmessage(id, "%s: перезарядка!",rune_name);
			}
		}
	}
}



public teleportPlayer(id)
{
	new NewLocation[3];
	get_user_origin(id, NewLocation, 3);
	set_user_origin(id, NewLocation);
	new Float:pLook[3]
	entity_get_vector(id, EV_VEC_angles, pLook)
	pLook[1]+=float(180)
	entity_set_vector(id, EV_VEC_angles, pLook)
	entity_set_int(id, EV_INT_fixangle, 1)
	unstuckplayer( id )
	entity_set_vector( id, EV_VEC_velocity,Float:{0.0,0.0,0.0});
}

#define TSC_Vector_MA(%1,%2,%3,%4)	(%4[0] = %2[0] * %3 + %1[0], %4[1] = %2[1] * %3 + %1[1])

public unstuckplayer(id)
{
	static Float:Origin[3]
	pev(id, pev_origin, Origin)
	static iHull, iSpawnPoint, i
	iHull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	// fast unstuck 
	if(is_player_stuck(id,Origin))
	{
		Origin[2] += 64.0
	}
	else
	{
		engfunc(EngFunc_SetOrigin, id, Origin)	
		return;
	}
	if(is_player_stuck(id,Origin))
	{
		Origin[2] -= 128.0
	}
	else
	{
		engfunc(EngFunc_SetOrigin, id, Origin)	
		return;
	}
	
	// slow unstuck 
	if(is_player_stuck(id,Origin))
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

public bool:is_bad_aiming(id)
{
	new target[3]
	new Float:target_flt[3]

	get_user_origin(id, target, 3);
	
	IVecFVec(target,target_flt);

	if(engfunc(EngFunc_PointContents,target_flt) == CONTENTS_SKY)
		return true

	return false
}