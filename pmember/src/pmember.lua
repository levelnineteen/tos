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

local function RepShortName(jobid, gender)
	--Kannu
	if jobid == 4018 and gender == 1 then
		return op.j4018m;
	end
	for key, val in pairs(op) do
		if tonumber(string.sub(key, 2)) == jobid then
			return val;
		end
	end
	--nothing=newjob
	--CHAT_SYSTEM("new job!!");
	local addname = GET_JOB_NAME(cls, gender);

	local newtext = "{";
	for key, val in pairs(op) do
		newtext = newtext .. "\t\"" .. key .. "\":\""	..		val		.. "\",\n";
	end
	newtext = newtext .. "\t\"j" .. jobid .. "\":\""	..		_G.dictionary.ReplaceDicIDInCompStr(addname)		.. "\"\n}\n";
	local filep = io.open(jsonpath, "w");
	if filep then
		filep:write(newtext);
		filep:close();
	end
	local acutil = require("acutil");
	op = acutil.loadJSON(jsonpath);

	CHAT_SYSTEM("[pmember] : You found a new class of " .. addname .. " ! Add it to settings.json as j" .. jobid .. ".");

	return addname;
end

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
	local gender =  otherpcinfo:GetIconInfo().gender;
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
		startext = startext .. op.jobname .. RepShortName(jobid, gender) .. "{/}" .. grade .. " ";
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
					CHAT_SYSTEM(op.logout .. "[LOGOUT] {/}" .. op.charname .. partyMemberName .. "{/}");
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
	logout = "{#FF0000}",
	j1001 = "ソードマン",
	j1002 = "ハイランダー",
	j1003 = "ペルタスト",
	j1004 = "ホプライト",
	j1006 = "バーバリアン",
	j1007 = "カタフラクト",
	j1010 = "ロデレロ",
	j1008 = "コルセア",
	j1011 = "スクワイア",
	j1009 = "ドッペルゾナー",
	j1014 = "フェンサー",
	j1013 = "シノビ",
	j1015 = "ドラグーン",
	j1016 = "テンプラー",
	j1012 = "ムルミロ",
	j1017 = "ランサー",
	j1005 = "センチュリオン",
	j1018 = "マタドール",
	j2001 = "ウィザード",
	j2002 = "パイロマンサー",
	j2003 = "クリオマンサー",
	j2004 = "サイコキノ",
	j2007 = "リンカー",
	j2010 = "ソーマタージュ",
	j2011 = "エレメンタリスト",
	j2006 = "ソーサラー",
	j2008 = "クロノマンサー",
	j2005 = "アルケミスト",
	j2009 = "ネクロマンサー",
	j2017 = "ルーンキャスター",
	j2015 = "ウォーロック",
	j2016 = "フェザーフット",
	j2014 = "セージ",
	j2018 = "エンチャンター",
	j2012 = "ミミック",
	j2013 = "タオイスト・ダミー",
	j2019 = "シャドウマンサー",
	j3001 = "アーチャー",
	j3003 = "クォレシューター",
	j3004 = "レンジャー",
	j3002 = "ハンター",
	j3005 = "サッパー",
	j3006 = "ポイズンシューター",
	j3008 = "スカウト",
	j3009 = "ローグ",
	j3011 = "フレッチャー",
	j3010 = "シュバルツライター",
	j3014 = "ファルコナー",
	j3015 = "キャノニア",
	j3016 = "マスケティア",
	j3017 = "メルゲン",
	j3007 = "ハッカペル",
	j3012 = "パイドパイパー",
	j3013 = "アプレイサー",
	j3018 = "バレットマーカー",
	j4001 = "クレリック",
	j4002 = "プリースト",
	j4003 = "クリヴィス",
	j4004 = "ボコル",
	j4007 = "ティルトルビー",
	j4006 = "サドゥー",
	j4011 = "パラディン",
	j4009 = "モンク",
	j4010 = "パードナー",
	j4012 = "チャプレイン",
	j4005 = "ドルイド",
	j4008 = "オラクル",
	j4018 = "巫女",
	j4018m = "神主",
	j4014 = "プレイグドクター",
	j4015 = "カバリスト",
	j4016 = "インクイジター",
	j4017 = "タオイスト",
	j4013 = "シェパード",
	j4019 = "ジーロット",
	j9001 = "GM"
};

