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

if isClient() then
    return
end

local coinTableFilename = "ApocalypseCoinTable.txt"

local ApocalypseCoinTable = {}

local function isSinglePlayer()
    return not isClient() and not isServer()
end


local function getPlayerBySteamID(_id)
    local _players = getOnlinePlayers()
    print("Connected players > ", _players)
    print(type(_players))
    print(_players:size())
    print(_players:get(0))
    for p=0, _players:size(), 1 do
        local player = _players:get(p)
        print("player > ", p, player)
        local _sid = player:getSteamID()
        local _sidString = string.format("%.0f", _sid)
        print("sids > ", _sid, _sidString)
        if _sidString == _id then
            return player
        end
    end
end

local function encodeTable(t)
    local toReturn = "";
    for k, v in pairs(t) do
        toReturn = toReturn .. k .. "=" .. tostring(v) .. ",\n";
    end
    return toReturn
end

local function decodeTable(txt)
    local toReturn = {}
    for k, v in string.gmatch(txt, "(%w+)=(%d+)") do -- If number
        toReturn[k] = tonumber(v);
    end
    for k, v in string.gmatch(txt, "(%w+)=(%d+.%d+)") do -- If decimal number
        toReturn[k] = tonumber(v);
    end
    for k, v in string.gmatch(txt, "(%w+)=([%a%s]+)") do -- If string
        if v == "true" then toReturn[k] = true -- If string is a boolean
        elseif v == "false" then toReturn[k] = false -- If string is a boolean
        else toReturn[k] = v;
        end
    end
    return toReturn
end

function SaveCoinTableFile(t)
    local fileWriterObj = getFileWriter(coinTableFilename, true, false)
    local text = encodeTable(t)
    print("saving to file...")
    fileWriterObj:write(text)
    fileWriterObj:close()
    print("SAVE OK!")
end

function LoadCoinTableFile()
    print("loading coin table")
    local fileReaderObj = getFileReader(coinTableFilename, true)
    local text = "";
    local line = fileReaderObj:readLine()
    while line ~= nil do
        text = text .. line
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()

    if text and text ~= "" then
        local data = decodeTable(text)
        ApocalypseCoinTable = data
        return data
    end
    print("finished loading coin table")
end


if isSinglePlayer() then
    Events.OnGameStart.Add(LoadCoinTableFile)
else
    Events.OnServerStarted.Add(LoadCoinTableFile)
end


local function sendClientTradeData(id)
    local playerCoin = ApocalypseCoinTable[id]
    if isSinglePlayer() then
        triggerEvent("OnServerCommand", "ACOIN_Balance_Update", "true", {playerCoin, })
        -- check is singleplayer
    else
        local player = getPlayerBySteamID(id)
        print("send trade data to ", id, " ", tostring(playerCoin))
        sendServerCommand(player, "ACOIN_Balance_Update", "true", {playerCoin,})
        print("SENT TO player > ", player)
    end
end

-- Add client data to modData
-- args[1] - client user name
-- args[2] - pay to user name
-- args[3] - amount
-- args[4] - timestamp
function OnClientCommandApocalypseShop(module, command, player, args)
    print("client command recieved >> ", module, " ", command)
    if module ~= "ApocalypseTrade" then
        return
    end
    local mod_data = getGameTime():getModData()
    print("MOD DATA > ", tostring(mod_data))

    if command == "pay" then
        print("ApocalypseShop pay player > ",tostring(player))

        if isSinglePlayer() then
            print("ApocalypseShop pay from SteamID > ", tostring(args[1]))
            print("ApocalypseShop pay to > ",tostring(args[2]))
        else
            print("ApocalypseShop pay from SteamID > ", string.format("%.0f", args[1]))
            print("ApocalypseShop pay to > ", string.format("%.0f", args[2]))
        end
        print("ApocalypseShop pay amount > ",tostring(args[3]))

        local _senderId
        local _recieverId
        if isSinglePlayer() then
            _senderId = args[1]
            _recieverId = args[2]
        else
            _senderId = player:getSteamID()
            _senderId = string.format("%.0f", _senderId)
            local _recieverPlayer = getPlayerByOnlineID(args[2])
            _recieverId = _recieverPlayer:getSteamID()
            _recieverId = string.format("%.0f", _recieverId)
        end

        local totalAmount = args[3]
        local currentAmount = ApocalypseCoinTable[_recieverId]
        if currentAmount ~= nil then
            totalAmount = totalAmount + currentAmount
        end

        print("ApocalypseShop user total now > ",tostring(totalAmount))
        print("sender ", _senderId, " reciever ", _recieverId)
        ApocalypseCoinTable[_recieverId] = totalAmount

        sendClientTradeData(_recieverId)
        if _senderId ~= _recieverId then
            sendClientTradeData(_senderId)
        end

        print("MOD DATA > ", tostring(ApocalypseCoinTable))
        SaveCoinTableFile(ApocalypseCoinTable)
    end

    if command == "trade_data_request" then
        if isSinglePlayer() then
            local _username = player:getUsername()
            sendClientTradeData(_username)
        else
            pSID = player:getSteamID()
            pSID = string.format("%.0f", pSID)
            print("SENDING PLAYER TRADE DATA!!")
            sendClientTradeData(pSID)
        end
    end
end

-- add client listener
Events.OnClientCommand.Add(OnClientCommandApocalypseShop)