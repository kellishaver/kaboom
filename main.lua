function love.load()
  asteroids = {
    small = {
      points = 100,
      graphic = love.graphics.newImage("assets/images/asteroid_s.png"),
      width = 25,
      height = 25
    },
    medium = {
      points = 75,
      graphic = love.graphics.newImage("assets/images/asteroid_m.png"),
      width = 50,
      height = 50
    },
    large = {
      points = 25,
      graphic = love.graphics.newImage("assets/images/asteroid_l.png"),
      width = 140,
      height = 140
    }
  }

  bg1 = {
    graphic = love.graphics.newImage("assets/images/bg1.png"),
    x = 0,
    width = 3200
  }

  bg2 = {
    graphic = love.graphics.newImage("assets/images/bg2.png"),
    x = -3200,
    width = 3200
  }

  bgSpeed = 150

  debris = {}

  gameMode = "title"

  gameover = love.audio.newSource("assets/sounds/gameover.wav", "static")
  hit = love.audio.newSource("assets/sounds/hit.mp3", "static")
  kaboom = love.audio.newSource("assets/sounds/kaboom.mp3", "static")

  music = love.audio.newSource("assets/sounds/music.mp3", "stream")
  music:setVolume(0.5)
  music:setLooping(true)

  player = {
    score = 0,
    lives = 3
  }

  ship = {
    graphic = love.graphics.newImage("assets/images/ship.png"),
    height = 50,
    laser = love.audio.newSource("assets/sounds/pew.mp3", "static"),
    shots = {},
    speed = 200,
    width = 50,
    x = 75,
    y = 275
  }

  showFlash = 0

  title = love.graphics.newImage("assets/images/title.png")

  for i=0,20 do
    addAsteroid()
  end
end

function love.update(dt)
  if gameMode == "play" then
    if love.keyboard.isDown("left") and ship.x > 0 then
      ship.x = ship.x - ship.speed*dt
    elseif love.keyboard.isDown("right") and ship.x < 800 - ship.width then
      ship.x = ship.x + ship.speed*dt
    elseif love.keyboard.isDown("up") and ship.y > 0 then
      ship.y = ship.y - ship.speed*dt
    elseif love.keyboard.isDown("down") and ship.y < 600 - ship.height then
      ship.y = ship.y + ship.speed*dt
    end

    local remDebris = {}
    local remShot = {}

    for i,v in ipairs(ship.shots) do
      v.x = v.x + dt * 250
      if v.x > 800 then
        table.insert(remShot, i)
      end
      for ii,vv in ipairs(debris) do
        if checkCollision(v.x, v.y, 5, 5, vv.x-3, vv.y-3, vv.width+6, vv.height+6) then
          player.score = player.score + vv.points

          ship.laser:stop()
          kaboom:stop()
          love.audio.play(kaboom)
          if vv.graphic == asteroids.large.graphic then
            vv.graphic = asteroids.medium.graphic
            vv.points = asteroids.medium.points
            vv.width = asteroids.medium.width
            vv.height = asteroids.medium.height
            vv.speed = math.random(100)+200
            vv.x = vv.x + asteroids.large.width/2 - asteroids.medium.width/2
            vv.y = vv.y + asteroids.large.height/2 - asteroids.medium.height/2
          elseif vv.graphic ==asteroids.medium.graphic then
            vv.graphic = asteroids.small.graphic
            vv.points = asteroids.small.points
            vv.width = asteroids.small.width
            vv.height = asteroids.small.height
            vv.speed = math.random(100)+250
            vv.x = vv.x + asteroids.medium.width/2 - asteroids.small.width/2
            vv.y = vv.y + asteroids.medium.height/2 - asteroids.small.height/2
          else
            table.insert(remDebris, ii)
          end
          table.insert(remShot, i)
        end
      end
    end

    for i,v in ipairs(debris) do
      v.rotation = v.rotation + 0.2
      v.x = v.x - dt * v.speed
      if v.x < -100 then
        table.insert(remDebris, i)
        if v.width == 25 and player.score > 0 then
          player.score = player.score - 1
        elseif v.width == 50 and player.score > 3 then
          player.score = player.score - 3
        elseif player.score > 5 then
          player.score = player.score - 5
        end
      end
      if checkCollision(ship.x, ship.y, ship.width, ship.height, v.x, v.y, v.width, v.height) then
        kaboom:stop()
        hit:stop()
        love.audio.play(hit)
        showFlash = 1
        table.remove(debris, i)
        player.lives = player.lives - 1
        if player.score > 100 then
          player.score = player.score - 100
        end
        if(player.lives < 0) then
          love.audio.stop()
          love.audio.play(gameover)
          gameMode  = "gameover"
        end
      end
    end

    for i,v in ipairs(remDebris) do
      table.remove(debris, v)
      addAsteroid()
    end

    for i,v in ipairs(remShot) do
      table.remove(ship.shots, v)
    end

    bg1.x = bg1.x - bgSpeed * dt
    bg2.x = bg2.x - bgSpeed * dt

    if bg1.x <= 0 - bg1.width then
      bg1.x = bg2.x + bg2.width
    end
    if bg2.x <= 0 - bg2.width then
      bg2.x = bg1.x + bg1.width
    end
  elseif gameMode == "gameover" then
    for i,v in ipairs(debris) do
      if v.x < 800 then
        table.remove(debris, i)
        addAsteroid()
      end
    end
    for i,v in ipairs(ship.shots) do
      table.remove(ship.shots, i)
    end
  end

  if showFlash > 0 and showFlash < 1000 then
    showFlash = showFlash + 1
  end

