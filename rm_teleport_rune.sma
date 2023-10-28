#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fakemeta>
#include <hamsandwich>

#include <msg_floatstocks>

new rune_name[] = "rm_teleport_rune_name";
new rune_descr[] = "rm_teleport_rune_desc";

new rune_model_path[64] = "models/rm_reloaded/rune_green.mdl";
new rune_sound_path[64] = "sound/rm_reloaded/teleport.wav";


new Float:g_Teleport[MAX_PLAYERS + 1] = {0.0,...};

new Float:g_MsgTime[MAX_PLAYERS + 1] = {0.0,...};

new g_spriteid_steam1 = 0;

new g_pCommonTr;

new rune_model_id = -1;

new Float:g_fCooldown = 1.0;


new g_sTeleportSprite[64] = "sprites/steam1.spr";

public plugin_init()
{
	register_plugin("RM_TELEPORT","2.7","Karaulov"); 
	rm_register_rune(rune_name,rune_descr,Float:{0.0,255.0,0.0},rune_model_path, rune_sound_path, rune_model_id);
	g_pCommonTr = create_tr2();
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "knife_attack_pressed", 1);
	
	/* Чтение конфигурации */
	new cost = 7500;
	rm_read_cfg_int(rune_name,"COST_MONEY",cost,cost);
	rm_base_set_rune_cost(cost);
	
	/* Чтение конфигурации */
	rm_read_cfg_flt(rune_name,"COOLDOWN",g_fCooldown,g_fCooldown);

	// Максимальное количество предметов/рун которые могут быть на карте в одно время
	new max_count = 10;
	rm_read_cfg_int(rune_name,"MAX_COUNT_ON_MAP",max_count,max_count);
	rm_base_set_max_count( max_count );
}

public plugin_end()
{
	free_tr2(g_pCommonTr);
}

public plugin_precache()
{
	/* Чтение конфигурации */
	rm_read_cfg_str(rune_name,"model",rune_model_path,rune_model_path,charsmax(rune_model_path));
	rm_read_cfg_str(rune_name,"sound",rune_sound_path,rune_sound_path,charsmax(rune_sound_path));
	rm_read_cfg_str(rune_name,"teleport_sprite",g_sTeleportSprite,g_sTeleportSprite,charsmax(g_sTeleportSprite));

	rune_model_id = precache_model(rune_model_path);
	
	if (file_exists(rune_sound_path,true))
	{
		precache_generic(rune_sound_path);
	}
	
		// model/.mdl
	if (strlen(g_sTeleportSprite) >= 10 && file_exists(g_sTeleportSprite,true))
	{
		g_spriteid_steam1 = precache_model(g_sTeleportSprite);
	}
}

public rm_give_rune(id)
{
	g_Teleport[id] = 1.0;
	rm_base_highlight_player(id);
	rm_base_highlight_screen(id);
}

public rm_drop_rune(id)
{
	g_Teleport[id] = 0.0;
}

public bool:is_player_point( id, Float:coords[3] )
{
	new iPlayers[ 32 ], iNum;
	new Float:fOrigin[3];
	get_players( iPlayers, iNum  );
	for( new i = 0; i < iNum; i++ )
	{
		new iPlayer = iPlayers[ i ];
		if (iPlayer != id && is_user_connected(iPlayer) && is_user_alive(iPlayer) && is_user_onground(iPlayer))
		{
			get_entvar(iPlayer, var_origin, fOrigin );
			if (get_distance_f(fOrigin,coords) < 256.0)
				return true;
		}
	}
	return false;
}

