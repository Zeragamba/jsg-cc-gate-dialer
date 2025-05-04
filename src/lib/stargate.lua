local ErrorType = require("lib/errors")
local Stargate = {}

local pointsOfOrigin = {
	MilkyWay = "Point of Origin", -- TODO: support Nether PoO
	Pegasus = "Subido",
	Universe = 17,
}

function Stargate.connect()
	local gate = {}
	local _stargate = peripheral.find("stargate")

	if not _stargate then
		print("ERROR: Stargate not found. Is it connected?")
		print(
			"Check that both modems have a red circle on them. Right click to connect."
		)
		return false
	end

	local localType = _stargate.getGateType()

	function gate.getStatus()
		return _stargate.getGateStatus()
	end

	function gate.getGateType()
		return _stargate.getGateType()
	end

	function gate.resolveAddress(remoteAddress)
		if not remoteAddress then
			return false, { error = ErrorType.ADDRESS_MISSING }
		elseif #remoteAddress <= 5 then
			return false, { error = ErrorType.ADDRESS_INCOMPLETE }
		elseif #remoteAddress >= 9 then
			return false, { error = ErrorType.ADDRESS_TOO_LONG }
		end

		local success_or_error, numGlyphs =
			_stargate.getSymbolsNeeded(remoteAddress)
		if success_or_error == "address_malformed" then
			return false, { error = ErrorType.ADDRESS_INVALID }
		end

		local targetAddress = { table.unpack(remoteAddress, 1, numGlyphs) }
		table.insert(targetAddress, pointsOfOrigin[localType])

		return true, { address = targetAddress }
	end

	function gate.waitForStatus(status)
		while _stargate.getGateStatus() ~= status do
			os.sleep(1)
		end
	end

	function gate.dialGlyph(symbol)
		_stargate.engageSymbol(symbol)
		gate.waitForStatus("idle")
	end

	function gate.openGate()
		local success, _, reason, error_name = _stargate.engageGate()
		if success then
			return true
		else
			local error_msg = error_name .. ": " .. reason
			return false, error_msg
		end
	end

	function gate.closeGate()
		_stargate.disengageGate()
	end

	function gate.abort()
		_stargate.abortDialing()
	end

	function gate.dialAddress(address)
		if #address < 7 or #address > 9 then
			error(
				"ArgError: Address must be 7-9 symbols, including point of origin"
			)
		end

		local startX, startY = term.getCursorPos()
		for index in ipairs(address) do
			print("Chevron " .. index .. ": ")
		end
		print()
		print("q: Abort and Quit")
		term.setCursorPos(startX, startY)

		for index, symbol in ipairs(address) do
			write("Chevron " .. index .. ": " .. symbol)
			gate.dialGlyph(symbol)

			if index ~= #address then
				print(" -> engaged")
			else
				local success, error_msg = gate.openGate()
				if success then
					print(" -> LOCKED")
				else
					print(" -> ERROR")
					print(error_msg)
				end
			end
		end
	end

	return gate
end

return Stargate
