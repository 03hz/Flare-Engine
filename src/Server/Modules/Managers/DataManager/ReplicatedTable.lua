local ReplicatedTable = {}
ReplicatedTable.__newindex = function()
	if game:GetService("RunService"):IsClient() then
		return warn("This table is read only, consider using server for editing its contents.");
	end;
end;

ReplicatedTable.Data = {}

return ReplicatedTable
