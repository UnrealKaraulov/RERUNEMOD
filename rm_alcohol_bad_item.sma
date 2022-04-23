#include <amxmodx>
#include <amxmisc>
#include <rm_api>
#include <fakemeta>
#include <fun>

new g_bHasAlcohol[MAX_PLAYERS + 1] = {false,...};

new rune_model_id = -1;

public plugin_init()
{
	register_plugin("RM_VODKA","2.3","Karaulov");
	rm_register_rune("Бутылка водки","Игрок будет под мухой 30 секунд.",Float:{255.0,0.0,255.0}, "models/rm_reloaded/w_butilka_vodki.mdl", _,rune_model_id);
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
	rm_base_highlight_screen(id, 70);
}

public reset_vodka(id)
{
	if (g_bHasAlcohol[id])
	{
		g_bHasAlcohol[id] = false;
		if (is_user_connected(id))
		{
			if (is_user_alive(id))
				rm_base_drop_item_notice(id);
			rm_base_disable_highlight(id);
		}
	}
}