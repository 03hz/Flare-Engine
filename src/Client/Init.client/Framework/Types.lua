export type RequireType = (ModuleScript | "Maid" | "Network" | "Promise" | "Roact" | "Signal" | "Spring") -> {}
export type BaseRuntimeModule = {
	Init: (any),
	Start: (any)
};

return nil;