
local AuctionatorVersion = "1.0.0";
local AuctionatorAuthor  = "Zirco";


local AuctionatorLoaded = false;

local recommendElements		= {};
local auctionsTabElements	= {};

AUCTIONATOR_ENABLE_ALT	= 1;
AUCTIONATOR_OPEN_FIRST	= 0;

local AUCTIONATOR_TAB_INDEX = 4;

-----------------------------------------

local auctionator_orig_AuctionFrameTab_OnClick;
local auctionator_orig_ContainerFrameItemButton_OnClick;
local auctionator_orig_AuctionFrameAuctions_Update;
local auctionator_orig_AuctionsCreateAuctionButton_OnClick;

local KM_NULL_STATE	= 0;
local KM_PREQUERY	= 1;
local KM_INQUERY	= 2;
local KM_POSTQUERY	= 3;
local KM_ANALYZING	= 4;

local processing_state	= KM_NULL_STATE;
local current_page;
local forceMsgAreaUpdate = false;

local scandata;
local sorteddata = {};
local basedata;

local currentAuctionItemName = "";
local currentAuctionStackSize = 0;
local currentAuctionTexture = nil;

local currentAuctionClass;
local currentAuctionSubclass;

local auctionator_last_buyoutprice;
local auctionator_last_item_posted = nil;
local auctionator_pending_message = nil;

-----------------------------------------

local	BoolToString, BoolToNum, NumToBool, pluralizeIf, round, chatmsg, calcNewPrice, roundPriceDown;
local	val2gsc, priceToString, ItemType2AuctionClass, SubType2AuctionSubclass;

-----------------------------------------


function Auctionator_EventHandler()

--	chatmsg (event);

	if (event == "VARIABLES_LOADED")			then	Auctionator_OnLoad(); 					end; 
	if (event == "ADDON_LOADED")				then	Auctionator_OnAddonLoaded(); 			end; 
	if (event == "AUCTION_ITEM_LIST_UPDATE")	then	Auctionator_OnAuctionUpdate(); 			end; 
	if (event == "AUCTION_OWNED_LIST_UPDATE")	then	Auctionator_OnAuctionOwnedUpdate(); 	end; 
	if (event == "AUCTION_HOUSE_SHOW")			then	Auctionator_OnAuctionHouseShow(); 		end; 
	if (event == "AUCTION_HOUSE_CLOSED")		then	Auctionator_OnAuctionHouseClosed(); 	end; 
	if (event == "NEW_AUCTION_UPDATE")			then	Auctionator_OnNewAuctionUpdate(); 		end; 

end

-----------------------------------------


function Auctionator_OnLoad()

	chatmsg("Auctionator Loaded");

	AuctionatorLoaded = true;

end

-----------------------------------------

function Auctionator_OnAddonLoaded()
				
		Auctionator_AddSellTab ();
		Auctionator_AddSellPanel ();
		
		Auctionator_SetupHookFunctions ();
		
		auctionsTabElements[1]  = AuctionsScrollFrame;
		auctionsTabElements[2]  = AuctionsButton1;
		auctionsTabElements[3]  = AuctionsButton2;
		auctionsTabElements[4]  = AuctionsButton3;
		auctionsTabElements[5]  = AuctionsButton4;
		auctionsTabElements[6]  = AuctionsButton5;
		auctionsTabElements[7]  = AuctionsButton6;
		auctionsTabElements[8]  = AuctionsButton7;
		auctionsTabElements[9]  = AuctionsButton8;
		auctionsTabElements[10] = AuctionsButton9;
		auctionsTabElements[11] = AuctionsQualitySort;
		auctionsTabElements[12] = AuctionsDurationSort;
		auctionsTabElements[13] = AuctionsHighBidderSort;
		auctionsTabElements[14] = AuctionsBidSort;
		auctionsTabElements[15] = AuctionsCancelAuctionButton;

		recommendElements[1] = getglobal ("Auctionator_Recommend_Text");
		recommendElements[2] = getglobal ("Auctionator_RecommendPerItem_Text");
		recommendElements[3] = getglobal ("Auctionator_RecommendPerItem_Price");
		recommendElements[4] = getglobal ("Auctionator_RecommendPerStack_Text");
		recommendElements[5] = getglobal ("Auctionator_RecommendPerStack_Price");
		recommendElements[6] = getglobal ("Auctionator_Recommend_Basis_Text");
		recommendElements[7] = getglobal ("Auctionator_RecommendItem_Tex");

end


-----------------------------------------


function Auctionator_AuctionFrameTab_OnClick (index)

	if ( not index ) then
		index = this:GetID();
	end

	AuctionFramePost:Hide();
	
	-- Show an Auctioneer tab if its the one clicked
	local tab = getglobal("AuctionFrameTab"..index);
	if (tab) then
		if (tab:GetName() == "AuctionFrameTabPost") then
			AuctionFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopLeft");
			AuctionFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Top");
			AuctionFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopRight");
			AuctionFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotLeft");
			AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Bot");
			AuctionFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotRight");
			AuctionFramePost:Show();
		end
	end
	
	-- getglobal("Auctionator_Sell_Template"):Hide();
	
	-- chatmsg ("Now tab is "..index..". AUCTIONATOR_TAB_INDEX = "..AUCTIONATOR_TAB_INDEX);
	-- chatmsg (this)
	-- if (index == 2) then index = 4 end

	-- if (index == 3) then		
		-- Auctionator_ShowElems (auctionsTabElements);
	-- end
	
	-- if (index ~= AUCTIONATOR_TAB_INDEX) then
		-- auctionator_orig_AuctionFrameTab_OnClick (index);
		-- auctionator_last_item_posted = nil;
		-- forceMsgAreaUpdate = true;
		
	-- elseif (index == AUCTIONATOR_TAB_INDEX) then
		-- chatmsg ("Trying to tab to auctionator...");
		-- AuctionFrameTab_OnClick(3);
		
		-- PanelTemplates_SetTab(AuctionFrame, AUCTIONATOR_TAB_INDEX);
		-- chatmsg (this:GetID ())
		
		-- AuctionFrameTopLeft:SetTexture	("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-TopLeft");
		-- AuctionFrameTop:SetTexture		("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Top");
		-- AuctionFrameTopRight:SetTexture	("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-TopRight");
		-- AuctionFrameBotLeft:SetTexture	("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-BotLeft");
		-- AuctionFrameBot:SetTexture		("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot");
		-- AuctionFrameBotRight:SetTexture	("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-BotRight");

		-- Auctionator_HideElems (auctionsTabElements);
		
		-- getglobal("Auctionator_Sell_Template"):Show();

		-- Auctionator_HideElems (recommendElements);

		OpenAllBags(true);
		
		if (currentAuctionItemName ~= "") then
			Auctionator_CalcBaseData();
		end
	
end

-----------------------------------------


function Auctionator_ContainerFrameItemButton_OnModifiedClick (button)
	
	if (	AUCTIONATOR_ENABLE_ALT == 0
		or  not	AuctionFrame:IsShown()
		or	not	IsAltKeyDown())
	then
		return auctionator_orig_ContainerFrameItemButton_OnModifiedClick (button);
	end;

	if (PanelTemplates_GetSelectedTab (AuctionFrame) ~= AUCTIONATOR_TAB_INDEX) then
	
		AuctionFrameTab_OnClick (AUCTIONATOR_TAB_INDEX);
	
	end
	
	
	PickupContainerItem(this:GetParent():GetID(), this:GetID());

	local infoType = GetCursorInfo()

	if (infoType == "item") then
		ClickAuctionSellItemButton();
		ClearCursor();
	end

end


-----------------------------------------

function Auctionator_AuctionFrameAuctions_Update()
	
	auctionator_orig_AuctionFrameAuctions_Update();

	if (PanelTemplates_GetSelectedTab (AuctionFrame) == AUCTIONATOR_TAB_INDEX  and	AuctionFrame:IsShown()) then
		Auctionator_HideElems (auctionsTabElements);
	end

	
end

-----------------------------------------
-- Intercept the Create Auction click so
-- that we can note the auction values
-----------------------------------------

function Auctionator_AuctionsCreateAuctionButton_OnClick()
	
	if (PanelTemplates_GetSelectedTab (AuctionFrame) == AUCTIONATOR_TAB_INDEX  and AuctionFrame:IsShown()) then
		
		auctionator_last_buyoutprice = MoneyInputFrame_GetCopper(BuyoutPrice);
		auctionator_last_item_posted = currentAuctionItemName;

	end
	
	auctionator_orig_AuctionsCreateAuctionButton_OnClick();

end

-----------------------------------------