end

function love.draw()
  love.window.setTitle("Kaboom")
  if gameMode == "play" then
    love.audio.play(music)
    love.graphics.draw(bg1.graphic, bg1.x, 0)
    love.graphics.draw(bg2.graphic, bg2.x, 0)

    love.graphics.draw(ship.graphic, ship.x, ship.y)

    for i,v in ipairs(debris) do
      if v.width == asteroids.large.width then
        love.graphics.draw(v.graphic, v.x, v.y)
      else
        love.graphics.draw(v.graphic, v.x, v.y, v.rotation*math.pi/180, 1, 1, v.width/2, v.height/2)
      end
    end

    love.graphics.setColor(255,255,255,255)
    for i,v in ipairs(ship.shots) do
      love.graphics.rectangle("fill", v.x, v.y, 5, 2)
    end

    love.graphics.print("SCORE: " .. player.score, 10, 10)
    love.graphics.print("LIVES: " .. player.lives, 700, 10)

    if showFlash > 0 and showFlash < 10 then
      love.graphics.setColor(255,0,0,50)
      love.graphics.rectangle("fill", 0, 0, 800, 600)
    end

  elseif gameMode == "title" then
    love.audio.stop()
    love.graphics.draw(title, 0, 0)
  else
    love.graphics.setColor(255,255,255,255)
    love.graphics.print("GAME OVER", 320, 270, 0, 2, 2)
    love.graphics.print("FINAL SCORE: " .. player.score, 320, 300)
    love.graphics.print("Press 'c' to continue. Press 't' to tweet your score....", 10, 580)
  end
end

function love.keyreleased(key)
  if gameMode == "play" then
    if (key == " ") then
      local shot = {}
      shot.x = ship.x+ship.width
      shot.y = ship.y+ship.height/2
      table.insert(ship.shots, shot)
      ship.laser:stop()
      love.audio.play(ship.laser)
    elseif (key == "escape") then
      gameMode = "title"
    end
  elseif gameMode == "title" then
    if (key == " ") then
      player.score = 0
      player.lives = 3
      gameMode = "play"
    end
  elseif gameMode == "gameover" then
    if (key == "c") then
      gameMode = "title"
    end
    if (key == "t") then
      openURL()
    end
  end
end

function addAsteroid()
  local seed = math.random(100)
  if seed < 25 then
    local asteroid = {
      points = asteroids.small.points,
      graphic = asteroids.small.graphic,
      width = asteroids.small.width,
      height = asteroids.small.height,
      rotation = math.random(360),
      speed = math.random(100)+250,
      x = math.random(3200)+800,
      y = math.random(600-asteroids.large.height/2)
    }
    table.insert(debris, asteroid)
  elseif seed < 75 then
    local asteroid = {
      points = asteroids.medium.points,
      graphic = asteroids.medium.graphic,
      width = asteroids.medium.width,
      height = asteroids.medium.height,
      rotation = math.random(360),
      speed = math.random(100)+200,
      x = math.random(3200)+800,
      y = math.random(600-asteroids.large.height/2)
    }
    table.insert(debris, asteroid)
  else
    local asteroid = {
      points = asteroids.large.points,
      graphic = asteroids.large.graphic,
      width = asteroids.large.width,
      height = asteroids.large.height,
      rotation = math.random(360),
      speed = math.random(100)+150,
      x = math.random(3200)+800,
      y = math.random(600-asteroids.large.height/2)
    }
    table.insert(debris, asteroid)
  end
end

function checkCollision(ax1,ay1,aw,ah, bx1,by1,bw,bh)
  local ax2,ay2,bx2,by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
  return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end

function openURL()
   url = "https://twitter.com/intent/tweet?text=I+just+scored+".. player.score .."+points+playing+Kaboom.+http%3A%2F%2Fkaboom-game.herokuapp.com"
   local os1 = love._os
   if os1 == "OS X" then
      os.execute("open "..url)
   elseif os1 == "Windows" then
      os.execute("start "..url)
   elseif os1 == "Linux" then
      os.execute("xdg-open "..url)
   end
end
