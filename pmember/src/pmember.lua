local devuser = 'LV19';
local addonname = 'PMEMBER';

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS'][devuser] = _G['ADDONS'][devuser] or {};
_G['ADDONS'][devuser][addonname] = _G['ADDONS'][devuser][addonname] or {};

local g = _G['ADDONS'][devuser][addonname];
g.idlist = {};
g.avelevel = 0;
g.partynum = 0;
g.aveanobool = 0;
g.aveanonum = 0;

local jsonpath = "../addons/pmember/settings.json";
local isLoaded = false;
local op;

function PMEMBER_PARTY_JOB_TOOLTIP(frame, cid, uiChild, nowJobName)
	PARTY_JOB_TOOLTIP_OLD(frame, cid, uiChild, nowJobName);
	--CHAT_SYSTEM("SET_PARTY_JOB_TOOLTIP " .. cid);
	local otherpcinfo = session.otherPC.GetByStrCID(cid);
	if otherpcinfo == nil then
		--CHAT_SYSTEM("info is nil");
		return nil;
	end
	--CHAT_SYSTEM("info is not null");

	local aid = otherpcinfo:GetAID();
	if aid == session.loginInfo.GetAID() then
		--CHAT_SYSTEM("my aid");
		return nil;
	end

	--CHAT_SYSTEM("list check..");

	local isannounced = 0;
	local cidlistnum = 0;
	for i = 1, #g.idlist do
		if g.idlist[i].aid == aid then
			--CHAT_SYSTEM("aid is announced");
			if g.idlist[i].cid == cid then
				--CHAT_SYSTEM("cid is announced");
				cidlistnum = i;
				isannounced = 2;
			else
				cidlistnum = i;
				isannounced = 1;
				g.idlist[i].cid = cid;
				g.idlist[i].logout = 0;
			--CHAT_SYSTEM("cid changed");
			end
		end
	end
	
	local list = session.party.GetPartyMemberList(PARTY_NORMAL);
	local count = list:Count();
	if g.partynum == 0 then
		g.partynum = count;
	end
	local partyMemberName ="";
	local level = 0;
	local mapName = "";

	for i = 0 , count - 1 do
		local partyMemberInfo = list:Element(i);	
		if partyMemberInfo:GetAID() == aid then
			partyMemberName = partyMemberInfo:GetName();
			level = partyMemberInfo:GetLevel();
			mapName = geMapTable.GetMapName(partyMemberInfo:GetMapID());
		end
	end

	local mymapName = geMapTable.GetMapName(session.GetMapID());

	if isannounced == 2 then
		if mapName == nil or mapName == "None" then
		else
			if g.idlist[cidlistnum].logout == 1 then
				g.idlist[cidlistnum].logout = 0;
				CHAT_SYSTEM(op.login .. "[LOGIN] {/}" .. op.charname .. partyMemberName .. "{/}");
			end
		end
		return nil;
	end

	if isannounced == 0 then
		local saveids = {cid = cid, aid = aid, name = partyMemberName, map = mapName, logout = 0}
		table.insert(g.idlist, saveids);
	--CHAT_SYSTEM("ids saved");
	end

	local jobhistory = otherpcinfo.jobHistory;
	local nowjobinfo = jobhistory:GetJobHistory(jobhistory:GetJobHistoryCount()-1);
	local clslist, cnt  = GetClassList("Job");
	local nowjobcls;
	if nil == nowjobinfo then
		nowjobcls = nowJobName; 
	else
		nowjobcls = GetClassByTypeFromList(clslist, nowjobinfo.jobID);
	end; 

	local OTHERPCJOBS = {}
	for i = 0, jobhistory:GetJobHistoryCount()-1 do
		local tempjobinfo = jobhistory:GetJobHistory(i);
		
		if OTHERPCJOBS[tempjobinfo.jobID] == nil then
			OTHERPCJOBS[tempjobinfo.jobID] = tempjobinfo.grade;
		else
			if tempjobinfo.grade > OTHERPCJOBS[tempjobinfo.jobID] then
				OTHERPCJOBS[tempjobinfo.jobID] = tempjobinfo.grade;
			end
		end
	end
	local startext = ("");
	for jobid, grade in pairs(OTHERPCJOBS) do
		local cls = GetClassByTypeFromList(clslist, jobid);
		if grade == 1 then
			grade = "{#088A08}" .. grade .. "{/}";
		elseif grade == 2 then
			grade = "{#01DF01}" .. grade .. "{/}";
		elseif grade == 3 then
			grade = "{#2EFE2E}" .. grade .. "{/}";
		end
		startext = startext .. op.jobname .. dictionary.ReplaceDicIDInCompStr(GET_JOB_NAME(cls, gender)) .. "{/}" .. grade .. " ";
	end
	local pcobj = _G.GetMyPCObject();
	if mapName == mymapName then
		if level > pcobj.Lv then
			startext = op.join .. "[JOIN] {/}" .. op.charname .. partyMemberName .. " {/}" ..op.highlevel .. "Lv" .. level .. "{/}{nl} " .. startext ;
		else
			startext = op.join .. "[JOIN] {/}" .. op.charname .. partyMemberName .. " {/}" ..op.lowlevel .. "Lv" .. level .. "{/}{nl} " .. startext ;
		end
	else
		if level > pcobj.Lv then
			startext = op.join .. "[JOIN] {/}" .. op.charname .. partyMemberName .. " {/}" ..op.highlevel .. "Lv" .. level .. "{/}" .. op.mapname .."(" .. mapName .."){/}{nl} " .. startext ;
		else
			startext = op.join .. "[JOIN] {/}" .. op.charname .. partyMemberName .. " {/}" ..op.lowlevel .. "Lv" .. level .. "{/}" .. op.mapname .."(" .. mapName .."){/}{nl} " .. startext ;
		end
	end
	CHAT_SYSTEM(startext);