local function LOAD_SETTINGS()
	local acutil = require("acutil");
	local _op, err = Load();

	if err then
		op = defaults;
		acutil.saveJSON(jsonpath, op);
		local filep = io.open(jsonpath, "w+");
		if filep then
			filep:write("{");
			filep:write("\t\"text\":\""	..		op.text		.."\",\n");
			filep:write("\t\"highlevel\":\""	..	op.highlevel	.."\",\n");
			filep:write("\t\"lowlevel\":\""	..		op.lowlevel	.."\",\n");
			filep:write("\t\"jobname\":\""	..		op.jobname	.."\",\n");
			filep:write("\t\"rank1\":\""	..		op.rank1	.."\",\n");
			filep:write("\t\"rank2\":\""	..		op.rank2	.."\",\n");
			filep:write("\t\"rank3\":\""	..		op.rank3	.."\",\n");
			filep:write("\t\"mapname\":\""	..		op.mapname	.."\",\n");
			filep:write("\t\"charname\":\""	..		op.charname	.."\",\n");
			filep:write("\t\"join\":\""	..		op.join		.."\",\n");
			filep:write("\t\"login\":\""	..		op.login	.."\",\n");
			filep:write("\t\"logout\":\""	..		op.logout	.."\",\n");
			filep:write("\t\"j1001\":\""	..		op.j1001	.."\",\n");
			filep:write("\t\"j1002\":\""	..		op.j1002	.."\",\n");
			filep:write("\t\"j1003\":\""	..		op.j1003	.."\",\n");
			filep:write("\t\"j1004\":\""	..		op.j1004	.."\",\n");
			filep:write("\t\"j1006\":\""	..		op.j1006	.."\",\n");
			filep:write("\t\"j1007\":\""	..		op.j1007	.."\",\n");
			filep:write("\t\"j1010\":\""	..		op.j1010	.."\",\n");
			filep:write("\t\"j1008\":\""	..		op.j1008	.."\",\n");
			filep:write("\t\"j1011\":\""	..		op.j1011	.."\",\n");
			filep:write("\t\"j1009\":\""	..		op.j1009	.."\",\n");
			filep:write("\t\"j1014\":\""	..		op.j1014	.."\",\n");
			filep:write("\t\"j1013\":\""	..		op.j1013	.."\",\n");
			filep:write("\t\"j1015\":\""	..		op.j1015	.."\",\n");
			filep:write("\t\"j1016\":\""	..		op.j1016	.."\",\n");
			filep:write("\t\"j1012\":\""	..		op.j1012	.."\",\n");
			filep:write("\t\"j1017\":\""	..		op.j1017	.."\",\n");
			filep:write("\t\"j1005\":\""	..		op.j1005	.."\",\n");
			filep:write("\t\"j1018\":\""	..		op.j1018	.."\",\n");
			filep:write("\t\"j2001\":\""	..		op.j2001	.."\",\n");
			filep:write("\t\"j2002\":\""	..		op.j2002	.."\",\n");
			filep:write("\t\"j2003\":\""	..		op.j2003	.."\",\n");
			filep:write("\t\"j2004\":\""	..		op.j2004	.."\",\n");
			filep:write("\t\"j2007\":\""	..		op.j2007	.."\",\n");
			filep:write("\t\"j2010\":\""	..		op.j2010	.."\",\n");
			filep:write("\t\"j2011\":\""	..		op.j2011	.."\",\n");
			filep:write("\t\"j2006\":\""	..		op.j2006	.."\",\n");
			filep:write("\t\"j2008\":\""	..		op.j2008	.."\",\n");
			filep:write("\t\"j2005\":\""	..		op.j2005	.."\",\n");
			filep:write("\t\"j2009\":\""	..		op.j2009	.."\",\n");
			filep:write("\t\"j2017\":\""	..		op.j2017	.."\",\n");
			filep:write("\t\"j2015\":\""	..		op.j2015	.."\",\n");
			filep:write("\t\"j2016\":\""	..		op.j2016	.."\",\n");
			filep:write("\t\"j2014\":\""	..		op.j2014	.."\",\n");
			filep:write("\t\"j2018\":\""	..		op.j2018	.."\",\n");
			filep:write("\t\"j2012\":\""	..		op.j2012	.."\",\n");
			filep:write("\t\"j2013\":\""	..		op.j2013	.."\",\n");
			filep:write("\t\"j2019\":\""	..		op.j2019	.."\",\n");
			filep:write("\t\"j3001\":\""	..		op.j3001	.."\",\n");
			filep:write("\t\"j3003\":\""	..		op.j3003	.."\",\n");
			filep:write("\t\"j3004\":\""	..		op.j3004	.."\",\n");
			filep:write("\t\"j3002\":\""	..		op.j3002	.."\",\n");
			filep:write("\t\"j3005\":\""	..		op.j3005	.."\",\n");
			filep:write("\t\"j3006\":\""	..		op.j3006	.."\",\n");
			filep:write("\t\"j3008\":\""	..		op.j3008	.."\",\n");
			filep:write("\t\"j3009\":\""	..		op.j3009	.."\",\n");
			filep:write("\t\"j3011\":\""	..		op.j3011	.."\",\n");
			filep:write("\t\"j3010\":\""	..		op.j3010	.."\",\n");
			filep:write("\t\"j3014\":\""	..		op.j3014	.."\",\n");
			filep:write("\t\"j3015\":\""	..		op.j3015	.."\",\n");
			filep:write("\t\"j3016\":\""	..		op.j3016	.."\",\n");
			filep:write("\t\"j3017\":\""	..		op.j3017	.."\",\n");
			filep:write("\t\"j3007\":\""	..		op.j3007	.."\",\n");
			filep:write("\t\"j3012\":\""	..		op.j3012	.."\",\n");
			filep:write("\t\"j3013\":\""	..		op.j3013	.."\",\n");
			filep:write("\t\"j3018\":\""	..		op.j3018	.."\",\n");
			filep:write("\t\"j4001\":\""	..		op.j4001	.."\",\n");
			filep:write("\t\"j4002\":\""	..		op.j4002	.."\",\n");
			filep:write("\t\"j4003\":\""	..		op.j4003	.."\",\n");
			filep:write("\t\"j4004\":\""	..		op.j4004	.."\",\n");
			filep:write("\t\"j4007\":\""	..		op.j4007	.."\",\n");
			filep:write("\t\"j4006\":\""	..		op.j4006	.."\",\n");
			filep:write("\t\"j4011\":\""	..		op.j4011	.."\",\n");
			filep:write("\t\"j4009\":\""	..		op.j4009	.."\",\n");
			filep:write("\t\"j4010\":\""	..		op.j4010	.."\",\n");
			filep:write("\t\"j4012\":\""	..		op.j4012	.."\",\n");
			filep:write("\t\"j4005\":\""	..		op.j4005	.."\",\n");
			filep:write("\t\"j4008\":\""	..		op.j4008	.."\",\n");
			filep:write("\t\"j4018\":\""	..		op.j4018	.."\",\n");
			filep:write("\t\"j4018m\":\""	..		op.j4018m	.."\",\n");
			filep:write("\t\"j4014\":\""	..		op.j4014	.."\",\n");
			filep:write("\t\"j4015\":\""	..		op.j4015	.."\",\n");
			filep:write("\t\"j4016\":\""	..		op.j4016	.."\",\n");
			filep:write("\t\"j4017\":\""	..		op.j4017	.."\",\n");
			filep:write("\t\"j4013\":\""	..		op.j4013	.."\",\n");
			filep:write("\t\"j4019\":\""	..		op.j4019	.."\",\n");
			filep:write("\t\"j9001\":\""	..		op.j9001	.."\"\n");
			filep:write("}\n");
			filep:close();
		end
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

CHAT_SYSTEM("Party Member v1.2.0 loaded!");