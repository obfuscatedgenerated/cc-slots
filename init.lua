local obsi = require "/lib/obsi2"

local casino
if fs.exists("/clientlib.lua") then
    casino = require "/clientlib"
end

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
    elseif symbol_1 == symbol_2 or symbol_1 == symbol_3 then
        payout = symbols[symbol_1].payout.double or 0
    elseif symbol_2 == symbol_3 then
        payout = symbols[symbol_2].payout.double or 0
    end

    return payout
end

local holds = { false, false, false }
local holds_available = 0

local function update_reel(reel_idx, diff, left_margin, top_margin)
    if left_margin == nil then left_margin = 1 end
    if top_margin == nil then top_margin = 1 end

    -- don't apply spin logic if reel is held
    if spinning and not holds[reel_idx] then
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

    -- draw hold status above image if held
    if holds[reel_idx] then
        local hold_text = "(HOLD)"
        local hold_text_x = left_margin + math.floor((gap + (reel_idx - 1) * symbol.image.width - #hold_text) / 2) - 1
        obsi.graphics.write(hold_text, hold_text_x, math.floor(top_margin / 2) - 3)
    end
end

local function list_contains(list, value)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

local offered_hold_last_spin = false
local function offer_holds()
    -- in actual fruit machines, holds are a bit deceptive as the game already knows what the next symbols will be
    -- in this one, since the rtp is so low, these are actual strategic advantages and the game knows nothing about the next symbols
    
    -- for high value doubles:
    -- 50% chance to offer 2 holds
    -- 30% chance to offer 1 hold
    -- 20% chance to offer no holds

    -- for low value doubles:
    -- 20% chance to offer 1 hold
    -- 80% chance to offer no holds

    -- for no doubles:
    -- 5% chance to offer 1 hold

    if offered_hold_last_spin then
        -- don't offer holds two spins in a row
        offered_hold_last_spin = false
        holds_available = 0
        return
    end

    local symbol_1 = reels.reel[reel_pos[1]]
    local symbol_2 = reels.reel[reel_pos[2]]
    local symbol_3 = reels.reel[reel_pos[3]]

    local high_value = {
        "bar_single",
        "bar_double",
        "bar_triple",
        "jackpot",
        "seven",
        "bell",
    }

    if symbol_1 == symbol_2 and symbol_2 == symbol_3 then
        -- triple - no holds
        return
    elseif symbol_1 == symbol_2 or symbol_1 == symbol_3 or symbol_2 == symbol_3 then
        -- deterime which symbol is the double
        local double_symbol = symbol_1
        if symbol_1 ~= symbol_2 then
            double_symbol = symbol_2
        end
        if symbol_1 ~= symbol_3 and symbol_2 ~= symbol_3 then
            double_symbol = symbol_3
        end

        if list_contains(high_value, double_symbol) then
            -- high value double

            local roll = math.random(1, 100)
            if roll <= 50 then
                holds_available = 2
            elseif roll <= 80 then
                holds_available = 1
            end
        else
            -- low value double

            local roll = math.random(1, 100)
            if roll <= 20 then
                holds_available = 1
            end
        end
    else
        -- no doubles
        local roll = math.random(1, 100)
        if roll <= 5 then
            holds_available = 1
        else
            holds_available = 0
        end
    end

    if holds_available > 0 then
        offered_hold_last_spin = true
    end
end

local function toggle_hold(reel_idx)
    if not can_spin or spinning then
        return
    end


    if holds[reel_idx] then
        -- give back a hold if abandoning a hold
        holds[reel_idx] = false
        holds_available = holds_available + 1
    else
        if holds_available > 0 then
            -- use a hold if applying a hold
            holds[reel_idx] = true
            holds_available = holds_available - 1
        end
    end
end

local played_sounds = { true, true, true }
local payout_next_sec = false

local toast = nil
local toast_start_time = nil
local toast_duration = 3

local hold_waiting_keyup = false

local function show_toast(text, duration)
    if duration then
        toast_duration = duration
    end

    toast_start_time = obsi.timer.getTime()
    toast = text
end

function obsi.update()
    -- draw bottom text
    local bottom_text = "Press SPACE to spin!"
    if casino then bottom_text = "2 chips a play. " .. bottom_text end

    local bottom_text_x = math.floor((obsi.graphics.getWidth() - #bottom_text) / 2)
    obsi.graphics.write(bottom_text, bottom_text_x, obsi.graphics.getHeight() - 1)

    -- draw a toast if available
    if toast and obsi.timer.getTime() - toast_start_time < toast_duration then
        local text_x = math.floor((obsi.graphics.getWidth() - #toast) / 2)
        obsi.graphics.write(toast, text_x, 2)
    end

    -- draw holds available if any
    if holds_available > 0 then
        local holds_text = "Holds available: " .. holds_available
        local holds_text_x = math.floor((obsi.graphics.getWidth() - #holds_text) / 2)
        obsi.graphics.write(holds_text, holds_text_x, obsi.graphics.getHeight() - 4)

        local holds_instruction_text = "Press 1, 2, 3 to toggle hold on a reel."
        local holds_instruction_text_x = math.floor((obsi.graphics.getWidth() - #holds_instruction_text) / 2)
        obsi.graphics.write(holds_instruction_text, holds_instruction_text_x, obsi.graphics.getHeight() - 3)
    end

    local iden_id

    -- toggle holds if number keys are pressed
    if obsi.keyboard.isScancodeDown(keys.one) then
        if not hold_waiting_keyup then
            hold_waiting_keyup = true
            toggle_hold(1)
        end
    elseif obsi.keyboard.isScancodeDown(keys.two) then
        if not hold_waiting_keyup then
            hold_waiting_keyup = true
            toggle_hold(2)
        end
    elseif obsi.keyboard.isScancodeDown(keys.three) then
        if not hold_waiting_keyup then
            hold_waiting_keyup = true
            toggle_hold(3)
        end
    else
        hold_waiting_keyup = false
    end

    -- start the spin if space is pressed
    if can_spin and not spinning and obsi.keyboard.isScancodeDown(keys.space) then
        -- take player money if casino module loaded
        if casino then
            -- Read player's identity
            local id = casino.read_card_identity()
            if not id then
                show_toast("Please insert a card with chips to play!")
                return
            end

            local iden = casino.fetch_identity(id)
            if not iden then
                show_toast("ID error. Please try again or ask for help.")
                return
            end

            iden_id = iden.id

            -- Check if the balance is enough to play
            if iden.chips < 2 then
                show_toast("Please top up your chips!")
                return
            end

            -- Deduct 2 chips from the player's balance
            local decrease_balance_response, decrease_balance_err = casino.decrease_balance(iden.id, 2)
            if not decrease_balance_response then
                show_toast("Chip error. Please try again or ask for help.")
                return
            end
        end

        -- randomise stop variances for each reel
        for i = 1, 3 do
            stop_variances[i] = math.random(-0.05, 0.3)
        end

        -- start spin
        holds_available = 0
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

            local chips_plural = "chip"
            if payout > 1 then
                chips_plural = "chips"
            end
            show_toast("You won " .. payout .. " " .. chips_plural .. "!", 3)

            if iden_id and casino then
                casino.increase_balance(iden_id, payout)
            end
        end

        holds = { false, false, false }
        holds_available = 0
        offer_holds()

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

    -- TODO: implement nudge (might want a way to preview what comes next)
end

obsi.init()
