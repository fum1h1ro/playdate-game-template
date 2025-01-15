local submodule = import "sub"
local submodule2 = import "sub2"

local idx = 0

function playdate.update()


    submodule.foo()



    while true do
        if idx % 60 == 0 then
            print("update")
        end
        idx = idx + 1
        coroutine.yield()
    end
end


