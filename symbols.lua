local obsi = require "/lib/obsi2"

local symbols = {
    cherry = { name = "cherry", image = nil, payout = { double = 1, triple = 2 } },
    lemon = { name = "lemon", image = nil, payout = { double = 3, triple = 6 } },
    orange = { name = "orange", image = nil, payout = { double = 3, triple = 5 } },
    plum = { name = "plum", image = nil, payout = { double = 3, triple = 8 } },
    grape = { name = "grape", image = nil, payout = { double = 3, triple = 4 } },
    seven = { name = "seven", image = nil, payout = { triple = 60 } },
    bell = { name = "bell", image = nil, payout = { triple = 12 } },
    bar_single = { name = "bar_single", image = nil, payout = { triple = 15 } },
    bar_double = { name = "bar_double", image = nil, payout = { triple = 25 } },
    bar_triple = { name = "bar_triple", image = nil, payout = { triple = 35 } },
    jackpot = { name = "jackpot", image = nil, payout = { triple = 120 } },
}
local TARGET_SIZE_X, TARGET_SIZE_Y = 24, 24

local function load_symbol_images()
    for k, v in pairs(symbols) do
        v.image = obsi.graphics.newImage("symbols/" .. k .. ".nfp")

        -- resize the image to the target size
        if v.image.width < TARGET_SIZE_X or v.image.height < TARGET_SIZE_Y then
            -- padding

            local new_image = obsi.graphics.newBlankImage(TARGET_SIZE_X, TARGET_SIZE_Y, -1)

            -- Center the old data in the new data
            local x_offset = math.floor((TARGET_SIZE_X - v.image.width) / 2)
            local y_offset = math.floor((TARGET_SIZE_Y - v.image.height) / 2)

            for x = 1, v.image.width do
                for y = 1, v.image.height do
                    new_image.data[y + y_offset][x + x_offset] = v.image.data[y][x]
                end
            end
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

return {
    symbols = symbols,
    load_symbol_images = load_symbol_images,
}
