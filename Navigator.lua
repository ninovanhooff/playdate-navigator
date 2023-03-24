local lume <const> = masterplayer.lume
local playdate <const> = playdate
local menu <const> = playdate.getSystemMenu()

local pendingNavigators = {}
local backStack = {}
local activeScreen


--- Usage:
--- local navigator <const> = import "lua/navigator"
--- <setup navigation stack by using one or more pushScreen calls>
--- navigator:start()  -- must be called at the end of main.lua to ensure proper navigation state
--- Add navigator:update() to your playdate.update() call

local function popScreenImmediately()
    printT("Popping off backstack:", activeScreen.className, activeScreen)
    table.remove(backStack)
    activeScreen:destroy()
end

function pushScreen(newScreen)
    table.insert(
        pendingNavigators,
        function()
            printT("Adding to backstack", newScreen.className, newScreen)
            table.insert(backStack, newScreen)
        end
    )
end

function popScreen()
    table.insert(pendingNavigators, popScreenImmediately)
end

function clearNavigationStack()
    table.insert(
        pendingNavigators,
        function()
            printT("Clearing navigationStack", activeScreen.className, activeScreen)
            while #backStack > 0 do
                activeScreen = backStack[#backStack]
                popScreenImmediately()
            end
        end
    )
end

class("Navigator", {}).extends()

function Navigator:init(initialScreenFunction)
    Navigator.super.init(self)

    self.initialScreenFunction = initialScreenFunction
end

function Navigator:start()
    if #pendingNavigators > 0 then
        self:executePendingNavigators()
    else
        self:resumeActiveScreen()
    end
end

--- Ensure that the backstack is non-empty and resumes the the screen at the top of the backstack
--- If the backstack is empty, an Initial Screen will be inserted and an error logged
function Navigator:resumeActiveScreen()
    if #backStack < 1 then
        printT("ERROR: No active screen, adding initial Screen")
        table.insert(backStack, self.initialScreenFunction())
    end

    activeScreen = backStack[#backStack]
    printT("Resuming screen", activeScreen.className, activeScreen)
    playdate.setCollectsGarbage(true) -- prevent permanently disabled GC by previous Screen
    activeScreen:resume()
end

function Navigator:executePendingNavigators()
    if #pendingNavigators > 0 then
        for _, navigator in ipairs(pendingNavigators) do
            navigator()
        end
        pendingNavigators = {}
        local newPos = lume.findIndexOf(backStack, activeScreen)
        if activeScreen and newPos and newPos ~= #backStack then
            -- the activeScreen was moved from the top of the stack to another position
            printT("Pausing screen", activeScreen.className, activeScreen)
            activeScreen:pause()
        end

        menu:removeAllMenuItems()
        self:resumeActiveScreen()
    end
end

function Navigator:updateActiveScreen()
    activeScreen:update()
end

function Navigator:update()
    self:executePendingNavigators()
    self:updateActiveScreen()
end


function Navigator:gameWillPause()
    printT("GameWillPause screen", activeScreen.className, activeScreen)
    activeScreen:gameWillPause()
end

function Navigator:gameWillResume()
    printT("GameWillResume screen", activeScreen.className, activeScreen)
    activeScreen:gameWillResume()
end

function Navigator:crankDocked()
    printT("Crank Docked for screen", activeScreen.className, activeScreen)
    activeScreen:crankDocked()
end

function Navigator:crankUndocked()
    printT("Crank Undocked for screen", activeScreen.className, activeScreen)
    activeScreen:crankUndocked()
end

function Navigator:debugDraw()
    activeScreen:debugDraw()
end
