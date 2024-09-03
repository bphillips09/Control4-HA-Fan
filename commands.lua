SPEEDS = 9
PERCENTAGE_STEP = 100/SPEEDS
WAS_ON = false

function RFP.BUTTON_ACTION(idBinding, strCommand, tParams)
    if tParams.ACTION == "2" then
        if tParams.BUTTON_ID == "0" then
            SetFanValue(100)
        elseif tParams.BUTTON_ID == "1" then
            SetFanValue(0)
        else
            if WAS_ON then
                SetFanValue(0)
            else
                SetFanValue(100)
            end
        end
    end
end

function RFP.DO_PUSH(idBinding, strCommand, tParams)
    --Do nothing for now
end

function RFP.DO_RELEASE(idBinding, strCommand, tParams)
    --Do nothing for now
end

function RFP.DO_CLICK(idBinding, strCommand, tParams)
    local tParams = {
        ACTION = "2",
        BUTTON_ID = ""
    }
    
    if idBinding == 200 then
        tParams.BUTTON_ID = "0"
    elseif idBinding == 201 then
        tParams.BUTTON_ID = "1"
    elseif idBinding == 202 then
        tParams.BUTTON_ID = "2"
    end

    RFP:BUTTON_ACTION(strCommand, tParams)
end

function SetFanValue(value)
    local target = tonumber(value)

    local fanSpeedServiceCall = {
        domain = "fan",
        service = "turn_on",

        service_data = {
            percentage = target
        },

        target = {
            entity_id = EntityID
        }
    }

    if target == 0 then
        fanSpeedServiceCall.service_data = {}
        fanSpeedServiceCall["service"] = "turn_off"
    end

    local tParams = {
        JSON = JSON:encode(fanSpeedServiceCall)
    }

    C4:SendToProxy(999, "HA_CALL_SERVICE", tParams)
end

function RFP.ON(idBinding, strCommand, tParams)
    local colorServiceCall = {
        domain = "fan",
        service = "turn_on",

        service_data = {
        },

        target = {
            entity_id = EntityID
        }
    }

    tParams = {
        JSON = JSON:encode(colorServiceCall)
    }

    C4:SendToProxy(999, "HA_CALL_SERVICE", tParams)
end

function RFP.OFF(idBinding, strCommand, tParams)
    local colorServiceCall = {
        domain = "fan",
        service = "turn_off",

        service_data = {
        },

        target = {
            entity_id = EntityID
        }
    }

    tParams = {
        JSON = JSON:encode(colorServiceCall)
    }

    C4:SendToProxy(999, "HA_CALL_SERVICE", tParams)
end

function RFP.TOGGLE(idBinding, strCommand, tParams)
    if WAS_ON then
        SetFanValue(0)
    else
        SetFanValue(100)
    end
end

function RFP.CYCLE_SPEED_UP(idBinding, strCommand, tParams)
    local fanSpeedServiceCall = {
        domain = "fan",
        service = "increase_speed",

        service_data = {
        },

        target = {
            entity_id = EntityID
        }
    }

    tParams = {
        JSON = JSON:encode(fanSpeedServiceCall)
    }

    C4:SendToProxy(999, "HA_CALL_SERVICE", tParams)
end

function RFP.CYCLE_SPEED_DOWN(idBinding, strCommand, tParams)
    local fanSpeedServiceCall = {
        domain = "fan",
        service = "decrease_speed",

        service_data = {
        },

        target = {
            entity_id = EntityID
        }
    }

    tParams = {
        JSON = JSON:encode(fanSpeedServiceCall)
    }

    C4:SendToProxy(999, "HA_CALL_SERVICE", tParams)
end

function RFP.SET_SPEED(idBinding, strCommand, tParams)
    local target = tonumber(tParams.SPEED)

    local fanSpeedServiceCall = {
        domain = "fan",
        service = "set_percentage",

        service_data = {
            percentage = target * PERCENTAGE_STEP
        },

        target = {
            entity_id = EntityID
        }
    }

    if target == 0 then
        fanSpeedServiceCall.service_data = {}
        fanSpeedServiceCall["service"] = "turn_off"
    end

    tParams = {
        JSON = JSON:encode(fanSpeedServiceCall)
    }

    C4:SendToProxy(999, "HA_CALL_SERVICE", tParams)
end

function RFP.RECEIEVE_STATE(idBinding, strCommand, tParams)
    local jsonData = JSON:decode(tParams.response)

    local stateData

    if jsonData ~= nil then
        stateData = jsonData
    end

    Parse(stateData)
end

function RFP.RECEIEVE_EVENT(idBinding, strCommand, tParams)
    local jsonData = JSON:decode(tParams.data)

    local eventData

    if jsonData ~= nil then
        eventData = jsonData["event"]["data"]["new_state"]
    end

    Parse(eventData)
end

function Parse(data)
    if data == nil then
        print("NO DATA")
        return
    end

    if data["entity_id"] ~= EntityID then
        return
    end

    if not Connected then
        C4:SendToProxy(5001, 'ONLINE_CHANGED', { STATE = true })
        Connected = true
    end

    local attributes = data["attributes"]
    local state = data["state"]

    if state ~= nil then
        if state == "off" then
            WAS_ON = false
            C4:SendToProxy(5001, 'OFF', {})
        elseif state == "on" then
            WAS_ON = true
            C4:SendToProxy(5001, 'ON', {})
        end
    end

    if attributes == nil then
        return
    end

    local selectedAttribute = attributes["percentage_step"]
    if selectedAttribute ~= nil and PERCENTAGE_STEP ~= tonumber(selectedAttribute) then
        PERCENTAGE_STEP = tonumber(selectedAttribute)
    end

    selectedAttribute = attributes["percentage"]
    if selectedAttribute ~= nil then
        local percentageValue = tonumber(selectedAttribute)
        local control4Value = percentageValue * SPEEDS / 100
        local roundedValue = math.floor(control4Value+0.5)

        C4:SendToProxy(5001, 'CURRENT_SPEED', { SPEED = roundedValue })
    end
end