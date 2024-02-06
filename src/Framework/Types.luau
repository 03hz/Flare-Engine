export type RequireType = (ModuleScript | "Maid" | "Network" | "Promise" | "Roact" | "Signal" | "Spring") -> {}
export type BaseRuntimeModule = {
	Init: (any?),
	Start: (any?)
}

--[=[
	Framework type returned on `FlareServer:GetModulesFromCache()`.

	@type RequireType (ModuleScript | "Maid" | "Network" | "Promise" | "Roact" | "Signal" | "Spring") -> {}
	@within FlareServer
]=]

--[=[
	Framework type used by runtime modules.

	@type BaseRuntimeModule { Init: (any?), Start: (any?) }
	@within FlareServer
]=]

return nil;