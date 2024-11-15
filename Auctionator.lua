
local AuctionatorVersion = "1.0.0-Vanilla";
local AuctionatorAuthor  = "Zirco; Vanilla adaptation by Nimeral";


local AuctionatorLoaded = false;

local recommendElements		= {};
local auctionsTabElements	= {};


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
local currentAuctionStackSize = 1;
local currentAuctionTexture = nil;

local currentAuctionClass;
local currentAuctionSubclass;

local auctionator_last_buyoutprice = 1;
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

    if (string.lower (arg1) == "blizzard_auctionui") then			
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
        --auctionsTabElements[16] = AuctionFrameAuctions;
        --auctionsTabElements[16] = AuctionFrame;

        recommendElements[1] = getglobal ("Auctionator_Recommend_Text");
        recommendElements[2] = getglobal ("Auctionator_RecommendPerItem_Text");
        recommendElements[3] = getglobal ("Auctionator_RecommendPerItem_Price");
        recommendElements[4] = getglobal ("Auctionator_RecommendPerStack_Text");
        recommendElements[5] = getglobal ("Auctionator_RecommendPerStack_Price");
        recommendElements[6] = getglobal ("Auctionator_Recommend_Basis_Text");
        recommendElements[7] = getglobal ("Auctionator_RecommendItem_Tex");
    end
end


-----------------------------------------


function Auctionator_AuctionFrameTab_OnClick (index)

    if ( not index ) then
        index = this:GetID();
    end

    getglobal("Auctionator_Sell_Template"):Hide();
    
        if (index == 3) then		
        Auctionator_ShowElems (auctionsTabElements);
    end
    
    if (index ~= AUCTIONATOR_TAB_INDEX) then
        auctionator_orig_AuctionFrameTab_OnClick (index);
        auctionator_last_item_posted = nil;
        forceMsgAreaUpdate = true;
        
    elseif (index == AUCTIONATOR_TAB_INDEX) then
        AuctionFrameTab_OnClick(3);
        
        
        PanelTemplates_SetTab(AuctionFrame, AUCTIONATOR_TAB_INDEX);
        
        Auctionator_HideElems (auctionsTabElements);
        
        Auctionator_HideElems (recommendElements);
        
        getglobal("Auctionator_Sell_Template"):Show();
        AuctionFrame:EnableMouse(false);
        
        OpenAllBags(true);
        
        if (currentAuctionItemName ~= "") then
            Auctionator_CalcBaseData();
        end
    
    end

end

-----------------------------------------

local bagID = nil;
local slotID = nil;

function Auctionator_ContainerFrameItemButton_OnClick (button)
    if (button == "RightButton"
        and	AuctionFrame:IsShown()
    )
    then
     if (PanelTemplates_GetSelectedTab (AuctionFrame) ~= AUCTIONATOR_TAB_INDEX) then
    
        AuctionFrameTab_OnClick (AUCTIONATOR_TAB_INDEX);
    
    end 
        bagID = this:GetParent():GetID();  
        slotID = this:GetID();             
           
        PickupContainerItem(bagID, slotID);
        ClickAuctionSellItemButton();
        ClearCursor();

   else 
         return auctionator_orig_ContainerFrameItemButton_OnClick (button);
    end;
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
    
    auctionator_orig_ContainerFrameItemButton_OnClick = ContainerFrameItemButton_OnClick;
    ContainerFrameItemButton_OnClick = Auctionator_ContainerFrameItemButton_OnClick;
    
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
        
    local n = AuctionFrame.numTabs+1;
    
    AUCTIONATOR_TAB_INDEX = n;

    local framename = "AuctionFrameTab"..n;

    local frame = CreateFrame("Button", framename, AuctionFrame, "AuctionTabTemplate");

    setglobal("AuctionFrameTab4", frame);
    frame:SetID(n);
    --frame:SetParent("FriendsFrameTabTemplate");
    frame:SetText("Auctionator");
    frame:SetPoint("LEFT", getglobal("AuctionFrameTab"..n-1), "RIGHT", -8, 0);
    frame:Show();

    --Attempting to index local 'frame' now
    
    -- Configure the tab button.
    --setglobal(AuctionFrameTab4, AuctionFrameTab4);
    
    --tabButton:SetPoint("TOPLEFT", getglobal("AuctionFrameTab"..(tabIndex - 1)):GetName(), "TOPRIGHT", -8, 0);
    --tabButton:SetID(tabIndex);
    
    PanelTemplates_SetNumTabs (AuctionFrame, n);
    PanelTemplates_EnableTab  (AuctionFrame, n);
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
        return;
    end
    
    if (PanelTemplates_GetSelectedTab (AuctionFrame) ~= AUCTIONATOR_TAB_INDEX) then
        return;
    end;
    
    processing_state = KM_ANALYZING;
    
    local numBatchAuctions, totalAuctions = GetNumAuctionItems("list");
    
    --chatmsg("auctions:"..numBatchAuctions.." out of  "..totalAuctions)

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
        return;
    end;
   
    ----- Condense the scan data into a table that has only a single entry per stacksize/price combo

    local i,sd;
    local conddata = {};

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

    --AuctionFrame:setTopLevel (false);
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

