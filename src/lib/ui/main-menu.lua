return function(stargate, addressBook)
    local _, statusBarY = term.getSize()

    local localType = stargate.getGateType()
    local selectedAddress = 1
    local menuY = 4
    local menuMaxItems = statusBarY - menuY - 1

    local MainMenu = {}

    function MainMenu.getRemoteAddress(addressIndex)
        local addressEntry = addressBook[addressIndex]
        local remoteAddress = addressEntry.addresses[localType]
        local success, data = stargate.resolveAddress(remoteAddress)

        if not success then
            return false, data
        end

        return true, {
            name = addressEntry.name,
            address = data.address
        }
    end

    function MainMenu.renderMenu()
        term.setCursorPos(1, 1)
        print("Local Gate: " .. localType)
        print("Please select an address")

        term.setCursorPos(1, menuY)
        for index, entry in ipairs(addressBook) do
            write("  " .. entry.name)

            local _, data = MainMenu.getRemoteAddress(index)
            if data.error then
                write(" [" .. data.error .. "]")
            end

            print("")
        end

        term.setCursorPos(1, statusBarY)
        term.write("q: exit SSGD | c: close gate | a: abort dialing")
    end

    function MainMenu.setSelectedIndex(value)
        if value > #addressBook then
            value = 1
        end

        if value <= 0 then
            value = #addressBook
        end

        selectedAddress = value
    end

    function MainMenu.reset()
        term.clear()
        MainMenu.renderMenu()
        MainMenu.drawCursor()
    end

    function MainMenu.clearCursor()
        cursorY = menuY
        repeat
            term.setCursorPos(1, cursorY)
            term.write(" ")
            cursorY = cursorY + 1
        until cursorY == menuY + menuMaxItems
    end

    function MainMenu.drawCursor()
        MainMenu.clearCursor()
        term.setCursorPos(1, menuY + selectedAddress - 1)
        term.write(">")
    end

    function MainMenu.moveCursorUp()
        MainMenu.clearCursor()
        MainMenu.setSelectedIndex(selectedAddress - 1)
        MainMenu.drawCursor()
    end

    function MainMenu.moveCursorDown()
        MainMenu.setSelectedIndex(selectedAddress + 1)
        MainMenu.drawCursor()
    end

    function MainMenu.drawCursor()
        MainMenu.clearCursor()
        term.setCursorPos(1, menuY + selectedAddress - 1)
        term.write(">")
    end

    function MainMenu.onCloseGate()
        term.clear()
        term.setCursorPos(1, 1)
        term.write("Closing gate")
        stargate.closeGate()
    end

    function MainMenu.onAbortDialing()
        term.clear()
        term.setCursorPos(1, 1)
        term.write("Aborting dialing")
        stargate.abort()
    end

    function MainMenu.onDialAddress()
        term.reset()

        local success, data = MainMenu.getRemoteAddress(selectedAddress)

        if not success then
            local errorType = data.error
            print("ERROR:")

            if errorType == ErrorType.ADDRESS_MISSING then
                print("No " .. localType .. " address found")
            elseif errorType == ErrorType.ADDRESS_TOO_LONG then
                print("Address contains too many glyphs.")
                print(
                        "Must be between 6 and 8 glyphs, excluding Point of Origin"
                )
            elseif errorType == ErrorType.ADDRESS_INCOMPLETE then
                local symbolsNeeded = entry.type == "Universe" and 8 or 7
                print("Address is incomplete for dialing")
                print(
                        "Dialing a " .. entry.type .. " gate from a " .. localType .. " gate requires " .. symbolsNeeded .. " glyphs"
                )
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
        stargate.dialAddress(data.address)
    end

    MainMenu.renderMenu()
    MainMenu.drawCursor()

    while true do
        local _, keycode = os.pullEvent("key")
        local key = keys.getName(keycode)

        if key == "down" then
            MainMenu.moveCursorDown()
        elseif key == "up" then
            MainMenu.moveCursorUp()
        elseif key == "c" then
            MainMenu.onCloseGate()
            os.sleep(5)
            MainMenu.reset()
        elseif key == "a" then
            MainMenu.onAbortDialing()
            MainMenu.reset()
            os.sleep(5)
        elseif key == "enter" then
            MainMenu.onDialAddress()
            os.sleep(5)
            MainMenu.reset()
        end
    end
end
