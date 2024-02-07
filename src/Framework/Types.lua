export type RequireType = (ModuleScript | "Maid" | "Network" | "Promise" | "Roact" | "Signal" | "Spring") -> {}

--[=[
	Framework type returned on `FlareServer:GetModulesFromCache()`.

	@type RequireType (ModuleScript | "Maid" | "Network" | "Promise" | "Roact" | "Signal" | "Spring") -> {}
	@within FlareServer
]=]

export type BaseRuntimeModule = {
	Init: (any?),
	Start: (any?)
}

--[=[
	Framework type used by runtime modules.

	@type BaseRuntimeModule { Init: (any?), Start: (any?) }
	@within FlareServer
]=]

return nil;