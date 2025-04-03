local addressBook
local stargate
local version = "0.1.0"

local pointsOfOrigin = {
  MilkyWay = "Point of Origin", -- TODO: support Nether PoO
  Pegasus = "Subido",
  Universe = 17
}

local ErrorType = {
  ADDRESS_MISSING = "ADDRESS_MISSING",
  ADDRESS_INVALID = "ADDRESS_INVALID",
  ADDRESS_INCOMPLETE = "ADDRESS_INCOMPLETE",
  OUT_OF_RANGE = "OUT_OF_RANGE",
  ADDRESS_TOO_LONG = "ADDRESS_TOO_LONG",
}

term.reset = function()
  term.clear()
  term.setCursorPos(1, 1)
end

function main()
  if not initialize() then return end
  term.reset()
  mainMenu()
end

function initialize()
  addressBook = require("address-book")
  if not addressBook then
    print("ERROR: address-book.lua missing.")
    print("Please reinstall SSGD to generate a new one")
    print("  ssgd-install")
    return false
  end

  print("Booting SSGD " .. version)
  os.sleep(1)
  print(#addressBook .. " addresses found")

  print("Searching for connected stargate")
  os.sleep(1)
  stargate = peripheral.find("stargate")
  if not stargate then
    print("ERROR: Stargate not found. Is it connected?")
    print("Check that both wired modems have a red circle on them. Right click to connect.")
    return false
  end

  return true
end

function listenForExit()
  while true do
    local _, keycode = os.pullEvent("key_up")
    local key = keys.getName(keycode)

    if key == "q" then
      stargate.abortDialing()
      term.reset()
      print("Exiting SSGD")
      return
    end
  end
end

function listenEvents()
  while true do
    local eventData = { os.pullEventRaw() }
    local event = eventData[1]

    if event == "terminate" then
      term.reset()
      print("Exiting SSGD, aborting dialing")
      stargate.abortDialing()
      return
    elseif event == "stargate_failed" then
      local reason = eventData[3]
      term.reset()
      print("Stargate Error: " .. reason)
      return
    elseif event == "stargate_incoming_wormhole" then
      term.reset()
      print("ERROR: Unscheduled off world activation!")
      return
    end
  end
end

function mainMenu()
  local selectedAddress = 1

  local function delayReset()
    os.sleep(5)
    term.clear()
  end

  local function setSelectedIndex(value)
    if value > #addressBook then
      value = 1
    end

    if value <= 0 then
      value = #addressBook
    end

    selectedAddress = value
  end

  local function onCloseGate()
    print("Closing gate")
    stargate.disengageGate()
  end

  local function onAbortDialing()
    print("Aborting dialing")
    stargate.abortDialing()
  end

  local function onDialAddress()
    term.reset()
    local success, data = getAddressToDial(selectedAddress)

    if not success then
      local errorType = data.error
      local localType = stargate.getGateType()
      print("ERROR:")

      if errorType == ErrorType.ADDRESS_MISSING then
        print("No " .. localType .. " address found")
      elseif errorType == ErrorType.ADDRESS_TOO_LONG then
        print("Address contains too many glyphs.")
        print("Must be between 6 and 8 glyphs, excluding Point of Origin")
      elseif errorType == ErrorType.ADDRESS_INCOMPLETE then
        local symbolsNeeded = entry.type == "Universe" and 8 or 7
        print("Address is incomplete for dialing")
        print("Dialing a " .. entry.type .. " gate from a " .. localType .. " gate requires " .. symbolsNeeded .. " glyphs")
      elseif errorType == ErrorType.OUT_OF_RANGE then
        print("Gate is out of range for dialing")
        print("Universe gates can only dial other Universe gates")
      else
        print(errorType)
      end

      return
    end

    print("Dialing " .. data.name)
    print()
    dialAddress(data.address)
  end

  while true do
    renderMenu(selectedAddress)

    local _, keycode = os.pullEvent("key")
    local key = keys.getName(keycode)

    if key == "down" then
      setSelectedIndex(selectedAddress + 1)
    elseif key == "up" then
      setSelectedIndex(selectedAddress - 1)
    elseif key == "c" then
      onCloseGate()
      delayReset()
    elseif key == "a" then
      onAbortDialing()
      delayReset()
    elseif key == "enter" then
      onDialAddress()
      delayReset()
    end
  end
end

function getAddressToDial(addressIndex)
  local localType = stargate.getGateType()
  local addressEntry = addressBook[addressIndex]
  local remoteType = addressEntry.type
  local remoteAddress = addressEntry.addresses[localType]

  local isValid, errorType = isValidAddress(remoteAddress, remoteType)
  if not isValid then
    return false, { error = errorType }
  end

  local success_or_error, numGlyphs = stargate.getSymbolsNeeded(remoteAddress)
  if success_or_error == "address_malformed" then
    return false, { error = "Address invalid." }
  end

  local targetAddress = { table.unpack(remoteAddress, 1, numGlyphs) }
  table.insert(targetAddress, pointsOfOrigin[localType])

  return true, {
    name = addressEntry.name,
    type = addressEntry.type,
    address = targetAddress
  }
end

function renderMenu(selectedAddress)
  local localType = stargate.getGateType()

  term.setCursorPos(1, 1)
  print("Local Gate: " .. localType)
  print("Please select an address")

  for index, entry in ipairs(addressBook) do
    local remoteType = entry.type
    local remoteAddress = entry.addresses[localType]
    local isValid, errorType = isValidAddress(remoteAddress, remoteType)

    local caret = " "
    if selectedAddress == index then
      caret = isValid and ">" or "X"
    end
    write(caret .. " " .. entry.name)

    if errorType then
      write(" [" .. errorType .. "]")
    end

    print("")
  end

  print("")
  print("q: exit SSGD | c: close gate | a: abort dialing")
end

function isValidAddress(remoteAddress, remoteType)
  local localType = stargate.getGateType()

  local isMultiGate = localType ~= remoteType
  local needsFullAddress = isMultiGate and remoteType == "Universe"
  local outOfRange = isMultiGate and localType == "Universe"

  if not remoteAddress then
    return false, ErrorType.ADDRESS_MISSING
  elseif outOfRange then
    return false, ErrorType.OUT_OF_RANGE
  elseif #remoteAddress <= 5 then
    return false, ErrorType.ADDRESS_INCOMPLETE
  elseif needsFullAddress and #remoteAddress < 8 then
    return false, ErrorType.ADDRESS_INCOMPLETE
  elseif isMultiGate and #remoteAddress < 7 then
    return false, ErrorType.ADDRESS_INCOMPLETE
  elseif #remoteAddress >= 9 then
    return false, ErrorType.ADDRESS_TOO_LONG
  else
    return true
  end
end

function waitForStatus(status)
  while stargate.getGateStatus() ~= status do
    os.sleep(1)
  end
end

function dialSymbol(symbol)
  stargate.engageSymbol(symbol)
  waitForStatus("idle")
end

function openGate()
  local success, _, reason, error_name = stargate.engageGate()
  if success then
    return true
  else
    local error_msg = error_name .. ": " .. reason
    return false, error_msg
  end
end

function dialAddress(address)
  if #address < 7 or #address > 9 then
    error("ArgError: Address must be 7-9 symbols, including point of origin")
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
    dialSymbol(symbol)

    if index ~= #address then
      print(" -> engaged")
    else
      local success, error_msg = openGate()
      if success then
        print(" -> LOCKED")
      else
        print(" -> ERROR")
        print(error_msg)
      end
    end
  end
end

parallel.waitForAny(listenForExit, listenEvents, main)
