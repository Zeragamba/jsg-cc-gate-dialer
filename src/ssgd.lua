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
local stargate = peripheral.find("stargate")
if not stargate then
  print("ERROR: Stargate not found. Is it connected?")
  print("Check that both wired modems have a red circle on them. Right click to connect.")
  return
end

local pointsOfOrigin = {
  MilkyWay = "Point of Origin", -- TODO: support Nether PoO
  Pegasus = "Subido",
  Universe = 17
}

local localType = stargate.getGateType()
print(localType .. " stargate connected")
os.sleep(1)

function main()
  resetTerm()
  mainMenu()
end

function resetTerm()
  term.clear()
  term.setCursorPos(1, 1)
end

function listenForExit()
  while true do
    local _, keycode = os.pullEvent("key_up")
    local key = keys.getName(keycode)

    if key == "q" then
      stargate.abortDialing()
      resetTerm()
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
      print()
      print("Exiting SSGD, aborting dialing")
      stargate.abortDialing()
      return
    elseif event == "stargate_failed" then
      local reason = eventData[3]
      print()
      print("Stargate Error: " .. reason)
      return
    elseif event == "stargate_incoming_wormhole" then
      print()
      print("ERROR: Unscheduled off world activation!")
      return
    end
  end
end

function mainMenu()
  local selectedAddress = 1

  while true do
    renderMenu(selectedAddress)

    local _, keycode = os.pullEvent("key")
    local key = keys.getName(keycode)

    if key == "down" then
      selectedAddress = selectedAddress + 1
      if selectedAddress > #addressBook then
        selectedAddress = 1
      end
      goto continue
    elseif key == "up" then
      selectedAddress = selectedAddress - 1
      if selectedAddress <= 0 then
        selectedAddress = #addressBook
      end
      goto continue
    elseif key == "c" then
      print("Closing gate")
      stargate.disengageGate()
    elseif key == "a" then
      print("Aborting dialing")
      stargate.abortDialing()
    elseif key == "enter" then
      resetTerm()
      local addressEntry = addressBook[selectedAddress]
      local gateType = stargate.getGateType()

      local targetName = addressEntry.name
      local targetType = addressEntry.type
      local targetAddress = addressEntry.addresses[gateType]

      print("Target Name: " .. targetName)
      print("Target Type: " .. targetType)
      print("Target # Glyphs: " .. #targetAddress)

      print("")
      print("Source Type: " .. gateType)

      local isValid, errorMsg = isValidAddress(targetAddress, targetType)
      if isValid then
        print("Dialing...")
        dialAddress(targetAddress)
      else
        print()
        print("ERROR:")

        if errorMsg == "Address Missing" then
          print("No " .. gateType .. " address found")
        elseif errorMsg == "Too many glyphs" then
          print("Address contains too many glyphs.")
          print("Must be between 6 and 8 glyphs, excluding Point of Origin")
        elseif errorMsg == "Incomplete Address" then
          print("Address is incomplete for dialing")

          if targetType == "Universe" then
            print("Dialing a Universe gate from a " .. gateType .. " gate requires 8 glyphs")
          else
            print("Dialing a " .. targetType .. " gate from a " .. gateType .. " gate requires 7 glyphs")
          end
        elseif errorMsg == "Out of Range" then
          print("Gate is out of range for dialing")
          print("Universe gates can only dial other Universe gates")
        else
          print(errorMsg)
        end
      end
    else
      goto continue
    end

    os.sleep(5)
    term.clear()

    :: continue ::
  end
end

function renderMenu(selectedAddress)
  term.setCursorPos(1, 1)
  print("Local Gate: " .. localType)
  print("Please select an address")

  for index, entry in ipairs(addressBook) do
    local targetType = entry.type
    local targetAddress = entry.addresses[localType]
    local isValid, errorMsg = isValidAddress(targetAddress, targetType)

    local caret = " "
    if selectedAddress == index then
      caret = isValid and ">" or "X"
    end
    write(caret .. " " .. entry.name)

    if errorMsg then
      write(" [" .. errorMsg .. "]")
    end

    print("")
  end

  print("")
  print("q: exit SSGD | c: close gate | a: abort dialing")
end

function isValidAddress(targetAddress, targetType)
  local isMultiGate = localType ~= targetType
  local needsFullAddress = isMultiGate and targetType == "Universe"
  local outOfRange = isMultiGate and localType == "Universe"

  if not targetAddress then
    return false, "Address Missing"
  elseif outOfRange then
    return false, "Out of range"
  elseif #targetAddress <= 5 then
    return false, "Incomplete Address"
  elseif needsFullAddress and #targetAddress < 8 then
    return false, "Incomplete Address"
  elseif isMultiGate and #targetAddress < 7 then
    return false, "Incomplete Address"
  elseif #targetAddress >= 9 then
    return false, "Too many glyphs"
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
  if #address < 6 or #address > 8 then
    error("ArgError: Address must be 6-8 symbols, excluding Point of Origin")
  end

  local pointOfOrigin = pointsOfOrigin[localType]
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
