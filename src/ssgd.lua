term.clear()
term.setCursorPos(1, 1)

local addressBook = require("address-book")
if not addressBook then
  print("ERROR: address-book.lua missing.")
  print("Please reinstall SSGD to generate a new one")
  print("  ssgd-install")
  return
end

print("Booting SSGD")
os.sleep(1)
print(#addressBook .. " addresses found")

print("Searching for connected stargate")
local selectedAddress = 1
local stargate = peripheral.find("stargate")
if not stargate then
  print("ERROR: Stargate not found. Is it connected?")
  print("Check that both wired modems have a red circle on them. Right click to connect.")
  return
end

local pointsOfOrigin = {
  MilkyWay = "Point of Origin", -- TODO: support Nether PoO
  Pegasus = "Subido",
  Universe = "G17"
}

local type = stargate.getGateType()
local pointOfOrigin = pointsOfOrigin[type]
print(type .. " stargate connected")
os.sleep(1)

function main()
  term.clear()
  selectedAddress = 1
  mainMenu()
end

function listenForExit()
  while true do
    local _, keycode = os.pullEvent("key_up")
    local key = keys.getName(keycode)

    if key == "q" then
      stargate.abortDialing()
      term.clear()
      term.setCursorPos(1, 1)
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
      print("Exiting SSGD, aborting dialing")
      stargate.abortDialing()
      return
    elseif event == "stargate_failed" then
      local reason = eventData[3]
      print("ERROR: " .. reason)
      return
    elseif event == "stargate_incoming_wormhole" then
      print("ERROR: Unscheduled off world activation!")
      return
    end
  end
end

function mainMenu()
  while true do
    displayMenu()

    local event, keycode, is_held = os.pullEvent("key")
    local key = keys.getName(keycode)

    if key == "down" then
      selectedAddress = selectedAddress + 1
      if selectedAddress > #addressBook then
        selectedAddress = 1
      end
    elseif key == "up" then
      selectedAddress = selectedAddress - 1
      if selectedAddress <= 0 then
        selectedAddress = #addressBook
      end
    elseif key == "c" then
      term.clear()
      term.setCursorPos(1, 1)
      print("Closing gate")
      stargate.disengageGate()
      os.sleep(5)
      term.clear()
    elseif key == "a" then
      term.clear()
      term.setCursorPos(1, 1)
      print("Aborting dialing")
      stargate.abortDialing()
      os.sleep(5)
      term.clear()
    elseif key == "enter" then
      term.clear()
      term.setCursorPos(1, 1)
      local addressEntry = addressBook[selectedAddress]
      local gateType = stargate.getGateType()

      local targetName = addressEntry.name
      local targetType = addressEntry.type
      local targetAddress = addressEntry.addresses[gateType]

      print("Target: " .. targetName)
      print("Target Type: " .. targetType)
      print("Source Type: " .. gateType)

      if not targetAddress then
        print("No " .. gateType .. " address found")
        os.sleep(5)
        term.clear()
        goto continue
      end

      if targetType ~= gateType and #targetAddress < 7 then
        print()
        print("ERROR:")
        print("Address incomplete for dialing a " .. targetType .. " gate from a " .. gateType .. " gate.")
        print("Please update the address book with a 7 or 8 glyph address")
        os.sleep(5)
        term.clear()
        goto continue
      end

      print("Dialing...")
      dialAddress(targetAddress)
      os.sleep(5)
      term.clear()
    end

    :: continue ::
  end
end

function displayMenu()
  term.setCursorPos(1, 1)
  local gateType = stargate.getGateType()
  print("Local Gate: " .. stargate.getGateType())
  print("Please select an address")

  for index, entry in ipairs(addressBook) do
    local remoteType = entry.type
    local remoteAddress = entry.addresses[gateType]

    if not remoteAddress then
      local caret = selectedAddress == index and "X" or " "
      print(caret .. " " .. entry.name .. " [Address Missing]")
    elseif gateType ~= remoteType and #remoteAddress < 7 then
      local caret = selectedAddress == index and "X" or " "
      print(caret .. " " .. entry.name .. " [Incomplete Address]")
    else
      local caret = selectedAddress == index and ">" or " "
      print(caret .. " " .. entry.name)
    end
  end

  print("")
  print("q: exit SSGD | c: close gate | a: abort dialing")
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
  if #address < 6 or #address > 8 then
    error("ArgError: Address must be 6-8 symbols, excluding Point of Origin")
  end

  local lastChevron = #address + 1
  for index, symbol in ipairs(address) do
    write("Chevron " .. index .. ": " .. symbol)
    dialSymbol(symbol)
    print(" -> engaged")
  end

  write("Chevron " .. lastChevron .. ": " .. pointOfOrigin)
  dialSymbol(pointOfOrigin)
  local success, error_msg = openGate()
  if success then
    print(" -> LOCKED")
  else
    print(" -> ERROR")
    print(error_msg)
  end
end

parallel.waitForAny(listenForExit, listenEvents, main)