function Auctionator_OnAuctionOwnedUpdate ()

	if (auctionator_last_item_posted) then
	
		Auctionator_Recommend_Text:SetText ("Auction Created for "..auctionator_last_item_posted);

		MoneyFrame_Update ("Auctionator_RecommendPerStack_Price", auctionator_last_buyoutprice);

		Auctionator_RecommendPerStack_Price:Show();
		Auctionator_RecommendPerItem_Price:Hide();
		Auctionator_RecommendPerItem_Text:Hide();
		Auctionator_Recommend_Basis_Text:Hide();
	end
	
end

-----------------------------------------

function Auctionator_OnNewAuctionUpdate()


end

-----------------------------------------

function Auctionator_SetupHookFunctions ()
	
	auctionator_orig_AuctionFrameTab_OnClick = AuctionFrameTab_OnClick;
	AuctionFrameTab_OnClick = Auctionator_AuctionFrameTab_OnClick;
	
	auctionator_orig_ContainerFrameItemButton_OnModifiedClick = ContainerFrameItemButton_OnModifiedClick;
	ContainerFrameItemButton_OnModifiedClick = Auctionator_ContainerFrameItemButton_OnModifiedClick;
	
	auctionator_orig_AuctionFrameAuctions_Update = AuctionFrameAuctions_Update;
	AuctionFrameAuctions_Update = Auctionator_AuctionFrameAuctions_Update;
	
	auctionator_orig_AuctionsCreateAuctionButton_OnClick = AuctionsCreateAuctionButton_OnClick;
	AuctionsCreateAuctionButton_OnClick = Auctionator_AuctionsCreateAuctionButton_OnClick;
	
end

-----------------------------------------

function Auctionator_AddSellPanel ()
	
--	local frame = CreateFrame("Frame", "Auctionator_Sell_Panel", AuctionFrame, "Auctionator_Sell_Template");
	--frame:SetParent("AuctionFrame");
	--frame:SetPoint("TOPLEFT", "AuctionFrame", "TOPLEFT", 0, 0);
	--relevel(frame);
--	frame:Hide();
	
end

-----------------------------------------

function Auctionator_AddSellTab ()
		
	local tabIndex = 1;
	while (getglobal("AuctionFrameTab"..(tabIndex)) ~= nil and
		getglobal("AuctionFrameTab"..(tabIndex)):GetName() ~= "AuctionFrameTabTransactions") do
			tabIndex = tabIndex + 1;
	end
	insertAHTab(tabIndex, AuctionFrameTabPost, AuctionFramePost);

	local n = tabIndex;
	
	AUCTIONATOR_TAB_INDEX = n;

	-- local framename = "AuctionFrameTab"..n;

	-- local frame = CreateFrame("Button", framename, AuctionFrame, "CharacterFrameTabButtonTemplate");

	-- setglobal(framename, frame);
	-- frame:SetID(n);
	-- --frame:SetParent("FriendsFrameTabTemplate");
	-- frame:SetText("Auctionator");
	-- frame:SetPoint("LEFT", getglobal("AuctionFrameTab"..n-1), "RIGHT", -8, 0);
	-- frame:Show();

	--Attempting to index local 'frame' now
	
	-- Configure the tab button.
	--setglobal(AuctionFrameTab4, AuctionFrameTab4);
	
	--tabButton:SetPoint("TOPLEFT", getglobal("AuctionFrameTab"..(tabIndex - 1)):GetName(), "TOPRIGHT", -8, 0);
	--tabButton:SetID(tabIndex);
	
	--PanelTemplates_SetNumTabs (AuctionFrame, n);
	--PanelTemplates_EnableTab  (AuctionFrame, n);
end

-----------------------------------------

function Auctionator_HideElems (tt)

	if (not tt) then
		return;
	end
	
	for i,x in ipairs(tt) do
		x:Hide();
	end
end

-----------------------------------------

function Auctionator_ShowElems (tt)

	for i,x in ipairs(tt) do
		x:Show();
	end
end

-----------------------------------------

function Auctionator_OnAuctionUpdate ()

	if (processing_state ~= KM_POSTQUERY) then
		chatmsg ("No KM_POSTQUERY so no Auctionator_OnAuctionUpdate actually");
		return;
	end
	
	if (PanelTemplates_GetSelectedTab (AuctionFrame) ~= AUCTIONATOR_TAB_INDEX) then
		chatmsg ("Selected tab !="..AUCTIONATOR_TAB_INDEX.."so no Auctionator_OnAuctionUpdate actually");
		return;
	end;
	
	processing_state = KM_ANALYZING;
	
	local numBatchAuctions, totalAuctions = GetNumAuctionItems("list");
	
    chatmsg("auctions:"..numBatchAuctions.." out of  "..totalAuctions)

	if (totalAuctions >= 50) then
		Auctionator_SetMessage ("Scanning auctions: page "..current_page);
	end
	
	if (numBatchAuctions > 0) then
	
		local x;
		
		for x = 1, numBatchAuctions do
		
			local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", x);

			if (name == currentAuctionItemName and buyoutPrice > 0) then
			
				local sd = {};
				
				sd["stackSize"]		= count;
				sd["buyoutPrice"]	= buyoutPrice;
				sd["owner"]			= owner;
				
				tinsert (scandata, sd);
				
				
			end
		end
	end

	chatmsg ("In the center of auction update");
	
	if (numBatchAuctions == 50) then
				
		processing_state = KM_PREQUERY;	
		
	else
	
		if (table.getn (scandata) > 0) then
			Auctionator_Process_Scandata ();
			Auctionator_CalcBaseData();
		else
			Auctionator_SetMessage ("No auctions were found for \n\n"..currentAuctionItemName);
		end
		
		processing_state = KM_NULL_STATE;

	end
	
	
	
end

-----------------------------------------

function Auctionator_SetMessage (msg)
	Auctionator_HideElems (recommendElements);
	Auctionator_HideElems (overallElements);

	AuctionatorMessage:SetText (msg);
	AuctionatorMessage:Show();
end

-----------------------------------------

function Auctionator_Process_Scandata ()

	sorteddata = {};
	
	if (scandata == nil) then
		chatmsg ("No scandata to sort");
		return;
	end;
   
	----- Condense the scan data into a table that has only a single entry per stacksize/price combo

	local i,sd;
	local conddata = {};
	chatmsg ("Processing scandata");

	for i,sd in ipairs (scandata) do
	
		local key = "_"..sd.stackSize.."_"..sd.buyoutPrice;
		
	
		if (conddata[key]) then
			conddata[key].count = conddata[key].count + 1;	
		else
			local data = {};
			
			data.stackSize 		= sd.stackSize;
			data.buyoutPrice	= sd.buyoutPrice;
			data.itemPrice		= sd.buyoutPrice / sd.stackSize;
			data.count			= 1;
			data.numYours		= 0;
			
			conddata[key] = data;
		end

		if (sd.owner == UnitName("player")) then
			conddata[key].numYours = conddata[key].numYours + 1;
		end
	
	end


	----- create a table of these entries sorted by itemPrice


	local n = 1;
	for i,v in pairs (conddata) do
		sorteddata[n] = v;
		n = n + 1;
	end
	

	table.sort (sorteddata, function(a,b) return a.itemPrice < b.itemPrice; end);

end

-----------------------------------------

local bestPriceOurStackSize;

-----------------------------------------

function Auctionator_CalcBaseData ()

	local bestPrice		= {};		-- a table with one entry per stacksize that is the cheapest auction for that particular stacksize
	local absoluteBest;				-- the overall cheapest auction
	
	local j, sd;

	----- find the best price per stacksize and overall -----
	
	for j,sd in ipairs(sorteddata) do
	
		if (bestPrice[sd.stackSize] == nil or bestPrice[sd.stackSize].itemPrice >= sd.itemPrice) then
			bestPrice[sd.stackSize] = sd;
		end
	
		if (absoluteBest == nil or absoluteBest.itemPrice > sd.itemPrice) then
			absoluteBest = sd;
		end
	
	end
	
	basedata = absoluteBest;

	if (bestPrice[currentAuctionStackSize]) then
		basedata				= bestPrice[currentAuctionStackSize];
		bestPriceOurStackSize	= bestPrice[currentAuctionStackSize];
	end

	
	Auctionator_UpdateRecommendation();
end

-----------------------------------------

