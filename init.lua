local obsi = require "/lib/obsi2"

local symbols = require "symbols"
local load_symbol_images = symbols.load_symbol_images
symbols = symbols.symbols

local reels = require "reels"

local play_sound = require "play_sound"

local reel_pos = reels.random_reels()

local sounds = {}

local spinning = false
local can_spin = true
local spin_start_time = 0

local stop_variances = { 0, 0, 0 }

function obsi.load()
    load_symbol_images()

    -- load sound effects
    sounds.reel1 = "sounds/reel1.wav"
    sounds.reel2 = "sounds/reel2.wav"
    sounds.reel3 = "sounds/reel3.wav"
    sounds.win = "sounds/win.wav"
    sounds.jackpot = "sounds/jackpot.wav"
end


local function calculate_payout()
    local payout = 0

    local symbol_1 = reels.reel[reel_pos[1]]
    local symbol_2 = reels.reel[reel_pos[2]]
    local symbol_3 = reels.reel[reel_pos[3]]

    if symbol_1 == symbol_2 and symbol_2 == symbol_3 then
        payout = symbols[symbol_1].payout.triple or 0
    elseif symbol_1 == symbol_2 or symbol_2 == symbol_3 or symbol_1 == symbol_3 then
        payout = symbols[symbol_1].payout.double or 0
    end

    return payout
end

local function update_reel(reel_idx, diff, left_margin, top_margin)
    if left_margin == nil then left_margin = 1 end
    if top_margin == nil then top_margin = 1 end

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
    local symbol = symbols[symbol_name]

    local gap = 2
    if reel_idx == 1 then
        gap = 0
    end

    obsi.graphics.draw(symbol.image, left_margin + ((reel_idx - 1) * symbol.image.width) + gap, top_margin)
end

local played_sounds = {true, true, true}
local payout_next_sec = false

function obsi.update()
    -- TODO: take player money

    -- start the spin if space is pressed
    if can_spin and not spinning and obsi.keyboard.isScancodeDown(keys.space) then
        -- randomise stop variances for each reel
        for i = 1, 3 do
            stop_variances[i] = math.random(-0.05, 0.3)
        end

        -- start spin
        played_sounds = {}
        redstone.setOutput("top", false)

        spinning = true
        can_spin = false
        spin_start_time = obsi.timer.getTime()
    end

    local diff = obsi.timer.getTime() - spin_start_time


    -- stop the spin after 3 seconds
    if spinning and diff >= 3 then
        spinning = false

        -- another scuffed way to delay something, no setTimer sighh..
        payout_next_sec = true
    end

    if payout_next_sec and diff >= 4 then
        payout_next_sec = false

        local payout = calculate_payout()
        if payout > 0 then
            -- play the right sound
            if payout == symbols.jackpot.payout.triple then
                -- light up our light and play the sound
                redstone.setOutput("top", true)
                play_sound(sounds.jackpot)
            else
                play_sound(sounds.win)
            end

            -- TODO: payout the player
        end

        can_spin = true
    end

    -- compute margins to center the reels (each reel image will have the same dimensions so we can use the first one)
    local left_margin = math.floor((obsi.graphics.getPixelWidth() - (3 * symbols.cherry.image.width)) / 2)
    local top_margin = math.floor((obsi.graphics.getPixelHeight() - (symbols.cherry.image.height)) / 2)

    -- update and draw the reels
    for i = 1, 3 do
        -- if the time for a sound to be played is passed, play the sound and marked it as played
        -- this is a bit scuffedm but its the easiest way to schedule a sound to play at a certain time without repeating it every frame
        if not played_sounds[i] and diff >= (i + stop_variances[i]) then
            play_sound(sounds["reel" .. i])
            played_sounds[i] = true
        end

        update_reel(i, diff, left_margin, top_margin)
    end

    -- TODO: nudge and hold
end

obsi.init()
