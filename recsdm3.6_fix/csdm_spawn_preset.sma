/**
 * csdm_spawn_preset.sma
 * Allows for Counter-Strike to be played as DeathMatch.

 * CSDM Spawn Method - Preset Spawning
 * by Freecode and BAILOPAN
 * (C)2003-2006 David "BAILOPAN" Anderson
 *
 * Give credit where due.
 * Share the source - it sets you free
 * http://www.opensource.org/
 * http://www.gnu.org/
 *
 *
 *
 * Modification from ReCSDM Team (C) 2016
 * http://www.dedicated-server.ru/
 *
 */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <reapi>
#include <csdm>

#pragma semicolon 1

#define	MAX_SPAWNS	60

new PLUGINNAME[] = "ReCSDM Spawns";
new VERSION[] = CSDM_VERSION;
new AUTHORS[] = "ReCSDM Team";

new g_MainMenu[] = "Менеджер точек возрождения";
new g_MainMenuID = -1;
new g_cMain;

new g_AddSpawnsMenu[] = "Меню добавления точек возрождения";
new g_AddSpawnsMenuID;
new g_cAddSpawns;

new g_SpawnVecs[MAX_SPAWNS][3];
new g_SpawnAngles[MAX_SPAWNS][3];
new g_SpawnVAngles[MAX_SPAWNS][3];
new g_SpawnTeam[MAX_SPAWNS];
new g_TotalSpawns = 0;
new g_MainPlugin = -1;
new g_Ents[MAX_SPAWNS];
new g_Ent[33];
new g_iszInfoTarget;
new Float:red[3] = {255.0,0.0,0.0};
new Float:yellow[3] = {255.0,200.0,20.0};

public csdm_Init(const version[])
{
	if (version[0] == 0) {
		set_fail_state("ReCSDM failed to load.");
		return;
	}

	csdm_addstyle("preset", "spawn_Preset");
}

public csdm_CfgInit()
{
	csdm_reg_cfg("settings", "read_cfg");
}

public plugin_init()
{
	register_plugin(PLUGINNAME,VERSION,AUTHORS);

	register_concmd("edit_spawns", "showmen", ADMIN_MAP, "Редактирование конфигурации точек возрождения");

	g_iszInfoTarget = engfunc(EngFunc_AllocString, "info_target");

	g_MainPlugin = module_exists("csdm_main") ? true : false;

	if (g_MainPlugin) {
		new menu = csdm_main_menu();
		menu_additem(menu, "Редактор точек возрождения", "edit_spawns", ADMIN_MAP);
	}
}

public read_cfg(action, line[], section[])
{
	if (action == CFG_RELOAD)
	{
		new Map[32], config[32],  MapFile[256];

		readSpawns();

		get_mapname(Map, charsmax(Map));
		get_configsdir(config, charsmax(config));

		formatex(MapFile, charsmax(MapFile), "%s\csdm\%s.spawns.cfg", config, Map);

		if (g_TotalSpawns) {
			log_amx("Loaded %d spawn points for map %s.", g_TotalSpawns, Map);
		} else {
			log_amx("No spawn points file found (%s)", MapFile);
		}
	}
}