function Auctionator_UpdateRecommendation ()

	if (basedata) then
		local newBuyoutPrice = basedata.itemPrice * currentAuctionStackSize;

		if (basedata.numYours < basedata.count) then
			newBuyoutPrice = calcNewPrice (newBuyoutPrice);
		end
		
		local newStartPrice = calcNewPrice(round(newBuyoutPrice *0.95)); 
		
		Auctionator_ShowElems (recommendElements);
		AuctionatorMessage:Hide();
		
		Auctionator_Recommend_Text:SetText ("Recommended Buyout Price");
		Auctionator_RecommendPerStack_Text:SetText ("for your stack of "..currentAuctionStackSize);
		
		if (currentAuctionTexture) then
			Auctionator_RecommendItem_Tex:SetNormalTexture (currentAuctionTexture);
			if (currentAuctionStackSize > 1) then
				Auctionator_RecommendItem_TexCount:SetText (currentAuctionStackSize);
				Auctionator_RecommendItem_TexCount:Show();
			else
				Auctionator_RecommendItem_TexCount:Hide();
			end
		else
			Auctionator_RecommendItem_Tex:Hide();
		end
		
		MoneyFrame_Update ("Auctionator_RecommendPerItem_Price",  round(newBuyoutPrice / currentAuctionStackSize));
		MoneyFrame_Update ("Auctionator_RecommendPerStack_Price", round(newBuyoutPrice));
		
		MoneyInputFrame_SetCopper (BuyoutPrice, newBuyoutPrice);
		MoneyInputFrame_SetCopper (StartPrice,  newStartPrice);

		Auctionator_ScrollbarUpdate();
		
		if (basedata.stackSize == sorteddata[1].stackSize and basedata.buyoutPrice == sorteddata[1].buyoutPrice) then
			Auctionator_Recommend_Basis_Text:SetText ("(based on cheapest)");
		elseif (bestPriceOurStackSize and basedata.stackSize == bestPriceOurStackSize.stackSize and basedata.buyoutPrice == bestPriceOurStackSize.buyoutPrice) then
			Auctionator_Recommend_Basis_Text:SetText ("(based on cheapest stack of the same size)");
		else
			Auctionator_Recommend_Basis_Text:SetText ("(based on auction selected below)");
		end
		
	end
end



-----------------------------------------

function Auctionator_OnAuctionHouseShow()

	if (AUCTIONATOR_OPEN_FIRST ~= 0) then
		AuctionFrameTab_OnClick (AUCTIONATOR_TAB_INDEX);
	end

end

-----------------------------------------

function Auctionator_OnAuctionHouseClosed()

	AuctionatorOptionsFrame:Hide();
	AuctionatorDescriptionFrame:Hide();
	Auctionator_Sell_Template:Hide();
	
end



-----------------------------------------

function Auctionator_OnUpdate(self, elapsed)

	Auctionator_Idle (self, elapsed);

end


-----------------------------------------

function Auctionator_Idle(self, elapsed)

	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + 0.1;--elapsed;
	
	if (AuctionatorMessage == nil) then
		return;
	end;
	
	self.NumIdles = self.NumIdles + 1;
	
	if (self.TimeSinceLastUpdate > 0.25) then
	
		self.TimeSinceLastUpdate = 0;

		------- check whether to send a new auction query to get the next page -------

		if (processing_state == KM_PREQUERY) then
			chatmsg ("KM_PREQUERY...");
			if (CanSendAuctionQuery()) then
				processing_state = KM_IN_QUERY;
				chatmsg ("KM_IN_QUERY...");
				QueryAuctionItems (currentAuctionItemName, "", "", nil, currentAuctionClass, currentAuctionSubclass, current_page, nil, nil);
				processing_state = KM_POSTQUERY;
				chatmsg ("KM_POSTQUERY!");
				current_page = current_page + 1;
			end
		end
	end
	
	------- check whether the "sell" item has changed -------

	local auctionItemName, auctionTexture, auctionCount = GetAuctionSellItemInfo(); 

	if (auctionItemName == nil) then
		auctionItemName = "";
		auctionCount	= 0;
	end

	if (currentAuctionItemName ~= auctionItemName or currentAuctionStackSize ~= auctionCount or self.NumIdles == 1 or forceMsgAreaUpdate) then
	
		if (self.NumIdles == 1) then chatmsg ("self.NumIdles == 1"); end
		if (forceMsgAreaUpdate) then chatmsg ("forceMsgAreaUpdate"); end
		
		forceMsgAreaUpdate = false;
		
		sorteddata = {};
		Auctionator_ScrollbarUpdate();

		currentAuctionItemName  = auctionItemName;
		currentAuctionStackSize = auctionCount;
		currentAuctionTexture	= auctionTexture;
		
		Auctionator_RecommendPerItem_Price:Hide();
		Auctionator_RecommendPerStack_Price:Hide();

		processing_state = KM_NULL_STATE;
		
		basedata = nil;
		
		if (currentAuctionItemName == "") then
			
			if (auctionator_pending_message) then
				Auctionator_SetMessage (auctionator_pending_message);
				auctionator_pending_message = nil;
			elseif (auctionator_last_item_posted == nil) then
				Auctionator_SetMessage ("Drag an item to the Auction Item area\n\nto see recommended pricing information");
			end
		else
			local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(currentAuctionItemName);
		
			currentAuctionClass		= ItemType2AuctionClass (sType);
			currentAuctionSubclass	= "Guns"--Oh, no one's looking! SubType2AuctionSubclass (currentAuctionClass, sSubType);

			SortAuctionItems("list", "buyout");

			if (IsAuctionSortReversed("list", "buyout")) then
				SortAuctionItems("list", "buyout");
			end
		 
			current_page = 0;
			processing_state = KM_PREQUERY;
			chatmsg ("Just KM_PREQUERY in Auctionator_Idle");

			scandata = {};
		end

	end

end

	
-----------------------------------------

function Auctionator_ScrollbarUpdate()

	local line;				-- 1 through 12 of our window to scroll
	local dataOffset;		-- an index into our data calculated from the scroll offset

	local numrows = table.getn (sorteddata);

	if (numrows == nil) then
		chatmsg ("numrows set to 0")
		numrows = 0
	end
		
	FauxScrollFrame_Update (AuctionatorScrollFrame, numrows, 12, 16);

	for line = 1,12 do

		dataOffset = line + FauxScrollFrame_GetOffset (AuctionatorScrollFrame);
		
		local lineEntry = getglobal ("AuctionatorEntry"..line);
		
		lineEntry:SetID(dataOffset);
		
		if dataOffset <= numrows and sorteddata[dataOffset] then
			
			local data = sorteddata[dataOffset];

			local lineEntry_avail	= getglobal("AuctionatorEntry"..line.."_Availability");
			local lineEntry_comm	= getglobal("AuctionatorEntry"..line.."_Comment");
			local lineEntry_stack	= getglobal("AuctionatorEntry"..line.."_StackPrice");

			if (data.itemPrice == basedata.itemPrice and data.stackSize == basedata.stackSize) then
				lineEntry:LockHighlight();
			else
				lineEntry:UnlockHighlight();
			end

			if ( data.stackSize == currentAuctionStackSize ) then	lineEntry_avail:SetTextColor (0.2, 0.9, 0.2);
			else													lineEntry_avail:SetTextColor (1.0, 1.0, 1.0);
			end;

			
			if		(data.numYours == 0) then			lineEntry_comm:SetText ("");
			elseif	(data.numYours == data.count) then	lineEntry_comm:SetText ("yours");
			else										lineEntry_comm:SetText ("yours: "..data.numYours);
			end;
				
			
			local tx = string.format ("%i %s of %i", data.count, pluralizeIf ("stack", data.count), data.stackSize);

			MoneyFrame_Update ("AuctionatorEntry"..line.."_PerItem_Price", round(data.buyoutPrice/data.stackSize) );

			lineEntry_avail:SetText (tx);
			lineEntry_stack:SetText (priceToString(data.buyoutPrice));

			lineEntry:Show();
		else
			lineEntry:Hide();
		end
	end
end

-----------------------------------------

function Auctionator_EntryOnClick()
	local entryIndex = this:GetID();
	
--	chatmsg (entryIndex);
	
	basedata = sorteddata[entryIndex];

	Auctionator_UpdateRecommendation();

	PlaySound ("igMainMenuOptionCheckBoxOn");
end

-----------------------------------------

function AuctionatorMoneyFrame_OnLoad()

	this.small = 1;
	MoneyFrame_SetType("STATIC");
end

-----------------------------------------

