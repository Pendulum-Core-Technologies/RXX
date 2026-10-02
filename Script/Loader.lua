local httpsv = game:GetService("HttpService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local rs = replicatedStorage:WaitForChild("_RetroStudio")
local remotes = rs.Remotes
local hash = require(rs.HashLib)

-- this loader is forked off of another script called RwtroShey, so you may see similar functions!!!
local blacklistedClasses = {
    ["TouchTransmitter"] = true,
    ["WeldConstraint"] = true,
    ["RotateP"] = true,
    ["Snap"] = true,
    ["UICorner"] = true -- idk if i spelled this right
}

local hint = Instance.new("Hint")
hint.Parent = workspace
hint.Text = "© Pendulum Core 2026" -- funny copyright icon,,,,,

local raw = readfile("game.raw")
local data = httpsv:JSONDecode(raw)

-- functions wow
local function hashgod999()
    local clk = os.clock()
    return hash.md5(("\224\182\158%*\224\182\158"):format(clk)), clk
end

local function sanitize(str)
    if type(str) ~= "string" then return str end
    str = string.gsub(str, "\r\n", "\n")
    str = string.gsub(str, "\r", "\n")
    str = string.gsub(str, "[\0-\8\11\12\14-\31]", "")
    return str
end

local function encodestr(str)
    local result = {}
    for i = 1, #str do
        local b = string.byte(str, i)
        table.insert(result, string.format("\\u%04x", b))
    end
    return table.concat(result)
end

local function encodetable(val)
    if type(val) == "string" then
        return encodestr(val)
    elseif type(val) == "table" then
        local newtab = {}
        for k, v in pairs(val) do
            local newK = (type(k) == "string") and encodestr(k) or k
            newtab[newK] = encodetable(v)
        end
        return newtab
    else
        return val
    end
end

-- leaving this comment here incase i need to find this
local function encodevs(vs)
    if type(vs) ~= "string" or #vs == 0 then
        return '{"\\u0042\\u006c\\u006f\\u0063\\u006b\\u0073":[]}'
    end
    
    local ok, decoded = pcall(function()
        return httpsv:JSONDecode(vs)
    end)
    
    if not ok or type(decoded) ~= "table" then
        return '{"\\u0042\\u006c\\u006f\\u0063\\u006b\\u0073":[]}'
    end
    
    if not decoded.Blocks then
        decoded.Blocks = {}
    end
    
    local escapedTable = encodetable(decoded)
    return httpsv:JSONEncode(escapedTable)
end

local function dcval(val)
    if type(val) == "table" then
        local tag = val[1]
        if tag == "V3" then
            return Vector3.new(val[2], val[3], val[4])
        elseif tag == "C3" then
            return Color3.new(val[2], val[3], val[4])
        elseif tag == "CF" then
            return CFrame.new(table.unpack(val[2]))
        elseif tag == "Enum" then
            local parts = string.split(val[2], ".")
            if #parts == 3 and Enum[parts[2]] then
                return Enum[parts[2]][parts[3]]
            end
        end
    elseif type(val) == "string" then
        return sanitize(val)
    end
    return val
end

local function setproperty(inst, name, val)
    local args = {
        [1] = { [1] = inst },
        [2] = name,
        [3] = val
    }
    pcall(function()
        remotes.ChangeObjectPropertyAndReturn:InvokeServer(table.unpack(args))
    end)
end

local function setattribute(inst, name, val)
    local decoded = dcval(val)
    if name == "VisualSource" then
        decoded = encodevs(decoded)
    end
    
    pcall(function()
        inst:SetAttribute(name, decoded)
    end)
    
    local changeAttrRemote = remotes:FindFirstChild("ChangeObjectAttribute") or remotes:FindFirstChild("SetAttribute") or remotes:FindFirstChild("ChangeAttribute")
    if changeAttrRemote then
        pcall(function()
            if changeAttrRemote:IsA("RemoteFunction") then
                changeAttrRemote:InvokeServer(inst, name, decoded)
            else
                changeAttrRemote:FireServer(inst, name, decoded)
            end
        end)
    end
    
    setproperty(inst, name, decoded)
end

local total = 0
local count = 0

local function countnode(nodes)
    for _, node in ipairs(nodes) do
        if not blacklistedClasses[node.Class] then
            -- epic error below (its probably there because the file is .lua and my editor thinks its an error lol)
            total += 1
        end
        if node.Children then
            countnode(node.Children)
        end
    end
end

countnode(data)

local function bnode(node, parentInst)
    if blacklistedClasses[node.Class] then
        for _, childNode in ipairs(node.Children or {}) do
            bnode(childNode, parentInst)
        end
        return
    end

    local hash, clk = hashgod999()
    local createArgs = {
        [1] = node.Class,
        [2] = parentInst or workspace,
        [3] = hash,
        [4] = clk
    }

    local ok, inst = pcall(function()
        return remotes.CreateObject:InvokeServer(table.unpack(createArgs))
    end)

    if not ok or not inst then
        return
    end

    count += 1
    hint.Text = string.format("Creating objects... (%d/%d)", count, total)

    if node.Name then
        setproperty(inst, "Name", node.Name)
    end

    for prop, val in pairs(node.Props or {}) do
        setproperty(inst, prop, dcval(val))
    end

    for attr, val in pairs(node.Attrs or {}) do
        setattribute(inst, attr, val)
    end

    for _, childNode in ipairs(node.Children or {}) do
        bnode(childNode, inst)
    end
end

for _, itemData in ipairs(data) do
    bnode(itemData, workspace)
end

remotes.ChangeHistoryInteractionRequested:FireServer("AddCheckpoint")
hint.Text = "finished loading?!?!"
task.wait(3)
hint:Destroy()
print("i <3 RBXTest")
