-- harvestTree.lua


-- SLOTS describes the usage of each slot in the turtle. As defined below it is:

-- F = fuel, S = sapling, W = Wood, I=Incoming
-- I W W W
-- W W W W
-- W W W S
-- F F F F
SLOTS = {incoming={start=1, stop=1},
         wood={start=2, stop=11},
         saplings={start=12, stop=12},
         fuel={start=13, stop=16}}

function goHome()

function getnextavailslot(item)
    -- getnextavailslot returns the slot number of the next non-full slot in the
    -- range of `item` (based on the SLOTS global table) and the qty available in
    -- that slot.
    --
    -- `item` must be one of "wood", "saplings", "fuel", and the return value
    -- will be in the range [1, 16], [1, 64] both inclusive.
    --
    -- if getnextavailslot fails to find any available slots, it will return -1, -1

    local t = SLOTS[item]
    for s=t.start, t.stop do
        local avail = 64 - turtle.getItemCount(s)
        if avail > 0 then
            return s, avail
        end
    end
    return -1, -1
end

function itemmanage(slot)
    -- itemmanage will read what kind of item is in `slot` and move it to the
    -- appropriate slot as determined by getnextavailslot.

    -- TODO: logic here to determind what kind of item it is
    local itemtype = "wood"
    local qty = turtle.getItemCount(slot)

    while qty > 0 do
        local dSlot, dAvail = getnextavailslot(itemtype)
        if dSlot == dAvail == -1 then
            -- there is no available slot! Drop the item!
            turtle.turnRight() -- we need to turn or turtle will pick it up
                               -- again immediately
            turtle.drop(slot)
            turtle.turnLeft()
        end
        turtle.transferTo(dSlot, dAvail)
        qty = qty - dAvail
    end

end

function dig(direction)
    local f  -- which dig function to call
    local g  -- which suck function to call
    if direction == "up" then
        f = turtle.digUp
        g = turtle.suckUp
    elseif direction == "down" then
        f = turtle.digDown
        g = turtle.suckDown
    else:
        f = turtle.dig
        g = turtle.suck
    end

    dSlot, _ = getnextavailslot("incoming")
    turtle.select(dSlot)
    f()
    while g() do
        itemmanage(turtle.getSelectedSlot())
    end -- suck until you don't grab anything anymore

end

function fellTree()
    -- precondition: turtle is immediately in front of the tree.
    -- postcondition: turtle is one square forward, but the tree is gone.

    local height = 2

    dig("forward")
    turtle.forward()
    dig("down")

    while turtle.detectUp() do
        dig("up")
        turtle.up()
        height = height + 1
    end

    for h=height, 2, -1 do
        turtle.down()
    end
end

function clearForward(f)
    -- postcondition: all trees from the current location to the next fencepost
    --                ahead will be cleared. Any block that isn't a fencepost will
    --                cause action `f` to be applied.
    while true do
        success, nextBlock = turtle.inspect()
        if success and isTree(nextBlock) then
            f()
        elseif success then
            -- there's a non-tree block ahead of me, I must be at the fence!
            return
        else
            turtle.forward()
        end
    end
end

function clearRow()
    -- precondition: turtle is inside the fenced in lumber area
    -- postcondition: all trees on the row are gone and the turtle is at the
    --                end of a row, facing the inside.

    clearForward(fellTree)

    -- We're now at the end of the row. We need to slide rows, move to one end
    -- of this new row, and about face to satisfy our postcondition.
    while true do
        turtle.turnLeft()
        success, nextBlock = turtle.inspect()
        if (not success) or (success and isTree(nextBlock)) then
            if success then
                fellTree()
            end
            turtle.forward()
            turtle.turnRight()
            clearForward(fellTree)
            turtle.turnLeft()
            turtle.turnLeft()
        end
end