function Auctionator_ShowOptionsFrame()

	AuctionatorOptionsFrame:Show();
	AuctionatorOptionsFrame:SetBackdropColor(0,0,0,100);
	
	AuctionatorConfigFrameTitle:SetText ("Auctionator Options for "..UnitName("player"));
	
	local expText = "<html><body>"
					.."<h1>What is Auctionator?</h1><br/>"
					.."<p>"
					.."Figuring out a good buyout price when posting auctions can be tedious and time-consuming.  If you're like most people, you first browse the current "
					.."auctions to get a sense of how much your item is currently selling for.  Then you undercut the lowest price by a bit.  If you're creating multiple auctions "
					.."you're bouncing back and forth between the Browse tab and the Auctions tab, doing lots of division in "
					.."your head, and doing lots of clicking and typing."
					.."</p><br/><h1>How it works</h1><br/><p>"
					.."Auctionator makes this whole process easy and streamlined.  When you select an item to auction, Auctionator displays a summary of all the current auctions for "
					.."that item sorted by per-item price.  Auctionator also calculates a recommended buyout price based on the cheapest per-item price for your item.  If you're "
					.."selling a stack rather than a single item, Auctionator bases its recommended buyout price on the cheapest stack of the same size."
					.."</p><br/><p>"
					.."If you don't like Auctionator's recommendation, you can click on any line in the summary and Auctionator will recalculate the recommended buyout price based "
					.."on that auction.  Of course, you can always override Auctionator's recommendation by just typing in your own buyout price."
					.."</p><br/><p>"
					.."With Auctionator, creating an auction is usually just a matter of picking an item to auction and clicking the Create Auction button."
					.."</p>"
					.."</body></html>"
					;



	AuctionatorExplanation:SetText ("Auctionator is an addon designed to make it easier and faster to setup your auctions at the auction house.");
	AuctionatorDescriptionHTML:SetText (expText);
	AuctionatorDescriptionHTML:SetSpacing (3);

	AuctionatorVersionText:SetText ("Version: "..AuctionatorVersion);

	
	AuctionatorOption_Enable_Alt:SetChecked (NumToBool(AUCTIONATOR_ENABLE_ALT));
	AuctionatorOption_Open_First:SetChecked (NumToBool(AUCTIONATOR_OPEN_FIRST));
end

-----------------------------------------

function AuctionatorOptionsSave()

	AUCTIONATOR_ENABLE_ALT = BoolToNum(AuctionatorOption_Enable_Alt:GetChecked ());
	AUCTIONATOR_OPEN_FIRST = BoolToNum(AuctionatorOption_Open_First:GetChecked ());
	
end

-----------------------------------------

function Auctionator_ShowTooltip_EnableAlt()

	GameTooltip:SetOwner(this, "ANCHOR_BOTTOM");
	GameTooltip:SetText("Enable alt-key shortcut", 0.9, 1.0, 1.0);
	GameTooltip:AddLine("If this option is checked, holding the Alt key down while clicking an item in your bags will switch to the Auctionator panel, place the item in the Auction Item area, and start the scan.", 0.5, 0.5, 1.0, 1);
	GameTooltip:Show();

end

-----------------------------------------

function Auctionator_ShowTooltip_OpenFirst()

	GameTooltip:SetOwner(this, "ANCHOR_BOTTOM");
	GameTooltip:SetText("Automatically open Auctionator panel", 0.9, 1.0, 1.0);
	GameTooltip:AddLine("If this option is checked, the Auctionator panel will display first whenever you open the Auction House window.", 0.5, 0.5, 1.0, 1);
	GameTooltip:Show();

end



--[[***************************************************************

	All function below here are local utility functions.
	These should be declared local at the top of this file.

--*****************************************************************]]


function BoolToString (b)
	if (b) then
		return "true";
	end
	
	return "false";
end

-----------------------------------------

function BoolToNum (b)
	if (b) then
		return 1;
	end
	
	return 0;
end

-----------------------------------------

function NumToBool (n)
	if (n == 0) then
		return false;
	end
	
	return true;
end

-----------------------------------------

function pluralizeIf (word, count)

	if (count and count == 1) then
		return word;
	else
		return word.."s";
	end
end

-----------------------------------------

function round (v)
	return math.floor (v + 0.5);
end

-----------------------------------------

function chatmsg (msg)
	if (DEFAULT_CHAT_FRAME) then
		DEFAULT_CHAT_FRAME:AddMessage (msg);
	end
end

-----------------------------------------

function calcNewPrice (price)

	if	(price > 2000000)	then return roundPriceDown (price, 10000, 10000);	end;
	if	(price > 1000000)	then return roundPriceDown (price,  2500,  2500);	end;
	if	(price >  500000)	then return roundPriceDown (price,  1000,  1000);	end;
	if	(price >   50000)	then return roundPriceDown (price,   500,   500);	end;
	if	(price >   10000)	then return roundPriceDown (price,   500,   200);	end;
	if	(price >    2000)	then return roundPriceDown (price,   100,    50);	end;
	if	(price >     100)	then return roundPriceDown (price,    10,     5);	end;
	if	(price >       0)	then return math.floor (price - 1);	end;

	return 0;
end

-----------------------------------------
-- roundPriceDown - rounds a price down to the next lowest multiple of a.
--				  - if the result is not at least b lower, rounds down by a again.
--
--	examples:  	(128790, 500, 250)  ->  128500 
--				(128700, 500, 250)  ->  128000 
--				(128400, 500, 250)  ->  128000
-----------------------------------------

function roundPriceDown (price, a, b)
	
	local newprice = math.floor(price / a) * a;
	
	if ((price - newprice) < b) then
		newprice = newprice - a;
	end
	
	return newprice;
	
end

-----------------------------------------

function val2gsc (v)
	local rv = round(v)
	
	local g = math.floor (rv/10000);
	
	rv = rv - g*10000;
	
	local s = math.floor (rv/100);
	
	rv = rv - s*100;
	
	local c = rv;
			
	return g, s, c
end

-----------------------------------------

function priceToString (val)

	local gold, silver, copper  = val2gsc(val);

	local st = "";
	

	if (gold ~= 0) then
		st = gold.."g ";
	end


	if (st ~= "") then
		st = st..format("%02is ", silver);
	elseif (silver ~= 0) then
		st = st..silver.."s ";
	end

		
	if (st ~= "") then
		st = st..format("%02ic", copper);
	elseif (copper ~= 0) then
		st = st..copper.."c";
	end
	
	return st;
end

-----------------------------------------

function ItemType2AuctionClass(itemType)
	local itemClasses = { GetAuctionItemClasses() };
	if (itemClasses ~= nil) then
		if table.getn (itemClasses) > 0 then
		local itemClass;
			for x, itemClass in pairs(itemClasses) do
				if (itemClass == itemType) then
					return x;
				end
			end
		end
	else chatmsg ("Can't GetAuctionItemClasses"); end
end

-----------------------------------------

function SubType2AuctionSubclass(auctionClass, itemSubtype)
	local itemClasses = { GetAuctionItemSubClasses(auctionClass.number) };
	if itemClasses.n > 0 then
	local itemClass;
		for x, itemClass in pairs(itemClasses) do
			if (itemClass == itemSubtype) then
				return x;
			end
		end
	end
end

function relevel(frame) --Local
	local myLevel = frame:GetFrameLevel() + 1
	local children = { frame:GetChildren() }
	for _,child in pairs(children) do
		child:SetFrameLevel(myLevel)
		relevel(child)
	end
end

function insertAHTab(tabIndex, tabButton, tabFrame)
	-- Count the number of auction house tabs (including the tab we are going
	-- to insert).
	local tabCount = 1;
	while (getglobal("AuctionFrameTab"..(tabCount)) ~= nil) do
		tabCount = tabCount + 1;
	end

	-- Adjust the tabIndex to fit within the current tab count.
	if (tabIndex < 1 or tabIndex > tabCount) then
		tabIndex = tabCount;
	end

	-- Make room for the tab, if needed.
	for index = tabCount, tabIndex + 1, -1  do
		setglobal("AuctionFrameTab"..(index), getglobal("AuctionFrameTab"..(index - 1)));
		getglobal("AuctionFrameTab"..(index)):SetID(index);
	end

	-- Configure the frame.
	tabFrame:SetParent("AuctionFrame");
	tabFrame:SetPoint("TOPLEFT", "AuctionFrame", "TOPLEFT", 0, 0);
	relevel(tabFrame);

	-- Configure the tab button.
	setglobal("AuctionFrameTab"..tabIndex, tabButton);
	tabButton:SetParent("AuctionFrame");
	tabButton:SetPoint("TOPLEFT", getglobal("AuctionFrameTab"..(tabIndex - 1)):GetName(), "TOPRIGHT", -8, 0);
	tabButton:SetID(tabIndex);
	tabButton:Show();

	-- If we inserted a tab in the middle, adjust the layout of the next tab button.
	if (tabIndex < tabCount) then
		nextTabButton = getglobal("AuctionFrameTab"..(tabIndex + 1));
		nextTabButton:SetPoint("TOPLEFT", tabButton:GetName(), "TOPRIGHT", -8, 0);
	end

	-- Update the tab count.
	PanelTemplates_SetNumTabs(AuctionFrame, tabCount)
end



