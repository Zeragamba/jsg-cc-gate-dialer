local MouseHandler = {}

function MouseHandler.new()
    local self = {}
    local clickZones = {}

    function self.reset()
        clickZones = {}
    end

    function self.registerArea(x, y, width, height, onClick)
        local zone = {}
        zone.x = x
        zone.y = y
        zone.width = width
        zone.height = height
        zone.onClick = onClick

        table.insert(clickZones, zone)
    end

    function self.listen()
        while true do
            local _, button, x, y = os.pullEvent("mouse_click")

            for _, area in ipairs(clickZones) do
                local xLeft = area.x
                local xRight = area.x + area.width
                local yTop = area.y
                local yBottom = area.y + area.height - 1

                if x >= xLeft and x <= xRight and y >= yTop and y <= yBottom then
                    area.onClick(button)
                end
            end
        end
    end

    return self
end

return MouseHandler
