#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:h_aak_Enabled, Handle:h_aak_TeamKill, Handle:h_aak_Add_0Slot, Handle:h_aak_Add_1Slot , Handle:h_aak_AmmoRate, Handle:h_aak_AddGranade, Handle:h_aak_Access, Handle:h_aak_MsgEnabled, Handle:h_aak_Add_HSOnly;
new bool:b_aak_enabled, bool:b_aak_teamlill, bool:b_aak_0slot,  bool:b_aak_1slot, bool:b_aak_3slot, bool:b_aak_msg, bool:b_aak_hsonly;
new Float:i_aak_rate;
new String:WeaponNames[24][64] ={/*пушки 0..17 */"galil","ak47","scout","sg552","awp","g3sg1","famas","m4a1","aug","sg550","m3","xm1014","mac10","tmp","mp5navy","ump45","p90","m249",/*пистоли 18..22*/ "glock","usp","p228","deagle","elite","fiveseven"};
new WeaponClips[24] ={/*пушки 0..17 */35,30,10,30,10,20,25,30,30,30,8,7,30,30,30,25,50,100,/*пистоли 18..22*/20,12,13,7,30,20};

public Plugin:myinfo =
{
	name = "MF Ammo at kill",
	description = "Выдает патроны за убийство",
	author = "merk26",
	version = "1.1",
	url = "http://www.атомхост.рф/"
};

public OnPluginStart()
{

	h_aak_Enabled 			= CreateConVar("mf_aak_enabled", 		"1", 	"Включить/Выключить плагин", _, true, 0.0, true, 1.0);
	h_aak_MsgEnabled		= CreateConVar("mf_aak_msg", 			"1", 	"Показывать сообщения о пополнении (внизу экрана)", _, true, 0.0, true, 1.0);
	h_aak_TeamKill 			= CreateConVar("mf_aak_teamkill", 		"0", 	"Давать патроны за тимкилл", _, true, 0.0, true, 1.0);
	h_aak_Add_HSOnly 		= CreateConVar("mf_aak_hsonly", 		"1", 	"Пополнять боезапасы только при убийстве в голову (mf_aak_0slot и mf_aak_1slot влияют)", _, true, 0.0, true, 1.0);
	h_aak_Add_0Slot 		= CreateConVar("mf_aak_0slot", 			"1", 	"Пополнять боезапасы штурмового оружия", _, true, 0.0, true, 1.0);
	h_aak_Add_1Slot 		= CreateConVar("mf_aak_1slot", 			"1", 	"Пополнять боезапасы пистолета", _, true, 0.0, true, 1.0);
	h_aak_AmmoRate 			= CreateConVar("mf_aak_rate", 			"0.7", 	"Коэффиицент восстановления боеприпасов", _, true, 0.1, true, 1.0);
	h_aak_AddGranade 		= CreateConVar("mf_aak_3slot", 			"1", 	"Выдавать вторую гранату (при убийстве с боевый гранаты)", _, true, 0.0, true, 1.0);
	//h_aak_Access 			= CreateConVar("mf_aak_access", 		"none", "Флаг доступа (none для всех игроков)");
	
	AutoExecConfig(true, "mf_ammo_at_kill");
	
	HookConVarChange(h_aak_Enabled, CvarChanges);
	HookConVarChange(h_aak_TeamKill, CvarChanges);
	HookConVarChange(h_aak_MsgEnabled, CvarChanges);
	HookConVarChange(h_aak_Add_0Slot, CvarChanges);
	HookConVarChange(h_aak_Add_1Slot, CvarChanges);
	HookConVarChange(h_aak_AddGranade, CvarChanges);
	HookConVarChange(h_aak_AmmoRate, CvarChanges);
	HookConVarChange(h_aak_Add_HSOnly, CvarChanges);

	HookEvent("player_death", OnPlayerDeath, EventHookMode:1);
	return 0;
}

public OnConfigsExecuted()
{
	b_aak_enabled 	= GetConVarBool(h_aak_Enabled);
	b_aak_teamlill 	= GetConVarBool(h_aak_TeamKill);
	b_aak_msg 		= GetConVarBool(h_aak_MsgEnabled);
	b_aak_0slot 	= GetConVarBool(h_aak_Add_0Slot);
	b_aak_1slot		= GetConVarBool(h_aak_Add_1Slot);
	b_aak_3slot 	= GetConVarBool(h_aak_AddGranade);
	b_aak_hsonly 	= GetConVarBool(h_aak_Add_HSOnly);
	i_aak_rate		= GetConVarFloat(h_aak_AmmoRate);
	return 0;
}