--[[
	Auctioneer Addon for World of Warcraft(tm).
	Version: 3.8.0 (Kangaroo)
	Revision: $Id: AuctionFramePost.lua 958 2006-08-16 04:21:17Z mentalpower $

	Auctioneer Post Auctions tab

	License:
		This program is free software; you can redistribute it and/or
		modify it under the terms of the GNU General Public License
		as published by the Free Software Foundation; either version 2
		of the License, or (at your option) any later version.

		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.

		You should have received a copy of the GNU General Public License
		along with this program(see GPL.txt); if not, write to the Free Software
		Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
--]]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_OnLoad()
	-- Methods
	this.CalculateAuctionDeposit = AuctionFramePost_CalculateAuctionDeposit;
	this.UpdateDeposit = AuctionFramePost_UpdateDeposit;
	this.GetItemID = AuctionFramePost_GetItemID;
	this.GetItemSignature = AuctionFramePost_GetItemSignature;
	this.GetItemName = AuctionFramePost_GetItemName;
	this.SetNoteText = AuctionFramePost_SetNoteText;
	this.GetSavePrice = AuctionFramePost_GetSavePrice;
	this.GetStartPrice = AuctionFramePost_GetStartPrice;
	this.SetStartPrice = AuctionFramePost_SetStartPrice;
	this.GetBuyoutPrice = AuctionFramePost_GetBuyoutPrice;
	this.SetBuyoutPrice = AuctionFramePost_SetBuyoutPrice;
	this.GetStackSize = AuctionFramePost_GetStackSize;
	this.SetStackSize = AuctionFramePost_SetStackSize;
	this.GetStackCount = AuctionFramePost_GetStackCount;
	this.SetStackCount = AuctionFramePost_SetStackCount;
	this.GetDuration = AuctionFramePost_GetDuration;
	this.SetDuration = AuctionFramePost_SetDuration;
	this.GetDeposit = AuctionFramePost_GetDeposit;
	this.SetAuctionItem = AuctionFramePost_SetAuctionItem;
	this.ValidateAuction = AuctionFramePost_ValidateAuction;
	this.UpdateAuctionList = AuctionFramePost_UpdateAuctionList;
	this.UpdatePriceModels = AuctionFramePost_UpdatePriceModels;

	-- Data Members
	this.itemID = nil;
	this.itemSignature = nil;
	this.itemName = nil;
	this.updating = false;
	this.prices = {};

	-- Controls
	this.auctionList = getglobal(this:GetName().."List");
	this.bidMoneyInputFrame = getglobal(this:GetName().."StartPrice");
	this.buyoutMoneyInputFrame = getglobal(this:GetName().."BuyoutPrice");
	this.stackSizeEdit = getglobal(this:GetName().."StackSize");
	this.stackSizeCount = getglobal(this:GetName().."StackCount");
	this.depositMoneyFrame = getglobal(this:GetName().."DepositMoneyFrame");
	this.depositErrorLabel = getglobal(this:GetName().."UnknownDepositText");

	-- Setup the tab order for the money input frames.
	MoneyInputFrame_SetPreviousFocus(this.bidMoneyInputFrame, this.stackSizeCount);
	MoneyInputFrame_SetNextFocus(this.bidMoneyInputFrame, getglobal(this.buyoutMoneyInputFrame:GetName().."Gold"));
	MoneyInputFrame_SetPreviousFocus(this.buyoutMoneyInputFrame, getglobal(this.bidMoneyInputFrame:GetName().."Copper"));
	MoneyInputFrame_SetNextFocus(this.buyoutMoneyInputFrame, this.stackSizeEdit);

	-- Configure the logical columns
	this.logicalColumns =
	{
		Quantity =
		{
			title = _AUCT("UiQuantityHeader");
			dataType = "Number";
			valueFunc = (function(record) return record.quantity end);
			alphaFunc = AuctionFramePost_GetItemAlpha;
			compareAscendingFunc = (function(record1, record2) return record1.quantity < record2.quantity end);
			compareDescendingFunc = (function(record1, record2) return record1.quantity > record2.quantity end);
		},
		Name =
		{
			title = _AUCT("UiNameHeader");
			dataType = "String";
			valueFunc = (function(record) return record.name end);
			colorFunc = AuctionFramePost_GetItemColor;
			alphaFunc = AuctionFramePost_GetItemAlpha;
			compareAscendingFunc = (function(record1, record2) return record1.name < record2.name end);
			compareDescendingFunc = (function(record1, record2) return record1.name > record2.name end);
		},
		TimeLeft =
		{
			title = _AUCT("UiTimeLeftHeader");
			dataType = "String";
			valueFunc = (function(record) return Auctioneer.Util.GetTimeLeftString(record.timeLeft) end);
			alphaFunc = AuctionFramePost_GetItemAlpha;
			compareAscendingFunc = (function(record1, record2) return record1.timeLeft < record2.timeLeft end);
			compareDescendingFunc = (function(record1, record2) return record1.timeLeft > record2.timeLeft end);
		},
		Bid =
		{
			title = _AUCT("UiBidHeader");
			dataType = "Money";
			valueFunc = (function(record) return record.bid end);
			alphaFunc = AuctionFramePost_GetItemAlpha;
			compareAscendingFunc = (function(record1, record2) return record1.bid < record2.bid end);
			compareDescendingFunc = (function(record1, record2) return record1.bid > record2.bid end);
		},
		BidPer =
		{
			title = _AUCT("UiBidPerHeader");
			dataType = "Money";
			valueFunc = (function(record) return record.bidPer end);
			alphaFunc = AuctionFramePost_GetItemAlpha;
			compareAscendingFunc = (function(record1, record2) return record1.bidPer < record2.bidPer end);
			compareDescendingFunc = (function(record1, record2) return record1.bidPer > record2.bidPer end);
		},
		Buyout =
		{
			title = _AUCT("UiBuyoutHeader");
			dataType = "Money";
			valueFunc = (function(record) return record.buyout end);
			alphaFunc = AuctionFramePost_GetItemAlpha;
			compareAscendingFunc = (function(record1, record2) return record1.buyout < record2.buyout end);
			compareDescendingFunc = (function(record1, record2) return record1.buyout > record2.buyout end);
		},
		BuyoutPer =
		{
			title = _AUCT("UiBuyoutPerHeader");
			dataType = "Money";
			valueFunc = (function(record) return record.buyoutPer end);
			alphaFunc = AuctionFramePost_GetItemAlpha;
			compareAscendingFunc = (function(record1, record2) return record1.buyoutPer < record2.buyoutPer end);
			compareDescendingFunc = (function(record1, record2) return record1.buyoutPer > record2.buyoutPer end);
		},
	};

	-- Configure the physical columns
	this.physicalColumns =
	{
		{
			width = 50;
			logicalColumn = this.logicalColumns.Quantity;
			logicalColumns = { this.logicalColumns.Quantity };
			sortAscending = true;
		},
		{
			width = 210;
			logicalColumn = this.logicalColumns.Name;
			logicalColumns = { this.logicalColumns.Name };
			sortAscending = true;
		},
		{
			width = 90;
			logicalColumn = this.logicalColumns.TimeLeft;
			logicalColumns = { this.logicalColumns.TimeLeft };
			sortAscending = true;
		},
		{
			width = 130;
			logicalColumn = this.logicalColumns.Bid;
			logicalColumns =
			{
				this.logicalColumns.Bid,
				this.logicalColumns.BidPer
			};
			sortAscending = true;
		},
		{
			width = 130;
			logicalColumn = this.logicalColumns.Buyout;
			logicalColumns =
			{
				this.logicalColumns.Buyout,
				this.logicalColumns.BuyoutPer
			};
			sortAscending = true;
		},
	};

	this.auctions = {};
	ListTemplate_Initialize(this.auctionList, this.physicalColumns, this.logicalColumns);
	ListTemplate_SetContent(this.auctionList, this.auctions);

	this:ValidateAuction();
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_UpdatePriceModels(frame)
	if (not frame.updating) then
		frame.prices = {};

		local name = frame:GetItemName();
		local count = frame:GetStackSize();
		if (name and count) then
			local bag, slot, id, rprop, enchant, uniq = EnhTooltip.FindItemInBags(name);
			local itemKey = id..":"..rprop..":"..enchant;
			local hsp, histCount, market, warn, nexthsp, nextwarn = Auctioneer.Statistic.GetHSP(itemKey, Auctioneer.Util.GetAuctionKey());

			-- Get the fixed price
			if (Auctioneer.Storage.GetFixedPrice(itemKey)) then
				local startPrice, buyPrice = Auctioneer.Storage.GetFixedPrice(itemKey, count);
				local fixedPrice = {};
				fixedPrice.text = _AUCT('UiPriceModelFixed');
				fixedPrice.note = "";
				fixedPrice.bid = startPrice;
				fixedPrice.buyout = buyPrice;
				table.insert(frame.prices, fixedPrice);
			end

			-- Get the last sale price if BeanCounter is loaded.
			if (IsAddOnLoaded("BeanCounter")) then
				-- TODO: Support should be added to BeanCounter for looking
				-- up itemKey (itemId:suffixId:enchantID) instead of by name.
				local lastSale = BeanCounter.Sales.GetLastSaleForItem(name);
				if (lastSale and lastSale.bid and lastSale.buyout) then
					local lastPrice = {};
					lastPrice.text = _AUCT('UiPriceModelLastSold');
					lastPrice.note = string.format(_AUCT('FrmtLastSoldOn'), date("%x", lastSale.time));
					lastPrice.bid = (lastSale.bid / lastSale.quantity) * count;
					lastPrice.buyout = (lastSale.buyout / lastSale.quantity) * count;
					table.insert(frame.prices, lastPrice);
				end
			end

			-- Calculate auctioneer's suggested resale price.
			if (hsp == 0) then
				local auctionPriceItem = Auctioneer.Core.GetAuctionPriceItem(itemKey, Auctioneer.Util.GetAuctionKey());
				local aCount,minCount,minPrice,bidCount,bidPrice,buyCount,buyPrice = Auctioneer.Core.GetAuctionPrices(auctionPriceItem.data);
				hsp = math.floor(buyPrice / buyCount); -- use mean buyout if median not available
			end
			local discountBidPercent = tonumber(Auctioneer.Command.GetFilterVal('pct-bidmarkdown'));
			local auctioneerPrice = {};
			auctioneerPrice.text = _AUCT('UiPriceModelAuctioneer');
			auctioneerPrice.note = warn;
			auctioneerPrice.buyout = Auctioneer.Statistic.RoundDownTo95(Auctioneer.Util.NullSafe(hsp) * count);
			auctioneerPrice.bid = Auctioneer.Statistic.RoundDownTo95(Auctioneer.Statistic.SubtractPercent(auctioneerPrice.buyout, discountBidPercent));
			table.insert(frame.prices, auctioneerPrice);

			-- Add the fallback custom price
			local customPrice = {}
			customPrice.text = _AUCT('UiPriceModelCustom');
			customPrice.note = "";
			customPrice.bid = nil;
			customPrice.buyout = nil;
			table.insert(frame.prices, customPrice);

			-- Update the price model combo.
			local dropdown = getglobal(frame:GetName().."PriceModelDropDown");
			local index = UIDropDownMenu_GetSelectedID(dropdown);
			if (index == nil) then
				index = 1;
			end
			AuctionFramePost_PriceModelDropDownItem_SetSelectedID(dropdown, index);
		else
			-- Update the price model combo.
			local dropdown = getglobal(frame:GetName().."PriceModelDropDown");
			AuctionFramePost_PriceModelDropDownItem_SetSelectedID(dropdown, nil);
		end
	end
