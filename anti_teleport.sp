#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo = {
	name        = "[TF2] Anti-Teleport",
	author      = "Sgt. Gremulock",
	description = "Allows server operators to prevent players from teleporting with some configurable options.",
	version     = PLUGIN_VERSION,
	url         = "https://sourcemod.net/"
};

// Integer representation of TFClassType values
enum {
	TF_CLASS_UNKNOWN = 0,
	TF_CLASS_SCOUT,
	TF_CLASS_SNIPER,
	TF_CLASS_SOLDIER,
	TF_CLASS_DEMOMAN,
	TF_CLASS_MEDIC,
	TF_CLASS_HEAVY,
	TF_CLASS_PYRO,
	TF_CLASS_SPY,
	TF_CLASS_ENGINEER
};

// Handles
ConVar g_cvEnable   = null;
ConVar g_cvBots     = null;
ConVar g_cvTeam     = null;
ConVar g_cvClasses  = null;
ConVar g_cvImmunity = null;

// Booleans
//bool g_bLateLoad = false;
bool g_bClass[10] = {false, ...};

// Integers

// Floats

// Strings

// Others

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax)
{
	// Game is not TF2
	if (GetEngineVersion() != Engine_TF2)
	{
		strcopy(sError, iErrMax, "This plugin is only compatible with TF2!");
		return APLRes_Failure;
	}

	//g_bLateLoad = bLate;
	return APLRes_Success;
}

public void OnPluginStart()
{
	// Create the ConVars
	CreateConVar("sm_anti_teleport_version", PLUGIN_VERSION, "Plugin's version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvEnable   = CreateConVar("sm_anti_teleport_enable",   "1",                                                          "Enable/Disable the plugin\n1 = Enable, 0 = Disable",                                                       _, true, 0.0, true, 1.0);
	g_cvBots     = CreateConVar("sm_anti_teleport_bots",     "0",                                                          "Prevent just bots from teleporting\n1 = Enable, 0 = Disable",                                              _, true, 0.0, true, 1.0);
	g_cvTeam     = CreateConVar("sm_anti_teleport_team",     "1",                                                          "Team(s) to prevent players from teleporting on\n1 = Both, 2 = RED, 3 = BLU",                               _, true, 1.0, true, 3.0);
	g_cvClasses  = CreateConVar("sm_anti_teleport_classes",  "scout,soldier,pyro,demoman,heavy,engineer,medic,sniper,spy", "Prevent players from teleporting as specific classes");
	g_cvImmunity = CreateConVar("sm_anti_teleport_immunity", "1",                                                          "Enable/Disable immunity for admins with access to \"sm_anti_teleport_immunity\"\n1 = Enable, 0 = Disable", _, true, 0.0, true, 1.0);
	AutoExecConfig();

	// Hook ConVar changes
	g_cvClasses.AddChangeHook(ConVar_Update);

	// Create the immunity override
	AddCommandOverride("sm_anti_teleport_immunity", Override_Command, ADMFLAG_CHEATS);
}

public void OnConfigsExecuted()
{
	char sClasses[256];
	g_cvClasses.GetString(sClasses, sizeof(sClasses));

	g_bClass[TF_CLASS_SCOUT]    = StrContains(sClasses, "scout",    false) != -1;
	g_bClass[TF_CLASS_SOLDIER]  = StrContains(sClasses, "soldier",  false) != -1;
	g_bClass[TF_CLASS_PYRO]     = StrContains(sClasses, "pyro",     false) != -1;
	g_bClass[TF_CLASS_DEMOMAN]  = StrContains(sClasses, "demoman",  false) != -1;
	g_bClass[TF_CLASS_HEAVY]    = StrContains(sClasses, "heavy",    false) != -1;
	g_bClass[TF_CLASS_ENGINEER] = StrContains(sClasses, "engineer", false) != -1;
	g_bClass[TF_CLASS_MEDIC]    = StrContains(sClasses, "medic",    false) != -1;
	g_bClass[TF_CLASS_SNIPER]   = StrContains(sClasses, "sniper",   false) != -1;
	g_bClass[TF_CLASS_SPY]      = StrContains(sClasses, "spy",      false) != -1;
}

public void ConVar_Update(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	OnConfigsExecuted();
}

public Action TF2_OnPlayerTeleport(int iClient, int iTeleporter, bool &bResult)
{
	// Plugin is disabled
	if (!g_cvEnable.BoolValue)
	{
		return Plugin_Continue;
	}

	// Immunity is enabled and client has access to the override
	if (g_cvImmunity.BoolValue && CheckCommandAccess(iClient, "sm_anti_teleport_immunity", ADMFLAG_CHEATS))
	{
		return Plugin_Continue;
	}

	// Bots only is enabled and client is not a bot
	if (g_cvBots.BoolValue && !IsFakeClient(iClient))
	{
		return Plugin_Continue;
	}

	// Team value is not set to both and client's team does not equal the value
	if (g_cvTeam.IntValue != 1 && GetClientTeam(iClient) != g_cvTeam.IntValue)
	{
		return Plugin_Continue;
	}

	// Class of client is not set for anti-teleport
	if (!g_bClass[view_as<int>(TF2_GetPlayerClass(iClient))])
	{
		return Plugin_Continue;
	}

	bResult = false;
	return Plugin_Changed;
}