public CvarChanges(Handle:convar, String:oldValue[], String:newValue[])
{
	if (convar 	== h_aak_Enabled) 			b_aak_enabled 	= GetConVarBool(convar);
	else if (convar == h_aak_TeamKill)		b_aak_teamlill 	= GetConVarBool(convar);
	else if (convar == h_aak_MsgEnabled) 	b_aak_msg 	= GetConVarBool(convar);
	else if (convar == h_aak_Add_0Slot) 	b_aak_0slot 	= GetConVarBool(convar);
	else if (convar == h_aak_Add_1Slot) 	b_aak_1slot		= GetConVarBool(convar);
	else if (convar == h_aak_AddGranade) 	b_aak_3slot 	= GetConVarBool(convar);
	else if (convar == h_aak_Add_HSOnly) 	b_aak_hsonly 	= GetConVarBool(convar);
	else if (convar == h_aak_AmmoRate) 		i_aak_rate 		= GetConVarFloat(convar);
	else if (convar == h_aak_Access)
	{
		// определение флага
	}

	return 0;
}

public OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	if (!b_aak_enabled)	return 0; // используем return чтобы не делать кучу условий в условии
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new bool:headshot = GetEventBool(event, "headshot");
	
	if (attacker == victim) return 0; // прерываем суицид
	if (GetClientTeam(victim) == GetClientTeam(attacker) && !b_aak_teamlill)  return 0; //проверяем на тимкилл
	
	new weapon_0slot;
	new weapon_1slot;
	decl String:AttackerWeapon[64];
	GetClientWeapon(attacker, AttackerWeapon, 64);
	ReplaceString(AttackerWeapon, 64, "weapon_", "", false);
	
		
	decl String:weapon_dead[64];								// берем оружие с которого убили, для выдачи гранаты
	GetEventString(event, "weapon", weapon_dead, sizeof(weapon_dead));
	
	if(StrEqual(weapon_dead, "hegrenade", false) && b_aak_3slot) // даем гранату, если просят
	{
		GivePlayerItem(attacker, "weapon_hegrenade"); 
		if(b_aak_msg) PrintHintText(attacker, "Вы получили боевую гранату!");
	}
	
	if(!headshot && b_aak_hsonly) return 0; //проверяем на хедшот
	

	weapon_0slot = GetPlayerWeaponSlot(attacker, 0);
	weapon_1slot = GetPlayerWeaponSlot(attacker, 1);
	

	if(b_aak_0slot && IsValidEdict(weapon_0slot)) // обрабатываем основное оружие
		{
			for(new i = 0; i<18;i++)
			{
				if (!StrEqual(WeaponNames[i], AttackerWeapon, false)) 
					continue;
				new rem_ammo = GetWeaponClip(weapon_0slot);
				new add_ammo =  RoundFloat((float(WeaponClips[i]) - float(rem_ammo)) * i_aak_rate);
				SetWeaponClip(weapon_0slot, rem_ammo + add_ammo);
				if(b_aak_msg) PrintHintText(attacker, "Боезапас пополнен (%i)", add_ammo);
			}
		}
	if(b_aak_1slot && IsValidEdict(weapon_1slot)) // обрабатываем пистолет
		{
			for(new i = 18; i<24;i++)
			{
				if (!StrEqual(WeaponNames[i], AttackerWeapon, false)) 
					continue;
				new rem_ammo = GetWeaponClip(weapon_1slot);
				new  add_ammo =  RoundFloat((float(WeaponClips[i]) - float(rem_ammo)) * i_aak_rate);
				SetWeaponClip(weapon_1slot, rem_ammo + add_ammo);
				if(b_aak_msg) PrintHintText(attacker, "Боезапас пополнен (%i патрон(а)/(ов))", add_ammo);
			}
		}
	return 0;
}

SetWeaponClip(weapon, value) //меняем кол-во патронов
{
	SetEntProp(weapon, PropType:1, "m_iClip1", value, 4);
	return 0;
}
GetWeaponClip(weapon) // узнаем кол-во патронов в рожке
{
	new data = GetEntProp(weapon, PropType:1, "m_iClip1");
	return data;
}