-- SLOTS describes the usage of each slot in the turtle. As defined below it is:

-- F = fuel, S = sapling, W = Wood, I=Incoming
-- I W W W
-- W W W W
-- W W W S
-- F F F F
SLOTS = {incoming={start=1, stop=1},
         wood={start=2, stop=11},
         sapling={start=12, stop=12},
         fuel={start=13, stop=16}}

function getnextavailslot(item, toPush)
    -- getnextavailslot returns the slot number of the next non-full slot in the
    -- range of `item` (based on the SLOTS global table) and the qty available in
    -- that slot.
    --
    -- `item` must be one of "wood", "sapling", "fuel", and the return value
    -- will be in the range [1, 16], [1, 64] both inclusive.
    --
    -- if getnextavailslot fails to find any available slots, it will return -1, -1

    local t = SLOTS[item]
    for s=t.start, t.stop do
        local avail = 64 - turtle.getItemCount(s)
        if toPush then
            if (avail < 64) then 
                return s, 64-avail
            end
        else
            if (avail > 0) then
                return s, avail
            end
        end
    end
    return -1, -1
end

function itemmanage(slot)
    -- itemmanage will read what kind of item is in `slot` and move it to the
    -- appropriate slot as determined by getnextavailslot.

    i_slot, _ = getnextavailslot("incoming", false)
    turtle.select(slot)

    local item = turtle.getItemDetail(slot)
    local qty = turtle.getItemCount(slot)
    local itemtype
    if item == nil then
        return
    elseif item.name == "minecraft:sapling" then
        itemtype = "sapling"
    elseif item.name == "minecraft:log" then
        itemtype = "wood"
    elseif item.name == "minecraft:coal" then
        itemtype = "fuel"
    else
        turtle.dropUp()
        turtle.select(i_slot)
        return
    end

    while qty > 0 do
        local dSlot, dAvail = getnextavailslot(itemtype, false)
        if dSlot == dAvail == -1 then
            -- there is no available slot! Drop the item!
            turtle.dropUp()
            turtle.select(i_slot)
        end
        turtle.transferTo(dSlot, dAvail)
        qty = qty - dAvail
    end

    turtle.select(i_slot)

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
    else
        f = turtle.dig
        g = turtle.suck
    end

    f()
    while g() do
        itemmanage(turtle.getSelectedSlot())
    end -- suck until you don't grab anything anymore

end

function fellTree()
    -- precondition: turtle is immediately in front of the tree.
    -- postcondition: turtle is one square forward, but the tree is gone.

    local height = 1

    dig("forward")
    turtle.forward()
    dig("down")

    repeat
    	success, block = turtle.inspectUp()
    	local keepGoing = success and isTree(block)
        if keepGoing then
            dig("up")
            turtle.up()
            height = height + 1
        end
    until not keepGoing

    for h=height, 2, -1 do
        turtle.down()
    end

    dig("down")

    s_slot, _ = getnextavailslot("sapling", false)
    i_slot, _ = getnextavailslot("incoming", false)
    turtle.select(s_slot)
    turtle.placeDown()
    turtle.select(i_slot)
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
            turtle.suckDown()
            itemmanage(turtle.getSelectedSlot())
        end
    end
end

function turn(direction)
	-- turns the turtle to the next row in `direction`
	local f
	if direction == "left" then
		f, g = turtle.turnLeft, turtle.turnRight
	else
		f, g = turtle.turnRight, turtle.turnLeft
	end

	f()
	success, block = turtle.inspect()
	if success then
		if isTree(block) then
			fellTree()
		else
            g()
			return  -- we're in a corner.
		end
	end
	turtle.forward()
	f()
end

function reset()

    for slot=1, 16 do
        itemmanage(slot)
    end

    -- fill furnace, pick up fuel
    w_slot, _ = getnextavailslot("wood", true)
    f_slot, f_qty = getnextavailslot("fuel", false)

    if w_slot ~= -1 then
        turtle.turnRight()
        turtle.select(w_slot)
        turtle.drop(3)
        turtle.up()
        turtle.forward()
        turtle.dropDown(3)
        turtle.back()
        turtle.down()
        turtle.turnLeft()
    end
    if f_slot ~= -1 then
        turtle.turnRight()
        turtle.down()
        turtle.forward()
        turtle.select(f_slot)
        turtle.suckUp(f_qty)
        turtle.back()
        turtle.up()
        turtle.turnLeft()
    end

    -- fill chest
    turtle.turnLeft()
    while true do
        w_slot, qty = getnextavailslot("wood", true)
        if w_slot == -1 then
            break
        end
        turtle.select(w_slot)
        turtle.drop(qty)
    end
    turtle.turnRight()

    if turtle.getFuelLevel() < 160 then
        turtle.select(f_slot)
        turtle.refuel(3)
    end
    turtle.select(1)
end
    

function main()
	-- precondition: Turtle is at a corner of a flat 10x10 square, facing in, y= +1
	-- postcondition: Turtle is at the same corner as above at the same orientation.

    i_slot, _ = getnextavailslot("incoming", false)
    turtle.select(i_slot)

	for i=0, 10, 1 do
		clearForward(fellTree)
		if i % 2 == 1 then
			turn("right")
		else
			turn("left")
		end
	end

	turtle.turnRight()
	clearForward()
	turtle.turnRight()
	clearForward()  -- into home
	turtle.turnRight()
	turtle.turnRight()

end

function isTree(block)
	return (block.name == "minecraft:log") or (block.name == "minecraft:log2")
end

function run()
    while true do
        turtle.down()
        reset()
        turtle.up()
        main()
        sleep(180)
    end
end