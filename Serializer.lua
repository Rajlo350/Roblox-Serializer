local module = {
	meshFolder = nil
}

local properties = {
	Part = {"Name", "Orientation", "Size", "CFrame", "Color", "Transparency", "CanCollide", "Anchored", "Material", "Shape"},
	MeshPart = {"Name", "MeshId", "CFrame", "Size", "Transparency", "BrickColor", "CanCollide", "Anchored", "Material"},
	Decal = {"Name", "Texture", "Transparency", "Face", "Color3"},
}

-- Parts can be under root, or have one model (no nested parts or models inside nested)
function module.serialize(object: Instance)
	local children = object:GetChildren()
	local result = {}

	local function getItem(item: Instance)
		local propertyType = properties[item.ClassName]
		local itemObject = {itemType = item.ClassName, props = {}, decals = {}}
		for _, property in pairs(propertyType) do
			local newProperty = item[property]
			itemObject.props[property] = newProperty
		end
		local function getDecalItem(decal)
			local result = {}
			for _, prop in pairs(properties.Decal) do
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
		local itemObject = {itemType = "Model", Name = model.Name, pivot = model:GetPivot(), parts = {}}
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

	local function getInstancedPart(item)
		local itemType, props = item.itemType, item.props
		local newInstance = itemType ~= "MeshPart" and Instance.new(itemType)
			or getMesh(props.MeshId)
		for k,v in pairs(props) do
			if k == "MeshId" then
				continue
			end
			newInstance[k] = v
			-- key is property name
			-- (handles the naming)
		end
		local function loadDecals()
			for _, decalItem in pairs(item.decals) do
				if not decalItem then
					continue
				end
				local function getDecalInstance(decalItem)
					local decal = Instance.new("Decal")
					for k,v in pairs(decalItem) do
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
			continue
		end
	end

	return container
end

return module
