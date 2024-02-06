local TimeUtils = {}

--// Gets raw seconds from specified time string
function TimeUtils.GetSecondsFromTimeString(Time: string): number
	if Time:find("seconds") then
		return Time:gsub("%D+", "");
	elseif Time:find("minutes") then
		return Time:gsub("%D+", "") * 60;
	end;
end;

return TimeUtils
