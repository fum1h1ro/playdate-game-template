
local idx = 0

function playdate.update()
    if idx % 60 == 0 then
        print("update")
    end
    idx += 1
end