readSpawns()
{
	new iEnt = NULLENT;
	while((iEnt = rg_find_ent_by_class(iEnt, "info_player_csdm")))
		set_entvar(iEnt, var_flags, get_entvar(iEnt, var_flags) | FL_KILLME);
	

	new Map[32], config[32],  MapFile[256];

	get_mapname(Map, charsmax(Map));
	get_configsdir(config, charsmax(config));
	formatex(MapFile, charsmax(MapFile), "%s\csdm\%s.spawns.cfg", config, Map);

	g_TotalSpawns = 0;

	if (file_exists(MapFile)) 
	{
		new Data[124], pos[12][8], len, line;

		while(g_TotalSpawns < MAX_SPAWNS && (line = read_file(MapFile, line, Data, charsmax(Data), len)) != 0) 
		{
			if (Data[0] == '[' || strlen(Data) < 2) {
				continue;
			}

			parse(Data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7);

			// Origin
			g_SpawnVecs[g_TotalSpawns][0] = str_to_num(pos[1]);
			g_SpawnVecs[g_TotalSpawns][1] = str_to_num(pos[2]);
			g_SpawnVecs[g_TotalSpawns][2] = str_to_num(pos[3]);

			//Angles
			g_SpawnAngles[g_TotalSpawns][0] = str_to_num(pos[4]);
			g_SpawnAngles[g_TotalSpawns][1] = str_to_num(pos[5]);
			g_SpawnAngles[g_TotalSpawns][2] = str_to_num(pos[6]);

			// Teams
			g_SpawnTeam[g_TotalSpawns] = str_to_num(pos[7]);

			//v-Angles
			g_SpawnVAngles[g_TotalSpawns][0] = str_to_num(pos[8]);
			g_SpawnVAngles[g_TotalSpawns][1] = str_to_num(pos[9]);
			g_SpawnVAngles[g_TotalSpawns][2] = str_to_num(pos[10]);
			
			
			new iEnt = rg_create_entity("info_target");
			if (!iEnt || is_nullent(iEnt))
			{
				return g_TotalSpawns > 0;
			}
			set_entvar(iEnt, var_classname, "info_player_csdm");
			set_entvar(iEnt, var_origin, g_SpawnVecs[g_TotalSpawns]);

			g_TotalSpawns++;
		}
	}

	return 1;
}

