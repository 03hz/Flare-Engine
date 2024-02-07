export type RequireType = (ModuleScript | "Maid" | "Network" | "Promise" | "Roact" | "Signal" | "Spring") -> {}
export type BaseRuntimeModule = {
	Init: (any),
	Start: (any)
};

--[=[
	Framework type returned on `FlareClient:GetModulesFromCache()`.

	@type RequireType (ModuleScript | "Maid" | "Network" | "Promise" | "Roact" | "Signal" | "Spring") -> {}
	@within FlareClient
]=]

--[=[
	Framework type used by runtime modules.

	@type BaseRuntimeModule { Init: (any?), Start: (any?) }
	@within FlareClient
]=]

return nil;