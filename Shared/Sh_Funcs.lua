

function table_count(ta)
    local count = 0
    for k, v in pairs(ta) do count = count + 1 end
    return count
end

function table_last_count(ta)
    local count = 0
    for i, v in ipairs(ta) do
        if v then
            count = count + 1
        end
    end
    return count
end

function GetCharacterFromId(id)
    for k, v in pairs(Character.GetPairs()) do
        if v:GetID() == id then
            return v
        end
    end
end

function split_str(str,sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

function clamp(val, minval, maxval, valadded)
    if val + valadded <= maxval then
        if val + valadded >= minval then
            val = val + valadded
        else
            val = minval
        end
    else
        val = maxval
    end
    return val
end
