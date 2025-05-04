local addressBook
local stargate
local version = require("lib/version")
local Stargate = require("lib/stargate")
local MainMenu = require("lib/ui/main-menu")

term.reset = function()
    term.clear()
    term.setCursorPos(1, 1)
end

function main()
    if not initialize() then
        return
    end
    term.reset()

    if not pcall(function()
        MainMenu(stargate, addressBook)
    end) then
        onExit()
    end
end

function initialize()
    addressBook = require("address-book")
    if not addressBook then
        print("ERROR: address-book.lua missing.")
        print("Please reinstall SSGD to generate a new one")
        print("  ssgd-install")
        return false
    end

    print("Booting SSGD | Version: " .. version)
    os.sleep(1)
    print(#addressBook .. " addresses found")

    print("Searching for connected stargate")
    os.sleep(1)
    stargate = Stargate.connect()

    return true
end

function onExit()
    stargate.abort()
    term.reset()
    term.write("Exiting SSGD")
    term.setCursorPos(1, 2)
end

function listenEvents()
    while true do
        local eventData = { os.pullEventRaw() }
        local event = eventData[1]

        if event == "terminate" then
            onExit()
            return
        elseif event == "key_up" then
            local key = keys.getName(eventData[2])

            if key == "q" then
                onExit()
                return
            end
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

parallel.waitForAny(listenEvents, main)