public bool:get_teleport_point(iPlayer, Float:newTeleportPoint[3])
{
	new iEyesOrigin[ 3 ];
	get_user_origin( iPlayer, iEyesOrigin, Origin_Eyes );
	
	new iEyesEndOrigin[ 3 ];
	get_user_origin( iPlayer, iEyesEndOrigin, Origin_AimEndEyes );
	
	new Float:vecEyesOrigin[ 3 ];
	IVecFVec( iEyesOrigin, vecEyesOrigin );
	
	new Float:vecEyesEndOrigin[ 3 ];
	IVecFVec( iEyesEndOrigin, vecEyesEndOrigin );
	
	if (is_player_point(iPlayer,vecEyesEndOrigin))
	{
		xs_vec_copy(vecEyesEndOrigin, newTeleportPoint)
		return true;
	}
	
	new maxDistance = get_distance(iEyesOrigin,iEyesEndOrigin);
	
	new Float:vecDirection[ 3 ];
	velocity_by_aim( iPlayer, 32, vecDirection );
	
	new Float:vecAimOrigin[ 3 ];
	new Float:vecAimOriginPrev[ 3 ];
	xs_vec_add( vecEyesOrigin, vecDirection, vecAimOrigin );

	new i = 0;
	while (i < maxDistance) {
		i+=32;
		xs_vec_copy(vecAimOrigin, vecAimOriginPrev);
		if ( get_distance_f(vecAimOrigin,vecEyesEndOrigin) < 64.0 )
		{
			xs_vec_copy(vecAimOrigin, newTeleportPoint);
			return true;
		}
		
		xs_vec_add( vecAimOrigin, vecDirection, vecAimOrigin );
		if(!rm_is_hull_vacant(iPlayer, vecAimOrigin, HULL_HEAD,g_pCommonTr) )
		{
			xs_vec_copy(vecAimOriginPrev, newTeleportPoint);
			return true;
		}
	}
	
	
	xs_vec_copy(vecAimOrigin, newTeleportPoint);
	return false;
}

public knife_attack_pressed(iWeaponEnt)
{
	if(!is_nullent(iWeaponEnt))
	{
		new iOwner = get_entvar(iWeaponEnt, var_owner);
		if (is_real_player(iOwner))
		{
			try_teleport(iOwner);
		}
	}
	return HAM_IGNORED;
}

public try_teleport(id)
{
	if (g_Teleport[id] > 0.0)
	{
		if ((get_entvar(id, var_button) & IN_ATTACK) && get_user_weapon(id) == CSW_KNIFE)
		{
			if( get_gametime() - g_Teleport[id] > g_fCooldown)
			{
				new Float:TeleportPoint[3];
				if (get_teleport_point(id,TeleportPoint))
				{
					teleportPlayer(id,TeleportPoint);
					g_Teleport[id] = get_gametime();
				}
				else 
				{
					cant_teleport_msg(id,1);
				}
			}
			else 
			{
				cant_teleport_msg(id,0);
			}
		}
	}
}

public cant_teleport_msg(id,type)
{
	if (get_gametime() - g_MsgTime[id] > 1.0)
	{
		if (type == 0)
		{
			set_dhudmessage(255, 221, 0, -1.0, 0.55, 0, 0.0, 0.0, 1.1, 0.0)
			show_dhudmessage(id, "COOLDOWN");
		}
		else 
		{
			client_cmd(id,"spk ^"%s^"", "buttons/button9.wav");
			set_dhudmessage(238, 255, 0, -1.0, 0.55, 0, 0.0, 0.0, 1.1, 0.0);
			show_dhudmessage(id, "NO ACCESS");
		}
		g_MsgTime[id] = get_gametime();
	}
}


public teleportPlayer(id, Float:TeleportPoint[3])
{
	new Float:pOrigin[3];
	get_entvar(id, var_origin, pOrigin);
	set_entvar(id, var_origin, TeleportPoint);
	new Float:pLook[3];
	get_entvar(id, var_angles, pLook);
	pLook[1]+=180.0;
	set_entvar(id, var_angles, pLook);
	set_entvar(id, var_fixangle, 1);
	set_entvar(id, var_velocity,Float:{0.0,0.0,0.0});
	rm_unstuck_player( id );
	create_smoke(pOrigin);
}

create_smoke(Float:origin[3]) {
	if (g_spriteid_steam1 == 0)
	{
		te_create_teleport_splash(origin);
		return;
	}
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0);
	write_byte(TE_SMOKE);
	engfunc(EngFunc_WriteCoord, origin[0]);
	engfunc(EngFunc_WriteCoord, origin[1]);
	engfunc(EngFunc_WriteCoord, origin[2] + 3.0);
	write_short(g_spriteid_steam1);
	write_byte(40);
	write_byte(8);
	message_end();
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