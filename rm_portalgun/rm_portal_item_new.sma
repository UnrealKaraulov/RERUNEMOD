#include <amxmodx>
#include <reapi>
#include <hamsandwich>
#include <xs>
#include <rm_api>

#define PLUGIN "RM_PORTAL"
#define VERSION "3.1_NEW"
#define AUTHOR "trofian, polarhigh, karaulov"

#define IGNORE_ALL (IGNORE_MISSILE | IGNORE_MONSTERS | IGNORE_GLASS)


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


#define PORTAL_CLASSNAME "portal_custom"
#define PORTAL_LOCK_TIME 1.0
#define PORTAL_DESTINATION_SHIFT 4.0
#define PORTAL_WIDTH 46.0
#define PORTAL_HEIGHT 72.0

#define PBOX_SHIFT 1.0		// Начальный сдвиг от стены
#define PBOX_DEPTH 2.0		// Глубина портала	
#define PBOX_STEP 1.0		// Шаг движения
#define PBOX_ITERS 50		// Количество итераций

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
new g_iPortalWeaponAnim[MAX_PLAYERS + 1] = {0,...};
new g_portals[MAX_PLAYERS + 1][2];
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
// Сущности которые не могут пройти сквозь портал по класснейму
new Array:g_aBlockedEntities;
new bool:g_bCheckBlockedEntities = true;
new g_szBlockedEntities[2048] = {EOS};
// Запрещёнка которую игрок не сможет пронести с собой в портал
new Array:g_aForbiddenEntities;
new bool:g_bCheckForbiddenEntities = true;
new g_szForbiddenEntities[2048] = {EOS};
// Сущности которые не смогут пройти в портал по размерам
new Float:g_fMaxEntitySize = 100.0;
new bool:g_bCheckEntitySize = true;
// Перезарядка порталов для сущностей
new Float:g_fPortalEntityCooldown = 0.05;
// Перезарядка порталов для игроков
new Float:g_flLastTeleportTime[MAX_PLAYERS + 1][2];
// Иммунитет после телепорта (на игрока, секунды)
new Float:g_fPortalPlayerCooldown = 0.5;
// Время смены оружия
new Float:nextDeployTime[MAX_PLAYERS + 1] = {0.0,...};
new Float:g_fDeployCooldown = 1.0;
// Дальность на которую можно открыть портал
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
	
	formatex(g_szBlockedEntities,charsmax(g_szBlockedEntities), "%s,func_,trigger_,info_,ambient_", RUNE_CLASSNAME);
	
	rm_read_cfg_str(rune_name, "BLOCKED_ENTITIES", g_szBlockedEntities, g_szBlockedEntities, charsmax(g_szBlockedEntities));
	rm_read_cfg_str(rune_name, "FORBIDDEN_ENTITIES", "", g_szForbiddenEntities, charsmax(g_szForbiddenEntities));
	
	new temp;
	rm_read_cfg_int(rune_name, "CHECK_ENTITY_SIZE", 1, temp);
	g_bCheckEntitySize = bool:temp;
	
	rm_read_cfg_int(rune_name, "CHECK_BLOCKED_ENTITIES", 1, temp);
	g_bCheckBlockedEntities = bool:temp;
	
	rm_read_cfg_int(rune_name, "CHECK_FORBIDDEN_ENTITIES", 1, temp);
	g_bCheckForbiddenEntities = bool:temp;
	
	rm_read_cfg_flt(rune_name, "ENTITY_TELEPORT_COOLDOWN", 0.01, g_fPortalEntityCooldown);
	rm_read_cfg_flt(rune_name, "PORTAL_DEPLOY_COOLDOWN", 1.0, g_fDeployCooldown);
	rm_read_cfg_int(rune_name, "MAX_PORTAL_DISTANCE", 2000, g_iMaxPortalDistance);
	
	// Иммунитет игрока после телепорта
	rm_read_cfg_flt(rune_name, "PLAYER_TELEPORT_COOLDOWN", 0.25, g_fPortalPlayerCooldown);

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
	
	for(new i = 0; i <= MAX_PLAYERS;i++)
	{
		for(new n = 0; n <= 1;n++)
		{
			g_flLastTeleportTime[i][n] = 0.0;
			g_portals[i][n] = g_iPlayerData[i][n] = 0;
		}
	}

	// Вывод конфигурации в лог для удобства отладки
	log_amx("[PORTAL] Config summary:");
	log_amx("[PORTAL] MAX_ENTITY_SIZE = %.2f", g_fMaxEntitySize);
	log_amx("[PORTAL] CHECK_ENTITY_SIZE = %d", g_bCheckEntitySize ? 1 : 0);
	log_amx("[PORTAL] CHECK_BLOCKED_ENTITIES = %d", g_bCheckBlockedEntities ? 1 : 0);
	log_amx("[PORTAL] CHECK_FORBIDDEN_ENTITIES = %d", g_bCheckForbiddenEntities ? 1 : 0);
	log_amx("[PORTAL] ENTITY_TELEPORT_COOLDOWN = %.3f", g_fPortalEntityCooldown);
	log_amx("[PORTAL] PLAYER_TELEPORT_COOLDOWN = %.3f", g_fPortalPlayerCooldown);
	log_amx("[PORTAL] PORTAL_DEPLOY_COOLDOWN = %.3f", g_fDeployCooldown);
	log_amx("[PORTAL] MAX_PORTAL_DISTANCE = %d", g_iMaxPortalDistance);
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	// Инициализация массива заблокированных сущностей
	g_aBlockedEntities = ArrayCreate(64);
	g_aForbiddenEntities = ArrayCreate(64);
	
	parse_blocked_entities();
	parse_forbidden_entities();
	
	g_pCommonTr = create_tr2();
	
	RegisterHookChain(RG_RoundEnd, "@round_restart", true);
	RegisterHookChain(RG_CSGameRules_RestartRound, "@round_restart", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "@player_killed_post", true);
	
	register_clcmd("weapon_knife", "@cmd_drop");
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "@knife_deploy_p", .Post = 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_knife", "@knife_postframe");
	register_forward(FM_UpdateClientData, "@update_client_data_p", 1);
	
	for(new i = 0; i <= MAX_PLAYERS; i++) {
		for(new j = 0; j < 2; j++) {
			g_portals[i][j] = 0;
			g_flLastTeleportTime[i][j] = 0.0;
		}
	}
}

