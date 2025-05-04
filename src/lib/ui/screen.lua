local Screen = {}
local MouseHandler = require("lib/ui/mouse-handler")

function Screen.new(display)
    local self = {}
    local mouseHandler = MouseHandler.new()

    function self.reset()
        mouseHandler.reset()
    end

    function self.resetColors()
        display.setBackgroundColor(colors.black)
        display.setTextColor(colors.white)
    end

    function self.button(label, onClick)
        local x, y = display.getCursorPos()

        mouseHandler.registerArea(x, y, #label, 1, onClick)

        display.setCursorPos(x, y)
        display.setTextColor(colors.blue)
        display.setBackgroundColor(colors.gray)
        display.write(label)

        self.resetColors()
    end

    function self.write(text)
        display.write(text)
    end

    function self.newLine()
        local _, y = display.getCursorPos()
        self.setCursorPos(1, y + 1)
    end

    function self.print(text)
        if text then
            display.write(text)
        end

        self.newLine()
    end

    function self.setCursorPos(x, y)
        display.setCursorPos(x, y)
    end

    function self.listen()
        parallel.waitForAny(mouseHandler.listen)
    end

    function self.stop()
        mouseHandler.stop()
    end

    return self
end

return Screen