end

-------------------------------------------------------------------------------
-- Updates the content of the auction list based on the current auction item.
-------------------------------------------------------------------------------
function AuctionFramePost_UpdateAuctionList(frame)
	frame.auctions = {};
	local itemSignature = frame:GetItemSignature();
	if (itemSignature) then
		local auctions = Auctioneer.Filter.QuerySnapshot(AuctionFramePost_ItemSignatureFilter, itemSignature);
		if (auctions) then
			for _,a in pairs(auctions) do
				local id,rprop,enchant,name,count,min,buyout,uniq = Auctioneer.Core.GetItemSignature(a.signature);
				local auction = {};
				auction.item = string.format("item:%s:%s:%s:0", id, enchant, rprop);
				auction.quantity = count;
				auction.name = name;
				auction.owner = a.owner;
				auction.timeLeft = a.timeLeft;
				auction.bid = Auctioneer.Statistic.GetCurrentBid(a.signature);
				auction.bidPer = math.floor(auction.bid / auction.quantity);
				auction.buyout = buyout;
				auction.buyoutPer = math.floor(auction.buyout / auction.quantity);
				table.insert(frame.auctions, auction);
			end
		end
	end
	ListTemplate_SetContent(frame.auctionList, frame.auctions);
	ListTemplate_Sort(frame.auctionList, 5);
end

-------------------------------------------------------------------------------
-- Updates the deposit value.
-------------------------------------------------------------------------------
function AuctionFramePost_UpdateDeposit(frame)
	if (not frame.updating) then
		local itemID = frame:GetItemID();
		local duration = frame:GetDuration();
		local stackSize = frame:GetStackSize();
		local stackCount = frame:GetStackCount();
		if (itemID) then
			local deposit = AuctionFramePost_CalculateAuctionDeposit(itemID, stackSize, duration);
			if (deposit) then
				MoneyFrame_Update(frame.depositMoneyFrame:GetName(), deposit * stackCount);
				frame.depositMoneyFrame:Show();
				frame.depositErrorLabel:Hide();
			else
				MoneyFrame_Update(frame.depositMoneyFrame:GetName(), 0);
				frame.depositMoneyFrame:Hide();
				frame.depositErrorLabel:Show();
			end
		else
			MoneyFrame_Update(frame.depositMoneyFrame:GetName(), 0);
			frame.depositMoneyFrame:Hide();
			frame.depositErrorLabel:Hide();
		end
	end
end

-------------------------------------------------------------------------------
-- Gets the item ID.
-------------------------------------------------------------------------------
function AuctionFramePost_GetItemID(frame)
	return frame.itemID;
end

-------------------------------------------------------------------------------
-- Gets the item signature.
-------------------------------------------------------------------------------
function AuctionFramePost_GetItemSignature(frame)
	return frame.itemSignature;
end

-------------------------------------------------------------------------------
-- Gets the item name.
-------------------------------------------------------------------------------
function AuctionFramePost_GetItemName(frame)
	return frame.itemName;
end

-------------------------------------------------------------------------------
-- Sets the price model note (i.e. "Undercutting 5%")
-------------------------------------------------------------------------------
function AuctionFramePost_SetNoteText(frame, text, colorize)
	getglobal(frame:GetName().."PriceModelNoteText"):SetText(text);
	if (colorize) then
		local cHex, cRed, cGreen, cBlue = Auctioneer.Util.GetWarnColor(text);
		getglobal(frame:GetName().."PriceModelNoteText"):SetTextColor(cRed, cGreen, cBlue);
	else
		getglobal(frame:GetName().."PriceModelNoteText"):SetTextColor(1.0, 1.0, 1.0);
	end
end

-------------------------------------------------------------------------------
-- Gets whether or not to save the current price information as the fixed
-- price.
-------------------------------------------------------------------------------
function AuctionFramePost_GetSavePrice(frame)
	local checkbox = getglobal(frame:GetName().."SavePriceCheckBox");
	return (checkbox and checkbox:IsVisible() and checkbox:GetChecked());
end

-------------------------------------------------------------------------------
-- Gets the starting price.
-------------------------------------------------------------------------------
function AuctionFramePost_GetStartPrice(frame)
	return MoneyInputFrame_GetCopper(getglobal(frame:GetName().."StartPrice"));
end

-------------------------------------------------------------------------------
-- Sets the starting price.
-------------------------------------------------------------------------------
function AuctionFramePost_SetStartPrice(frame, price)
	frame.ignoreStartPriceChange = true;
	MoneyInputFrame_SetCopper(getglobal(frame:GetName().."StartPrice"), price);
	frame:ValidateAuction();
end

-------------------------------------------------------------------------------
-- Gets the buyout price.
-------------------------------------------------------------------------------
function AuctionFramePost_GetBuyoutPrice(frame)
	return MoneyInputFrame_GetCopper(getglobal(frame:GetName().."BuyoutPrice"));
end

-------------------------------------------------------------------------------
-- Sets the buyout price.
-------------------------------------------------------------------------------
function AuctionFramePost_SetBuyoutPrice(frame, price)
	frame.ignoreBuyoutPriceChange = true;
	MoneyInputFrame_SetCopper(getglobal(frame:GetName().."BuyoutPrice"), price);
	frame:ValidateAuction();
end

-------------------------------------------------------------------------------
-- Gets the stack size.
-------------------------------------------------------------------------------
function AuctionFramePost_GetStackSize(frame)
	return getglobal(frame:GetName().."StackSize"):GetNumber();
end

-------------------------------------------------------------------------------
-- Sets the stack size.
-------------------------------------------------------------------------------
function AuctionFramePost_SetStackSize(frame, size)
	-- Update the stack size.
	getglobal(frame:GetName().."StackSize"):SetNumber(size);

	-- Update the deposit cost.
	frame:UpdateDeposit();
	frame:UpdatePriceModels();
	frame:ValidateAuction();