public plugin_end() {
	free_tr2(g_pCommonTr);
	if(g_aBlockedEntities != Invalid_Array) {
		ArrayDestroy(g_aBlockedEntities);
	}
	if(g_aForbiddenEntities != Invalid_Array) {
		ArrayDestroy(g_aForbiddenEntities);
	}
}

// Функция парсинга заблокированных сущностей
parse_blocked_entities() {
	if(!g_bCheckBlockedEntities || strlen(g_szBlockedEntities) == 0) {
		return;
	}
	
	// Очищаем массив на случай повторного вызова
	if(ArraySize(g_aBlockedEntities) > 0) {
		ArrayClear(g_aBlockedEntities);
	}
	
	log_amx("[PORTAL] Raw blocked entities string: '%s'", g_szBlockedEntities);
	
	// Разбиваем строку по запятым
	static classname[64];
	static start, end;
	new len = strlen(g_szBlockedEntities);
	new count = 0;
	
	for(start = 0, end = 0; end <= len; end++) {
		// Если нашли запятую или конец строки
		if(g_szBlockedEntities[end] == ',' || g_szBlockedEntities[end] == 0) {
			if(end > start) {
				// Копируем подстроку
				copyc(classname, charsmax(classname), g_szBlockedEntities[start], ',');
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
parse_forbidden_entities() {
	if(!g_bCheckForbiddenEntities || strlen(g_szForbiddenEntities) == 0) {
		return;
	}
	
	// Очищаем массив на случай повторного вызова
	if(ArraySize(g_aForbiddenEntities) > 0) {
		ArrayClear(g_aForbiddenEntities);
	}
	
	log_amx("[PORTAL] Raw forbidden entities string: '%s'", g_szForbiddenEntities);
	
	// Разбиваем строку по запятым
	new classname[64];
	new start, end;
	new len = strlen(g_szForbiddenEntities);
	new count = 0;
	
	for(start = 0, end = 0; end <= len; end++) {
		// Если нашли запятую или конец строки
		if(g_szForbiddenEntities[end] == ',' || g_szForbiddenEntities[end] == 0) {
			if(end > start) {
				// Копируем подстроку
				copyc(classname, charsmax(classname), g_szForbiddenEntities[start], ',');
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
					ArrayPushString(g_aForbiddenEntities, classname);
					count++;
				}
			}
			start = end + 1; // Переходим к следующему элементу
		}
	}
	
	log_amx("[PORTAL] Successfully loaded %d forbidden entities", count);
}

// Улучшенная функция проверки размера сущности
bool:is_entity_size_valid(const id) {
	if(!g_bCheckEntitySize || !is_entity(id)) {
		return true;
	}
	
	static Float:mins[3], Float:maxs[3];
	get_entvar(id, var_mins, mins);
	get_entvar(id, var_maxs, maxs);
	
	new Float:size_x = floatabs(maxs[0] - mins[0]);
	new Float:size_y = floatabs(maxs[1] - mins[1]);
	new Float:size_z = floatabs(maxs[2] - mins[2]);
	
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

// Сущность не сможет пройти сквозь портал
bool:is_entity_blocked(const classname[]) {
	if(!g_bCheckBlockedEntities || ArraySize(g_aBlockedEntities) == 0) {
		return false;
	}
	
	static temp[64], i;
	
	for(i = 0; i < ArraySize(g_aBlockedEntities); i++) {
		ArrayGetString(g_aBlockedEntities, i, temp, charsmax(temp));
		
		// Совпадение по префиксу
		if(containi(classname, temp) == 0) {
			return true;
		}
	}
	
	return false;
}

// Игрок не сможет пронести запрещёнку сквозь портал
bool:is_entity_forbidden(const pid) {
	if(!g_bCheckForbiddenEntities || ArraySize(g_aForbiddenEntities) == 0) {
		return false;
	}
	
	static temp[64], i;
	
	for(i = 0; i < ArraySize(g_aForbiddenEntities); i++) {
		ArrayGetString(g_aForbiddenEntities, i, temp, charsmax(temp));
		
		new iEnt = MAX_PLAYERS;
		while((iEnt = rg_find_ent_by_class(iEnt, temp)))
		{
			new owner = get_entvar(iEnt, var_owner);
			new aiment = get_entvar(iEnt, var_aiment);
			
			if (pid == owner || pid == aiment)
			{
				return true;
			}
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

bool:is_can_portal(const iPlayer) {
	static Float:vecEyesOrigin[3];
	static Float:vecEyesEndOrigin[3];
	
	// Получаем позицию глаз игрока
	get_entvar(iPlayer, var_origin, vecEyesOrigin);
	static Float:vecViewOfs[3];
	get_entvar(iPlayer, var_view_ofs, vecViewOfs);
	xs_vec_add(vecEyesOrigin, vecViewOfs, vecEyesOrigin);
	
	// Трассируем луч чтобы получить точку куда смотрит игрок
	static Float:vecAngle[3];
	static Float:vecDirection[3];
	get_entvar(iPlayer, var_v_angle, vecAngle);
	angle_vector(vecAngle, ANGLEVECTOR_FORWARD, vecDirection);
	
	static Float:vecEnd[3];
	xs_vec_mul_scalar(vecDirection, float(g_iMaxPortalDistance), vecEnd);
	xs_vec_add(vecEyesOrigin, vecEnd, vecEnd);
	
	engfunc(EngFunc_TraceLine, vecEyesOrigin, vecEnd, IGNORE_ALL, iPlayer, g_pCommonTr);
	get_tr2(g_pCommonTr, TR_vecEndPos, vecEyesEndOrigin);
	
	// ПРОСТАЯ ПРОВЕРКА: есть ли стены между игроком и точкой портала?
	// Отодвигаем стартовую точку от игрока, чтобы не задеть себя
	static Float:vecStartCheck[3];
	xs_vec_mul_scalar(vecDirection, 32.0, vecStartCheck);
	xs_vec_add(vecEyesOrigin, vecStartCheck, vecStartCheck);
	
	// Запускаем луч от игрока к точке портала
	engfunc(EngFunc_TraceLine, vecStartCheck, vecEyesEndOrigin, IGNORE_ALL, iPlayer, g_pCommonTr);
	
	// Получаем точку, куда попал луч
	static Float:vecHitPoint[3];
	get_tr2(g_pCommonTr, TR_vecEndPos, vecHitPoint);
	
	// Если луч попал в ту же точку (или очень близко) - значит нет препятствий
	if(get_distance_f(vecHitPoint, vecEyesEndOrigin) < 5.0) {
		return true;
	}
	
	// Если расстояние большое - значит луч уперся в стену на пути
	return false;
}

@knife_postframe(const weapon) {
	new id = get_entvar(weapon, var_owner);
	
	if(!is_user_connected(id) || !VISIBLE_PORTAL_GUN(id)) {
		return HAM_IGNORED;
	}
	
	static Float:nextAttackTime[MAX_PLAYERS + 1];
	if(nextAttackTime[id] > get_gametime()) {
		return HAM_SUPERCEDE;
	}
	
	new buttons = get_entvar(id, var_button);
	new type = -1;
	if(buttons & IN_ATTACK) {
		type = PORTAL_1;
	} else if(buttons & IN_ATTACK2) {
		type = PORTAL_2;
	} else {
		SET_PORTAL_GUN_ANIM(id, GUN_ANIM_IDLE);
		return HAM_SUPERCEDE;
	}
	
	if(type == -1) {
		return HAM_SUPERCEDE;
	}
	
	// Получаем данные для создания портала
	static Float:origin[3], Float:originEyes[3], Float:angle[3], Float:normal[3];
	static portalBox[portalBox_t];
	
	get_entvar(id, var_origin, origin);
	get_entvar(id, var_view_ofs, originEyes);
	xs_vec_add(originEyes, origin, originEyes);
	
	get_entvar(id, var_v_angle, angle);
	angle_vector(angle, ANGLEVECTOR_FORWARD, normal);
	
	// Основная проверка - если любая из проверок не пройдена, создаем эффект ошибки
	new bool:success = false;
	
	if(portalBox_create(originEyes, normal, id, portalBox)) {
		// test hull проверка
		static Float:testOrigin[3];
		xs_vec_mul_scalar(portalBox[pfwd], 10.0, testOrigin);
		xs_vec_add(testOrigin, portalBox[pcenter], testOrigin);

		engfunc(EngFunc_TraceLine, portalBox[pcenter], testOrigin, IGNORE_ALL, id, g_pCommonTr);

		if(!get_tr2(g_pCommonTr, TR_StartSolid)) {
			if(is_can_portal(id)) {
				new Float:radius = floatmin(PORTAL_HEIGHT, PORTAL_WIDTH) / 2.0;
				new anotherEnt = 0;
				new bool:portalBlocked = false;
				
				// Проверка на пересечение с другими порталами
				while((anotherEnt = engfunc(EngFunc_FindEntityInSphere, anotherEnt, portalBox[pcenter], radius))) {
					if(get_entvar(anotherEnt, var_modelindex) == g_idPortalModel && !portal_test_owner(id, anotherEnt, type)) {
						portalBlocked = true;
						break;
					}
				}
				
				if(!portalBlocked) {
					// Финальная проверка - создание портала
					success = portal_open(id, portalBox, type, true);
				}
			}
		}
	}
	
	// Если портал не создан - показываем ошибку
	if(!success) {
		if(g_portals[id][type] != 0 && is_entity(g_portals[id][type])) {
			rg_remove_entity(g_portals[id][type]);
			g_portals[id][type] = 0;
		} 
		effect_sparks_error_open(portalBox[pcenter], portalBox[pfwd], type);
	}
	
	// Всегда проигрываем звук выстрела и анимацию
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
	new classname[64];
	get_entvar(toucher, var_classname, classname, charsmax(classname));
	
	if(g_bCheckBlockedEntities && is_entity_blocked(classname)) {
		return;
	}
	
	if(toucher <= MAX_PLAYERS && g_bCheckForbiddenEntities && is_entity_forbidden(toucher)) {
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
	
	new other_portal = g_portals[owner][other_portal_type];
	
	// Проверяем что второй портал существует
	if (!is_entity(other_portal))
	{
		return;
	}
	
	// Проверяем cooldown на портале для сущностей(используем nextthink)
	if(toucher > MAX_PLAYERS && get_entvar(portal, var_nextthink) > get_gametime()) {
		return;
	}
	
	// PER-PLAYER IMMUNITY: если это игрок, проверяем индивидуальный таймаут для данного портала типа
	if(toucher >= 1 && toucher <= MAX_PLAYERS) {
		if(g_flLastTeleportTime[toucher][portal_type] > get_gametime()) {
			return;
		}
	}
	
	// Телепортируем
	if(portal_teleport(toucher, other_portal, portal))
	{
		// Если это игрок — отмечаем время телепорта 
		if(toucher >= 1 && toucher <= MAX_PLAYERS) 
		{
			g_flLastTeleportTime[toucher][other_portal_type] = get_gametime()  + g_fPortalPlayerCooldown;
			g_flLastTeleportTime[toucher][portal_type] = get_gametime()  + g_fPortalPlayerCooldown;
		}
		else 
		{
			// ДЛЯ СУЩНОСТЕЙ: устанавливаем кулдаун на ОБА портала
			set_entvar(portal, var_nextthink, get_gametime() + g_fPortalEntityCooldown);
			set_entvar(other_portal, var_nextthink, get_gametime() + g_fPortalEntityCooldown);
		}
	}
}

@cmd_drop(const id) {
	if(!is_user_alive(id)) {
		return PLUGIN_CONTINUE;
	}
	
	if(!HAS_PORTAL_GUN(id)) {
		return PLUGIN_CONTINUE;
	}
	
	if(nextDeployTime[id] > get_gametime()) {
		return PLUGIN_CONTINUE;
	}
	
	VISIBLE_PORTAL_GUN(id) = !VISIBLE_PORTAL_GUN(id);
	
	new weapon = get_member(id, m_pActiveItem);
	if(is_entity(weapon)) {
		ExecuteHamB(Ham_Item_Deploy, weapon);
	}
	
	nextDeployTime[id] = get_gametime() + g_fDeployCooldown;
	
	return PLUGIN_CONTINUE;
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
	
	return true;
}

// Новые функции для проверки телепортации
bool:portal_calculate_exit_position(const entPortalOut, const Float:entity_mins[3], const Float:entity_maxs[3], Float:destination[3]) {
    static Float:portal_origin[3], Float:portal_angles[3], Float:portal_normal[3];
    get_entvar(entPortalOut, var_origin, portal_origin);
    get_entvar(entPortalOut, var_angles, portal_angles);
    
    // Получаем нормаль портала
    angle_vector(portal_angles, ANGLEVECTOR_FORWARD, portal_normal);
    portal_normal[2] = -portal_normal[2]; // Инвертируем Z как в оригинальной логике
    
    // Вычисляем размеры entity
    static Float:boxSize[3];
    boxSize[0] = (floatabs(entity_mins[0]) + floatabs(entity_maxs[0])) / 2.0;
    boxSize[1] = (floatabs(entity_mins[1]) + floatabs(entity_maxs[1])) / 2.0;
    boxSize[2] = (floatabs(entity_mins[2]) + floatabs(entity_maxs[2])) / 2.0;
    
    // Получаем размеры портала
    static Float:portal_mins[3], Float:portal_maxs[3];
    get_entvar(entPortalOut, var_mins, portal_mins);
    get_entvar(entPortalOut, var_maxs, portal_maxs);
    
    // Выбираем dimension по углу pitch портала (как в оригинале)
    new dimension = 1; // По умолчанию Y
    if (portal_angles[0] > 45.0) {
        dimension = 2; // Z
    }

    // Вычисляем половину размера портала
    new Float:portal_half = floatabs(portal_maxs[dimension] - portal_mins[dimension]) * 0.5;
    if (portal_half <= 0.01) {
        portal_half = (dimension == 2) ? (PORTAL_HEIGHT * 0.5) : (PORTAL_WIDTH * 0.5);
    }

    new Float:entity_half = boxSize[dimension];
    new Float:shift = entity_half + portal_half + PORTAL_DESTINATION_SHIFT + PBOX_DEPTH;

    // Строим точку назначения
    xs_vec_mul_scalar(portal_normal, shift, destination);
    xs_vec_add(portal_origin, destination, destination);

    // Проверяем валидность координат
    if (destination[0] != destination[0] || destination[1] != destination[1] || destination[2] != destination[2]) {
        return false;
    }

    if (floatabs(destination[0]) > 100000.0 || floatabs(destination[1]) > 100000.0 || floatabs(destination[2]) > 100000.0) {
        return false;
    }
    
    return true;
}

bool:portal_can_teleport_entity(const entPortalOut, const Float:entity_mins[3], const Float:entity_maxs[3]) {
    static Float:destination[3];
    
    if (!portal_calculate_exit_position(entPortalOut, entity_mins, entity_maxs, destination)) {
        return false;
    }
    
    // Проверяем hull entity в точке назначения
    engfunc(EngFunc_TraceHull, destination, destination, 0, HULL_HUMAN, 0, g_pCommonTr);
    
    if (get_tr2(g_pCommonTr, TR_StartSolid) || get_tr2(g_pCommonTr, TR_AllSolid) || get_tr2(g_pCommonTr, TR_pHit) >= 0) {
        return false;
    }
    
    return true;
}

// Обновленная portal_open с точной проверкой
bool:portal_open(id, const portalBox[portalBox_t], type, bool:sound = false) {
    // Если уже есть портал этого типа - удаляем
    if(g_portals[id][type] != 0) {
        if(is_entity(g_portals[id][type])) {
            rg_remove_entity(g_portals[id][type]);
        }
        g_portals[id][type] = 0;
    }

    // Создаем портал
    new portal = rg_create_entity("info_target");
    if(!portal) return false;

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

    set_entvar(portal, var_skin, type);
    set_entvar(portal, var_rendermode, kRenderNormal);
    set_entvar(portal, var_renderamt, 255.0);
    
    g_portals[id][type] = portal;
    
    SetTouch(portal,"@portal_touch");

    // ТОЧНАЯ ПРОВЕРКА: используем ту же логику что и в portal_teleport
    static Float:player_mins[3] = {-16.0, -16.0, -36.0};
    static Float:player_maxs[3] = {16.0, 16.0, 36.0};
    
    if(!portal_can_teleport_entity(portal, player_mins, player_maxs)) {
        // Если нельзя выйти - уничтожаем портал
        rg_remove_entity(portal);
        g_portals[id][type] = 0;
        effect_sparks_error_open(portalBox[pcenter], portalBox[pfwd], type);
        return false;
    }

    if(sound) {
        emit_sound(portal, CHAN_STATIC, type == PORTAL_1 ? g_sPortalSoundOpen1 : g_sPortalSoundOpen2, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }
    
    return true;
}

// Обновленная portal_teleport с использованием новых функций
bool:portal_teleport(const id, const entPortalOut, const entPortalIn) {
    enum {
        Portal_On_Floor = 1,
        Portal_On_Ceiling
    }
    
    enum _:Portal_Properties {
        Portal_Start,
        Portal_End
    }
    
    new bitPortalAprxmOrig[Portal_Properties] = {0,...};
    
    static Float:fPortalAngles[Portal_Properties][3];
    static Float:fPortalNormal[Portal_Properties][3];
    static Float:fPortalEndOrigin[3];
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
    
    static Float:mins[3];
    static Float:maxs[3];
    get_entvar(id, var_mins, mins);
    get_entvar(id, var_maxs, maxs);
    
    static classname[64];
    get_entvar(id, var_classname, classname, charsmax(classname));
    
    static Float:destination[3];
    
    if(!xs_vec_nearlyequal(mins, Vec3Zero) && !xs_vec_nearlyequal(maxs, Vec3Zero)) {
        // Используем новую функцию для расчета позиции
        if(!portal_calculate_exit_position(entPortalOut, mins, maxs, destination)) {
            return false;
        }
        
        // Проверяем hull в точке назначения
        engfunc(EngFunc_TraceHull, destination, destination, 0, HULL_HUMAN, id, g_pCommonTr);
        if(get_tr2(g_pCommonTr, TR_StartSolid) || get_tr2(g_pCommonTr, TR_AllSolid) || get_tr2(g_pCommonTr, TR_pHit) >= 0) {
            return false;
        }
        
        // Вычисляем zCenter (как в оригинале)
        static Float:boxSize[3];
        static Float:zCenter;
        boxSize[0] = (floatabs(mins[0]) + floatabs(maxs[0])) / 2.0;
        boxSize[1] = (floatabs(mins[1]) + floatabs(maxs[1])) / 2.0;
        boxSize[2] = (floatabs(mins[2]) + floatabs(maxs[2])) / 2.0;
        
        zCenter = boxSize[2] > maxs[2] ? (maxs[2] - boxSize[2]) : (boxSize[2] - maxs[2]);
        destination[2] += zCenter;
        
        set_entvar(id, var_origin, destination);
        engfunc(EngFunc_SetOrigin, id, destination);
    } else {
        set_entvar(id, var_origin, fPortalEndOrigin);
        engfunc(EngFunc_SetOrigin, id, fPortalEndOrigin);
    }
    
    // Остальная логика телепортации без изменений
    new Float:fSpeed = vector_length(fEntVelocity);
    
    if(bitPortalAprxmOrig[Portal_End] && fSpeed > IGNORE_SPEED) 
    {
        if(!xs_vec_nearlyequal(fPortalNormal[Portal_End], VEC_FLOOR) && !xs_vec_nearlyequal(fPortalNormal[Portal_End], VEC_CEILING)) 
        {
            fEntAngles[0] = fEntAngles[0] - 80.0 - fPortalAngles[Portal_Start][0] + fPortalAngles[Portal_End][0];
            fEntAngles[1] = fPortalAngles[Portal_End][1];
            fEntAngles[2] = fPortalAngles[Portal_End][2];
        }
    }
    else if((bitPortalAprxmOrig[Portal_Start] && bitPortalAprxmOrig[Portal_End]) || (~bitPortalAprxmOrig[Portal_Start] && bitPortalAprxmOrig[Portal_End])) 
    {
        // same
    } 
    else if(bitPortalAprxmOrig[Portal_Start] && ~bitPortalAprxmOrig[Portal_End]) 
    {
        xs_vec_copy(fPortalAngles[Portal_End], fEntAngles);
    } 
    else 
    {
        fEntAngles[1] = fEntAngles[1] + 180.0 + fPortalAngles[Portal_End][1] - fPortalAngles[Portal_Start][1];
    }
    
    if(FClassnameIs(id, "player")) {
        set_entvar(id, var_v_angle, fEntAngles);
        set_entvar(id, var_fixangle, 1);
    }
    
    set_entvar(id, var_angles, fEntAngles);
    
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

bool:portalBox_create(const Float:shotFrom[3], const Float:shotDirection[3], playerId, outPortalBox[portalBox_t]) {
	static Float:pointEnd[3], Float:normal[3];
	
	xs_vec_mul_scalar(shotDirection, 9999.0, pointEnd);
	xs_vec_add(shotFrom, pointEnd, pointEnd);
	
	engfunc(EngFunc_TraceLine, shotFrom, pointEnd, 0, playerId, g_pCommonTr);
	
	get_tr2(g_pCommonTr, TR_vecEndPos, pointEnd);
	get_tr2(g_pCommonTr, TR_vecPlaneNormal, normal);
	
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
	
	for(i = 0; i < 4; i++) {
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
