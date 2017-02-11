local devuser = 'LV19';
local addonname = 'PLINK';

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS'][devuser] = _G['ADDONS'][devuser] or {};
_G['ADDONS'][devuser][addonname] = _G['ADDONS'][devuser][addonname] or {};

function PLINK_COMMAND(words)
	local g = _G['ADDONS'][devuser][addonname];
	local cmd = table.remove(words,1);
	local link = table.remove(words,1);
	local pcparty = _G.session.party.GetPartyInfo();
	if not cmd then
	elseif cmd == "show" then
		if pcparty == nil then
			CHAT_SYSTEM("You are not in Party");
		else
			local partyID = pcparty.info:GetPartyID();
			CHAT_SYSTEM("Your PartyID is " .. partyID);
		end
	elseif cmd == "join" then
		if link == nil then
			CHAT_SYSTEM("Need PatyID (/plink join partyID)");
		else
			if pcparty == nil then
				_G.party.JoinPartyByLink(0, link);
			else 
				CHAT_SYSTEM(ClMsg("HadMyParty"));
			end
		end
	end
end

function PLINK_ON_INIT(addon, frame)
	local g = _G['ADDONS'][devuser][addonname];
	local acutil = require("acutil");
	acutil.slashCommand("/plink", PLINK_COMMAND);
end

CHAT_SYSTEM("Party Link v1.0.0 loaded");