end

-------------------------------------------------------------------------------
-- Gets the stack count.
-------------------------------------------------------------------------------
function AuctionFramePost_GetStackCount(frame)
	return getglobal(frame:GetName().."StackCount"):GetNumber();
end

-------------------------------------------------------------------------------
-- Sets the stack count.
-------------------------------------------------------------------------------
function AuctionFramePost_SetStackCount(frame, count)
	-- Update the stack count.
	getglobal(frame:GetName().."StackCount"):SetNumber(count);

	-- Update the deposit cost.
	frame:UpdateDeposit();
	frame:ValidateAuction();
end

-------------------------------------------------------------------------------
-- Gets the duration.
-------------------------------------------------------------------------------
function AuctionFramePost_GetDuration(frame)
	if (getglobal(frame:GetName().."ShortAuctionRadio"):GetChecked()) then
		return 120;
	elseif(getglobal(frame:GetName().."MediumAuctionRadio"):GetChecked()) then
		return 480;
	else
		return 1440;
	end
end

-------------------------------------------------------------------------------
-- Sets the duration.
-------------------------------------------------------------------------------
function AuctionFramePost_SetDuration(frame, duration)
	local shortRadio = getglobal(frame:GetName().."ShortAuctionRadio");
	local mediumRadio = getglobal(frame:GetName().."MediumAuctionRadio");
	local longRadio = getglobal(frame:GetName().."LongAuctionRadio");

	-- Figure out radio to set as checked.
	if (duration == 120) then
		shortRadio:SetChecked(1);
		mediumRadio:SetChecked(nil);
		longRadio:SetChecked(nil);
	elseif (duration == 480) then
		shortRadio:SetChecked(nil);
		mediumRadio:SetChecked(1);
		longRadio:SetChecked(nil);
	else
		shortRadio:SetChecked(nil);
		mediumRadio:SetChecked(nil);
		longRadio:SetChecked(1);
	end

	-- Update the deposit cost.
	frame:UpdateDeposit();
	frame:ValidateAuction();
end

-------------------------------------------------------------------------------
-- Gets the deposit amount required to post.
-------------------------------------------------------------------------------
function AuctionFramePost_GetDeposit(frame)
	return getglobal(frame:GetName().."DepositMoneyFrame").staticMoney;
end

-------------------------------------------------------------------------------
-- Sets the item to display in the create auction frame.
-------------------------------------------------------------------------------
function AuctionFramePost_SetAuctionItem(frame, bag, item, count)
	-- Prevent validation while updating.
	frame.updating = true;

	-- Update the controls with the item.
	local button = getglobal(frame:GetName().."AuctionItem");
	if (bag and item) then
		-- Get the item's information.
		local itemLink = GetContainerItemLink(bag, item);
		local itemID, randomProp, enchant, uniqueId, name = EnhTooltip.BreakLink(itemLink);
		local itemTexture, itemCount = GetContainerItemInfo(bag, item);
		if (count == nil) then
			count = itemCount;
		end

		-- Save the item's information.
		frame.itemID = itemID;
		frame.itemSignature = AucPostManager.CreateItemSignature(itemID, randomProp, enchant);
		frame.itemName = name;

		-- Show the item
		getglobal(button:GetName().."Name"):SetText(name);
		getglobal(button:GetName().."Name"):Show();
		getglobal(button:GetName().."IconTexture"):SetTexture(itemTexture);
		getglobal(button:GetName().."IconTexture"):Show();

		-- Set the defaults.
		local duration = Auctioneer.Command.GetFilterVal('auction-duration')
		if duration == 1 then
			-- 2h
			frame:SetDuration(120)
		elseif duration == 2 then
			-- 8h
			frame:SetDuration(480)
		elseif duration == 3 then
			-- 24h
			frame:SetDuration(1440)
		else
			-- last
			frame:SetDuration(Auctioneer.Command.GetFilterVal('last-auction-duration'))
		end
		frame:SetStackSize(count);
		frame:SetStackCount(1);

		-- Clear the current pricing model so that the default one gets selected.
		local dropdown = getglobal(frame:GetName().."PriceModelDropDown");
		AuctionFramePost_PriceModelDropDownItem_SetSelectedID(dropdown, nil);
		
		-- Update the Transactions tab if BeanCounter is loaded.
		if (AuctionFrameTransactions) then
			AuctionFrameTransactions:SearchTransactions(name, true, nil);
		end
	else
		-- Clear the item's information.
		frame.itemID = nil;
		frame.itemSignature = nil;
		frame.itemName = nil;

		-- Hide the item
		getglobal(button:GetName().."Name"):Hide();
		getglobal(button:GetName().."IconTexture"):Hide();

		-- Clear the defaults.
		frame:SetStackSize(1);
		frame:SetStackCount(1);
	end

	-- Update the deposit cost and validate the auction.
	frame.updating = false;
	frame:UpdateDeposit();
	frame:UpdatePriceModels();
	frame:UpdateAuctionList();
	frame:ValidateAuction();
end

