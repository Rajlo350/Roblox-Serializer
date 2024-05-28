local module = {
	meshFolder = nil
}

local properties = {
	Part = {"Name", "Size", "Color", "Transparency", "CFrame", "CanCollide", "Anchored", "Material", "Shape"},
	MeshPart = {"Name", "MeshId", "CFrame", "Size", "Transparency", "BrickColor", "CanCollide", "Anchored", "Material"},
	Decal = {"Name", "Texture", "Transparency", "Face", "Color3"},
}

local overriddenProperties = {"CFrame", "Position", "Color", "Size", "Material", "Shape"}
-- have to be converted to string for json encoding to work properly.

function module.serialize(object: Instance)
	local children = object:GetChildren()
	local result = {}

	local function getItem(item: Instance)
		local propertyType = properties[item.ClassName]
		local itemObject = {itemType = item.ClassName, props = {}, decals = {}}
		if item:IsA("Model") then
			itemObject.props["pivot"] = tostring(item:GetPivot())
		end
		if propertyType then
			for _, property in pairs(propertyType) do
				local newProperty = item[property]
				itemObject.props[property] = newProperty
				if table.find(overriddenProperties, property) then
					itemObject.props[property] = tostring(newProperty)
				end
			end
		end
		local function getDecalItem(decal)
			local result = {}
			for _, prop in pairs(properties.Decal) do
				if prop == "Face" then
					result[prop] = tostring(decal[prop])
					-- doesn't use string on value for unknown reason.
					continue
				end
				result[prop] = decal[prop]
			end
			return result
		end
		local function getDecals()
			local children = item:GetChildren()
			local decals = {}
			for _, child in pairs(children) do
				if not child:IsA("Decal") then
					continue
				end
				local decalItem = getDecalItem(child)
				table.insert(decals, decalItem)
			end
			return decals
		end
		local function insertDecalItems()
			local items = {}
			local decals = getDecals()
			for _, decal in pairs(decals) do
				table.insert(itemObject.decals, decal)
			end
			return items
		end
		insertDecalItems()
		return itemObject
	end
	
	
	local function getModel(model)
		local parts = model:GetChildren()
		local itemObject = {itemType = "Model", Name = model.Name, pivot = tostring(model:GetPivot()), parts = {}}
		for _, part in parts do
			if not part:IsA("BasePart") then
				continue
			end
			table.insert(itemObject.parts, getItem(part))
		end
		return itemObject
	end
	
	for _,item in pairs(children) do
		if item:IsA("Model") then
			table.insert(result, getModel(item))
			continue
		end
		table.insert(result, getItem(item))
	end
	return result
end

function module.construct(serialized: {}, containerName)
	local container = Instance.new("Model")
	container.Name = containerName or "generated_container"
	
	-- will find mesh in specified collection
	local function getMesh(meshId)
		local meshResult = Instance.new("Part")
		if not module.meshFolder then
			return meshResult
		end
		local meshes = module.meshFolder:GetChildren()
		for _, mesh in pairs(meshes) do
			if mesh.MeshId ~= meshId then
				continue
			end
			meshResult = mesh:Clone()
			break
		end
		return meshResult
	end
	
	local function stringSetToType(propertyString, propertyType)
		local array = string.split(propertyString, ",")
		if propertyType == "Position" or propertyType == "Size" then
			return Vector3.new(array[1], array[2], array[3])
		elseif propertyType == "CFrame" then
			return CFrame.new(
				array[1], array[2], array[3], 
				array[4], array[5], array[6], 
				array[7], array[8], array[9], 
				array[10], array[11], array[12]
			)
		elseif propertyType == "Color" then
			return Color3.new(array[1], array[2], array[3])
		elseif propertyType == "Material" or propertyType == "Shape" or "Enum" then
			local enumSplit = string.split(propertyString, ".")
			local enumType, enumValue = enumSplit[2], enumSplit[3]
			local enum = Enum[enumType][enumValue]
			return enum
		end
	end
	
	local function getInstancedPart(item)
		local itemType, props = item.itemType, item.props
		local newInstance = itemType ~= "MeshPart" and Instance.new(itemType)
			or getMesh(props.MeshId)
		for k,v in pairs(props) do
			if k == "MeshId" or v == "nil" then
				continue
			end
			if table.find(overriddenProperties, k) then
				newInstance[k] = stringSetToType(v,k)
				continue
			end
			newInstance[k] = v
		end
		-- key is property name
		-- (handles the naming)
		local function loadDecals()
			for _, decalItem in pairs(item.decals) do
				if not decalItem then
					continue
				end
				local function getDecalInstance(decalItem)
					local decal = Instance.new("Decal")
					for k,v in pairs(decalItem) do
						if k == "Face" then
							decal[k] = stringSetToType(v, "Enum")
							continue
						end
						decal[k] = v
					end
					return decal
				end
				local decalInstance = getDecalInstance(decalItem)
				decalInstance.Parent = newInstance
			end
		end
		local function smoothSurfaces(part)
			local surfaces = {
				"TopSurface", "FrontSurface",
				"RightSurface","LeftSurface",
				"BackSurface", "BottomSurface"
			}
			for _, surface in pairs(surfaces) do
				part[surface] = Enum.SurfaceType.Smooth
			end
		end
		loadDecals()
		smoothSurfaces(newInstance)
		return newInstance
	end
	
	local function getInstancedModel(item)
		local model = Instance.new("Model")
		model.Name = item.Name
		model:PivotTo(stringSetToType(item.pivot, "CFrame"))
		for _, part in pairs(item.parts) do
			getInstancedPart(part).Parent = model
		end
		return model
	end
	
	local partType = {"Part", "MeshPart"}
	for _, item in pairs(serialized) do
		local itemType = item.itemType
		if table.find(partType, itemType) then
			local part = getInstancedPart(item)
			part.Parent = container
			continue
		end
		if itemType == "Model" then
			local model = getInstancedModel(item)
			model.Parent = container
		end
	end
	
	return container
end

return module
