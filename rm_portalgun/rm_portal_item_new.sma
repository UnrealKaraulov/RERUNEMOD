#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <xs>
#include <rm_api>

#define PLUGIN "RM_PORTAL"
#define VERSION "3.0_NEW"
#define AUTHOR "trofian, polarhigh, karaulov"

#define IGNORE_ALL (IGNORE_MISSILE | IGNORE_MONSTERS | IGNORE_GLASS)

#define PORTAL_CLASSNAME "portal_custom"
#define PORTAL_LOCK_TIME 1.0
#define PORTAL_DESTINATION_SHIFT 4.0
#define PORTAL_WIDTH 46.0
#define PORTAL_HEIGHT 72.0

#define GUN_SHOOT_DELAY 0.45

#define GUN_ANIM_IDLE 0
#define GUN_ANIM_DEPLOY 3
#define GUN_ANIM_SHOT_RAND(%1) __get_portal_gun_shoot_anim(%1)

#define PORTAL_IS_VALID_PAIR(%1) ((%1) > 0 && (%1) <= 32 && is_entity(g_portals[%1][0]) && is_entity(g_portals[%1][1]))

#define PORTAL_1 0
#define PORTAL_2 1
#define PORTAL_ALL 2
#define SET_PORTAL_GUN_ANIM(%1,%2) g_iPortalWeaponAnim[%1] = %2
#define HAS_PORTAL_GUN(%1) g_iPlayerData[%1][0]
#define VISIBLE_PORTAL_GUN(%1) g_iPlayerData[%1][1]
#define VEC_FLOOR Float:{0.0, 0.0, 1.0}
#define VEC_CEILING Float:{0.0, 0.0, -1.0}
#define IGNORE_ANGLE_DEG_FL 75.0
#define IGNORE_ANGLE_DEG_CE 50.0
#define IGNORE_SPEED 300.0
#define xs_1_neg(%1) %1 = -%1


#define PBOX_SHIFT 1.0		// Начальный сдвиг от стены
#define PBOX_DEPTH 3.0		// Глубина портала	
#define PBOX_STEP 0.5		// Шаг движения
#define PBOX_ITERS 70		// Количество итераций

new const Float:Vec3Zero[3] = {0.0, 0.0, 0.0};

new const g_sPortalModel[] = "models/next_portalgun/portal.mdl";
new const g_sPortalGunModelV[] = "models/next_portalgun/v_portalgun.mdl";
new const g_sPortalGunModelP[] = "models/next_portalgun/p_portalgun.mdl";
new const g_sPortalGunSoundShot1[] = "next_portalgun/shoot1.wav";
new const g_sPortalGunSoundShot2[] = "next_portalgun/shoot2.wav";
new const g_sPortalSoundOpen1[] = "next_portalgun/portal_o.wav";
new const g_sPortalSoundOpen2[] = "next_portalgun/portal_b.wav";
new const g_sSparksSpriteBlue[] = "sprites/next_portalgun/blue.spr";
new const g_sSparksSpriteOrange[] = "sprites/next_portalgun/orange.spr";

new g_pCommonTr;
new g_idPortalGunModelV;
new g_idPortalModel;
new g_portals[MAX_PLAYERS + 1][2];
new g_iPortalWeaponAnim[MAX_PLAYERS + 1];
new g_iPlayerData[MAX_PLAYERS + 1][2];
new g_idSparksSpriteBlue;
new g_idSparksSpriteOrange;

new rune_model_id = -1;
new rune_name[] = "rm_portal_item_name";
new rune_descr[] = "rm_portal_item_desc";
new rune_model_path[64] = "models/next_portalgun/w_portalgun.mdl";
new rune_sound_path[64] = "sound/rm_reloaded/portal_gun.wav";
new g_iCfgSpawnSecondsDelay = 0;
new Float:flLastSpawnTime = 0.0;

// Новые конфигурационные переменные
new Float:g_fMaxEntitySize = 100.0;
new g_szBlockedEntities[2048];
new Array:g_aBlockedEntities;
new bool:g_bCheckEntitySize = true;
new bool:g_bCheckBlockedEntities = true;
new Float:g_fPortalCooldown_IN = 0.01;
new Float:g_fPortalCooldown_OUT = 0.3;
new Float:g_fDeployCooldown = 1.0;
new g_iMaxPortalDistance = 4000;

enum _:portalBox_t {
	Float:ppointUL[3],
	Float:ppointUR[3],
	Float:ppointDR[3],
	Float:ppointDL[3],
	Float:pcenter[3],
	Float:pfwd[3],
	Float:pup[3],
	Float:pright[3]
};