-------------------------------------------------------------------------------
-- Validates the current auction.
-------------------------------------------------------------------------------
function AuctionFramePost_ValidateAuction(frame)
	-- Only validate if its not turned off.
	if (not frame.updating) then
		-- Check that we have an item.
		local valid = false;
		if (frame.itemID) then
			valid = (frame.itemID ~= nil);
		end

		-- Check that there is a starting price.
		local startPrice = frame:GetStartPrice();
		local startErrorText = getglobal(frame:GetName().."StartPriceInvalidText");
		if (startPrice == 0) then
			valid = false;
			startErrorText:Show();
		else
			startErrorText:Hide();
		end

		-- Check that the starting price is less than or equal to the buyout.
		local buyoutPrice = frame:GetBuyoutPrice();
		local buyoutErrorText = getglobal(frame:GetName().."BuyoutPriceInvalidText");
		if (buyoutPrice > 0 and buyoutPrice < startPrice) then
			valid = false;
			buyoutErrorText:Show();
		else
			buyoutErrorText:Hide();
		end

		-- Check that the item stacks to the amount specified and that the player
		-- has enough of the item.
		local stackSize = frame:GetStackSize();
		local stackCount = frame:GetStackCount();
		local quantityErrorText = getglobal(frame:GetName().."QuantityInvalidText");
		if (frame.itemID and frame.itemSignature) then
			local quantity = AucPostManager.GetItemQuantityBySignature(frame.itemSignature);
			local maxStackSize = AuctionFramePost_GetMaxStackSize(frame.itemID);
			if (stackSize == 0) then
				valid = false;
				quantityErrorText:SetText(_AUCT('UiStackTooSmallError'));
				quantityErrorText:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
				quantityErrorText:Show();
			elseif (stackSize > 1 and (maxStackSize == nil or stackSize > maxStackSize)) then
				valid = false;
				quantityErrorText:SetText(_AUCT('UiStackTooBigError'));
				quantityErrorText:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
				quantityErrorText:Show();
			elseif (quantity < (stackSize * stackCount)) then
				valid = false;
				quantityErrorText:SetText(_AUCT('UiNotEnoughError'));
				quantityErrorText:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
				quantityErrorText:Show();
			else
				local msg = string.format(_AUCT('UiMaxError'), quantity);
				quantityErrorText:SetText(msg);
				quantityErrorText:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
				quantityErrorText:Show();
			end
		else
			quantityErrorText:Hide();
		end

		-- TODO: Check that the player can afford the deposit cost.
		local deposit = frame:GetDeposit();

		-- Update the state of the Create Auction button.
		local button = getglobal(frame:GetName().."CreateAuctionButton");
		if (valid) then
			button:Enable();
		else
			button:Disable();
		end

		-- Update the price model to reflect bid and buyout prices.
		local dropdown = getglobal(frame:GetName().."PriceModelDropDown");
		local index = UIDropDownMenu_GetSelectedID(dropdown);
		if (index and frame.prices and index <= table.getn(frame.prices)) then
			-- Check if the current selection matches
			local currentPrice = frame.prices[index];
			if ((currentPrice.bid and currentPrice.bid ~= startPrice) or
				(currentPrice.buyout and currentPrice.buyout ~= buyoutPrice)) then
				-- Nope, find one that does.
				for index,price in pairs(frame.prices) do
					if ((price.bid == nil or price.bid == startPrice) and (price.buyout == nil or price.buyout == buyoutPrice)) then
						if (UIDropDownMenu_GetSelectedID(dropdown) ~= index) then
							AuctionFramePost_PriceModelDropDownItem_SetSelectedID(dropdown, index);
						end
						break;
					end
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_AuctionItem_OnClick(button)
	local frame = button:GetParent();

	-- If the cursor has an item, get it and put it back down in its container.
	local item = AuctioneerUI_GetCursorContainerItem();
	if (item) then
		PickupContainerItem(item.bag, item.slot);
	end

	-- Update the current item displayed
	if (item) then
		local itemLink = GetContainerItemLink(item.bag, item.slot)
		local _, _, _, _, itemName = EnhTooltip.BreakLink(itemLink);
		local _, count = GetContainerItemInfo(item.bag, item.slot);
		frame:SetAuctionItem(item.bag, item.slot, count);
	else
		frame:SetAuctionItem(nil, nil, nil);
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_DurationRadioButton_OnClick(button, index)
	local frame = button:GetParent();
	if (index == 1) then
		Auctioneer.Command.SetFilter('last-auction-duration', 120)
		frame:SetDuration(120);
	elseif (index == 2) then
		Auctioneer.Command.SetFilter('last-auction-duration', 480)
		frame:SetDuration(480);
	else
		Auctioneer.Command.SetFilter('last-auction-duration', 1440)
		frame:SetDuration(1440);
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_StartPrice_OnChanged()
	local frame = this:GetParent():GetParent();
	if (not frame.ignoreStartPriceChange and not updating) then
		frame:ValidateAuction();
	end
	frame.ignoreStartPriceChange = false;
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_BuyoutPrice_OnChanged()
	local frame = this:GetParent():GetParent();
	if (not frame.ignoreBuyoutPriceChange and not frame.updating) then
		local updatePrice = Auctioneer.Command.GetFilter('update-price');
		if (updatePrice) then
			frame.updating = true;
			local discountBidPercent = tonumber(Auctioneer.Command.GetFilterVal('pct-bidmarkdown'));
			local bidPrice = Auctioneer.Statistic.SubtractPercent(frame:GetBuyoutPrice(), discountBidPercent);
			frame:SetStartPrice(bidPrice);
			frame.updating = false;
		end
		frame:ValidateAuction();
	end
	frame.ignoreBuyoutPriceChange = false;
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_StackSize_OnTextChanged()
	local frame = this:GetParent();

	-- Update the stack size displayed on the graphic.
	local itemID = frame:GetItemID();
	local stackSize = frame:GetStackSize();
	if (itemID and stackSize > 1) then
		getglobal(frame:GetName().."AuctionItemCount"):SetText(stackSize);
		getglobal(frame:GetName().."AuctionItemCount"):Show();
	else
		getglobal(frame:GetName().."AuctionItemCount"):Hide();
	end

	-- Update the deposit and validate the auction.
	frame:UpdateDeposit();
	frame:UpdatePriceModels();
	frame:ValidateAuction();
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_StackCount_OnTextChanged()
	local frame = this:GetParent();
	frame:UpdateDeposit();
	frame:ValidateAuction();
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_CreateAuctionButton_OnClick(button)
	local frame = button:GetParent();
	local itemSignature = frame:GetItemSignature();
	local name = frame:GetItemName();
	local startPrice = frame:GetStartPrice();
	local buyoutPrice = frame:GetBuyoutPrice();
	local stackSize = frame:GetStackSize();
	local stackCount = frame:GetStackCount();
	local duration = frame:GetDuration();
	local deposit = frame:GetDeposit();

	-- Check if we should save the pricing information.
	if (frame:GetSavePrice()) then
		local bag, slot, id, rprop, enchant, uniq = EnhTooltip.FindItemInBags(name);
		local itemKey = id..":"..rprop..":"..enchant;
		Auctioneer.Storage.SetFixedPrice(itemKey, startPrice, buyoutPrice, duration, stackSize, Auctioneer.Util.GetAuctionKey());
	end

	-- Post the auction.
	AucPostManager.PostAuction(itemSignature, stackSize, stackCount, startPrice, buyoutPrice, duration);

	-- Clear the current auction item.
	frame:SetAuctionItem(nil, nil, nil);
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_PriceModelDropDown_Initialize()
	local dropdown = this:GetParent();
	local frame = dropdown:GetParent();
	if (frame.prices) then
		for index, value in pairs(frame.prices) do
			local price = value;
			local info = {};
			info.text = price.text;
			info.func = AuctionFramePost_PriceModelDropDownItem_OnClick;
			info.owner = dropdown;
			UIDropDownMenu_AddButton(info);
		end
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_PriceModelDropDownItem_OnClick()
	local index = this:GetID();
	local dropdown = this.owner;
	local frame = dropdown:GetParent();
	if (frame.prices) then
		AuctionFramePost_PriceModelDropDownItem_SetSelectedID(dropdown, index);
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function AuctionFramePost_PriceModelDropDownItem_SetSelectedID(dropdown, index)
	local frame = dropdown:GetParent();
	frame.updating = true;
	if (index) then
		local price = frame.prices[index]
		if (price.note) then
			frame:SetNoteText(price.note, (price.text == _AUCT('UiPriceModelAuctioneer')));
		end
		if (price.buyout) then
			frame:SetBuyoutPrice(price.buyout);
		end
		if (price.bid) then
			frame:SetStartPrice(price.bid);
		end

		if (price.text == _AUCT('UiPriceModelCustom')) then
			getglobal(frame:GetName().."SavePriceText"):Show();
			getglobal(frame:GetName().."SavePriceCheckBox"):Show();
			getglobal(frame:GetName().."PriceModelNoteText"):Hide();
		elseif (price.text == _AUCT('UiPriceModelAuctioneer')) then
			getglobal(frame:GetName().."SavePriceText"):Hide();
			getglobal(frame:GetName().."SavePriceCheckBox"):Hide();
			getglobal(frame:GetName().."PriceModelNoteText"):Show();
		elseif (price.text == _AUCT('UiPriceModelLastSold')) then
			getglobal(frame:GetName().."SavePriceText"):Hide();
			getglobal(frame:GetName().."SavePriceCheckBox"):Hide();
			getglobal(frame:GetName().."PriceModelNoteText"):Show();
		else
			getglobal(frame:GetName().."SavePriceText"):Hide();
			getglobal(frame:GetName().."SavePriceCheckBox"):Hide();
			getglobal(frame:GetName().."PriceModelNoteText"):Hide();
		end

		AuctioneerDropDownMenu_Initialize(dropdown, AuctionFramePost_PriceModelDropDown_Initialize);
		AuctioneerDropDownMenu_SetSelectedID(dropdown, index);
	else
		frame:SetNoteText("");
		frame:SetStartPrice(0);
		frame:SetBuyoutPrice(0);
		getglobal(frame:GetName().."SavePriceText"):Hide();
		getglobal(frame:GetName().."SavePriceCheckBox"):Hide();
		getglobal(frame:GetName().."PriceModelNoteText"):Hide();
		UIDropDownMenu_ClearAll(dropdown);
	end
	frame.updating = false;
	frame:ValidateAuction();
end

-------------------------------------------------------------------------------
-- Calculate the deposit required for the specified item.
-------------------------------------------------------------------------------
function AuctionFramePost_CalculateAuctionDeposit(itemID, count, duration)
	local price = Auctioneer.API.GetVendorSellPrice(itemID);
	if (price) then
		local base = math.floor(count * price * GetAuctionHouseDepositRate() / 100);
		return base * duration / 120;
	end
end

-------------------------------------------------------------------------------
-- Calculate the maximum stack size for an item based on the information returned by GetItemInfo()
-------------------------------------------------------------------------------
function AuctionFramePost_GetMaxStackSize(itemID)
	local _, _, _, _, _, _, itemStackCount = GetItemInfo(itemID);
	return itemStackCount;
end

-------------------------------------------------------------------------------
-- Filter for Auctioneer.Filter.QuerySnapshot that filters on item name.
-------------------------------------------------------------------------------
function AuctionFramePost_ItemSignatureFilter(item, signature)
	local id,rprop,enchant,name,count,min,buyout,uniq = Auctioneer.Core.GetItemSignature(signature);
	if (item == AucPostManager.CreateItemSignature(id, rprop, enchant)) then
		return false;
	end
	return true;
end

-------------------------------------------------------------------------------
-- Returns 1.0 for player auctions and 0.4 for competing auctions
-------------------------------------------------------------------------------
function AuctionFramePost_GetItemAlpha(record)
	if (record.owner ~= UnitName("player")) then
		return 0.4;
	end
	return 1.0;
end

-------------------------------------------------------------------------------
-- Returns the item color for the specified result
-------------------------------------------------------------------------------
function AuctionFramePost_GetItemColor(auction)
	_, _, rarity = GetItemInfo(auction.item);
	if (rarity) then
		return ITEM_QUALITY_COLORS[rarity];
	end
	return { r = 1.0, g = 1.0, b = 1.0 };
end
