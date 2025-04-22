local obsi = require "/lib/obsi2"

-- (payouts should be multiplied by 100 for integer value, these are whole coins)
local symbols = {
    cherry = { name = "cherry", image = nil, payout = { double = 1, triple = 2 } },
    lemon = { name = "lemon", image = nil, payout = { triple = 5 } },
    orange = { name = "orange", image = nil, payout = { triple = 4 } },
    plum = { name = "plum", image = nil, payout = { triple = 6 } },
    grape = { name = "grape", image = nil, payout = { triple = 3 } },
    seven = { name = "seven", image = nil, payout = { triple = 50 } },
    bell = { name = "bell", image = nil, payout = { triple = 8 } },
    bar_single = { name = "bar_single", image = nil, payout = { triple = 10 } },
    bar_double = { name = "bar_double", image = nil, payout = { triple = 20 } },
    bar_triple = { name = "bar_triple", image = nil, payout = { triple = 30 } },
    jackpot = { name = "jackpot", image = nil, payout = { triple = 100 } },
}


-- define reel strip to use for all 3 reels
local reel = {
    symbols.cherry.name, symbols.cherry.name, symbols.cherry.name, symbols.cherry.name, symbols.cherry.name, -- 5 cherries
    symbols.lemon.name, symbols.lemon.name, symbols.lemon.name, symbols.lemon.name,                          -- 4 lemons
    symbols.orange.name, symbols.orange.name, symbols.orange.name, symbols.orange.name,                      -- 4 oranges
    symbols.plum.name, symbols.plum.name, symbols.plum.name, symbols.plum.name,                              -- 4 plums
    symbols.grape.name, symbols.grape.name,                                                                  -- 2 grapes
    symbols.bar_single.name, symbols.bar_single.name, symbols.bar_single.name, symbols.bar_single.name,      -- 4 bars
    symbols.bar_double.name, symbols.bar_double.name, symbols.bar_double.name,                               -- 3 bars
    symbols.bar_triple.name, symbols.bar_triple.name,                                                        -- 2 bars
    symbols.seven.name,                                                                                      -- 1 seven
    symbols.jackpot.name, symbols.jackpot.name,                                                              -- 1 jackpot
    symbols.bell.name,                                                                                       -- 1 bell
}


-- randomise position of each reel
local reel_pos = {
    math.random(1, #reel),
    math.random(1, #reel),
    math.random(1, #reel),
}

local TARGET_SIZE_X, TARGET_SIZE_Y = 24, 24


function obsi.load()
    -- load symbol images
    for k, v in pairs(symbols) do
        v.image = obsi.graphics.newImage("symbols/" .. k .. ".nfp")

        -- if the image is smaller than the target size, pad with -1 and keep it centered
        if v.image.width < TARGET_SIZE_X or v.image.height < TARGET_SIZE_Y then
            local new_image = obsi.graphics.newBlankImage(TARGET_SIZE_X, TARGET_SIZE_Y, -1)

            -- center the old data in the new data
            local x_offset = math.floor((TARGET_SIZE_X - v.image.width) / 2)
            local y_offset = math.floor((TARGET_SIZE_Y - v.image.height) / 2)

            for x = 1, v.image.width do
                for y = 1, v.image.height do
                    new_image.data[y + y_offset][x + x_offset] = v.image.data[y][x]
                end
            end

            -- update original image to new image
            v.image = new_image
        elseif v.image.width > TARGET_SIZE_X or v.image.height > TARGET_SIZE_Y then
            -- crop the data and sizes to the target size
            local new_image = obsi.graphics.newBlankImage(TARGET_SIZE_X, TARGET_SIZE_Y, -1)
            for x = 1, TARGET_SIZE_X do
                for y = 1, TARGET_SIZE_Y do
                    new_image.data[y][x] = v.image.data[y][x]
                end
            end
            v.image = new_image
        end
    end
end

local can_spin = true
local spinning = false
local spin_start_time = 0

local stop_variances = { 0, 0, 0 }

function obsi.update()
    if can_spin and obsi.keyboard.isScancodeDown(keys.space) and not spinning then
        -- give each stop variance a small random value
        for i = 1, 3 do
            stop_variances[i] = math.random(-0.05, 0.2)
        end

        -- start spin
        can_spin = false
        spinning = true
        spin_start_time = obsi.timer.getTime()
    end

    local diff = obsi.timer.getTime() - spin_start_time

    if spinning and diff > 3 then
        -- stop spin after 3 seconds
        spinning = false

        -- determine payout
        local payout = 0

        local symbol_1 = reel[reel_pos[1]]
        local symbol_2 = reel[reel_pos[2]]
        local symbol_3 = reel[reel_pos[3]]

        if symbol_1 == symbol_2 and symbol_2 == symbol_3 then
            -- all three symbols match
            payout = symbols[symbol_1].payout.triple or 0
        elseif symbol_1 == symbol_2 or symbol_2 == symbol_3 or symbol_1 == symbol_3 then
            -- two symbols match
            payout = symbols[symbol_1].payout.double or 0
        else
            -- no match
        end

        if payout > 0 then
            error("Congratulations! You won " .. payout .. " coins!")
        else
            can_spin = true
        end
    end

    -- spin animation
    for i = 1, 3 do
        if spinning then
            -- each reel stops staggerred
            if diff <= (i + stop_variances[i]) then
                reel_pos[i] = reel_pos[i] + 1
                if reel_pos[i] > #reel then
                    reel_pos[i] = 1
                end
            end
        end

        -- render each symbol
        local symbol_name = reel[reel_pos[i]]
        local symbol = symbols[symbol_name]

        obsi.graphics.draw(symbol.image, ((i - 1) * TARGET_SIZE_X) + 1, 1)
    end
end

obsi.init()
