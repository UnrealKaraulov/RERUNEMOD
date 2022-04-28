/*
https://next21.ru/2013/04/%D0%BF%D0%BB%D0%B0%D0%B3%D0%B8%D0%BD-portal-gun/
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <rm_api>

#define PLUGIN "RM_PORTAL"
#define VERSION "2.4 NOREAPI"
#define AUTHOR "karaulov, Polarhigh" // aka trofian

#define IGNORE_ALL	(IGNORE_MISSILE | IGNORE_MONSTERS | IGNORE_GLASS)
#define m_pActiveItem 373

#define PORTAL_CLASSNAME	"portal_custom"
#define PORTAL_LOCK_TIME 	1.0
#define PORTAL_DESTINATION_SHIFT 4.0
#define PORTAL_WIDTH		46.0
#define PORTAL_HEIGHT		72.0

#define GUN_SHOOT_DELAY		0.45
#define GUN_DEPLOY_DELAY	1.39

#define GUN_ANIM_IDLE		0
#define GUN_ANIM_DEPLOY		3
#define GUN_ANIM_SHOT_RAND(id) __get_portal_gun_shoot_anim(id)

new const g_sPortalModel[] = "models/next_portalgun/portal.mdl"
new const g_sPortalGunModelV[] = "models/next_portalgun/v_portalgun.mdl"
new const g_sPortalGunModelP[] = "models/next_portalgun/p_portalgun.mdl"

new const g_sPortalGunSoundShot1[] = "next_portalgun/shoot1.wav"
new const g_sPortalGunSoundShot2[] = "next_portalgun/shoot2.wav"

new const g_sPortalSoundOpen1[] = "next_portalgun/portal_o.wav"
new const g_sPortalSoundOpen2[] = "next_portalgun/portal_b.wav"

new const g_sSparksSpriteBlue[] = "sprites/next_portalgun/blue.spr"
new const g_sSparksSpriteOrange[] = "sprites/next_portalgun/orange.spr"

new g_pStringInfTarg, g_pStringPortalClass
new g_pCommonTr

#include <portal_gun\vec_utils.inc>
#include <portal_gun\types\portalBox.inc>
#include <portal_gun\portal.inc>

new g_pStringPortalGunModelV, g_pStringPortalGunModelP, g_knifeV, g_knifeP
new g_idPortalGunModelV
new g_idPortalModel

#define SET_PORTAL_GUN_ANIM(%0,%1) g_iPortalWeaponAnim[%0] = %1
new g_iPortalWeaponAnim[MAX_PLAYERS+1]

#define HAS_PORTAL_GUN(%0)	g_iPlayerData[%0][0]
#define VISIBLE_PORTAL_GUN(%0)	g_iPlayerData[%0][1]
new g_iPlayerData[MAX_PLAYERS+1][2]

new g_idSparksSpriteBlue, g_idSparksSpriteOrange

new g_iMaxplayers

new rune_model_id = -1


public plugin_precache() {
	g_idPortalModel = precache_model(g_sPortalModel)
	g_idPortalGunModelV = precache_model(g_sPortalGunModelV)
	precache_model(g_sPortalGunModelP)
	
	rune_model_id = precache_model("models/next_portalgun/w_portalgun.mdl")
	
	precache_sound(g_sPortalGunSoundShot1)
	precache_sound(g_sPortalGunSoundShot2)
	
	precache_sound(g_sPortalSoundOpen1)
	precache_sound(g_sPortalSoundOpen2)
	
	g_idSparksSpriteBlue = precache_model(g_sSparksSpriteBlue)
	g_idSparksSpriteOrange = precache_model(g_sSparksSpriteOrange)
	
	if (file_exists("sound/rm_reloaded/portal_gun.wav"))
	{
		precache_generic("sound/rm_reloaded/portal_gun.wav");
	}
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	rm_register_rune("rm_portal_rune_name","rm_portal_rune_desc",Float:{25.0,25.0,25.0}, "models/next_portalgun/w_portalgun.mdl", "rm_reloaded/portal_gun.wav",rune_model_id);
	
	g_pCommonTr = create_tr2()
	
	g_pStringInfTarg = engfunc(EngFunc_AllocString, "info_target")
	g_pStringPortalClass = engfunc(EngFunc_AllocString, PORTAL_CLASSNAME)
	g_pStringPortalGunModelV = engfunc(EngFunc_AllocString, g_sPortalGunModelV)
	g_pStringPortalGunModelP = engfunc(EngFunc_AllocString, g_sPortalGunModelP)
	
	g_knifeP = engfunc(EngFunc_AllocString, "models/p_knife.mdl")
	g_knifeV = engfunc(EngFunc_AllocString, "models/v_knife.mdl")
	
	g_iMaxplayers = get_maxplayers()
	
	register_event("HLTV", "@event_hltv", "a", "1=0", "2=0")
	
	RegisterHam(Ham_Killed, "player", "@player_killed_post", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "@knife_deploy_p", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_knife", "@knife_postframe")
	register_forward(FM_UpdateClientData, "@update_client_data_p", 1)
	
	register_touch(PORTAL_CLASSNAME, "*", "@portal_touch")
}

public rm_give_rune(id)
{
	native_give(id)
	rm_base_highlight_player(id);
	rm_base_highlight_screen(id);
}

public rm_drop_rune(id)
{
	native_remove(id)
}

public plugin_end() {
	free_tr2(g_pCommonTr)
}

public client_disconnected(id) {
	portal_remove_pair(id)
	HAS_PORTAL_GUN(id) = 0
	VISIBLE_PORTAL_GUN(id) = 0
}

@event_hltv() {
	for(new i = 1; i <= g_iMaxplayers; i++)
		if(portal_is_set_pair(i)) 
			portal_close(i, PORTAL_ALL)
}

@player_killed_post(id) {
	if(portal_is_set_pair(id))
		portal_close(id, PORTAL_ALL)
}

@knife_deploy_p(gun) {
	if(!pev_valid(gun))
		return HAM_IGNORED
	
	new id = pev(gun, pev_owner)
	if(!pev_valid(id))
		return HAM_IGNORED
	
	if(!VISIBLE_PORTAL_GUN(id))
		return HAM_IGNORED
	
	set_pev_string(id, pev_viewmodel2, g_pStringPortalGunModelV)
	set_pev_string(id, pev_weaponmodel2, g_pStringPortalGunModelP)
	
	SET_PORTAL_GUN_ANIM(id, GUN_ANIM_DEPLOY)
	
	return HAM_HANDLED
}

public bool:is_hull_vacant(id, Float:origin[3])
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, HULL_HEAD, id, g_pCommonTr)
	
	if (!get_tr2(g_pCommonTr, TR_StartSolid) && !get_tr2(g_pCommonTr, TR_AllSolid) && get_tr2(g_pCommonTr, TR_InOpen))
		return true
	
	return false
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
			pev(iPlayer, pev_origin, fOrigin );
			if (get_distance_f(fOrigin,coords) < 256.0)
				return true;
		}
	}
	return false;
}

public bool:is_can_portal(iPlayer)
{
	new iEyesOrigin[ 3 ];
	get_user_origin( iPlayer, iEyesOrigin, Origin_Eyes );
	
	new iEyesEndOrigin[ 3 ];
	get_user_origin( iPlayer, iEyesEndOrigin, Origin_AimEndEyes );
	

	new Float:vecEyesOrigin[ 3 ];
	IVecFVec( iEyesOrigin, vecEyesOrigin );
	
	new Float:vecEyesEndOrigin[ 3 ];
	IVecFVec( iEyesEndOrigin, vecEyesEndOrigin );
	
	if (is_player_point(iPlayer, vecEyesEndOrigin))
		return true;
		
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
		if(!is_hull_vacant(iPlayer, vecAimOrigin) )
			return false;
	}
	
	return true;
}

@knife_postframe(gun) {
	static id
	id = pev(gun, pev_owner)
	
	if(!(0 < id <= g_iMaxplayers))
		return HAM_IGNORED
	
	if(!VISIBLE_PORTAL_GUN(id))
		return HAM_IGNORED
	
	static Float:nextAttackTime[MAX_PLAYERS+1]
	if(nextAttackTime[id] > get_gametime())
		return HAM_SUPERCEDE
	
	new buttons = pev(id, pev_button)
	
	if((buttons & IN_ATTACK) || (buttons & IN_ATTACK2)) {
		new type = (buttons & IN_ATTACK) ? PORTAL_1 : PORTAL_2
		
		new Float:origin[3]
		pev(id, pev_origin, origin)
		
		new Float:originEyes[3]
		pev(id, pev_view_ofs, originEyes)
		xs_vec_add(originEyes, origin, originEyes)
		
		new Float:angle[3], Float:normal[3]
		pev(id, pev_v_angle, angle)
		angle_vector(angle, ANGLEVECTOR_FORWARD, normal)
		
		new portalBox[portalBox_t]
		
		// test surface
		if(!portalBox_create(originEyes, normal, id, portalBox))
			goto error
			
		// test hull
		new dimension = 1
		if(floatabs(portalBox[pfwd][2]) > 0.7)
			dimension = 2

		new Float:testOrigin[3]
		xs_vec_mul_scalar(portalBox[pfwd], VEC_HUMAN_HULL[dimension] + PORTAL_DESTINATION_SHIFT, testOrigin)
		xs_vec_add(testOrigin, portalBox[pcenter], testOrigin)
		
		engfunc(EngFunc_TraceHull, testOrigin, testOrigin, 0, HULL_HUMAN, id, g_pCommonTr)
		if(get_tr2(g_pCommonTr, TR_StartSolid) || get_tr2(g_pCommonTr, TR_AllSolid))
			goto error
		if (!is_can_portal(id))
			goto error
		// test another portal
		new Float:radius = floatmin(PORTAL_HEIGHT, PORTAL_WIDTH) / 2.0
		
		// @TODO сделать не радиус, а что-нибудь получше, поточнее
		new anotherEnt
	 	while((anotherEnt = engfunc(EngFunc_FindEntityInSphere, anotherEnt, portalBox[pcenter], radius)))
			if(pev(anotherEnt, pev_modelindex) == g_idPortalModel && !portal_test_owner(id, anotherEnt, type))
				goto error
		
		portal_open(id, portalBox, type, .sound = true)
		goto after
		
		error:
		effect_sparks_error_open(portalBox[pcenter], portalBox[pfwd], type)		
	}
	else {
		SET_PORTAL_GUN_ANIM(id, GUN_ANIM_IDLE)
		
		return HAM_SUPERCEDE
	}
	after:
	
	emit_sound(gun, CHAN_AUTO, random_num(0,1) ? g_sPortalGunSoundShot1 : g_sPortalGunSoundShot2, 1.0, ATTN_NORM, 0, PITCH_NORM)
	SET_PORTAL_GUN_ANIM(id, GUN_ANIM_SHOT_RAND(id))
	nextAttackTime[id] = get_gametime() + GUN_SHOOT_DELAY
	
	return HAM_SUPERCEDE
}

@update_client_data_p(id, sendWeapons, cd) {
	if(get_cd(cd, CD_ViewModel) == g_idPortalGunModelV) {
		set_cd(cd, CD_flNextAttack, 9999.0)
		set_cd(cd, CD_WeaponAnim, g_iPortalWeaponAnim[id])
	}
}

@portal_touch(portal, toucher) {
	static portal2
	portal2 = pev(portal, pev_owner)
	
	if(!pev_valid(portal2))
		return
	
	if(pev(portal, pev_nextthink) > get_gametime())
		return
	
	if(pev(portal2, pev_effects) & EF_NODRAW)
		return
	
	if(pev(toucher, pev_flags) & FL_KILLME)
		return
	
	if(portal_teleport(toucher, portal2, portal))
		set_pev(portal2, pev_nextthink, get_gametime() + PORTAL_LOCK_TIME)
}

@cmd_drop(id) {
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	if(get_user_weapon(id) != CSW_KNIFE)
		return PLUGIN_CONTINUE
	
	if(!HAS_PORTAL_GUN(id))
		return PLUGIN_CONTINUE
	
	static Float:nextDeployTime[MAX_PLAYERS+1]
	if(nextDeployTime[id] > get_gametime())
		return PLUGIN_HANDLED
	
	VISIBLE_PORTAL_GUN(id) = !VISIBLE_PORTAL_GUN(id)
	
	ExecuteHamB(Ham_Item_Deploy, get_pdata_cbase(id, m_pActiveItem))
	
	nextDeployTime[id] = get_gametime() + GUN_DEPLOY_DELAY
	
	return PLUGIN_HANDLED
}

@cmd_say_portalgun(id) {
	if(~get_user_flags(id) & ADMIN_MENU)
		return PLUGIN_CONTINUE
	
	new menu = menu_create("\yPortal Gun", "@menu_portalgun_handler")
	new players[32], num
	new str[64], player_num[11]

	get_players(players, num, "ch")

	for(new i; i < num; i++) {
		get_user_name(players[i], str, charsmax(str))
		if(HAS_PORTAL_GUN(players[i])) {
			add(str, charsmax(str), " \r[remove gun]")
		}
		else {
			add(str, charsmax(str), " \y[add gun]")
		}
		
		num_to_str(players[i], player_num, charsmax(player_num))
		menu_additem(menu, str, player_num, 0)
	}
	
	menu_display(id, menu, 0)
	
	return PLUGIN_HANDLED
}

@menu_portalgun_handler(id, menu, item) {
	if(item == MENU_EXIT) {
		menu_destroy(menu)
		
		return PLUGIN_HANDLED
	}

	new data[6], name[64], access, callback
	
	menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), callback)

	new player = str_to_num(data)

	if(!is_user_connected(player)) {
		menu_destroy(menu)
		@cmd_say_portalgun(id)
		client_print(id, print_center, "Player not connected")
		
		return PLUGIN_HANDLED
	}

	if(HAS_PORTAL_GUN(player)) {
		portal_remove_pair(player)
		HAS_PORTAL_GUN(player) = 0
		
		if(is_user_alive(player) && VISIBLE_PORTAL_GUN(player) && get_user_weapon(player) == CSW_KNIFE) {
			VISIBLE_PORTAL_GUN(player) = 0
			ExecuteHamB(Ham_Item_Deploy, get_pdata_cbase(player, m_pActiveItem))
		}
		else {
			VISIBLE_PORTAL_GUN(player) = 0
		}
		
		client_print(player, print_chat, "[%s] Portal Gun was removed by admin.", PLUGIN)
	}
	else {
		portal_create_pair(player)
		HAS_PORTAL_GUN(player) = 1
		VISIBLE_PORTAL_GUN(player) = 0
		
		client_print(player, print_chat, "[%s] You received a portal gun! Select knife and press G!", PLUGIN)
	}

	menu_destroy(menu)
	@cmd_say_portalgun(id)

	return PLUGIN_HANDLED
}

public native_give(id) {
	if(HAS_PORTAL_GUN(id))
		return 0
	
	portal_create_pair(id)
	HAS_PORTAL_GUN(id) = 1
	VISIBLE_PORTAL_GUN(id) = 1
	if ( get_user_weapon(id) == CSW_KNIFE )
	{
		set_pev_string(id, pev_viewmodel2, g_pStringPortalGunModelV)
		set_pev_string(id, pev_weaponmodel2, g_pStringPortalGunModelP)	
		SET_PORTAL_GUN_ANIM(id, GUN_ANIM_DEPLOY)
	}

	return 1
}



public  native_remove(id) {
	if(!HAS_PORTAL_GUN(id))
		return 0
	portal_remove_pair(id)
	HAS_PORTAL_GUN(id) = 0
	VISIBLE_PORTAL_GUN(id) = 0
	if ( get_user_weapon(id) == CSW_KNIFE )
	{
		set_pev_string(id, pev_viewmodel2, g_knifeV)
		set_pev_string(id, pev_weaponmodel2, g_knifeP)
		client_cmd(id,"slot2");
		client_cmd(id,"slot2");
	}
	return 1
}

@native_is_has() {
	return HAS_PORTAL_GUN(get_param(1))
}

@native_is_visible_portal_gun() {
	return VISIBLE_PORTAL_GUN(get_param(1))
}

@native_hide_portal() {
	new id = get_param(1)
	new type = get_param(2)
	
	if(type == 's') {
		portal_close(id, PORTAL_1)
	}
	else if(type == 'e') {
		portal_close(id, PORTAL_2)
	}
	else if(type == 'a') {
		portal_close(id, PORTAL_ALL)
	}
	else
		return 0
	
	return 1
}

__get_portal_gun_shoot_anim(id) {
	static sendAnim[MAX_PLAYERS+1] = {4, ...}
	if(sendAnim[id] > 7)
		sendAnim[id] = 4
	return sendAnim[id]++
}

effect_sparks_error_open(const Float:origin[], const Float:normal[], type) {
	new Float:sparksStart[3], Float:sparksEnd[3]
	xs_vec_mul_scalar(normal, 7.0, sparksStart)
	xs_vec_add(origin, sparksStart, sparksStart)
	xs_vec_mul_scalar(normal, 20.0, sparksEnd)
	xs_vec_add(origin, sparksEnd, sparksEnd)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITETRAIL)
	engfunc(EngFunc_WriteCoord, sparksStart[0])
	engfunc(EngFunc_WriteCoord, sparksStart[1])
	engfunc(EngFunc_WriteCoord, sparksStart[2])
	engfunc(EngFunc_WriteCoord, sparksEnd[0])
	engfunc(EngFunc_WriteCoord, sparksEnd[1])
	engfunc(EngFunc_WriteCoord, sparksEnd[2])
	write_short(type == PORTAL_1 ? g_idSparksSpriteBlue : g_idSparksSpriteOrange)
	write_byte(25)
	write_byte(1)
	write_byte(1)
	write_byte(20)
	write_byte(14)
	message_end()
}

/*get_random_shoot_anim() {
	return random_num(0, 1) ? random_num(1, 2) : random_num(4, 7)
}*/

/*#define PM_HULL_HUMAN	0
#define PM_HULL_HEAD	1
#define PM_HULL_POINT	2
#define PM_HULL_LARGE	3*/

// двойная проверка касания портала
// если нормаль [2] < 0.7 ,  то это не полportal_gun\gun