end

function PMEMBER_ON_PARTYINFO_UPDATE(frame, msg, argStr, argNum)
	ON_PARTYINFO_UPDATE_OLD(frame, msg, argStr, argNum);
	local pcparty = session.party.GetPartyInfo();
	if pcparty == nil then
		--CHAT_SYSTEM("party is nul");
		g.idlist = {};
		g.avelevel = 0;
		g.partynum = 0;
	else
		local average = session.party.GetPartyMemberLevelAverage();
		local list = session.party.GetPartyMemberList(PARTY_NORMAL);
		local count = list:Count();
		if count == 0 then
			return nil;
		end
		if count < g.partynum then
			--CHAT_SYSTEM("party decrease " .. g.partynum .. " to " .. count);
			g.partynum = g.partynum - 1;
			local delaid = 0;
			local delnum = 0;
			local checkaid = 0;
			local myAid = session.loginInfo.GetAID();
			for j = 1, #g.idlist do
				--CHAT_SYSTEM("now aid " .. g.idlist[j].aid .. " cid " .. g.idlist[j].cid);
				local check = 0;
				for i = 0 , count - 1 do
					local partyMemberInfo = list:Element(i);
					checkaid = partyMemberInfo:GetAID();
					if checkaid == g.idlist[j].aid then
						check = 1;
					end
				end
				--CHAT_SYSTEM("check " .. check);
				if check == 0 then
					--CHAT_SYSTEM("delnum " .. j);
					delnum = j;
				end
			end
			if delnum ~= 0 then
				--CHAT_SYSTEM("{#000000}[LEAVE] " .. g.idlist[delnum].name .. "{/}");
				table.remove(g.idlist, delnum);
			--CHAT_SYSTEM("length " .. #g.idlist);
			end
		else
			g.partynum = count;
		end
		if average ~= g.avelevel then
			g.avelevel = average;
			g.aveanobool = 1;
			g.aveanonum = 2;
		end
	end
end

function PMEMBER_SET_LOGOUT_PARTYINFO_ITEM(frame, msg, partyMemberInfo, count, makeLogoutPC, leaderFID, isCorsairType)
	SET_LOGOUT_PARTYINFO_ITEM_OLD(frame, msg, partyMemberInfo, count, makeLogoutPC, leaderFID, isCorsairType);
	local aid= partyMemberInfo:GetAID();
	for j = 1, #g.idlist do
		if g.idlist[j].aid == aid then
			if g.idlist[j].logout == 0 then
				local partyMemberName = partyMemberInfo:GetName();
				g.idlist[j].logout = 1;
				if partyMemberName ~= "None" then
					CHAT_SYSTEM(op.logout .. "[LOGOUT] {/}" .. partyMemberName .. op.test .. "");
				end
			end
		end
	end
end

function PMEMBER_UPDATE()
	if g.aveanobool == 1 then
		g.aveanonum = g.aveanonum - 1;
		if g.aveanonum <= 0 then
			g.aveanobool = 0;
			if g.avelevel ~= 0 then
				local pcobj = _G.GetMyPCObject();
				if g.avelevel > pcobj.Lv then
					CHAT_SYSTEM( op.text .. "Party Average LV is now {/}" .. op.highlevel .. g.avelevel .. "{/}");
				else
					CHAT_SYSTEM( op.text .. "Party Average LV is now {/}" .. op.lowlevel .. g.avelevel .. "{/}");
				end
			end
		end
	end
end

local function Load()
	local acutil = require("acutil");
	return acutil.loadJSON(jsonpath);
end

local defaults = {
	text = "",
	highlevel = "{#FF0000}",
	lowlevel = "{#00FFFF}",
	jobname = "{#088A08}",
	rank1 = "{#088A08}",
	rank2 = "{#01DF01}",
	rank3 = "{#2EFE2E}",
	mapname= "{#2E2EFE}",
	charname = "",
	join = "{#00FFFF}",
	login = "{#00FFFF}",
	logout = "{#FF0000}"
};

local function LOAD_SETTINGS()
	local acutil = require("acutil");
	local _op, err = Load();

	if err then
		op = defaults;
		acutil.saveJSON(jsonpath, op);
	else
		op = _op;
	end
end

function PMEMBER_SETUP_HOOKS()
	local acutil = require("acutil");
	acutil.setupHook(PMEMBER_PARTY_JOB_TOOLTIP, "PARTY_JOB_TOOLTIP");
	acutil.setupHook(PMEMBER_ON_PARTYINFO_UPDATE, "ON_PARTYINFO_UPDATE");
	acutil.setupHook(PMEMBER_SET_LOGOUT_PARTYINFO_ITEM, "SET_LOGOUT_PARTYINFO_ITEM");
end

function PMEMBER_ON_INIT(addon, frame)
	local g = _G['ADDONS'][devuser][addonname];
	local acutil = require("acutil");
	addon:RegisterMsg("FPS_UPDATE", "PMEMBER_UPDATE");
	PMEMBER_SETUP_HOOKS();
	--json
	if not isLoaded then
		isLoaded = true;
		LOAD_SETTINGS();
	end
end

CHAT_SYSTEM("Party Member v1.0.6 loaded!");
