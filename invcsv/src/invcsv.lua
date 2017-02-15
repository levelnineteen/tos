local devuser = 'LV19';
local addonname = 'INVCSV';

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS'][devuser] = _G['ADDONS'][devuser] or {};
_G['ADDONS'][devuser][addonname] = _G['ADDONS'][devuser][addonname] or {};

function INVCSV_INVENTORY_OUTPUT()
	local FilePath = path.GetDataPath() .. "../addons/invcsv/inv.csv";
	local f = io.open(FilePath, "a");
	if f == nil then
		CHAT_SYSTEM("CSV file does not exist!!");
	else
		local charname = _G.GetMyName();
		local timestr = _G.GetLocalTimeString();
		local group = GET_CHILD(ui.GetFrame('inventory'), 'inventoryGbox', 'ui::CGroupBox');
		local tree_box = GET_CHILD(group, 'treeGbox','ui::CGroupBox');
		local tree = GET_CHILD(tree_box, 'inventree','ui::CTreeControl');

		for i = 1 , #SLOTSET_NAMELIST do
			local slotSet = GET_CHILD(tree,SLOTSET_NAMELIST[i],'ui::CSlotSet')  ;
			for j = 0 , slotSet:GetChildCount() - 1 do
				local slot = slotSet:GetChildByIndex(j);
				local invItem = GET_SLOT_ITEM(slot); 
				if invItem ~= nil then
					local invIndex = invItem.invIndex;
					local itemCls = GetIES(invItem:GetObject());
					if itemCls ~= nil then
						local invname = dictionary.ReplaceDicIDInCompStr(itemCls.Name);
						local invcount = GET_REMAIN_INVITEM_COUNT(invItem);
						f:write(timestr .. "," , charname .. "," .. invname .. "," .. invcount ..  "\n");
					end
				end
			end
		end
	end
	f:close();
end

function INVCSV_COMMAND(words)
	local cmd = table.remove(words,1);
	if not cmd then
		CHAT_SYSTEM("inventory output...");
		INVCSV_INVENTORY_OUTPUT();
		CHAT_SYSTEM("done!!");
	end
end


function INVCSV_ON_INIT(addon, frame)
	local acutil = require("acutil");
	acutil.slashCommand("/invcsv", INVCSV_COMMAND);
end

CHAT_SYSTEM("Inventory CSV v1.0.1 loaded");