public plugin_precache() {
	rm_read_cfg_str(rune_name, "model", rune_model_path, rune_model_path, charsmax(rune_model_path));
	rm_read_cfg_str(rune_name, "sound", rune_sound_path, rune_sound_path, charsmax(rune_sound_path));

	// Чтение новых конфигурационных параметров
	rm_read_cfg_flt(rune_name, "MAX_ENTITY_SIZE", 100.0, g_fMaxEntitySize);
	rm_read_cfg_str(rune_name, "BLOCKED_ENTITIES", "func_door,func_door_rotating,func_breakable,func_wall,func_illusionary,func_train,trigger_multiple,trigger_once,info_target,ambient_generic", g_szBlockedEntities, charsmax(g_szBlockedEntities));
	
	new temp;
	rm_read_cfg_int(rune_name, "CHECK_ENTITY_SIZE", 1, temp);
	g_bCheckEntitySize = bool:temp;
	
	rm_read_cfg_int(rune_name, "CHECK_BLOCKED_ENTITIES", 1, temp);
	g_bCheckBlockedEntities = bool:temp;
	
	rm_read_cfg_flt(rune_name, "PORTAL_COOLDOWN_IN", 0.01, g_fPortalCooldown_IN);
	rm_read_cfg_flt(rune_name, "PORTAL_COOLDOWN_OUT", 0.3, g_fPortalCooldown_OUT);
	rm_read_cfg_flt(rune_name, "PORTAL_DEPLOY_COOLDOWN", 1.0, g_fDeployCooldown);
	rm_read_cfg_int(rune_name, "MAX_PORTAL_DISTANCE", 2000, g_iMaxPortalDistance);

	rune_model_id = precache_model(rune_model_path);
	rm_register_dictionary("runemod_pg_item.txt");
	rm_register_rune(rune_name, rune_descr, Float:{25.0, 25.0, 25.0}, rune_model_path, rune_sound_path, rune_model_id);
	rm_base_use_rune_as_item();

	g_idPortalModel = precache_model(g_sPortalModel);
	g_idPortalGunModelV = precache_model(g_sPortalGunModelV);
	precache_model(g_sPortalGunModelP);
	
	precache_sound(g_sPortalGunSoundShot1);
	precache_sound(g_sPortalGunSoundShot2);
	precache_sound(g_sPortalSoundOpen1);
	precache_sound(g_sPortalSoundOpen2);
	
	g_idSparksSpriteBlue = precache_model(g_sSparksSpriteBlue);
	g_idSparksSpriteOrange = precache_model(g_sSparksSpriteOrange);
	
	if(file_exists(rune_sound_path, true)) {
		precache_generic(rune_sound_path);
	}
	
	new cost = 4800;
	rm_read_cfg_int(rune_name, "COST_MONEY", cost, cost);
	rm_base_set_rune_cost(cost);

	new max_count = 10;
	rm_read_cfg_int(rune_name, "MAX_COUNT_ON_MAP", max_count, max_count);
	rm_base_set_max_count(max_count);
	
	rm_read_cfg_int(rune_name, "DELAY_BETWEEN_NEXT_SPAWN", g_iCfgSpawnSecondsDelay, g_iCfgSpawnSecondsDelay);
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	// Инициализация массива заблокированных сущностей
	g_aBlockedEntities = ArrayCreate(64);
	parse_blocked_entities();
	
	g_pCommonTr = create_tr2();
	
	RegisterHookChain(RG_RoundEnd, "@round_restart", true);
	RegisterHookChain(RG_CSGameRules_RestartRound, "@round_restart", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "@player_killed_post", true);
	
	register_clcmd("weapon_knife", "@cmd_drop");
	register_clcmd("slot3", "@cmd_drop");
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "@knife_deploy_p", .Post = 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_knife", "@knife_postframe");
	register_forward(FM_UpdateClientData, "@update_client_data_p", 1);
	
	for(new i = 0; i <= MAX_PLAYERS; i++) {
		for(new j = 0; j < 2; j++) {
			g_portals[i][j] = 0;
		}
	}
}

public plugin_end() {
	free_tr2(g_pCommonTr);
	if(g_aBlockedEntities != Invalid_Array) {
		ArrayDestroy(g_aBlockedEntities);
	}
}

// Исправленная функция парсинга заблокированных сущностей
// Полностью переписанная функция парсинга заблокированных сущностей
parse_blocked_entities() {
	if(!g_bCheckBlockedEntities || strlen(g_szBlockedEntities) == 0) {
		return;
	}
	
	// Очищаем массив на случай повторного вызова
	if(ArraySize(g_aBlockedEntities) > 0) {
		ArrayClear(g_aBlockedEntities);
	}
	
	new temp[2048];
	copy(temp, charsmax(temp), g_szBlockedEntities);
	
	log_amx("[PORTAL] Raw blocked entities string: '%s'", temp);
	
	// Разбиваем строку по запятым
	new classname[32];
	new start, end;
	new len = strlen(temp);
	new count = 0;
	
	for(start = 0, end = 0; end <= len; end++) {
		// Если нашли запятую или конец строки
		if(temp[end] == ',' || temp[end] == 0) {
			if(end > start) {
				// Копируем подстроку
				copyc(classname, charsmax(classname), temp[start], ',');
				trim(classname);
				
				// Убираем возможные пробелы
				while(classname[0] == ' ') {
					copy(classname, charsmax(classname), classname[1]);
				}
				
				new classlen = strlen(classname);
				while(classlen > 0 && classname[classlen-1] == ' ') {
					classname[--classlen] = 0;
				}
				
				// Добавляем в массив если не пустой
				if(strlen(classname) > 0) {
					ArrayPushString(g_aBlockedEntities, classname);
					count++;
				}
			}
			start = end + 1; // Переходим к следующему элементу
		}
	}
	
	log_amx("[PORTAL] Successfully loaded %d blocked entities", count);
}

// Улучшенная функция проверки размера сущности
bool:is_entity_size_valid(const id) {
	if(!g_bCheckEntitySize || !is_entity(id)) {
		return true;
	}
	
	static Float:min[3], Float:max[3];
	get_entvar(id, var_mins, min);
	get_entvar(id, var_maxs, max);
	
	new Float:size_x = floatabs(max[0] - min[0]);
	new Float:size_y = floatabs(max[1] - min[1]);
	new Float:size_z = floatabs(max[2] - min[2]);
	
	// Проверяем общий объем entity
	new Float:volume = size_x * size_y * size_z;
	new Float:max_volume = g_fMaxEntitySize * g_fMaxEntitySize * g_fMaxEntitySize;
	
	if(volume > max_volume) {
		return false;
	}
	
	// Дополнительная проверка на слишком большие размеры по любой из осей
	if(size_x > g_fMaxEntitySize || size_y > g_fMaxEntitySize || size_z > g_fMaxEntitySize) {
		return false;
	}
	
	return true;
}

// Функция проверки, заблокирована ли сущность
bool:is_entity_blocked(const classname[]) {
	if(!g_bCheckBlockedEntities || ArraySize(g_aBlockedEntities) == 0) {
		return false;
	}
	
	new temp[32];
	for(new i = 0; i < ArraySize(g_aBlockedEntities); i++) {
		ArrayGetString(g_aBlockedEntities, i, temp, charsmax(temp));
		
		// Прямое сравнение имен классов
		if(equal(classname, temp)) {
			return true;
		}
		
		// Дополнительная проверка на частичное совпадение (на всякий случай)
		if(containi(classname, temp) == 0) {
			return true;
		}
	}
	
	return false;
}

public rm_spawn_rune(iEnt) {
	if(floatround(floatabs(get_gametime() - flLastSpawnTime)) > g_iCfgSpawnSecondsDelay) {
		static Float:flOrigin[3];
		get_entvar(iEnt, var_origin, flOrigin);
		flOrigin[2] += 16.0;
		set_entvar(iEnt, var_origin, flOrigin);
		set_entvar(iEnt, var_avelocity, Float:{0.0, 70.0, 0.0});
		flLastSpawnTime = get_gametime();
		return SPAWN_SUCCESS;
	}
	
	return SPAWN_ERROR;
}

public rm_give_rune(id) {
	if(is_user_bot(id) || HAS_PORTAL_GUN(id)) {
		return NO_RUNE_PICKUP_SUCCESS;
	}
	
	native_give(id);
	rm_base_highlight_player(id);
	rm_base_highlight_screen(id);
	return RUNE_PICKUP_SUCCESS;
}

