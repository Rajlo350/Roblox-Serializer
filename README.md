# Roblox-Serializer
A simple serialization module that can encode a model or folder into a table format and construct a replica.


# Limitations
* The given model or folder can only have one nested model.
* Only parts, mesh parts, and decals are supported as of now.
* Due to the limitation of inserting meshes programatically, a mesh folder needs to be referenced.

# Example
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Serializer = require(ReplicatedStorage.Serializer)
Serializer.meshFolder = ReplicatedStorage.MeshFolder

local House = workspace.House
local serializedHouse = Serializer.serialize(House)

local container = Serializer.construct(serializedHouse)

container:PivotTo(container:GetPivot() + Vector3.new(0, 0, 62))
container.Parent = workspace
```

### Result
![serializer_result](https://github.com/Rajlo350/Roblox-Serializer/assets/89266878/f177dc9b-e2a5-40ad-b3be-6735e113233c)


Get the place file of this [from the repo](https://github.com/Rajlo350/Roblox-Serializer/blob/main/serializer_example.rbxl). Or test it [on Roblox](https://www.roblox.com/games/17637566518/Serializer-Module-Demo).
