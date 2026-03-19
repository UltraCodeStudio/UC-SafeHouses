local confirmed
local heading

function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

function DrawPropAxes(prop)
    local propForward, propRight, propUp, propCoords = GetEntityMatrix(prop)

    local propXAxisEnd = propCoords + propRight * 1.0
    local propYAxisEnd = propCoords + propForward * 1.0
    local propZAxisEnd = propCoords + propUp * 1.0

    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propXAxisEnd.x, propXAxisEnd.y, propXAxisEnd.z, 255, 0, 0, 255)
    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propYAxisEnd.x, propYAxisEnd.y, propYAxisEnd.z, 0, 255, 0, 255)
    DrawLine(propCoords.x, propCoords.y, propCoords.z + 0.1, propZAxisEnd.x, propZAxisEnd.y, propZAxisEnd.z, 0, 0, 255, 255)
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return b, c, e
end

local function DrawControlText(text, x, y)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.35)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

---@param previewObject number
---@param extraPadding number
---@return boolean canPlace, number? blockingObject
local function canPlaceInInterior(previewObject, extraPadding)
    local coords = GetEntityCoords(previewObject)
    local objects = lib.getNearbyObjects(coords, 3.0)

    local minA, maxA = GetModelDimensions(GetEntityModel(previewObject))
    local sizeA = maxA - minA

    for i = 1, #objects do
        local obj = objects[i].object

        if obj ~= previewObject and DoesEntityExist(obj) then
            local minB, maxB = GetModelDimensions(GetEntityModel(obj))
            local sizeB = maxB - minB

            local objCoords = GetEntityCoords(obj)
            local dist = #(coords - objCoords)

            local threshold = (math.max(sizeA.x, sizeA.y) * 0.5) +
                (math.max(sizeB.x, sizeB.y) * 0.5) +
                (extraPadding or 0.05)

            if dist < threshold then
                return false, obj
            end
        end
    end

    return true, nil
end

---@param prop string | number
---@return vector3? coords, number? heading
function PlaceProp(prop)
    if not prop then
        print("^1[ERROR]^7 Invalid Prop")
        return nil, nil
    end

    local p = promise.new()
    local model = joaat(prop)
    local heading = 0.0

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local hit, coords, entity

    while not hit do
        hit, coords, entity = RayCastGamePlayCamera(1000.0)
        Wait(0)
    end

    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, true)
    
    CreateThread(function()
        local resolved = false
        
        while not resolved do
            hit, coords, entity = RayCastGamePlayCamera(1000.0)
            SetEntityDrawOutline(obj, true)
            local canPlace, blocking = canPlaceInInterior(obj, 0.03)
            print(canPlace)
            if not canPlace then
                SetEntityDrawOutlineColor(255,0,0,255)
            else
                SetEntityDrawOutlineColor(0,255,0,255)
            end
            SetEntityCollision(obj, false, false)
            SetEntityCoordsNoOffset(obj, coords.x, coords.y, coords.z, false, false, false, true)
            FreezeEntityPosition(obj, true)
            
            SetEntityAlpha(obj, 100, false)

            if IsControlPressed(0, 174) then
                heading = heading + 1.0
            elseif IsControlPressed(0, 175) then
                heading = heading - 1.0
            end

            exports.ox_lib:showTextUI(
                "Press **[Left Arrow]** to Rotate Left\n" ..
                "Press **[Right Arrow]** to Rotate Right\n" ..
                "Press **[E]** to Confirm Placement\n" ..
                "Press **[Backspace]** to Cancel Placement",
                { position = "bottom-center" }
            )

            if heading > 360.0 then
                heading = 0.0
            elseif heading < 0.0 then
                heading = 360.0
            end

            SetEntityHeading(obj, heading)

            if IsControlJustPressed(0, 38) then
                resolved = true
                exports.ox_lib:hideTextUI()
                DeleteObject(obj)
                p:resolve({
                    coords = coords,
                    heading = heading,
                    cancelled = false
                })
            elseif IsControlJustPressed(0, 177) then
                resolved = true
                exports.ox_lib:hideTextUI()
                DeleteObject(obj)
                p:resolve({
                    coords = nil,
                    heading = nil,
                    cancelled = true
                })
            end

            Wait(0)
        end
    end)
    SetEntityDrawOutline(obj, false)
    local result = Citizen.Await(p)

    if result.cancelled then
        return nil, nil
    end

    return result.coords, result.heading
end
