public spawn_Preset(id, num)
{
	if (g_TotalSpawns < 2)
		return PLUGIN_CONTINUE;

	new players[32], n, x, num, locnum, final = -1;
	new Float:loc[32][3];
	new Float:FSpawnVecs[3];
	new Float:FSpawnAngles[3];
	new Float:FSpawnVAngles[3];
	new team = _:cs_get_user_team(id);
	new ffa = csdm_get_ffa();

	get_players(players, num);

	for (new i = 0; i < num; i++)
	{
		if (is_user_alive(players[i]) && players[i] != id && (ffa || _:cs_get_user_team(players[i]) != team)) {
			pev(players[i], pev_origin, loc[locnum]);
			locnum++;
		}
	}

	num = 0;

	n = random_num(0, g_TotalSpawns - 1);

	while (num <= g_TotalSpawns)
	{
		//have we visited all the spawns yet?
		if (num == g_TotalSpawns) {
			break;
		}

		if (n < g_TotalSpawns - 1) {
			n++;
		} else {
			n = 0;
		}

		// inc the number of spawns we've visited
		num++;

		if ((team == _TEAM_T && g_SpawnTeam[n] == 2) || (team == _TEAM_CT && g_SpawnTeam[n] == 1)) {
			continue;
		}

		final = n;
		IVecFVec(g_SpawnVecs[n], FSpawnVecs);

		for (x = 0; x < locnum; x++)
		{
			new Float:distance = get_distance_f(FSpawnVecs, loc[x]);

			if (distance < 500.0) {
				//invalidate
				final = -1;
				break;
			}
		}

		if (final == -1) {
			continue;
		}

		new trace = csdm_trace_hull(FSpawnVecs, 1);

		if (trace) {
			continue;
		}

		if (locnum < 1 || final != -1) {
			break;
		}
	}

	if (final != -1)
	{
		new Float:mins[3], Float:maxs[3];

		IVecFVec(g_SpawnVecs[final], FSpawnVecs);
		IVecFVec(g_SpawnAngles[final], FSpawnAngles);
		IVecFVec(g_SpawnVAngles[final], FSpawnVAngles);

		pev(id, pev_mins, mins);
		pev(id, pev_maxs, maxs);

		engfunc(EngFunc_SetSize, id, mins, maxs);
		engfunc(EngFunc_SetOrigin, id, FSpawnVecs);

		set_pev(id, pev_fixangle, 1);
		set_pev(id, pev_angles, FSpawnAngles);
		set_pev(id, pev_v_angle, FSpawnVAngles);
		set_pev(id, pev_fixangle, 1);

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

buildMenu()
{
	g_MainMenuID = menu_create(g_MainMenu, "m_MainHandler");

	g_cMain = menu_makecallback("c_Main");

	menu_additem(g_MainMenuID, "Добавить текущую позицию для возрождения","1", 0, g_cMain);
	menu_additem(g_MainMenuID, "Редактировать ближайшую точку возраждения (желтая) на текущей позиции","2", 0, g_cMain);
	menu_additem(g_MainMenuID, "Удалить ближайшую точку возрождения","3", 0, g_cMain);
	menu_additem(g_MainMenuID, "Обновить ближайшую точку возрождения", "4", 0, g_cMain);
	menu_additem(g_MainMenuID, "Показать статистику", "5", 0, -1);
	menu_additem(g_MainMenuID, "Назад", "6", 0, -1);

	g_AddSpawnsMenuID = menu_create(g_AddSpawnsMenu, "m_AddSpawnsHandler");
	g_cAddSpawns = menu_makecallback("c_AddSpawns");

	menu_additem(g_AddSpawnsMenuID, "Добавить на текущую позицию для возрождения всем","1", 0, g_cAddSpawns);
	menu_additem(g_AddSpawnsMenuID, "Добавить текущую позицию для возрождения T","2", 0, g_cAddSpawns);
	menu_additem(g_AddSpawnsMenuID, "Добавить текущую позицию для возрождения CT","3", 0, g_cAddSpawns);
	menu_additem(g_AddSpawnsMenuID, "Назад","4", 0, -1);	
}

public m_MainHandler(id, menu, item)
{
	if (item == MENU_EXIT) {
		ent_remove(-1);
		menu_destroy(menu);	
		return PLUGIN_HANDLED;
	}

	new cmd[6], iName[64], access, callback;

	menu_item_getinfo(menu, item, access, cmd, charsmax(cmd), iName, charsmax(iName), callback);

	switch(str_to_num(cmd))
	{
		case 1: menu_display(id, g_AddSpawnsMenuID, 0);
		case 2:
		{
			new Float:vecs[3], vec[3];
			new Float:angles[3], angle[3];
			new Float:vangles[3], vangle[3];

			pev(id, pev_origin, vecs);
			pev(id, pev_angles, angles);
			pev(id, pev_v_angle, vangles);

			FVecIVec(vecs,vec);
			FVecIVec(angles, angle);
			FVecIVec(vangles, vangle);

			vec[2] += 15;
			edit_spawn(g_Ent[id], vec, angle,vangle);
			menu_display(id, g_MainMenuID, 0);
		}
		case 3:
		{
			ent_unglow(g_Ent[id]);
			delete_spawn(g_Ent[id]);
			g_Ent[id] = closest_spawn(id);
			menu_display(id, g_MainMenuID, 0);				
		}
		case 4:
		{
			ent_unglow(g_Ent[id]);
			g_Ent[id] = closest_spawn(id);
			ent_glow(g_Ent[id], yellow);
			menu_display(id, g_MainMenuID, 0);

			new szteam[8];

			switch(g_SpawnTeam[g_Ent[id]])
			{
				case 0: formatex(szteam, charsmax(szteam), "random");
				case 1: formatex(szteam, charsmax(szteam), "T");
				case 2: formatex(szteam,charsmax(szteam), "CT");
			}

			client_print(id,print_chat,"Ближайшая точка возрождения: number %d , def: team = %s, org[%d,%d,%d], ang[%d,%d,%d], vang[%d,%d,%d]", 
				g_Ent[id] + 1, szteam, g_SpawnVecs[g_Ent[id]][0], g_SpawnVecs[g_Ent[id]][1], g_SpawnVecs[g_Ent[id]][2], 
				g_SpawnAngles[g_Ent[id]][0], g_SpawnAngles[g_Ent[id]][1], g_SpawnAngles[g_Ent[id]][2], 
				g_SpawnVAngles[g_Ent[id]][0], g_SpawnVAngles[g_Ent[id]][1], g_SpawnVAngles[g_Ent[id]][2]);
		}
		case 5:
		{	
			new Float:Org[3], RD_num, TR_num, CT_num;

			pev(id, pev_origin, Org);

			for (new x = 0; x < g_TotalSpawns; x++)
			{
				if (g_SpawnTeam[x] == 0)
					RD_num++;
				if (g_SpawnTeam[x] == 1)
					TR_num++;
				if (g_SpawnTeam[x] == 2)
					CT_num++;
			}

			client_print(id,print_chat,"Всего точек: %d; Для всех: %d; T: %d; CT: %d.^nОригинальных: X: %f	Y: %f  Z: %f",
				g_TotalSpawns, RD_num, TR_num, CT_num, Org[0], Org[1], Org[2]);

			menu_display(id, g_MainMenuID, 0);
		}
		case 6:
		{
			ent_remove(-1);
			menu_display(id, csdm_main_menu(), 0);
		}
	}

	return PLUGIN_HANDLED;
}

public c_Main(id, menu, item)
{
	if (item == MENU_EXIT)
		return PLUGIN_CONTINUE;

	new cmd[6], fItem[326], iName[64], access, callback;

	menu_item_getinfo(menu, item, access, cmd, charsmax(cmd), iName, charsmax(iName), callback);

	switch(str_to_num(cmd))
	{
		case 1:
		{
			if (g_TotalSpawns == MAX_SPAWNS) {
				formatex(fItem, charsmax(fItem),"Добавлено максимальное количество точек возрождения");
				menu_item_setname(menu, item, fItem);
				return ITEM_DISABLED;
			} else {
				formatex(fItem, charsmax(fItem),"Добавить текущую позицию для возрождения");
				menu_item_setname(menu, item, fItem);
				return ITEM_ENABLED;
			}
		}
		case 2:
		{
			if (g_TotalSpawns < 1) {
				formatex(fItem, charsmax(fItem),"Редактировать точку - Нет доступных точек");
				menu_item_setname(menu, item, fItem);
				return ITEM_DISABLED;

			} else if (g_Ents[g_Ent[id]] == 0) {
				formatex(fItem, charsmax(fItem),"Редактировать точку - Нет выбранных точек");
				menu_item_setname(menu, item, fItem);
				return ITEM_DISABLED;

			} else {
				formatex(fItem, charsmax(fItem),"Редактировать ближайшую точку возрождения (желтая) в текущей позиции");
				menu_item_setname(menu, item, fItem);
				return ITEM_ENABLED;
			}
		}
		case 3:
		{
			if (g_TotalSpawns < 1) {
				formatex(fItem, charsmax(fItem),"Удалит точку - Нет доступных точек возрождения");
				menu_item_setname(menu, item, fItem);
				return ITEM_DISABLED;

			} else if (g_Ents[g_Ent[id]] == 0) {
				formatex(fItem, charsmax(fItem),"Удалить точку - нет выбранных точек возрождения");
				menu_item_setname(menu, item, fItem);
				return ITEM_DISABLED;

			} else {
				new iorg[3];
				get_user_origin(id, iorg);

				new distance = get_distance(iorg, g_SpawnVecs[g_Ent[id]]);

				if (distance > 200) {
					formatex(fItem, charsmax(fItem),"Удалить точку - выбранная точка далеко");
					menu_item_setname(menu, item, fItem);
					return ITEM_DISABLED;

				} else {
					formatex(fItem, charsmax(fItem),"Удалить ближайшую точку возрождения");
					menu_item_setname(menu, item, fItem);
					return ITEM_ENABLED;
				}
			}
		}
	}

	return PLUGIN_HANDLED;
}

public m_AddSpawnsHandler(id, menu, item)
{
	if (item < 0) {
		ent_remove(-1);		
		return PLUGIN_HANDLED;
	}

	new cmd[6], iName[64], access, callback;

	menu_item_getinfo(menu, item, access, cmd, charsmax(cmd), iName, charsmax(iName), callback);

	new iChoice = str_to_num(cmd);

	if (iChoice == 4) {
		menu_display (id, g_MainMenuID, 0);
		return PLUGIN_HANDLED;
	}

	new Float:vecs[3], vec[3];
	new Float:angles[3], angle[3];
	new Float:vangles[3], vangle[3];
	new team;

	switch(iChoice)
	{
		case 1: team = 0;
		case 2: team = 1;
		case 3: team = 2;
	}

	pev(id, pev_origin, vecs);
	pev(id, pev_angles, angles);
	pev(id, pev_v_angle, vangles);

	FVecIVec(vecs, vec);
	FVecIVec(angles, angle);
	FVecIVec(vangles, vangle);

	vec[2] += 15;
	add_spawn(vec, angle, vangle, team);

	menu_display (id, g_AddSpawnsMenuID, 0);

	return PLUGIN_HANDLED;
}

public c_AddSpawns(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE;

	new cmd[6], fItem[326], iName[64], access, callback;

	menu_item_getinfo(menu, item, access, cmd, charsmax(cmd), iName, charsmax(iName), callback);

	switch (str_to_num(cmd))
	{
		case 1:
		{
			if (g_TotalSpawns == MAX_SPAWNS) {
				formatex(fItem, charsmax(fItem),"Добавить точку аозрождения для всех - Достигнуть лимит точек");
				menu_item_setname(menu, item, fItem);
				return ITEM_DISABLED;

			} else {
				formatex(fItem, charsmax(fItem),"Добавить точку аозрождения для всех");
				menu_item_setname(menu, item, fItem);
				return ITEM_ENABLED;
			}
		}
		case 2:
		{
			if (g_TotalSpawns == MAX_SPAWNS) {
				formatex(fItem, charsmax(fItem),"Добавить точку возрождения для T - достигнут лимит точек");
				menu_item_setname(menu, item, fItem);
				return ITEM_DISABLED;

			} else {
				formatex(fItem, charsmax(fItem),"Добавить текущую позицию для возрождения T");
				menu_item_setname(menu, item, fItem);
				return ITEM_ENABLED;
			}
		}
		case 3:
		{
			if (g_TotalSpawns == MAX_SPAWNS) {
				formatex(fItem, charsmax(fItem),"Добавить точку возрождения для CT - достигнут лимит точек");
				menu_item_setname(menu, item, fItem);
				return ITEM_DISABLED;

			} else {
				formatex(fItem, charsmax(fItem),"Добавить текущую позицию для возрождения CT");
				menu_item_setname(menu, item, fItem);
				return ITEM_ENABLED;
			}
		}
	}

	return PLUGIN_HANDLED;
}

add_spawn(vecs[3], angles[3], vangles[3], team)
{
	new Map[32], config[32],  MapFile[256], line[128];

	get_mapname(Map, charsmax(Map));
	get_configsdir(config, charsmax(config));

	formatex(MapFile, charsmax(MapFile), "%s\csdm\%s.spawns.cfg", config, Map);

	formatex(line, charsmax(line), "%d %d %d %d %d %d %d %d %d %d", vecs[0], vecs[1], vecs[2], angles[0], angles[1], angles[2], team, vangles[0], vangles[1], vangles[2]);
	write_file(MapFile, line, -1);

	// origin
	g_SpawnVecs[g_TotalSpawns][0] = vecs[0];
	g_SpawnVecs[g_TotalSpawns][1] = vecs[1];
	g_SpawnVecs[g_TotalSpawns][2] = vecs[2];

	// Angles
	g_SpawnAngles[g_TotalSpawns][0] = angles[0];
	g_SpawnAngles[g_TotalSpawns][1] = angles[1];
	g_SpawnAngles[g_TotalSpawns][2] = angles[2];

	// Teams
	g_SpawnTeam[g_TotalSpawns] = team;

	// v-Angles
	g_SpawnVAngles[g_TotalSpawns][0] = vangles[0];
	g_SpawnVAngles[g_TotalSpawns][1] = vangles[1];
	g_SpawnVAngles[g_TotalSpawns][2] = vangles[2];

	ent_make(g_TotalSpawns);

	g_TotalSpawns++;
}

edit_spawn(ent, vecs[3], angles[3], vangles[3])
{
	new Map[32], config[32],  MapFile[256];

	get_mapname(Map, charsmax(Map));
	get_configsdir(config, charsmax(config));

	formatex(MapFile, charsmax(MapFile), "%s\csdm\%s.spawns.cfg", config, Map);

	if (file_exists(MapFile))
	{
		new Data[124], len, line, pos[11][8], currentVec[3], newSpawn[128], team;

		while ((line = read_file(MapFile, line, Data, charsmax(Data), len)) != 0)
		{
			if (strlen(Data) < 2) {
				continue;
			}

			parse(Data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7);

			currentVec[0] = str_to_num(pos[1]);
			currentVec[1] = str_to_num(pos[2]);
			currentVec[2] = str_to_num(pos[3]);

			team = str_to_num(pos[7]);

			if (g_SpawnVecs[ent][0] == currentVec[0] && g_SpawnVecs[ent][1] == currentVec[1] && (g_SpawnVecs[ent][2] - currentVec[2]) <= 15) {

				formatex(newSpawn, 127, "%d %d %d %d %d %d %d %d %d %d",vecs[0], vecs[1], vecs[2], angles[0], angles[1], angles[2], team, 
					vangles[0], vangles[1], vangles[2]);

				write_file(MapFile, newSpawn, line-1);

				ent_remove(ent);

				g_SpawnVecs[ent][0] = vecs[0];
				g_SpawnVecs[ent][1] = vecs[1];
				g_SpawnVecs[ent][2] = vecs[2];

				g_SpawnAngles[ent][0] = angles[0];
				g_SpawnAngles[ent][1] = angles[1];
				g_SpawnAngles[ent][2] = angles[2];

				g_SpawnVAngles[ent][0] = vangles[0];
				g_SpawnVAngles[ent][1] = vangles[1];
				g_SpawnVAngles[ent][2] = vangles[2];

				ent_make(ent);
				ent_glow(ent,red);

				break;
			}
		}
	}
}

delete_spawn(ent)
{
	new Map[32], config[32], MapFile[256];

	get_mapname(Map, charsmax(Map));
	get_configsdir(config, charsmax(config));

	formatex(MapFile, charsmax(MapFile), "%s\csdm\%s.spawns.cfg", config, Map);

	if (file_exists(MapFile))
	{
		new Data[124], len, line, pos[11][8], currentVec[3];
	
		while ((line = read_file(MapFile, line, Data, charsmax(Data), len)) != 0) 
		{
			if (strlen(Data) < 2) {
				continue;
			}

			parse(Data,pos[1], 7, pos[2], 7, pos[3], 7);

			currentVec[0] = str_to_num(pos[1]);
			currentVec[1] = str_to_num(pos[2]);
			currentVec[2] = str_to_num(pos[3]);

			if (g_SpawnVecs[ent][0] == currentVec[0] && g_SpawnVecs[ent][1] == currentVec[1] && (g_SpawnVecs[ent][2] - currentVec[2]) <= 15)
			{
				write_file(MapFile, "", line-1);

				ent_remove(-1);
				readSpawns();
				ent_make(-1);

				break;
			}
		}
	}
}

closest_spawn(id)
{
	new origin[3], lastDist = 999999, closest;

	get_user_origin(id, origin);

	for (new x = 0; x < g_TotalSpawns; x++)
	{
		new distance = get_distance(origin, g_SpawnVecs[x]);

		if (distance < lastDist) {
			lastDist = distance;
			closest = x;
		}
	}

	return closest;
}

ent_make(id)
{
	new iEnt;

	if(id < 0)
	{
		for (new x = 0; x < g_TotalSpawns; x++)
		{
			iEnt = engfunc(EngFunc_CreateNamedEntity, g_iszInfoTarget);
			set_pev(iEnt, pev_classname, "view_spawn");

			switch(g_SpawnTeam[x])
			{
				case 0: engfunc(EngFunc_SetModel, iEnt, "models/player/vip/vip.mdl");
				case 1: engfunc(EngFunc_SetModel, iEnt, "models/player/terror/terror.mdl");
				case 2: engfunc(EngFunc_SetModel, iEnt, "models/player/urban/urban.mdl");
			}

			set_pev(iEnt, pev_solid, SOLID_SLIDEBOX);
			set_pev(iEnt, pev_movetype, MOVETYPE_NOCLIP);
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) & FL_ONGROUND);
			set_pev(iEnt, pev_sequence, 1);

			if (g_Ents[x]) {
				engfunc(EngFunc_RemoveEntity, g_Ents[x]);
			}

			g_Ents[x] = iEnt;
			ent_unglow(x);
		}

	} else {

		if (g_SpawnTeam[id] >= 0 && g_SpawnTeam[id] < 3)
		{
			iEnt = engfunc(EngFunc_CreateNamedEntity, g_iszInfoTarget);
			set_pev(iEnt, pev_classname, "view_spawn");

			switch (g_SpawnTeam[id]) 
			{
				case 0: /* CSDM random spawn point */	
				{
					engfunc(EngFunc_SetModel, iEnt, "models/player/vip/vip.mdl");
				}
				case 1: /* CSDM terrorist spawn point */
				{
					engfunc(EngFunc_SetModel, iEnt, "models/player/terror/terror.mdl");
				}
				case 2: /* CSDM CT spawn point */
				{
					engfunc(EngFunc_SetModel, iEnt, "models/player/urban/urban.mdl");
				}
			}

			set_pev(iEnt, pev_solid, SOLID_SLIDEBOX);
			set_pev(iEnt, pev_movetype, MOVETYPE_NOCLIP);
			set_pev(iEnt, pev_sequence, 1);
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) & FL_ONGROUND);

			if (g_Ents[id]) {
				engfunc(EngFunc_RemoveEntity, g_Ents[id]);
			}

			g_Ents[id] = iEnt;			
			ent_unglow(id);
		}
	}
}

