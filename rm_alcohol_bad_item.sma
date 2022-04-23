#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fakemeta>
#include <fun>
#include <screenfade_util>

new g_bHasAlcohol[MAX_PLAYERS + 1] = {false,...};

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_VODKA","2.1","Karaulov");
	rm_register_rune("Бутылка водки","Игрок будет под мухой 30 секунд.",Float:{255.0,255.0,255.0}, "models/rm_reloaded/w_butilka_vodki.mdl", _,rune_model_id);
	rm_base_use_rune_as_item( );
	RegisterHookChain(RG_PM_Move, "PM_Move", .post=false);
	RegisterHookChain(RG_PM_AirMove, "PM_Move", .post=false);
}

public PM_Move(const id)
{
	if ( is_real_player(id) && g_bHasAlcohol[id] )
	{
		new z_direction = 0;
		new Float:fPunchAngles[3];
		get_pmove(pm_punchangle,fPunchAngles);
		
		new btns = get_entvar(id, var_button);
		
		if (btns & IN_MOVELEFT)
		{
			z_direction -= 1;
		}
		if (btns & IN_MOVERIGHT)
		{
			z_direction += 1;
		}
		
		if (z_direction > 0)
		{
			if (fPunchAngles[2] < 65.0)
			{
				fPunchAngles[2]+=1.0;
			}
			
			if (fPunchAngles[2] < 5.0)
			{
				fPunchAngles[2] = 5.0;
			}
		}
		if (z_direction < 0)
		{
			if (fPunchAngles[2] > -65.0)
			{
				fPunchAngles[2]-=1.0;
			}
			
			if (fPunchAngles[2] > -5.0)
			{
				fPunchAngles[2] = -5.0;
			}
		}
		set_pmove(pm_punchangle,fPunchAngles);
	}
}

public plugin_precache()
{
	rune_model_id = precache_model("models/rm_reloaded/w_butilka_vodki.mdl");
}

public client_putinserver(id)
{
	g_bHasAlcohol[id] = false;
	reset_vodka(id);
	if (task_exists(id))
		remove_task(id);
}

public client_disconnected(id)
{
	g_bHasAlcohol[id] = false;
	reset_vodka(id);
	if (task_exists(id))
		remove_task(id);
}

public rm_give_rune(id)
{
	if (task_exists(id))
		remove_task(id);
	g_bHasAlcohol[id] = true;
	set_task(30.0,"reset_vodka",id);
	UTIL_ScreenFade(id, { 255, 0, 255 }, 1.0, 0.0, 70, FFADE_STAYOUT, true);
}

public reset_vodka(id)
{
	if (g_bHasAlcohol[id])
	{
		g_bHasAlcohol[id] = false;
		if (is_user_connected(id))
		{
			UTIL_ScreenFade(id, { 0, 0, 0 }, 1.0, 1.0);
			if (is_user_alive(id))
				rm_base_drop_item_notice(id);
		}
	}
}