function Auctionator_OnAuctionHouseClosed()

    AuctionatorDescriptionFrame:Hide();
    Auctionator_Sell_Template:Hide();
    
end

-----------------------------------------
local splitQueue = {}             -- Queue for splitting items
local auctionQueue = {}           -- Queue for creating auctions for split items
local splitQueueCount = 0         -- Manually track the split queue size
local auctionQueueCount = 0       -- Manually track the auction creation queue size
local splitProcessing = false     -- Flag to track if splitting is in progress
local auctionProcessing = false   -- Flag to track if auction creation is in progress
local splitPostPrice = 0
local itemInAH = false
function Auctionator_OnUpdate(self, elapsed)
    Auctionator_Post(self, elapsed)

    if not splitProcessing || not auctionProcessing and not itemInAH then
        Auctionator_Idle(self, elapsed)
    end
end

function Auctionator_Idle(self, elapsed) 
    if (self.TimeSinceLastUpdate == nil) then 
        self.TimeSinceLastUpdate = 0; 
    end; 
    self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + 0.1;--elapsed; 
     
    if (AuctionatorMessage == nil) then 
        return; 
    end; 
     
    if (self.NumIdles == nil) then 
        self.NumIdles = 0; 
    end; 
    self.NumIdles = self.NumIdles + 1;
    
    if (self.TimeSinceLastUpdate > 0.25) then
    
        self.TimeSinceLastUpdate = 0;

        ------- check whether to send a new auction query to get the next page -------

        if (processing_state == KM_PREQUERY) then
            if (CanSendAuctionQuery()) then
                processing_state = KM_IN_QUERY;
                QueryAuctionItems (currentAuctionItemName, "", "", nil, currentAuctionClass, currentAuctionSubclass, current_page, nil, nil);
                processing_state = KM_POSTQUERY;
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

            scandata = {};
        end

    end
end

function Auctionator_Post(self, elapsed)

    if (self.TimeSinceLastPost == nil) then 
        self.TimeSinceLastPost = 0; 
    end; 
    self.TimeSinceLastPost = self.TimeSinceLastPost + 0.1;--elapsed; 
     
    if (AuctionatorMessage == nil) then 
        return; 
    end; 
     
    if (self.NumIdlePosts == nil) then 
        self.NumIdlePosts = 0; 
    end; 
    self.NumIdlePosts = self.NumIdlePosts + 1;
    
    if (self.TimeSinceLastPost > 3) then
    
        self.TimeSinceLastPost = 0;

        if itemInAH and not splitProcessing and not auctionProcessing then
            chatmsg("Creating")
            local auctionItemName, auctionTexture, auctionCount = GetAuctionSellItemInfo()
            if auctionItemName then
         
                local minBid = round(splitPostPrice * 0.95)
                local buyoutPrice = round(splitPostPrice)
                local runTime = 2 

                print("Attempting to start auction...")
                print("Item: " .. auctionItemName .. ", Stack Size: " .. tostring(auctionCount))
                print("minBid: " .. tostring(minBid) .. ", buyoutPrice: " .. tostring(buyoutPrice) .. ", runTime: " .. tostring(runTime))

                if CanSendAuctionQuery() then
                    if StartAuction(1, 1, 2) then
                        print("Auction created for item: " .. auctionItemName)
                    else
                        print("Failed to start auction for item: " .. auctionItemName)
                    end
                else
                    print("Cannot send auction query at this time")
                    return
                end
            end
            itemInAH = false
        elseif not splitProcessing and auctionQueueCount > 0 and not auctionProcessing then
            auctionProcessing = true
            chatmsg("Moving")
        
            local operation = table.remove(auctionQueue, 1)
            auctionQueueCount = auctionQueueCount - 1
            PickupContainerItem(operation[1], operation[2]);
            ClickAuctionSellItemButton();
            ClearCursor();

            itemInAH = true
            auctionProcessing = false
        elseif not auctionProcessing and splitQueueCount > 0 and not splitProcessing then
            splitProcessing = true
           chatmsg("Splitting")
            Auctionator_ProcessSplitQueue()
        
            splitProcessing = false
        end
    end
