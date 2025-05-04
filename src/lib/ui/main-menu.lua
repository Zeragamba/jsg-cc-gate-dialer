local Screen = require("lib/ui/screen")

return function(stargate, addressBook)
    local _, statusBarY = term.getSize()

    local localType = stargate.getGateType()
    local selectedAddress = 1
    local menuY = 4
    local menuMaxItems = statusBarY - menuY - 1

    local self = {}
    local screen = Screen.new(term)

    function self.getRemoteAddress(addressIndex)
        local addressEntry = addressBook[addressIndex]
        local remoteAddress = addressEntry.addresses[localType]
        local success, data = stargate.resolveAddress(remoteAddress)

        if not success then
            return false, data
        end

        return true, {
            name = addressEntry.name,
            address = data.address,
        }
    end

    function self.onQuit()
        error("Exiting SSGD", 0)
    end

    function self.renderMenu()
        screen.reset()
        screen.setCursorPos(1, 1)
        screen.print("Local Gate: " .. localType)
        screen.print("Please select an address")

        screen.setCursorPos(1, menuY)
        for index, entry in ipairs(addressBook) do
            screen.write("  ")

            local _, data = self.getRemoteAddress(index)
            if data.error then
                screen.write(entry.name .. " [" .. data.error .. "]")
            else
                screen.button(entry.name, function()
                    self.onDialAddress(index)
                end)
            end

            screen.print()
        end

        screen.setCursorPos(1, statusBarY)
        screen.button("Q: Quit", function()
            self.onQuit()
        end)
        screen.write(" ")
        screen.button("C: Close Gate", function()
            self.onCloseGate()
        end)
        screen.write(" ")
        screen.button("A: Abort Dialing", function()
            self.onAbortDialing()
        end)
    end

    function self.setSelectedIndex(value)
        if value > #addressBook then
            value = 1
        end

        if value <= 0 then
            value = #addressBook
        end

        selectedAddress = value
    end

    function self.reset()
        term.clear()
        self.renderMenu()
        self.drawCursor()
    end

    function self.clearCursor()
        cursorY = menuY
        repeat
            term.setCursorPos(1, cursorY)
            term.write(" ")
            cursorY = cursorY + 1
        until cursorY == menuY + menuMaxItems
    end

    function self.drawCursor()
        self.clearCursor()
        term.setCursorPos(1, menuY + selectedAddress - 1)
        term.write(">")
    end

    function self.moveCursorUp()
        self.clearCursor()
        self.setSelectedIndex(selectedAddress - 1)
        self.drawCursor()
    end

    function self.moveCursorDown()
        self.setSelectedIndex(selectedAddress + 1)
        self.drawCursor()
    end

    function self.drawCursor()
        self.clearCursor()
        term.setCursorPos(1, menuY + selectedAddress - 1)
        term.write(">")
    end

    function self.onCloseGate()
        term.clear()
        term.setCursorPos(1, 1)
        term.write("Closing gate")
        stargate.closeGate()
        os.sleep(5)
        self.reset()
    end

    function self.onAbortDialing()
        term.clear()
        term.setCursorPos(1, 1)
        term.write("Aborting dialing")
        stargate.abort()
        os.sleep(5)
        self.reset()
    end

    function self.onDialAddress(index)
        term.reset()

        local success, data = self.getRemoteAddress(index)

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
        os.sleep(5)
        self.reset()
    end

    function listenKeyDown()
        while true do
            local _, keycode = os.pullEvent("key")
            local key = keys.getName(keycode)

            if key == "down" then
                self.moveCursorDown()
            elseif key == "up" then
                self.moveCursorUp()
            elseif key == "c" then
                self.onCloseGate()
            elseif key == "a" then
                self.onAbortDialing()
            elseif key == "enter" then
                self.onDialAddress(selectedAddress)
            end
        end
    end

    self.renderMenu()
    self.drawCursor()

    parallel.waitForAny(listenKeyDown, screen.listen)
end