public rm_drop_rune(id) {
	native_remove(id);
}

public client_disconnected(id) {
	portal_remove_pair(id);
	HAS_PORTAL_GUN(id) = 0;
	VISIBLE_PORTAL_GUN(id) = 0;
}

@round_restart() {
	for(new i = 1; i <= MaxClients; i++) {
		if(is_user_connected(i) && portal_is_set_pair(i)) {
			portal_close(i, PORTAL_ALL);
		}
	}
}

@player_killed_post(const id, const attacker, const inflictor) {
	if(portal_is_set_pair(id)) {
		portal_close(id, PORTAL_ALL);
	}
}

@knife_deploy_p(const weapon) {
	if(!is_entity(weapon)) {
		return HAM_IGNORED;
	}
	
	new id = get_entvar(weapon, var_owner);
	
	if(!is_user_connected(id)) {
		return HAM_IGNORED;
	}
	
	if(!VISIBLE_PORTAL_GUN(id)) {
		return HAM_IGNORED;
	}
	
	set_entvar(id, var_viewmodel, g_sPortalGunModelV);
	set_entvar(id, var_weaponmodel, g_sPortalGunModelP);
	SET_PORTAL_GUN_ANIM(id, GUN_ANIM_DEPLOY);
	
	return HAM_HANDLED;
}

bool:is_hull_vacant(const id, const Float:origin[3]) {
	engfunc(EngFunc_TraceHull, origin, origin, 0, HULL_HEAD, id, g_pCommonTr);
	
	if(!get_tr2(g_pCommonTr, TR_StartSolid) && !get_tr2(g_pCommonTr, TR_AllSolid) && get_tr2(g_pCommonTr, TR_InOpen)) {
		return true;
	}
	
	return false;
}

bool:is_player_point(const id, const Float:coords[3]) {
	new iPlayers[32];
	new iNum;
	static Float:fOrigin[3];
	
	get_players(iPlayers, iNum, "ach");
	
	for(new i = 0; i < iNum; i++) {
		new iPlayer = iPlayers[i];
		if(iPlayer != id && is_user_connected(iPlayer) && is_user_alive(iPlayer) && is_user_onground(iPlayer)) {
			get_entvar(iPlayer, var_origin, fOrigin);
			if(get_distance_f(fOrigin, coords) < 256.0) {
				return true;
			}
		}
	}
	
	return false;
}

bool:is_can_portal(const iPlayer) {
	static Float:vecEyesOrigin[3];
	static Float:vecEyesEndOrigin[3];
	
	// Получаем позицию глаз игрока
	get_entvar(iPlayer, var_origin, vecEyesOrigin);
	static Float:vecViewOfs[3];
	get_entvar(iPlayer, var_view_ofs, vecViewOfs);
	xs_vec_add(vecEyesOrigin, vecViewOfs, vecEyesOrigin);
	
	// Трассируем луч чтобы получить точку куда смотрит игрок (как Origin_AimEndEyes)
	static Float:vecAngle[3];
	static Float:vecDirection[3];
	get_entvar(iPlayer, var_v_angle, vecAngle);
	angle_vector(vecAngle, ANGLEVECTOR_FORWARD, vecDirection);
	
	static Float:vecEnd[3];
	xs_vec_mul_scalar(vecDirection, float(g_iMaxPortalDistance), vecEnd);
	xs_vec_add(vecEyesOrigin, vecEnd, vecEnd);
	
	// Трассируем луч чтобы получить реальную точку прицеливания
	engfunc(EngFunc_TraceLine, vecEyesOrigin, vecEnd, IGNORE_ALL, iPlayer, g_pCommonTr);
	get_tr2(g_pCommonTr, TR_vecEndPos, vecEyesEndOrigin);
	
	if(is_player_point(iPlayer, vecEyesEndOrigin)) {
		return true;
	}
	
	// Дальше оригинальная логика проверки по пути
	static Float:vecAimOrigin[3];
	xs_vec_mul_scalar(vecDirection, 32.0, vecDirection);
	xs_vec_add(vecEyesOrigin, vecDirection, vecAimOrigin);

	new Float:maxDistance = get_distance_f(vecAimOrigin, vecEyesEndOrigin);
	new i = 0;
	
	while(i < floatround(maxDistance)) {
		i += 32;
		
		if(get_distance_f(vecAimOrigin, vecEyesEndOrigin) < 64.0) {
			break;
		}
		
		xs_vec_add(vecAimOrigin, vecDirection, vecAimOrigin);
		if(!is_hull_vacant(iPlayer, vecAimOrigin)) {
			return false;
		}
	}
	
	return true;
}