ent_remove(ent)
{
	if(ent < 0)
	{
		for(new i = 0; i < g_TotalSpawns; i++)
		{
			if(pev_valid(g_Ents[i])) {
				engfunc(EngFunc_RemoveEntity, g_Ents[i]);
				g_Ents[i] = 0;
			}
		}

	} else {

		if(pev_valid(g_Ents[ent])) {
			engfunc(EngFunc_RemoveEntity, g_Ents[ent]);
			g_Ents[ent] = 0;
		}
	}
}

ent_glow(ent,Float:color[3])
{
	new iEnt = g_Ents[ent];

	if (iEnt)
	{
		set_ent_pos(ent);

		set_pev(iEnt, pev_renderfx, kRenderFxGlowShell);
		set_pev(iEnt, pev_renderamt, 127.0);
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha);
		set_pev(iEnt, pev_rendercolor, color);
	}
}

ent_unglow(ent)
{
	new iEnt = g_Ents[ent];

	if (iEnt)
	{
		set_ent_pos(ent);

		set_pev(iEnt, pev_renderfx, kRenderFxNone); 
		set_pev(iEnt, pev_renderamt, 127.0);
		set_pev(iEnt, pev_rendermode, kRenderTransAlpha);		
	}
}

set_ent_pos(ent)
{
	new iEnt, Float:org[3], Float:ang[3], Float:vang[3];

	iEnt = g_Ents[ent];

	IVecFVec(g_SpawnVecs[ent], org);
	set_pev( iEnt, pev_origin, org);

	IVecFVec(g_SpawnAngles[ent], ang);
	set_pev(iEnt, pev_angles, ang);

	IVecFVec(g_SpawnVAngles[ent], vang);
	set_pev(iEnt, pev_v_angle, vang);

	set_pev(iEnt, pev_fixangle, 1);
}

public showmen(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	buildMenu();
	ent_make(-1);
	menu_display (id, g_MainMenuID, 0);

	return PLUGIN_HANDLED;
}