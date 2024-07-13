--All available dialog voice record types
-- Alarm
-- Attack
-- Flee
-- Hello
-- Hit
-- Idle
-- Intruder
-- Thief

local gutils = require("scripts/gutils")
local customVoiceRecords = require("scripts/custom_voice_records")

local types = require("openmw.types")
local core = require("openmw.core")

local module = {}

local function noSpecificFilters(info)
    -- I probably can check the disposition as well for the "filterActorDisposition"
    local specificFilters = { "filterActorClass", "filterActorFaction", "filterActorId",
        "filterPlayerCell", "filterPlayerFaction", "isQuestFinished", "isQuestName", "isQuestRestart", "questStage" }
    local noFilters = true
    for _, filter in ipairs(specificFilters) do
        if info[filter] then
            noFilters = false
            break
        end
    end
    return noFilters
end

local function beastCheck(info, isBeast)
    -- Author: Mostly ChatGPT 2024
    local fileName = info.sound:match("[^/]+$")
    return isBeast or not fileName:match("^b")
end

local function findRelevantInfos(recordType, race, gender, isBeast)
    local fittingInfos = {}
    local records = core.dialogue.voice.records[recordType]
    if not records then return fittingInfos end

    --print("Looking for ", recordType, " voice record type")

    for _, voiceInfo in pairs(records.infos) do
        -- Need to also filter by enemy race and also accept those that are nil?
        if voiceInfo.sound and voiceInfo.filterActorRace == race and voiceInfo.filterActorGender == gender and noSpecificFilters(voiceInfo) and beastCheck(voiceInfo, isBeast) then
            --print(gutils.dialogRecordInfoToString(voiceInfo))
            table.insert(fittingInfos, voiceInfo)
        end
    end

    return fittingInfos
end

local lastPickedIndices = {}


-- TO DO: introduce vanilla lines into the custom ones and add voice target gender filter
local function say(actor, targetActor, recordType, force)
    if not actor then 
        error("Say was called without an actor")
    end
    
    local race = nil
    local gender = nil
    local isBeast = false
    local targetGender = nil

    if types.NPC.objectIsInstance(actor) then
        local npc = types.NPC.record(actor)
        if npc.isMale then
            gender = "male"
        else
            gender = "female"
        end
        race = npc.race
        isBeast = types.NPC.isWerewolf(actor)
    end

    if targetActor and types.NPC.objectIsInstance(targetActor) then
        if not types.NPC.record(targetActor).isMale then
            targetGender = "female"
        else
            targetGender = "male"
        end
    end

    if not types.NPC.objectIsInstance(actor) or types.Actor.isDead(actor) then return false end
    if not force and core.sound.isSayActive(actor) then return false end


    local fittingInfos = {}
    fittingInfos = customVoiceRecords.findRelevantInfos(recordType, race, gender, isBeast)
    if #fittingInfos == 0 then fittingInfos = findRelevantInfos(recordType, race, gender, isBeast) end

    -- Pick random voice file ensuring that same line doesnt repeat twice
    -- print("Fitting amount of voicelines: ", #fittingInfos)
    local lastPickedIndex = lastPickedIndices[recordType]
    local availableIndices = {}
    for i, info in ipairs(fittingInfos) do
        if info.targetGender and info.targetGender ~= targetGender then goto continue end
        if i == lastPickedIndex and #fittingInfos > 1 then goto continue end

        table.insert(availableIndices, i)
        ::continue::
    end

    if #availableIndices == 0 then
        gutils.print(
            "WARNING: No voice records of type " ..
            recordType ..
            " were found to fit " .. tostring(race) .. " " .. tostring(gender) .. " character.", 0)
        -- Not saying is not that bad, just ignore it
        return false
    end

    -- Do something if available
    local pickedIndex = availableIndices[math.random(1, #availableIndices)]
    lastPickedIndices[recordType] = pickedIndex

    local voiceInfo = fittingInfos[pickedIndex]
    -- print("Voiceline to use: ", voiceInfo.sound, voiceInfo.text)

    -- Finally say it!
    core.sound.say(voiceInfo.sound, actor, voiceInfo.text)
    return true
end

module.say = say

return module