// Исправляем выбор типа портала в @knife_postframe
@knife_postframe(const weapon) {
	new id = get_entvar(weapon, var_owner);
	
	if(!is_user_connected(id)) {
		return HAM_IGNORED;
	}
	
	if(!VISIBLE_PORTAL_GUN(id)) {
		return HAM_IGNORED;
	}
	
	static Float:nextAttackTime[MAX_PLAYERS + 1];
	if(nextAttackTime[id] > get_gametime()) {
		return HAM_SUPERCEDE;
	}
	
	new buttons = get_entvar(id, var_button);
	new type = -1;
	if(buttons & IN_ATTACK) {
		type = PORTAL_1; // Синий портал
	} else if(buttons & IN_ATTACK2) {
		type = PORTAL_2; // Оранжевый портал
	} else {
		SET_PORTAL_GUN_ANIM(id, GUN_ANIM_IDLE);
		return HAM_SUPERCEDE;
	}
	
	if(type == -1) {
		return HAM_SUPERCEDE;
	}
	
	// Остальной код создания портала...
	static Float:origin[3];
	static Float:originEyes[3];
	
	get_entvar(id, var_origin, origin);
	get_entvar(id, var_view_ofs, originEyes);
	xs_vec_add(originEyes, origin, originEyes);
	
	static Float:angle[3];
	static Float:normal[3];
	
	get_entvar(id, var_v_angle, angle);
	angle_vector(angle, ANGLEVECTOR_FORWARD, normal);
	
	static portalBox[portalBox_t];
	
	if(!portalBox_create(originEyes, normal, id, portalBox)) {
		goto error;
	}
	
	// test hull - простая версия
	static Float:testOrigin[3];
	xs_vec_mul_scalar(portalBox[pfwd], 10.0, testOrigin);
	xs_vec_add(testOrigin, portalBox[pcenter], testOrigin);

	engfunc(EngFunc_TraceLine, portalBox[pcenter], testOrigin, IGNORE_ALL, id, g_pCommonTr);

	if(get_tr2(g_pCommonTr, TR_StartSolid)) {
		goto error;
	}
	
	if(!is_can_portal(id)) {
		goto error;
	}
	
	new Float:radius = floatmin(PORTAL_HEIGHT, PORTAL_WIDTH) / 2.0;
	new anotherEnt = 0;
	
	while((anotherEnt = engfunc(EngFunc_FindEntityInSphere, anotherEnt, portalBox[pcenter], radius))) {
		if(get_entvar(anotherEnt, var_modelindex) == g_idPortalModel && !portal_test_owner(id, anotherEnt, type)) {
			goto error;
		}
	}
	
	portal_open(id, portalBox, type, true);
	goto after;
	
	error:
	// Исправляем удаление entity в блоке error
	if(g_portals[id][type] != 0 && is_entity(g_portals[id][type])) {
		rg_remove_entity(g_portals[id][type]);
		g_portals[id][type] = 0;
	} 
	effect_sparks_error_open(portalBox[pcenter], portalBox[pfwd], type);
	
	after:
	emit_sound(weapon, CHAN_AUTO, random_num(0, 1) ? g_sPortalGunSoundShot1 : g_sPortalGunSoundShot2, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	SET_PORTAL_GUN_ANIM(id, GUN_ANIM_SHOT_RAND(id));
	nextAttackTime[id] = get_gametime() + GUN_SHOOT_DELAY;
	
	return HAM_SUPERCEDE;
}


@update_client_data_p(const id, const sendWeapons, const cd_handle) {
	if(get_cd(cd_handle, CD_ViewModel) == g_idPortalGunModelV) {
		set_cd(cd_handle, CD_flNextAttack, 9999.0);
		set_cd(cd_handle, CD_WeaponAnim, g_iPortalWeaponAnim[id]);
	}
}


@portal_touch(const portal, const toucher) {
	// Игнорируем entity 0 (мир) и невалидные entity
	if(toucher == 0 || !is_entity(toucher)) {
		return;
	}
	
	// Проверка на заблокированные сущности
	new classname[32];
	get_entvar(toucher, var_classname, classname, charsmax(classname));
	
	if(g_bCheckBlockedEntities && is_entity_blocked(classname)) {
		return;
	}
	
	// Проверка размера сущности
	if(g_bCheckEntitySize && !is_entity_size_valid(toucher)) {
		return;
	}
	
	new owner = get_entvar(portal, var_owner);
	if (owner <= 0 || owner > MAX_PLAYERS)
	{
		return;
	}
	
	new portal_type = g_portals[owner][PORTAL_1] == portal ? PORTAL_1 : PORTAL_2;
	new other_portal_type = portal_type == PORTAL_1 ? PORTAL_2 : PORTAL_1;
	
	// Проверяем что второй портал существует
	if(!is_entity(g_portals[owner][other_portal_type])) {
		return;
	}
	
	new other_portal = g_portals[owner][other_portal_type];
	
	if (!is_entity(other_portal))
	{
		return;
	}
	
	// Проверяем cooldown на портале (используем nextthink)
	if(get_entvar(portal, var_nextthink) > get_gametime()) {
		return;
	}
	
	// Телепортируем
	if(portal_teleport(toucher, other_portal, portal)) {
		// Устанавливаем cooldown для выходного портала
		set_entvar(other_portal, var_nextthink, get_gametime() + g_fPortalCooldown_OUT);
		// Устанавливаем cooldown для входного портала
		set_task(0.01, "set_cd_task", other_portal);
	}
}

public set_cd_task(portal)
{
	if (is_entity(portal))
	{
		set_entvar(portal, var_nextthink, get_gametime() + g_fPortalCooldown_IN);
	}
}

@cmd_drop(const id) {
	if(!is_user_alive(id)) {
		return PLUGIN_CONTINUE;
	}
	
	if(!HAS_PORTAL_GUN(id)) {
		return PLUGIN_CONTINUE;
	}
	
	static Float:nextDeployTime[MAX_PLAYERS + 1];
	
	if(nextDeployTime[id] > get_gametime()) {
		return PLUGIN_HANDLED;
	}
	
	VISIBLE_PORTAL_GUN(id) = !VISIBLE_PORTAL_GUN(id);
	
	new weapon = get_member(id, m_pActiveItem);
	if(is_entity(weapon)) {
		ExecuteHamB(Ham_Item_Deploy, weapon);
	}
	
	nextDeployTime[id] = get_gametime() + g_fDeployCooldown;
	
	return PLUGIN_HANDLED;
}

public native_give(const id) {
	if(HAS_PORTAL_GUN(id)) {
		return 0;
	}
	
	portal_create_pair(id);
	HAS_PORTAL_GUN(id) = 1;
	VISIBLE_PORTAL_GUN(id) = 1;
	
	if(get_user_weapon(id) == CSW_KNIFE) {
		set_entvar(id, var_viewmodel, g_sPortalGunModelV);
		set_entvar(id, var_weaponmodel, g_sPortalGunModelP);
		SET_PORTAL_GUN_ANIM(id, GUN_ANIM_DEPLOY);
	}

	return 1;
}

public native_remove(const id) {
	portal_remove_pair(id);
	HAS_PORTAL_GUN(id) = 0;
	VISIBLE_PORTAL_GUN(id) = 0;
	
	if(!HAS_PORTAL_GUN(id)) {
		return 0;
	}
	
	if(get_user_weapon(id) == CSW_KNIFE) {
		set_entvar(id, var_viewmodel, "models/v_knife.mdl");
		set_entvar(id, var_weaponmodel, "models/p_knife.mdl");
		WriteClientStuffText(id, "slot1;slot1;slot2;slot2;^n");
	}
	
	return 1;
}

stock WriteClientStuffText(const index, const message[], any:...) {
	new buffer[256];
	new numArguments = numargs();
	
	if(numArguments == 2) {
		message_begin(MSG_ONE, SVC_STUFFTEXT, .player = index);
		write_string(message);
		message_end();
	} else {
		vformat(buffer, charsmax(buffer), message, 3);
		message_begin(MSG_ONE, SVC_STUFFTEXT, .player = index);
		write_string(buffer);
		message_end();
	}
}

__get_portal_gun_shoot_anim(const id) {
	static sendAnim[MAX_PLAYERS + 1] = {4, ...};
	
	if(sendAnim[id] > 7) {
		sendAnim[id] = 4;
	}
	
	return sendAnim[id]++;
}

effect_sparks_error_open(const Float:origin[], const Float:normal[], const type) {
	static Float:sparksStart[3];
	static Float:sparksEnd[3];
	
	xs_vec_mul_scalar(normal, 7.0, sparksStart);
	xs_vec_add(origin, sparksStart, sparksStart);
	xs_vec_mul_scalar(normal, 20.0, sparksEnd);
	xs_vec_add(origin, sparksEnd, sparksEnd);
	
	message_begin_f(MSG_BROADCAST, SVC_TEMPENTITY, sparksStart, 0);
	write_byte(TE_SPRITETRAIL);
	write_coord_f(sparksStart[0]);
	write_coord_f(sparksStart[1]);
	write_coord_f(sparksStart[2]);
	write_coord_f(sparksEnd[0]);
	write_coord_f(sparksEnd[1]);
	write_coord_f(sparksEnd[2]);
	write_short(type == PORTAL_1 ? g_idSparksSpriteBlue : g_idSparksSpriteOrange);
	write_byte(25);
	write_byte(1);
	write_byte(1);
	write_byte(20);
	write_byte(14);
	message_end();
}

bool:portal_test_owner(const player, const ent, const type) {
	if(ent == 0) {
		return false;
	}
	
	if(player <= 0 || player > MaxClients) {
		return false;
	}
	
	if(type < 2) {
		if(g_portals[player][type] == ent) {
			return true;
		}
	} else {
		if(g_portals[player][0] == ent || g_portals[player][1] == ent) {
			return true;
		}
	}
	
	return false;
}

bool:portal_is_set_pair(const player) {
	if(player > 0 && player <= MaxClients) {
		return (g_portals[player][0] && g_portals[player][1]);
	}
	
	return false;
}

bool:portal_create_pair(const player) {
	if(PORTAL_IS_VALID_PAIR(player)) {
		set_entvar(g_portals[player][0], var_effects, get_entvar(g_portals[player][0], var_effects) | EF_NODRAW);
		set_entvar(g_portals[player][1], var_effects, get_entvar(g_portals[player][1], var_effects) | EF_NODRAW);
		return true;
	}
	
	static pair[2];
	
	for(new i = 0; i < 2; i++) {
		pair[i] = rg_create_entity("info_target");
		
		if(!is_entity(pair[i])) {
			if(i == 1) {
				rg_remove_entity(pair[0]);
			}
			
			return false;
		}
		
		set_entvar(pair[i], var_model, g_sPortalModel);
		set_entvar(pair[i], var_classname, PORTAL_CLASSNAME);
		set_entvar(pair[i], var_solid, SOLID_TRIGGER);
		set_entvar(pair[i], var_movetype, MOVETYPE_NONE);
		set_entvar(pair[i], var_effects, get_entvar(pair[i], var_effects) | EF_NODRAW);
	}
	
	set_entvar(pair[0], var_owner, pair[1]);
	set_entvar(pair[1], var_owner, pair[0]);
	
	g_portals[player][0] = pair[0];
	g_portals[player][1] = pair[1];
	
	
	/*Not needed for empty portals
	SetTouch(pair[0],"@portal_touch");
	SetTouch(pair[1],"@portal_touch");*/
	
	return true;
}

portal_open(id, const portalBox[portalBox_t], type, bool:sound = false) {
	// Если уже есть портал этого типа - удаляем
	if(g_portals[id][type] != 0 && is_entity(g_portals[id][type])) {
		new old_portal = g_portals[id][type];
		rg_remove_entity(old_portal);
		g_portals[id][type] = 0;
	}

	new portal = rg_create_entity("info_target");
	if(!portal) return;

	set_entvar(portal, var_classname, PORTAL_CLASSNAME);
	set_entvar(portal, var_model, g_sPortalModel);
	set_entvar(portal, var_modelindex, g_idPortalModel);
	set_entvar(portal, var_solid, SOLID_TRIGGER);
	set_entvar(portal, var_movetype, MOVETYPE_FLY);
	set_entvar(portal, var_owner, id);

	// Устанавливаем позицию и углы
	set_entvar(portal, var_origin, portalBox[pcenter]);
	
	static Float:portal_angles[3];
	vector_to_angle(portalBox[pfwd], portal_angles);
	set_entvar(portal, var_angles, portal_angles);

	// Устанавливаем размеры
	static Float:mins[3], Float:maxs[3];
	mins[0] = -PORTAL_WIDTH; mins[1] = -PBOX_DEPTH; mins[2] = -PORTAL_HEIGHT;
	maxs[0] = PORTAL_WIDTH; maxs[1] = PBOX_DEPTH; maxs[2] = PORTAL_HEIGHT;
	set_entvar(portal, var_mins, mins);
	set_entvar(portal, var_maxs, maxs);

	// ВАЖНО: Устанавливаем скин для различия цветов
	// Обычно скин 0 - синий, скин 1 - оранжевый
	set_entvar(portal, var_skin, type);

	// Также устанавливаем визуальные эффекты
	set_entvar(portal, var_rendermode, kRenderNormal);
	set_entvar(portal, var_renderamt, 255.0);
	
	// Сохраняем портал
	g_portals[id][type] = portal;
	
	SetTouch(portal,"@portal_touch");

	if(sound) {
		emit_sound(portal, CHAN_STATIC, type == PORTAL_1 ? g_sPortalSoundOpen1 : g_sPortalSoundOpen2, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}

void:portal_close(const player, const type) {
	if(!PORTAL_IS_VALID_PAIR(player)) {
		return;
	}
	
	if(type < 2) {
		set_entvar(g_portals[player][type], var_effects, get_entvar(g_portals[player][type], var_effects) | EF_NODRAW);
	} else {
		set_entvar(g_portals[player][0], var_effects, get_entvar(g_portals[player][0], var_effects) | EF_NODRAW);
		set_entvar(g_portals[player][1], var_effects, get_entvar(g_portals[player][1], var_effects) | EF_NODRAW);
	}
}

void:portal_remove_pair(const player) {
	for(new i = 0; i < 2; i++) {
		if(g_portals[player][i] == 0 || !is_entity(g_portals[player][i])) {
			g_portals[player][i] = 0;
			continue;
		}
		
		rg_remove_entity(g_portals[player][i]);
		g_portals[player][i] = 0;
	}
}

bool:portal_teleport(const id, const entPortalOut, const entPortalIn) {
	enum {
		Portal_On_Floor = 1,
		Portal_On_Ceiling
	}
	
	enum _:Portal_Properties {
		Portal_Start,
		Portal_End
	}
	
	static Float:fPortalAngles[Portal_Properties][3];
	static Float:fPortalNormal[Portal_Properties][3];
	static Float:fPortalEndOrigin[3];
	static bitPortalAprxmOrig[Portal_Properties];
	static Float:fEntAngles[3];
	static Float:fEntVelocity[3];
	
	get_entvar(entPortalIn, var_angles, fPortalAngles[Portal_Start]);
	get_entvar(entPortalOut, var_angles, fPortalAngles[Portal_End]);
	angle_vector(fPortalAngles[Portal_Start], ANGLEVECTOR_FORWARD, fPortalNormal[Portal_Start]);
	angle_vector(fPortalAngles[Portal_End], ANGLEVECTOR_FORWARD, fPortalNormal[Portal_End]);
	xs_1_neg(fPortalNormal[Portal_Start][2]);
	xs_1_neg(fPortalNormal[Portal_End][2]);
	get_entvar(entPortalOut, var_origin, fPortalEndOrigin);
	get_entvar(id, var_v_angle, fEntAngles);
	get_entvar(id, var_velocity, fEntVelocity);
	
	if(xs_vec_angle(VEC_FLOOR, fPortalNormal[Portal_Start]) < IGNORE_ANGLE_DEG_FL) bitPortalAprxmOrig[Portal_Start] |= Portal_On_Floor;
	if(xs_vec_angle(VEC_CEILING, fPortalNormal[Portal_Start]) < IGNORE_ANGLE_DEG_CE) bitPortalAprxmOrig[Portal_Start] |= Portal_On_Ceiling;
	if(xs_vec_angle(VEC_FLOOR, fPortalNormal[Portal_End]) < IGNORE_ANGLE_DEG_FL) bitPortalAprxmOrig[Portal_End] |= Portal_On_Floor;
	if(xs_vec_angle(VEC_CEILING, fPortalNormal[Portal_End]) < IGNORE_ANGLE_DEG_CE) bitPortalAprxmOrig[Portal_End] |= Portal_On_Ceiling;
	
	static Float:min[3];
	static Float:max[3];
	get_entvar(id, var_mins, min);
	get_entvar(id, var_maxs, max);
	
	new classname[32];
	get_entvar(id, var_classname, classname, charsmax(classname));
	
	if(!xs_vec_nearlyequal(min, Vec3Zero) && !xs_vec_nearlyequal(max, Vec3Zero)) {
		static Float:boxSize[3];
		static Float:zCenter;
		boxSize[0] = (floatabs(min[0]) + floatabs(max[0])) / 2.0;
		boxSize[1] = (floatabs(min[1]) + floatabs(max[1])) / 2.0;
		boxSize[2] = (floatabs(min[2]) + floatabs(max[2])) / 2.0;
		
		zCenter = boxSize[2] > max[2] ? (max[2] - boxSize[2]) : (boxSize[2] - max[2]);
		
		static Float:portalMin[3];
		static Float:portalMax[3];
		get_entvar(entPortalOut, var_mins, portalMin);
		get_entvar(entPortalOut, var_maxs, portalMax);
		
		
		// @TODO переосмыслить
		new Float:sinAngle = xs_sin(xs_vec_angle(fPortalAngles[Portal_End], Vec3Zero), degrees);
		static Float:shift;
		
		new dimension = 1;
		
		if(fPortalAngles[Portal_End][0] > 45.0) {  // Используем 0 вместо XS_PITCH
			dimension = 2;
		}
		
		shift = boxSize[dimension] / sinAngle + portalMax[dimension] / sinAngle;
		
		static Float:destination[3];
		xs_vec_mul_scalar(fPortalNormal[Portal_End], shift + PORTAL_DESTINATION_SHIFT, destination);
		xs_vec_add(destination, fPortalEndOrigin, destination);
		
		engfunc(EngFunc_TraceHull, destination, destination, 0, HULL_HUMAN, id, g_pCommonTr);
		if(get_tr2(g_pCommonTr, TR_StartSolid) || get_tr2(g_pCommonTr, TR_AllSolid) || get_tr2(g_pCommonTr, TR_pHit) >= 0) {
			return false;
		}
		
		destination[2] += zCenter;
		
		set_entvar(id, var_origin, destination);
		engfunc(EngFunc_SetOrigin, id, destination);
	} else {
		set_entvar(id, var_origin, fPortalEndOrigin);
		engfunc(EngFunc_SetOrigin, id, fPortalEndOrigin);
	}
	
	static Float:fOutAngles[3];
	new Float:fSpeed = vector_length(fEntVelocity);
	
	if(bitPortalAprxmOrig[Portal_End] && fSpeed > IGNORE_SPEED) {
		if(xs_vec_nearlyequal(fPortalNormal[Portal_End], VEC_FLOOR) || xs_vec_nearlyequal(fPortalNormal[Portal_End], VEC_CEILING)) {
			xs_vec_copy(fEntAngles, fOutAngles);
		} else {
			fOutAngles[0] = fEntAngles[0] - 80.0 - fPortalAngles[Portal_Start][0] + fPortalAngles[Portal_End][0];
			fOutAngles[1] = fPortalAngles[Portal_End][1];
			fOutAngles[2] = fPortalAngles[Portal_End][2];
		}
	} else if((bitPortalAprxmOrig[Portal_Start] && bitPortalAprxmOrig[Portal_End]) || (~bitPortalAprxmOrig[Portal_Start] && bitPortalAprxmOrig[Portal_End])) {
		xs_vec_copy(fEntAngles, fOutAngles);
	} else if(bitPortalAprxmOrig[Portal_Start] && ~bitPortalAprxmOrig[Portal_End]) {
		xs_vec_copy(fPortalAngles[Portal_End], fOutAngles);
	} else {
		fOutAngles[0] = fEntAngles[0];
		fOutAngles[1] = fEntAngles[1] + 180.0 + fPortalAngles[Portal_End][1] - fPortalAngles[Portal_Start][1];
		fOutAngles[2] = fEntAngles[2];
	}
	
	set_entvar(id, var_angles, fOutAngles);
	
	if(FClassnameIs(id, "player")) {
		set_entvar(id, var_v_angle, fOutAngles);
		set_entvar(id, var_fixangle, 1);
	}
	
	static Float:fOutVelocity[3];
	
	if((bitPortalAprxmOrig[Portal_Start] & Portal_On_Floor && bitPortalAprxmOrig[Portal_End] & Portal_On_Ceiling) ||
	   (bitPortalAprxmOrig[Portal_Start] & Portal_On_Ceiling && bitPortalAprxmOrig[Portal_End] & Portal_On_Floor)) {
		xs_vec_copy(fEntVelocity, fOutVelocity);
		set_entvar(id, var_velocity, fOutVelocity);
		return true;
	}
	
	if((bitPortalAprxmOrig[Portal_Start] & Portal_On_Floor && bitPortalAprxmOrig[Portal_End] & Portal_On_Floor) || 
	   (bitPortalAprxmOrig[Portal_Start] & Portal_On_Ceiling && bitPortalAprxmOrig[Portal_End] & Portal_On_Ceiling)) {
		if(fSpeed < IGNORE_SPEED) {
			xs_vec_copy(fEntVelocity, fOutVelocity);
			xs_1_neg(fOutVelocity[2]);
		} else {
			xs_vec_mul_scalar(fPortalNormal[Portal_End], fSpeed, fOutVelocity);
		}
		set_entvar(id, var_velocity, fOutVelocity);
		return true;
	} else if(bitPortalAprxmOrig[Portal_Start] & (Portal_On_Floor | Portal_On_Ceiling) && ~bitPortalAprxmOrig[Portal_End]) {
		xs_vec_mul_scalar(fPortalNormal[Portal_End], fSpeed, fOutVelocity);
		set_entvar(id, var_velocity, fOutVelocity);
		return true;
	} else if(bitPortalAprxmOrig[Portal_End] & (Portal_On_Floor | Portal_On_Ceiling) && ~bitPortalAprxmOrig[Portal_Start]) {
		if(fSpeed < IGNORE_SPEED) {
			xs_vec_copy(fEntVelocity, fOutVelocity);
		} else {
			xs_vec_mul_scalar(fPortalNormal[Portal_End], fSpeed, fOutVelocity);
		}
		set_entvar(id, var_velocity, fOutVelocity);
		return true;
	}
	
	static Float:fNormalVelocity[3];
	xs_vec_normalize(fEntVelocity, fNormalVelocity);
	
	static Float:fReflectNormal[3];
	xs_vec_add(fPortalNormal[Portal_Start], fPortalNormal[Portal_End], fReflectNormal);
	
	xs_vec_normalize(fReflectNormal, fReflectNormal);
	xs_vec_reflect(fNormalVelocity, fReflectNormal, fOutVelocity);
	xs_1_neg(fOutVelocity[2]);
	xs_vec_neg(fOutVelocity, fOutVelocity);
	xs_vec_reflect(fOutVelocity, fPortalNormal[Portal_End], fOutVelocity);
	
	if(vector_length(fOutVelocity) <= 0) {
		xs_vec_copy(fNormalVelocity, fOutVelocity);
	}
	
	xs_vec_mul_scalar(fOutVelocity, fSpeed, fOutVelocity);
	
	if(vector_length(fOutVelocity) <= 0) {
		xs_vec_set(fOutVelocity, 0.1, 0.1, 0.1);
	}
	
	set_entvar(id, var_velocity, fOutVelocity);

	return true;
}

bool:portalBox_create(const Float:shotFrom[3], const Float:shotDirection[3], playerId, outPortalBox[portalBox_t]) {
	static Float:pointEnd[3], Float:normal[3];
	
	xs_vec_mul_scalar(shotDirection, 9999.0, pointEnd);
	xs_vec_add(shotFrom, pointEnd, pointEnd);
	
	engfunc(EngFunc_TraceLine, shotFrom, pointEnd, 0, playerId, g_pCommonTr);
	
	get_tr2(g_pCommonTr, TR_vecEndPos, pointEnd);
	get_tr2(g_pCommonTr, TR_vecPlaneNormal, normal);
	
	// ВАЖНО: Эта строка была пропущена!
	portalBox_create2(pointEnd, normal, outPortalBox);
	
	static firstPortalBox[portalBox_t];
	portalBox_copy(outPortalBox, firstPortalBox);
	
	portalBox_move(outPortalBox, outPortalBox[pfwd], PBOX_SHIFT);
	
	static i, res;
	for(i = 0; i < PBOX_ITERS; i++) {
		res = portalBox_check(outPortalBox, normal);
		
		if(res == 1) {
			return true;
		}
			
		if(res == -1) {
			portalBox_copy(firstPortalBox, outPortalBox);
			return false;
		}
		
		portalBox_move(outPortalBox, normal, PBOX_STEP);
	}
	
	portalBox_copy(firstPortalBox, outPortalBox);
	return false;
}

void:portalBox_create2(const Float:pointCenter[3], const Float:normal[3], outPortalBox[portalBox_t]) {
	static Float:fwd[3], Float:right[3], Float:up[3], Float:left[3], Float:down[3];
	
	vector_to_angle(normal, fwd);
	xs_anglevectors(fwd, fwd, right, up);
	
	up[2] = -up[2];
	fwd[2] = -fwd[2];
	right[2] = -right[2];
	
	xs_vec_copy(fwd, outPortalBox[pfwd]);
	xs_vec_copy(up, outPortalBox[pup]);
	xs_vec_copy(right, outPortalBox[pright]);
	xs_vec_copy(pointCenter, outPortalBox[pcenter]);
	
	xs_vec_mul_scalar(right, PORTAL_WIDTH / 2, right);
	xs_vec_mul_scalar(up, PORTAL_HEIGHT / 2, up);
	xs_vec_neg(right, left);
	xs_vec_neg(up, down);
	
	xs_vec_add(up, left, outPortalBox[ppointUL]);
	xs_vec_add(up, right, outPortalBox[ppointUR]);
	xs_vec_add(down, right, outPortalBox[ppointDR]);
	xs_vec_add(down, left, outPortalBox[ppointDL]);
	
	xs_vec_add(pointCenter, outPortalBox[ppointUL], outPortalBox[ppointUL]);
	xs_vec_add(pointCenter, outPortalBox[ppointUR], outPortalBox[ppointUR]);
	xs_vec_add(pointCenter, outPortalBox[ppointDR], outPortalBox[ppointDR]);
	xs_vec_add(pointCenter, outPortalBox[ppointDL], outPortalBox[ppointDL]);
}

void:portalBox_move(portalBox[portalBox_t], const Float:direction[3], Float:dist) {
	vec_move_point(portalBox[ppointUL], direction, dist);
	vec_move_point(portalBox[ppointUR], direction, dist);
	vec_move_point(portalBox[ppointDR], direction, dist);
	vec_move_point(portalBox[ppointDL], direction, dist);
	vec_move_point(portalBox[pcenter], direction, dist);
}

portalBox_check(const portalBox[portalBox_t], Float:outBestDirection[3]) {	
	static portalBoxBackward[portalBox_t], Float:backward[3];
	portalBox_copy(portalBox, portalBoxBackward);
	xs_vec_neg(portalBoxBackward[pfwd], backward);
	portalBox_move(portalBoxBackward, backward, PBOX_DEPTH);
	
	static Float:resTable[4];
	
	// Трассируем от каждого угла портала назад
	engfunc(EngFunc_TraceLine, portalBox[ppointUL], portalBoxBackward[ppointUL], IGNORE_ALL, 0, g_pCommonTr);
	get_tr2(g_pCommonTr, TR_flFraction, resTable[0]);

	engfunc(EngFunc_TraceLine, portalBox[ppointUR], portalBoxBackward[ppointUR], IGNORE_ALL, 0, g_pCommonTr);
	get_tr2(g_pCommonTr, TR_flFraction, resTable[1]);
	
	engfunc(EngFunc_TraceLine, portalBox[ppointDR], portalBoxBackward[ppointDR], IGNORE_ALL, 0, g_pCommonTr);
	get_tr2(g_pCommonTr, TR_flFraction, resTable[2]);
	
	engfunc(EngFunc_TraceLine, portalBox[ppointDL], portalBoxBackward[ppointDL], IGNORE_ALL, 0, g_pCommonTr);
	get_tr2(g_pCommonTr, TR_flFraction, resTable[3]);
	
	// Преобразуем в бинарные значения (1 = есть препятствие, 0 = свободно)
	static i;
	for(i = 0; i < sizeof resTable; i++) {
		resTable[i] = resTable[i] == 1.0 ? 0.0 : 1.0;
	}
	
	// Таблица состояний углов
	enum {VALID, INVALID, UP, UP_RIGHT, UP_LEFT, DOWN, DOWN_RIGHT, DOWN_LEFT, RIGHT, LEFT};
	static const dirState[][] = {
		{0, 0, 0, 0},	 {0, 0, 0, 1},	  {0, 0, 1, 0},	   {0, 0, 1, 1},	{0, 1, 0, 0},	 {0, 1, 0, 1},	  {0, 1, 1, 0},	   {0, 1, 1, 1},
		{1, 0, 0, 0},	 {1, 0, 0, 1},	  {1, 0, 1, 0},	   {1, 0, 1, 1},	{1, 1, 0, 0},	 {1, 1, 0, 1},	  {1, 1, 1, 0},	   {1, 1, 1, 1}
	};
	static const dirAction[] = {
		INVALID,		DOWN_LEFT,		  DOWN_RIGHT,		 DOWN,			  UP_RIGHT,		   UP_RIGHT,		RIGHT,			  DOWN_RIGHT,
		UP_LEFT,		LEFT,			 INVALID,			 DOWN_LEFT,		   UP,				  UP_LEFT,		  UP_RIGHT,		   VALID
	};
	
	// Ищем совпадение в таблице состояний
	for(i = (sizeof dirState) - 1; i > -1; i--) {
		if((resTable[0] == dirState[i][0]) &&
		   (resTable[1] == dirState[i][1]) &&
		   (resTable[2] == dirState[i][2]) &&
		   (resTable[3] == dirState[i][3]))
			break;
	}
	
	static Float:tmpVec[3];
	switch(dirAction[i]) {
		case VALID: {
			return 1;
		}
		case INVALID: {
			return -1;
		}
		case UP: {
			xs_vec_copy(portalBox[pup], outBestDirection);
		}
		case UP_RIGHT: {
			xs_vec_copy(portalBox[pup], outBestDirection);
			xs_vec_add(portalBox[pright], outBestDirection, outBestDirection);
		}
		case UP_LEFT: {
			xs_vec_neg(portalBox[pright], tmpVec);
			xs_vec_copy(portalBox[pup], outBestDirection);
			xs_vec_add(tmpVec, outBestDirection, outBestDirection);
		}
		case DOWN: {
			xs_vec_neg(portalBox[pup], outBestDirection);
		}
		case DOWN_RIGHT: {
			xs_vec_neg(portalBox[pup], outBestDirection);
			xs_vec_add(outBestDirection, portalBox[pright], outBestDirection);
		}
		case DOWN_LEFT: {
			xs_vec_neg(portalBox[pright], tmpVec);
			xs_vec_neg(portalBox[pup], outBestDirection);
			xs_vec_add(tmpVec, outBestDirection, outBestDirection);
		}
		case RIGHT: {
			xs_vec_copy(portalBox[pright], outBestDirection);
		}
		case LEFT: {
			xs_vec_neg(portalBox[pright], outBestDirection);
		}
	}
	return 0;
}

void:portalBox_copy(const portalBox[portalBox_t], outPortalBox[portalBox_t]) {
	xs_vec_copy(portalBox[ppointUL], outPortalBox[ppointUL]);
	xs_vec_copy(portalBox[ppointDL], outPortalBox[ppointDL]);
	xs_vec_copy(portalBox[ppointDR], outPortalBox[ppointDR]);
	xs_vec_copy(portalBox[ppointUR], outPortalBox[ppointUR]);
	
	xs_vec_copy(portalBox[pcenter], outPortalBox[pcenter]);
	
	xs_vec_copy(portalBox[pfwd], outPortalBox[pfwd]);
	xs_vec_copy(portalBox[pup], outPortalBox[pup]);
	xs_vec_copy(portalBox[pright], outPortalBox[pright]);
}

stock vec_move_point(Float:vec[], const Float:direction[], const Float:dist) {
	static Float:tmp[3];
	xs_vec_mul_scalar(direction, dist, tmp);
	xs_vec_add(vec, tmp, vec);
}

stock point_forward(const id, const Float:dist, Float:out[3]) {
	static Float:angles[3], Float:origin[3];
	get_entvar(id, var_angles, angles);
	get_entvar(id, var_origin, origin);
	angle_vector(angles, ANGLEVECTOR_FORWARD, angles);
	xs_vec_mul_scalar(angles, dist, angles);
	xs_vec_add(angles, origin, out);
}