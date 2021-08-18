// Chat with bubbles

#include <sourcemod>
#include <basecomm>
#include <tf2>
#include <tf2_stocks>
#include <smlib>
#include <clientprefs>

#include "tf2hudmsg.inc"

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "21w33b"

#define TF2_MAXPLAYERS 32

#define COOKIE_HIDE "clientChatbubbleHide"
#define COOKIE_OFF "clientChatbubbleIgnore"

public Plugin myinfo = {
	name = "[TF2] Chat Bubbles",
	author = "code: reBane, idea: fuffeh",
	description = "Talk in bubbles",
	version = PLUGIN_VERSION,
	url = "N/A"
}


CursorAnnotation clientBubble[TF2_MAXPLAYERS+1];
int maskRED=0,maskBLU=0,maskAlive=0;
int maskCanSee[TF2_MAXPLAYERS+1];

int maskCookieEnabled;
int maskCookieHidden;

ConVar cvar_BubbleDistance;
ConVar cvar_BubbleEnabled;
ConVar cvar_BubbleDefaultState;
float cval_BubbleDistance;
int cval_BubbleEnabled;
int cval_BubbleDefaultState;

static Handle playerTraceTimer;

public void OnPluginStart() {
	AddCommandListener(commandSay, "say");
	AddCommandListener(commandSayTeam, "say_team");
	
	cvar_BubbleDistance = CreateConVar("sm_chatbubble_distance", "500", "Maximum distance in hammer units to display chat bubble for", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 50.0);
	cvar_BubbleEnabled = CreateConVar("sm_chatbubble_enabled", "1", "0 = disabled, 1 = say & teamsay, 2 = teamsay only", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvar_BubbleDefaultState = CreateConVar("sm_chatbubble_default", "1", "Default state of chat bubbles for players: 0 = disabled, 1 = enabled, 2 = hidden (send, don't show)", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvar_BubbleDistance.AddChangeHook(OnConVarChanged);
	cvar_BubbleEnabled.AddChangeHook(OnConVarChanged);
	cvar_BubbleDefaultState.AddChangeHook(OnConVarChanged);
	OnConVarChanged(null,"","");
	
	RegClientCookie(COOKIE_HIDE, "Set whether you can see chat bubbles or not", CookieAccess_Public);
	RegClientCookie(COOKIE_OFF, "Completely disables chat bubbles for you", CookieAccess_Public);
	SetCookieMenuItem(cookieMenuHandler, 0, "Chat Bubbles");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	int team;
	for (int i=1; i<=TF2_MAXPLAYERS; i++) {
		clientBubble[i] = CursorAnnotation();
		clientBubble[i].SetLifetime(5.0);
		if (Client_IsIngame(i) && !IsFakeClient(i)) {
			if (IsPlayerAlive(i)) maskAlive |= clientBit(i);
			team = GetClientTeam(i);
			if (team == TFTeam_Red) maskRED |= clientBit(i);
			else if (team == TFTeam_Blue) maskBLU |= clientBit(i);
			if(AreClientCookiesCached(i)) {
				OnClientCookiesCached(i);
			}
		}
	}
	
	OnMapStart();
	
	PrintToChatAll("[Chat Bubbles] Version %s loaded!", PLUGIN_VERSION);
}

public void OnPluginEnd() {
	for (int i=1; i<=TF2_MAXPLAYERS; i++) {
		clientBubble[i].Close();
	}
	OnMapEnd();
}

public void OnMapStart() {
	if (playerTraceTimer == INVALID_HANDLE)
		playerTraceTimer = CreateTimer(0.1, Timer_PlayerTracing, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public void OnMapEnd() {
	KillTimer(playerTraceTimer);
	playerTraceTimer = INVALID_HANDLE;
}

public Action Timer_PlayerTracing(Handle timer) {
	updateClientMasks();
}

public void OnClientCookiesCached(int client) {
	Handle cookie;
	char buffer[2];
	if ((cookie=FindClientCookie(COOKIE_HIDE)) != INVALID_HANDLE) {
		GetClientCookie(client, cookie, buffer, sizeof(buffer));
		bool value;
		if (buffer[0]==0) { // no value set yet, check and set default
			value = cval_BubbleDefaultState == 2;
			SetClientCookie(client, cookie, value?"1":"0");
		} else value = !!StringToInt(buffer);
			
		if (value)
			maskCookieHidden |= clientBit(client);
		else
			maskCookieHidden &=~ clientBit(client);
	} else { //cookie is missing
		maskCookieHidden &=~ clientBit(client);
	}
	if ((cookie=FindClientCookie(COOKIE_OFF)) != INVALID_HANDLE) {
		GetClientCookie(client, cookie, buffer, sizeof(buffer));
		bool value;
		if (buffer[0]==0) { // no value set yet, check and set default
			value = cval_BubbleDefaultState != 0;
			SetClientCookie(client, cookie, value?"1":"0");
		} else value = !!StringToInt(buffer);
		
		if (value)
			maskCookieEnabled |= clientBit(client);
		else
			maskCookieEnabled &=~ clientBit(client);
	} else { //cookie is missing
		maskCookieEnabled |= clientBit(client);
	}
}

public void cookieMenuHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen) {
	if(action == CookieMenuAction_SelectOption) {
		showSettingsMenu(client);
	}
}

void showSettingsMenu(int client) {
	Menu menu = new Menu(settingsMenuActionHandler);
	if (!!(maskCookieEnabled & clientBit(client))) {
		if (!!(maskCookieHidden & clientBit(client))) {
			menu.SetTitle("Chat Bubbles\n \nYou send chat bubbles but can't see others\n ");
			menu.AddItem("off", "Hidden");
		} else {
			menu.SetTitle("Chat Bubbles\n \nYou see and send chat bubbles\n ");
			menu.AddItem("hide", "Enabled");
		}
	} else {
		menu.SetTitle("Chat Bubbles\n \nChat bubbles are complete disabled for you\n ");
		menu.AddItem("on", "Disabled");
	}
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;
	menu.Display(client, 30);
}

public int settingsMenuActionHandler(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_Select) {
		char info[32];
		Handle cookie;
		menu.GetItem(param2, info, sizeof(info));
		if(StrEqual(info, "hide")) {
			maskCookieHidden |= clientBit(param1);
			if((cookie = FindClientCookie(COOKIE_HIDE)) != null) {
				SetClientCookie(param1, cookie, "1");
			}
		} else if(StrEqual(info, "on")) {
			maskCookieEnabled |= clientBit(param1);
			if((cookie = FindClientCookie(COOKIE_OFF)) != null) {
				SetClientCookie(param1, cookie, "0");
			}
			maskCookieHidden &=~ clientBit(param1);
			if((cookie = FindClientCookie(COOKIE_HIDE)) != null) {
				SetClientCookie(param1, cookie, "0");
			}
		} else if(StrEqual(info, "off")) {
			maskCookieEnabled &=~ clientBit(param1);
			if((cookie = FindClientCookie(COOKIE_OFF)) != null) {
				SetClientCookie(param1, cookie, "1");
			}
		}
		showSettingsMenu(param1);
	} else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) {
		ShowCookieMenu(param1);
	} else if(action == MenuAction_End) {
		delete menu;
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (convar == null) {
		cval_BubbleEnabled = cvar_BubbleEnabled.IntValue;
		cval_BubbleDistance = cvar_BubbleDistance.FloatValue;
		cval_BubbleDefaultState = cvar_BubbleDefaultState.IntValue;
	} else if (convar == cvar_BubbleEnabled) {
		cval_BubbleEnabled = cvar_BubbleEnabled.IntValue;
	} else if (convar == cvar_BubbleDistance) {
		cval_BubbleDistance = cvar_BubbleDistance.FloatValue;
	} else if (convar == cvar_BubbleDefaultState) {
		cval_BubbleDefaultState = cvar_BubbleDefaultState.IntValue;
	}
}


/** 
 * Maintain team client masks
 */
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId( event.GetInt("userid") );
	TFTeam team = view_as<TFTeam>( event.GetInt("team") );
	if (IsFakeClient(client)) return;
	
	int bit = clientBit(client);
	switch (team) {
		case TFTeam_Red: {
			maskRED |= bit;
			maskBLU &=~ bit;
			maskAlive |= bit;
		}
		case TFTeam_Blue: {
			maskBLU |= bit;
			maskRED &=~ bit;
			maskAlive |= bit;
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId( event.GetInt("userid") );
	
	maskAlive &=~ clientBit(client);
}

static int clientBit(int client) {
	if (0 < client <= TF2_MAXPLAYERS)
		return 1<<client;
	return 0;
}

static CursorAnnotation forClient(int client) {
	if (!Client_IsIngame(client))
		ThrowError("Invalid client index or client not in game (%i)", client);
	return clientBubble[client];
}

public bool canSeeTraceFilter(int entity, int contentsMask, any data) {
	return entity == data;
}
static bool traceCanSee(int client, int target, float maxdistsquared) {
	if (!Client_IsValid(client) || !Client_IsValid(target)) return false;
	if (!Client_IsIngame(client) || !Client_IsIngame(target) ||
		!IsPlayerAlive(client) || !IsPlayerAlive(target) ||
		IsFakeClient(client) || IsFakeClient(target)) {
		return false;
	}
	
	float posClient[3], posTarget[3], mins[3]={-14.0,0.0,-14.0}, maxs[3]={14.0,72.0,14.0};
	Entity_GetAbsOrigin(client, posClient);
	Entity_GetAbsOrigin(target, posTarget);
	float distance = GetVectorDistance(posClient, posTarget, true);
	if (distance > maxdistsquared) {
		return false;
	}
	
	// mins and maxs are only rough estimates, but that's ok
	Handle ray = TR_TraceHullFilterEx(posClient, posTarget, mins, maxs, MASK_VISIBLE, canSeeTraceFilter, target);
	bool result = TR_DidHit(ray);
	delete ray;
	return result;
}
static void updateClientMasks() {
	float mdist = cval_BubbleDistance*cval_BubbleDistance;
	for (int i=1; i<TF2_MAXPLAYERS; i++) {
		for (int j=i+1; j<=TF2_MAXPLAYERS; j++) {
			
			bool canSee = traceCanSee(i,j, mdist);
			
			//perspecive i: i has not muted j and they can see each other
			if (canSee && !IsClientMuted(i,j)) {
				maskCanSee[i] |= clientBit(j);
			} else { //i muted j or los is broken
				maskCanSee[i] &=~ clientBit(j);
			}
			
			//perspecive j: j has not muted i and they can see each other
			if (canSee && !IsClientMuted(j,i)) {
				maskCanSee[j] |= clientBit(i);
			} else { //j muted i or los is broken
				maskCanSee[j] &=~ clientBit(i);
			}
			
		}
	}
}

static void bubble(int client, const char[] message, int visibility) {
	CursorAnnotation ca = forClient(client);
	ca.VisibilityBitmask = visibility;
	ca.ParentEntity = client;
	float pos[3], off[3]={0.0,72.0,0.0};
	Entity_GetAbsOrigin(client, pos);
	AddVectors(pos,off,pos);
	ca.SetPosition(pos);
	ca.SetText(message);
	ca.SetLifetime(5.0);
	ca.Update();
}

/** returns a tfteam if the client can chat with bubbles, or TFTeam_Unassigned if not */
static TFTeam clientBubbleTeam(int client, const char[] message) {
	// these strcontains calls are a "not starts with"
	if (!client || BaseComm_IsClientGagged(client) || !StrContains(message, "/") || !StrContains(message, "!") || !StrContains(message, "@"))
		return TFTeam_Unassigned;
	TFTeam team = view_as<TFTeam>( GetClientTeam(client) );
	if (team > TFTeam_Spectator) return team;
	return TFTeam_Unassigned;
}

static void handleSay(int client, const char[] message, bool teamSay) {
	TFTeam team = clientBubbleTeam(client, message);
	if (team <= TFTeam_Spectator) return;
	
	//basic targets: alive, has them fully enabled, can see the source, not the source
	int targets = maskAlive & (~maskCookieHidden) & maskCookieEnabled & maskCanSee[client] & ~clientBit(client);
	
	//check if player is invisible
	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked)) return;
	
	//if the player is disguised, play as say to not give away the actual team
	if (teamSay && !(TF2_IsPlayerInCondition(client, TFCond_Disguising)|TF2_IsPlayerInCondition(client, TFCond_Disguised)|TF2_IsPlayerInCondition(client, TFCond_DisguisedAsDispenser))) {
		//otherwise we mask the team for team say
		targets &= (team == TFTeam_Red) ? maskRED : maskBLU;
	}
	
	bubble(client, message, targets);
}

public Action commandSay(int client, const char[] command, int argc) {
	if (cval_BubbleEnabled != 1 || (maskCookieEnabled & clientBit(client))==0 ) return Plugin_Continue;
	char message[MAX_ANNOTATION_LENGTH];
	GetCmdArgString(message, sizeof(message));
	StripQuotes(message);
	if (!TrimString(message)) return Plugin_Continue;
	EscapeVGUILocalization(message, sizeof(message));
	handleSay(client, message, false);
	return Plugin_Continue;
}

public Action commandSayTeam(int client, const char[] command, int argc) {
	if (cval_BubbleEnabled == 0 || (maskCookieEnabled & clientBit(client))==0 ) return Plugin_Continue;
	char message[MAX_ANNOTATION_LENGTH];
	GetCmdArgString(message, sizeof(message));
	StripQuotes(message);
	if (!TrimString(message)) return Plugin_Continue;
	EscapeVGUILocalization(message, sizeof(message));
	handleSay(client, message, true);
	return Plugin_Continue;
}