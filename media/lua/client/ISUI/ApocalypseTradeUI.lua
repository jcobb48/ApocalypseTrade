--*****************************************************     
--**  LICENSE
--**     
--**  This program is free software: you can redistribute it and/or modify it under the terms 
--**  of the GNU General Public License as published by the Free Software Foundation, 
--**  either version 3 of the License, or any later version.
--**  
--**  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
--**  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
--**  See the GNU General Public License for more details.https://www.gnu.org/licenses/
--**  
--**  You should have received a copy of the GNU General Public License along with this program. 
--**  If not, see <https://www.gnu.org/licenses/>.
--**  
--**  
--**  Joaquin D. Gomez | inhousegames.dev      
--*****************************************************

local UI
local clientACoins = 0


local function isSinglePlayer()
    return not isClient() and not isServer()
end

local function getPlayerByName(_name)
    local _players = getOnlinePlayers()
    print("Connected players > ", _players)
    for i, player in ipairs(_players) do
        local _u = player:getUsername()
        if _u == _name then
            return player
        end
    end
end

function SendPayment(to, amount)
    local _player
    local _args
    if isSinglePlayer() then
        print("SinglePlayer -- SEND PAYMENT")
        _player = getPlayer()
        _args = { _player:getUsername(), to, amount }
    else
        print("MP SERVER -- SEND PAYMENT")
        _player = getPlayer()
        local _steamID = _player:getSteamID()
        _args = { _steamID, to, amount }
    end
    sendClientCommand("ApocalypseTrade", "pay", _args)
    print("sending payment client command...")
end


function RequestClientTradeData()
    sendClientCommand("ApocalypseTrade", "trade_data_request", {})
end

Events.EveryOneMinute.Add(RequestClientTradeData)

function PaymentPressed()
    local selectedPlayer = UI["playerSelector"]:getValue()
    print("player > ", selectedPlayer)
    local _thisUser = getPlayer():getUsername()
    local _onlineID
    if isSinglePlayer() then
        _onlineID = _thisUser
    else
        if _thisUser == selectedPlayer then
            _onlineID = getPlayer():getOnlineID()
        else
            local player = getPlayerByName(selectedPlayer)
            print("player object > ", player)
            _onlineID = player:getOnlineID()
        end
    end
    SendPayment(_onlineID, 1000)
end


function OnServerCommandApocalypseTradeClient(module, command, arguments)
    print("server command > ", module, command)
    if module ~= "ACOIN_Balance_Update" then
        return
    end
    clientACoins = arguments[1]
    UI["coinCount"]:setText(tostring(clientACoins))
end

Events.OnServerCommand.Add(OnServerCommandApocalypseTradeClient)

local function updateUserList()
    if isSinglePlayer() then
        local name = getPlayer():getUsername()
        UI["playerSelector"]:setItems({ name })
    else
        print("adding users")

        local _playerUsername = getPlayer():getUsername()
        local _playerNames = { _playerUsername }
        local _players = getConnectedPlayers()
        print(_players)
        if _players ~= nil then
            local count = 0
            for _ in ipairs(_players) do count = count + 1 end
            print("count: ", count)
            for i, _player in ipairs(_players) do
                local _pusername = _player:getUsername()
                print("user added ", _pusername)
                _playerNames.insert(i+1, _pusername)
            end
        end

        UI["playerSelector"]:setItems(_playerNames)
    end
end

function CreateUI()
    UI = NewUI();
    UI:setTitle("All elements UI test")
    UI:setColumnWidthPixel(1, 100);
    
    UI:addText("", "Apocalypse Shop", "Title", "Center")
    UI:setLineHeightPixel(100);
    UI:nextLine();


    UI:addText("", "ACoins:", _, "Center");
    UI:addText("coinCount", tostring(clientACoins), _, "Center");
    UI:nextLine();

    UI:addComboBox("playerSelector", {})
    updateUserList()


    UI:nextLine();
    UI:addButton("payButton", "Test Payment", PaymentPressed)
    UI:nextLine()

    UI:setBorderToAllElements(true)


    UI:saveLayout()
    UI:close()


end


-- Create the UI with all element exept image and image button
function createUI2()
    UI = NewUI();
    UI:setTitle("All elements UI test")
    UI:setColumnWidthPixel(1, 100);

    UI:addText("", "Apocalypse Shop", "Title", "Center");
    UI:setLineHeightPixel(100);
    UI:nextLine();


    UI:addText("", "ACoins:", _, "Center");
    UI:addText("", "0", _, "Center");
    UI:nextLine();

    UI:addText("", "Rich text:", _, "Center");
    UI:addRichText("", text1);
    UI:nextLine();

    UI:addText("", "Progress bar:", _, "Center");
    UI:addProgressBar("pb1", 0, 0, 100);
    UI:nextLine();


    UI:addButton("", "", _);
    UI:nextLine();

    UI:addText("", "Tick box:", _, "Center");
    UI:addTickBox("t1");
    UI:nextLine();

    UI:addText("", "Entry:", _, "Center");
    UI:addEntry("e1", "");
    UI:nextLine();

    UI:addText("", "Combo:", _, "Center")
    UI:addComboBox("c1", items1)
    UI:nextLine()

    UI:addText("", "ScrollList:", _, "Center")
    UI:addScrollList("s1", items2)

    UI:setBorderToAllElements(true)


    UI:saveLayout()
end

function OpenUIMenu(key)
    print("key ", key)
    if key ~= 24 then return end
    print("O pressed")
    RequestClientTradeData()
    updateUserList()
    UI:open()
end


--Events.OnGameStart.Add(CreateUI)
Events.OnCreateUI.Add(CreateUI)
Events.OnKeyPressed.Add(OpenUIMenu)