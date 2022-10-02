-- Mimics mysql.lua provider but in sqlite
sql.Query([[
    CREATE TABLE IF NOT EXISTS pointshop_data (
        sid64 TEXT NOT NULL PRIMARY KEY,
        points INTEGER NOT NULL,
        items TEXT NOT NULL
    );
]])

function PROVIDER:GetData(ply, callback)
    local query = sql.Query("SELECT * FROM pointshop_data WHERE sid64 == " .. sql.SQLStr(ply:SteamID64()))

    if query == nil then
        callback(0, {})
        return
    elseif query == false then
        ErrorNoHalt("PointShop SQL: Query Failed: " .. sql.LastError())
        print(debug.traceback())
        callback(0, {})
        return
    end

    callback(query[1].points, util.JSONToTable(query[1].items) or {})
end

function PROVIDER:SetPoints(ply, points)
    points = points or 0
    local query = sql.Query(string.format([[
        INSERT INTO pointshop_data (sid64, points, items)
        VALUES(%s, %s, "[]")
        ON CONFLICT(sid64) DO UPDATE SET points = %s
    ]], sql.SQLStr(ply:SteamID64()), points, points))

    if query == false then
        ErrorNoHalt("PointShop SQL: Query Failed: " .. sql.LastError())
        print(debug.traceback())
    end
end

function PROVIDER:GivePoints(ply, points)
    points = points or 0
    local query = sql.Query(string.format([[
        INSERT INTO pointshop_data (sid64, points, items)
        VALUES(%s, %s, "[]")
        ON CONFLICT(sid64) DO UPDATE SET points = points + %s
    ]], sql.SQLStr(ply:SteamID64()), points, points))

    if query == false then
        ErrorNoHalt("PointShop SQL: Query Failed: " .. sql.LastError())
        print(debug.traceback())
    end
end

function PROVIDER:TakePoints(ply, points)
    points = points or 0
    local query = sql.Query(string.format([[
        INSERT INTO pointshop_data (sid64, points, items)
        VALUES(%s, %s, "[]")
        ON CONFLICT(sid64) DO UPDATE SET points = points - %s
    ]], sql.SQLStr(ply:SteamID64()), points, points))

    if query == false then
        ErrorNoHalt("PointShop SQL: Query Failed: " .. sql.LastError())
        print(debug.traceback())
    end
end

function PROVIDER:GiveItem(ply, item_id, data)
    local tmp = table.Copy(ply.PS_Items)
    tmp[item_id] = data
    local items = sql.SQLStr(util.TableToJSON(tmp))

    local query = sql.Query(string.format([[
        INSERT INTO pointshop_data (sid64, points, items)
        VALUES(%s, 0, %s)
        ON CONFLICT(sid64) DO UPDATE SET items = %s
    ]], sql.SQLStr(ply:SteamID64()), items, items))

    if query == false then
        ErrorNoHalt("PointShop SQL: Query Failed: " .. sql.LastError())
        print(debug.traceback())
    end
end

function PROVIDER:TakeItem(ply, item_id)
    local tmp = table.Copy(ply.PS_Items)
    tmp[item_id] = nil
    local items = sql.SQLStr(util.TableToJSON(tmp))

    local query = sql.Query(string.format([[
        INSERT INTO pointshop_data (sid64, points, items)
        VALUES(%s, 0, %s)
        ON CONFLICT(sid64) DO UPDATE SET items = %s
    ]], sql.SQLStr(ply:SteamID64()), items, items))

    if query == false then
        ErrorNoHalt("PointShop SQL: Query Failed: " .. sql.LastError())
        print(debug.traceback())
    end
end

function PROVIDER:SaveItem(ply, item_id, data)
    self:GiveItem(ply, item_id, data)
end

function PROVIDER:SetData(ply, points, items)
    local tmp = table.Copy(ply.PS_Items)
    tmp[item_id] = nil

    local query = sql.Query(string.format([[
        REPLACE INTO pointshop_data VALUES(%s, %s, %s)
    ]], sql.SQLStr(ply:SteamID64()), points or 0, sql.SQLStr(util.TableToJSON(tmp))))

    if query == false then
        ErrorNoHalt("PointShop SQL: Query Failed: " .. sql.LastError())
        print(debug.traceback())
    end
end