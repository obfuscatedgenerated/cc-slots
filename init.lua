local obsi = require "/lib/obsi2"

local symbols = require "symbols"
local reels = require "reels"

local reel_pos = reels.random_reels()

local spinning = false
local spin_start_time = 0

local stop_variances = { 0, 0, 0 }

function obsi.load()
    symbols.load_symbol_images()
end


local function calculate_payout()
    local payout = 0

    local symbol_1 = reels.reel[reel_pos[1]]
    local symbol_2 = reels.reel[reel_pos[2]]
    local symbol_3 = reels.reel[reel_pos[3]]

    if symbol_1 == symbol_2 and symbol_2 == symbol_3 then
        payout = symbols.symbols[symbol_1].payout.triple or 0
    elseif symbol_1 == symbol_2 or symbol_2 == symbol_3 or symbol_1 == symbol_3 then
        payout = symbols.symbols[symbol_1].payout.double or 0
    end

    return payout
end

local function update_reel(reel_idx, diff)
    if spinning then
        -- each reel stops staggered (1 second per reel and their random variance)
        if diff <= (reel_idx + stop_variances[reel_idx]) then
            -- increment position and wrap around
            reel_pos[reel_idx] = reel_pos[reel_idx] + 1
            if reel_pos[reel_idx] > #reels.reel then
                reel_pos[reel_idx] = 1
            end
        end
    end

    local symbol_name = reels.reel[reel_pos[reel_idx]]
    local symbol = symbols.symbols[symbol_name]

    obsi.graphics.draw(symbol.image, ((reel_idx - 1) * symbol.image.width) + 1, 1)
end

function obsi.update()
    -- start the spin if space is pressed
    if not spinning and obsi.keyboard.isScancodeDown(keys.space) then
        -- start spin
        spinning = true
        spin_start_time = obsi.timer.getTime()
    end

    local diff = obsi.timer.getTime() - spin_start_time

    -- stop the spin and calculate the payout after 3 seconds
    if spinning and diff >= 3 then
        spinning = false

        local payout = calculate_payout()
        
    end

    -- update and draw the reels
    for i = 1, 3 do
        update_reel(i, diff)
    end
end

obsi.init()
