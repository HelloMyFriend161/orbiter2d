local G =  6.67430e-11

local cam_x = 0
local cam_y = 0
local cam_scale = 1
local cam_increment = 0.025

local player_mass = 500
local player_rotation = 0
local player_x = 400
local player_y = -100
local player_vx = 0
local player_vy = 0

local density = 500000
local SOI_size = 40
local celestial_bodies = {
    Earth = {x = 400, y = 100, r = 100, mass = 0, colour = {0, 255, 0}, moons = {}},
    Moon = {x = -2000, y = 0, r = 20, mass = 0, colour = {55, 55, 55}, moons = {}}
}
for i in pairs(celestial_bodies) do
    celestial_bodies[i].mass = density * celestial_bodies[i].r
end

celestial_bodies.Earth.moons = {celestial_bodies.Moon}

local timewarp = .5

local dt = 1

local r
local rr

local F
local theta

local function drawPlayerTriangle(x, y, rotation)
    local size = 10
    local points = {
        x + size * math.cos(rotation - math.pi / 2), y + size * math.sin(rotation - math.pi / 2),
        x - size * math.cos(rotation + math.pi / 6 - math.pi / 2), y - size * math.sin(rotation + math.pi / 6 - math.pi / 2),
        x - size * math.cos(rotation - math.pi / 6 - math.pi / 2), y - size * math.sin(rotation - math.pi / 6 - math.pi / 2)
    }

    love.graphics.polygon("fill", points)
end

function love.update()
    for i in pairs(celestial_bodies) do
        local dx = (celestial_bodies[i].x - player_x)
        local dy = (celestial_bodies[i].y - player_y)
        r = math.sqrt(dx * dx + dy * dy)

        F = G * (celestial_bodies[i].mass * player_mass) / (r * r) * timewarp
        theta = math.atan2(dx, dy)

        if r < celestial_bodies[i].r * SOI_size then
            if celestial_bodies[i].moons[1] then
                for x in pairs(celestial_bodies[i].moons) do
                    local dx2 = (celestial_bodies[i].moons[x].x - player_x)
                    local dy2 = (celestial_bodies[i].moons[x].y - player_y)
                    local r2 = math.sqrt(dx2 * dx2 + dy2 * dy2)

                    if r2 > (celestial_bodies[i].moons[x].r * SOI_size) then
                        player_vx = (player_vx + math.sin(theta) * F * dt)
                        player_vy = (player_vy + math.cos(theta) * F * dt)
                    end
                end
            else
                player_vx = (player_vx + math.sin(theta) * F * dt)
                player_vy = (player_vy + math.cos(theta) * F * dt)
            end
        end

        --// simple ground collision \\--
        if r < celestial_bodies[i].r then
            player_vx = player_vx - player_vx
            player_vy = player_vy - player_vy
        end
    end

    if love.keyboard.isDown("w") then
        player_vx = player_vx + math.sin(player_rotation) * -0.001 * timewarp
        player_vy = player_vy + math.cos(player_rotation) * -0.001 * timewarp
    elseif love.keyboard.isDown("s") then
        player_vx = player_vx + math.sin(player_rotation) * 0.001 * timewarp
        player_vy = player_vy + math.cos(player_rotation) * 0.001 * timewarp
    end
    if love.keyboard.isDown("a") then
        player_rotation = player_rotation + 0.025
    elseif love.keyboard.isDown("d") then
        player_rotation = player_rotation - 0.025
    end
    if love.keyboard.isDown("up") then
        cam_scale = cam_scale + cam_increment * cam_scale
    elseif love.keyboard.isDown("down") then
        cam_scale = cam_scale - cam_increment * cam_scale
    end
    if love.keyboard.isDown("1") then
        timewarp = .5
    elseif love.keyboard.isDown("2") then
        timewarp = 3
    elseif love.keyboard.isDown("3") then
        timewarp = 5
    elseif love.keyboard.isDown("4") then
        timewarp = 20
    elseif love.keyboard.isDown("5") then
        timewarp = 100
    elseif love.keyboard.isDown("6") then
        timewarp = 200
    end

    player_x = player_x + player_vx * timewarp
    player_y = player_y + player_vy * timewarp
    cam_x = player_x
    cam_y = player_y

    if cam_scale < 0.01 then
        cam_scale = 0.01
    elseif cam_scale > 50 then
        cam_scale = 50
    end

    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
end

function love.draw()

    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    -- Calculate the center of the screen
    local center_x = screen_width / 2
    local center_y = screen_height / 2

    -- Set the camera transformation
    love.graphics.push()
    love.graphics.scale(cam_scale)
    love.graphics.translate(center_x / cam_scale - cam_x, center_y / cam_scale - cam_y)

    for i in pairs(celestial_bodies) do
        love.graphics.setColor(celestial_bodies[i].colour[1], celestial_bodies[i].colour[2], celestial_bodies[i].colour[3])
        love.graphics.circle("fill", celestial_bodies[i].x, celestial_bodies[i].y, celestial_bodies[i].r)

        love.graphics.setColor(255,255,255,0.025)
        love.graphics.circle("fill", celestial_bodies[i].x, celestial_bodies[i].y, celestial_bodies[i].r * SOI_size)
    end
    love.graphics.setColor(255, 255, 255)
    drawPlayerTriangle(player_x, player_y, -player_rotation)

    local trajectory_x = player_vx
    local trajectory_y = player_vy

    local prev_line_x = player_x
    local prev_line_y = player_y

    local brk = false

    for i = 1, 50000 do
        for x in pairs(celestial_bodies) do
            local dx = celestial_bodies[x].x - prev_line_x
            local dy = celestial_bodies[x].y - prev_line_y
            r = math.sqrt(dx * dx + dy * dy)
            local rdx = prev_line_x - player_x
            local rdy = prev_line_y - player_y
            rr = math.sqrt(rdx * rdx + rdy * rdy)

            if r < celestial_bodies[x].r then brk = true end
            if rr < 1 and i > 100 then brk = true end

            F = G * (celestial_bodies[x].mass * player_mass) / (r * r)
            theta = math.atan2(dx, dy)

            if r < celestial_bodies[x].r * SOI_size then
                if celestial_bodies[x].moons[1] then
                    for y in pairs(celestial_bodies[x].moons) do
                        local dx2 = celestial_bodies[x].moons[y].x - prev_line_x
                        local dy2 = celestial_bodies[x].moons[y].y - prev_line_y
                        local r2 = math.sqrt(dx2 * dx2 + dy2 * dy2)

                        if r2 > celestial_bodies[x].moons[y].r * SOI_size then
                            trajectory_x = trajectory_x + (math.sin(theta) * F * dt)
                            trajectory_y = trajectory_y + (math.cos(theta) * F * dt)
                        end
                    end
                else
                    trajectory_x = trajectory_x + (math.sin(theta) * F * dt)
                    trajectory_y = trajectory_y + (math.cos(theta) * F * dt)
                end
            end
        end

        if brk == true then
            brk = false
            break
        end

        prev_line_x = prev_line_x + trajectory_x
        prev_line_y = prev_line_y + trajectory_y
        
        love.graphics.setColor(255,255,255,1-(i/50000))
        love.graphics.line(prev_line_x, prev_line_y, prev_line_x + trajectory_x, prev_line_y + trajectory_y)
    end

    -- Reset the camera transformation
    love.graphics.pop()
end