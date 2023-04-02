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

local pairs = pairs

local coinTableFilename = "ApocalypseCoinTable.txt"

local ApocalypseCoinTable = {}

local function isSinglePlayer()
    return not isClient() and not isServer()
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


local function sendACoinBalanceUpdate(id)
    local playerCoin = ApocalypseCoinTable[id]
    if isSinglePlayer() then
        triggerEvent("OnServerCommand", "ACOIN_Balance_Update", "true", {playerCoin, })
        -- check is singleplayer
    else
        sendServerCommand(player, "ACOIN_Balance_Update", "true", {playerCoin,})
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
        print("ApocalypseShop pay from > ",tostring(args[1]))
        print("ApocalypseShop pay to > ",tostring(args[2]))
        print("ApocalypseShop pay amount > ",tostring(args[3]))
        local totalAmount = args[3]
        print("ApocalypseShop user total now > ",tostring(totalAmount))
        if isSinglePlayer() then
            local currentAmount = ApocalypseCoinTable[args[2]]
            if currentAmount ~= nil then
                totalAmount = totalAmount + currentAmount
            end
            ApocalypseCoinTable[args[2]] = totalAmount
            sendACoinBalanceUpdate(args[1])
            sendACoinBalanceUpdate(args[2])
        else
            local _senderId = player:getSteamID()
            local _recieverPlayer = getPlayerFromUsername(args[2])
            local _recieverId = _recieverPlayer:getSteamID()
            print("MP sender ID  >> ", _senderId)
            print("MP reciever ID  >> ", _recieverId)
            local currentAmount = ApocalypseCoinTable[_recieverId]
            if currentAmount ~= nil then
                totalAmount = totalAmount + currentAmount
            end
            ApocalypseCoinTable[_recieverId] = totalAmount
            sendACoinBalanceUpdate(_senderId)
            sendACoinBalanceUpdate(_recieverId)
        end
        mod_data = ApocalypseCoinTable
        local data = mod_data[args[2]]
        print("MOD DATA > ", tostring(mod_data))
        SaveCoinTableFile(ApocalypseCoinTable)
    end

    if command == "balance" then
        if isSinglePlayer() then
            local _username = player:getUsername()
            sendACoinBalanceUpdate(_username)
        else
            local _username = player:getUsername()
            sendACoinBalanceUpdate(player.steamID)
        end
    end
end

-- add client listener
Events.OnClientCommand.Add(OnClientCommandApocalypseShop)