end

function Auctionator_QueueSplit(itemBag, itemSlot, freeSlots, stackSize)
    for i = 1, stackSize do
        splitQueueCount = splitQueueCount + 1
        chatmsg("inserting to split queue")
        table.insert(splitQueue, {itemBag = itemBag, itemSlot = itemSlot, freeBag = freeSlots[i][1], freeSlot = freeSlots[i][2]})
    end
end

-- Function to process the split queue
function Auctionator_ProcessSplitQueue()
    if splitQueueCount == 0 then
        splitProcessing = false
        return
    end

    local operation = table.remove(splitQueue, 1)
    splitQueueCount = splitQueueCount - 1
    
    SplitContainerItem(operation.itemBag, operation.itemSlot, 1)
    PickupContainerItem(operation.freeBag, operation.freeSlot)
    
    table.insert(auctionQueue, {operation.freeBag, operation.freeSlot})
    auctionQueueCount = auctionQueueCount + 1
    
    currentItemBeingPosted = operation
end

function Auctionator_SplitStack(itemBag, itemSlot, stackSize)
    local freeSlots, freeSlotCount = Auctionator_GetFreeBagSlots()

    if freeSlotCount < stackSize then
        DEFAULT_CHAT_FRAME:AddMessage("Not enough free bag slots to split the stack!", 1, 0, 0)
        return false
    end

    Auctionator_QueueSplit(itemBag, itemSlot, freeSlots, stackSize)
    return true
end


function Auctionator_GetFreeBagSlots()
    local freeSlots = {} -- Initialize table
    local count = 0      -- Manual counter

    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            if not GetContainerItemInfo(bag, slot) then
                count = count + 1
                freeSlots[count] = {bag, slot} -- Store bag and slot as a pair
            end
        end
    end

    return freeSlots, count -- Return both the table and the count
end

function Auctionator_PostStackIndividually()
    local itemName, stackSize, bag, slot = Auctionator_GetSelectedItem()
    if not itemName then
        DEFAULT_CHAT_FRAME:AddMessage("No item selected!", 1, 0, 0)
        return
    end

    splitPostPrice = basedata.itemPrice

    Auctionator_SplitStack(bag, slot, stackSize)

    ClickAuctionSellItemButton()
    ClearCursor()
end

function Auctionator_GetSelectedItem()
    local bag, slot = Auctionator_GetBagSlot() 
    if not bag or not slot then return nil end

    local itemName, stackSize, _ = GetContainerItemInfo(bag, slot)
    return itemName, stackSize, bag, slot
end

function Auctionator_GetBagSlot()
    return bagID, slotID
end

function Auctionator_GetBidPrice()
    return basedata.itemPrice * 0.95
end

function Auctionator_GetBuyoutPrice()
    return basedata.itemPrice
end

function Auctionator_CreateSingleAuctions()
    if CanSendAuctionQuery() then
        if StartAuction(100, 102, 2) then
            print("Auction created for item: ")
        else
            print("Failed to start auction for item: ")
        end
    else
        print("Cannot send auction query at this time")
        return
    end
    --Auctionator_PostStackIndividually()
end

local function AuctionErrorEvent(self, event, msg)
    print("Auction Error:", msg)
end

local auctionErrorFrame = CreateFrame("Frame")
auctionErrorFrame:RegisterEvent("UI_ERROR_MESSAGE")
auctionErrorFrame:SetScript("OnEvent", AuctionErrorEvent)
    
-----------------------------------------

function Auctionator_ScrollbarUpdate()

    local line;				-- 1 through 12 of our window to scroll
    local dataOffset;		-- an index into our data calculated from the scroll offset

    local numrows = table.getn (sorteddata);

    if (numrows == nil) then
        numrows = 0
    end
        
    FauxScrollFrame_Update (AuctionatorScrollFrame, numrows, 10, 16);

    for line = 1,10 do

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
   
    basedata = sorteddata[entryIndex];

    Auctionator_UpdateRecommendation();

    PlaySound ("igMainMenuOptionCheckBoxOn");
end

-----------------------------------------

function AuctionatorMoneyFrame_OnLoad()

    this.small = 1;
    SmallMoneyFrame_OnLoad();
    MoneyFrame_SetType("AUCTION");
end

function Auctionator_CheckAHOpen()
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        DEFAULT_CHAT_FRAME:AddMessage("The Auction House is not open!", 1, 0, 0)
        return false
    end
    return true
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





