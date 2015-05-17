-----------------------------------------------------
-- KABOOM! by Kelli Shaver (kelli@kellishaver.com)
--
-- A simple Asteroids type game I built to learn Lua
-----------------------------------------------------

-- Load our assets and instantiate objects
function love.load()
  -- We have three asteroids, large, medium, and small
  -- Set their graphics, point value, and dimensions.
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

  -- For the scrolling background, we'll repeatedly stitch
  -- together two separate background objects, which we
  -- set up ehre.
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

  -- The speed at which the backgorund will scroll
  bgSpeed = 150

  -- An empty object that will hold our debris field.
  debris = {}

  -- Start the game on the title screen by setting the
  -- initial game mode to "title"
  gameMode = "title"

  -- Instantiate a few sounds we can call as needed.
  gameover = love.audio.newSource("assets/sounds/gameover.wav", "static")
  hit = love.audio.newSource("assets/sounds/hit.mp3", "static")
  kaboom = love.audio.newSource("assets/sounds/kaboom.mp3", "static")

  -- And also the background music, which we'll start
  -- looping right away once the game begins.
  music = love.audio.newSource("assets/sounds/music.mp3", "stream")
  music:setVolume(0.5)
  music:setLooping(true)

  -- Player object - very simple, holds score and ship.
  -- Most other game data is stored in the ship.
  player = {
    score = 0,
    lives = 3
  }

  -- The ship object - we set its sprite, dimensions, 
  -- laser sound effect, and its x,y coordinates on screen,
  -- where 0,0 is the top left corner of the screen.
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

  -- We're drawing a screen flash effect when we're hit
  -- with an asteroid, but we need to make a little timer
  -- for that, or it can get very.... seizure inducing,
  -- so we'll instantiate a timer here and later we'll
  -- make sure the screen doesn't flash more than once a
  -- second.
  showFlash = 0

  -- Set the title sceen artwork.
  title = love.graphics.newImage("assets/images/title.png")

  -- Load up 20 asteroids we can use (repeatedly) to
  -- draw the debgis field. We create 20 random ones
  -- instead of looping through the base 3 repeatedly
  -- to give us a good random spread of sizes, rather
  -- than an even distribution.
  for i=0,20 do
    addAsteroid()
  end
end

-- The main run loop!
function love.update(dt)

  -- The "play" game mode.
  if gameMode == "play" then

    -- Keyboard comands to move the ship.
    -- We're checking the ship's position relative to the size
    -- of the screen so we can keep it confined within the
    -- screen - note, don't forget when checking the
    -- bottom and right edges to take into account the ship's
    -- width and height.
    if love.keyboard.isDown("left") and ship.x > 0 then
      ship.x = ship.x - ship.speed*dt
    elseif love.keyboard.isDown("right") and ship.x < 800 - ship.width then
      ship.x = ship.x + ship.speed*dt
    elseif love.keyboard.isDown("up") and ship.y > 0 then
      ship.y = ship.y - ship.speed*dt
    elseif love.keyboard.isDown("down") and ship.y < 600 - ship.height then
      ship.y = ship.y + ship.speed*dt
    end

    -- Tables of debris and shots to remove from the
    -- screen - cleaning up after ourselves.
    local remDebris = {}
    local remShot = {}

    -- Loop through all of the shots 
    for i,v in ipairs(ship.shots) do
      -- When a shot moves off-screen, dump it into th e
      -- table of shots to remove from the game.
      v.x = v.x + dt * 250
      if v.x > 800 then
        table.insert(remShot, i)
      end

      -- Loop through our asteroids and see if we hit
      -- something.
      for ii,vv in ipairs(debris) do

        -- If we hit an asteroid (note we add a tiny bit of padding).
        if checkCollision(v.x, v.y, 5, 5, vv.x-3, vv.y-3, vv.width+6, vv.height+6) then

          -- Increas the player's score by the asteroid's point value
          player.score = player.score + vv.points

          -- Note that here we need to stop sounds that are
          -- already playing, before we play a new sound
          -- effect, otherwise the sound stage gets really
          -- muddy and unpleasant.

          -- Stop the laser sound if it's playing already
          ship.laser:stop()

          -- Stop the kaboom sound if it's playing already
          kaboom:stop()

          -- Play the kaboom sound
          love.audio.play(kaboom)

          -- If we hit one of the bit asteroids, we need to
          -- turn it into a medium sized asteroid.
          if vv.graphic == asteroids.large.graphic then

            -- We do that by modifying the properties of the
            -- asteroid instance to match those of the medium
            -- asteroid defined earlier.
            vv.graphic = asteroids.medium.graphic
            vv.points = asteroids.medium.points
            vv.width = asteroids.medium.width
            vv.height = asteroids.medium.height

            -- We also randomly set its speed, because an impact
            -- should affect speed, and we set its new x,y
            -- coordinates based on its dimensions at the larger
            -- size.
            vv.speed = math.random(100)+200
            vv.x = vv.x + asteroids.large.width/2 - asteroids.medium.width/2
            vv.y = vv.y + asteroids.large.height/2 - asteroids.medium.height/2

          -- And we do the same thing with medium asteroids, to
          -- turn them into small ones.
          elseif vv.graphic ==asteroids.medium.graphic then
            vv.graphic = asteroids.small.graphic
            vv.points = asteroids.small.points
            vv.width = asteroids.small.width
            vv.height = asteroids.small.height
            vv.speed = math.random(100)+250
            vv.x = vv.x + asteroids.medium.width/2 - asteroids.small.width/2
            vv.y = vv.y + asteroids.medium.height/2 - asteroids.small.height/2
          
          -- but if they're small to begin with, we can just
          -- go ahead and add them to the table of asteroids
          -- to be removed from the screen.
          else
            table.insert(remDebris, ii)
          end

          -- We're done examining the sh ot and it's hit
          -- an asteroid, so it doesn't need to stick
          -- around, so let's add it to the table of shots
          -- to be removed.
          table.insert(remShot, i)
        end
      end
    end

    -- Now check all of the debris on screen
    for i,v in ipairs(debris) do

      -- Let's give the asteroids a bit of rotation just
      -- for fun.
      v.rotation = v.rotation + 0.2
      v.x = v.x - dt * v.speed

      -- Much like we checked to see if the ship was still
      -- on the screen, here we'll check to see if the
      -- asteroids are still on the screen and add them
      -- to the table of asteroids to be removed if they're
      -- not.
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

      -- Next, we check for a collision with the ship - no padding this
      -- time. The pilot's got it hard enough as it is. :)
      if checkCollision(ship.x, ship.y, ship.width, ship.height, v.x, v.y, v.width, v.height) then

        -- Once again, stop previously playing sounds
        -- Then we'll play the ship's "hit" sound that
        -- we set on it on game load.
        kaboom:stop()
        hit:stop()
        love.audio.play(hit)
        showFlash = 1

        -- Once an asteroid hits the ship, it's destroyed
        -- and needs to be removed from the game
        table.remove(debris, i)

        -- Decrease the number of lives the player has left.
        player.lives = player.lives - 1

        -- Decrease the player's score, but don't let it
        -- go into the negatives.
        if player.score > 100 then
          player.score = player.score - 100
        else
          player.score = 0
        end

        -- If that was the player's last life, stop all
        -- audio, play the game over sound, and then
        -- switch game modes to show the game over screen.
        if(player.lives < 0) then
          love.audio.stop()
          love.audio.play(gameover)
          gameMode  = "gameover"
        end
      end
    end

    -- Now we can remove all of that debris.
    for i,v in ipairs(remDebris) do
      table.remove(debris, v)
      addAsteroid()
    end

    -- And those shots.
    for i,v in ipairs(remShot) do
      table.remove(ship.shots, v)
    end


    -- Here's that timer for the flash effect.
    if showFlash > 0 and showFlash < 1000 then
      showFlash = showFlash + 1
    end

    -- Finally, let's scroll the background.
    -- Adjust background x coordinate based on
    -- background speed.
    bg1.x = bg1.x - bgSpeed * dt
    bg2.x = bg2.x - bgSpeed * dt

    -- Do the background stitching.
    -- Keep putting them end to end - as one scrolls off
    -- the screen to the left, attach it to the far right
    -- of the other background.
    if bg1.x <= 0 - bg1.width then
      bg1.x = bg2.x + bg2.width
    end
    if bg2.x <= 0 - bg2.width then
      bg2.x = bg1.x + bg1.width
    end

  -- Show the game over screen and reset some
  -- stuff, so the game isn't a mess if the
  -- player wants to play again.
  elseif gameMode == "gameover" then

    -- Remove all the debris.
    for i,v in ipairs(debris) do
      if v.x < 800 then
        table.remove(debris, i)
        addAsteroid()
      end
    end

    -- Remove all the shots.
    for i,v in ipairs(ship.shots) do
      table.remove(ship.shots, i)
    end
  end

end

-- Now to actually draw the game.
function love.draw()

  -- Applicationw indow title
  love.window.setTitle("Kaboom")

  -- If we're switching into the play mode...
  if gameMode == "play" then

    -- Set music, background, and draw the ship.
    love.audio.play(music)
    love.graphics.draw(bg1.graphic, bg1.x, 0)
    love.graphics.draw(bg2.graphic, bg2.x, 0)
    love.graphics.draw(ship.graphic, ship.x, ship.y)

    -- Loop th rough that table fo 20 asteroids we
    -- created in the beginning and draw them.
    for i,v in ipairs(debris) do
      if v.width == asteroids.large.width then
        love.graphics.draw(v.graphic, v.x, v.y)
      else
        love.graphics.draw(v.graphic, v.x, v.y, v.rotation*math.pi/180, 1, 1, v.width/2, v.height/2)
      end
    end

    -- Draw the shots - tiny white rectangles.
    love.graphics.setColor(255,255,255,255)
    for i,v in ipairs(ship.shots) do
      love.graphics.rectangle("fill", v.x, v.y, 5, 2)
    end

    -- Print the score and remaining lives.
    love.graphics.print("SCORE: " .. player.score, 10, 10)
    love.graphics.print("LIVES: " .. player.lives, 700, 10)

    -- Here's where we actually do that flash and make
    -- the screen red for a bit.
    if showFlash > 0 and showFlash < 10 then
      love.graphics.setColor(255,0,0,50)
      love.graphics.rectangle("fill", 0, 0, 800, 600)
    end

  -- Title mode is much simpler, just draw the title screen.
  elseif gameMode == "title" then
    love.audio.stop()
    love.graphics.draw(title, 0, 0)

  -- Similarly, draw the game over screen.
  else
    -- White text showing "GAME OVER" message, socre below,
    -- and game options in the lower left.
    love.graphics.setColor(255,255,255,255)
    love.graphics.print("GAME OVER", 320, 270, 0, 2, 2)
    love.graphics.print("FINAL SCORE: " .. player.score, 320, 300)
    love.graphics.print("Press 'c' to continue. Press 't' to tweet your score....", 10, 580)
  end
end

-- Key bindings.
function love.keyreleased(key)
  if gameMode == "play" then

    -- Space bar - add a shot and play the laser sound.
    if (key == " ") then
      local shot = {}
      shot.x = ship.x+ship.width
      shot.y = ship.y+ship.height/2
      table.insert(ship.shots, shot)
      ship.laser:stop()
      love.audio.play(ship.laser)

    -- Escape - exit to title screen.
    elseif (key == "escape") then
      gameMode = "title"
    end
  elseif gameMode == "title" then
    -- Space bar to start the gtame.
    if (key == " ") then
      player.score = 0
      player.lives = 3
      gameMode = "play"
    end
  elseif gameMode == "gameover" then
    -- "C" to go back to the title screen.
    if (key == "c") then
      gameMode = "title"
    end

    -- "T" to tweet your score!
    if (key == "t") then
      openURL()
    end
  end
end

-- The addAsteroid function we call atove needs
-- to do a few things.
function addAsteroid()
  -- Set a random seed  so we can set a random
  -- asteroid size.
  local seed = math.random(100)

  -- Make a small one.
  if seed < 25 then
    local asteroid = {
      -- Give it the properties of a small asteroid
      points = asteroids.small.points,
      graphic = asteroids.small.graphic,
      width = asteroids.small.width,
      height = asteroids.small.height,

      -- Set a random rotation speed and random
      -- starting coordinates.
      rotation = math.random(360),
      speed = math.random(100)+250,
      x = math.random(3200)+800,
      y = math.random(600-asteroids.large.height/2)
    }
    table.insert(debris, asteroid)

  -- And do the same for a medium asteroid (the most common)
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

  -- And the large asteroids.
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

    -- Finally, add the asteroid to the debris table.
    table.insert(debris, asteroid)
  end
end

-- We rolled our own check collision function here because there's
-- no point in including an entire additional game library for one
-- function. 
--
-- We're using the width,  height, and coordinates of both objects
-- to basically create two bounding boxes and then we just compare
-- them to see if they overlap.
function checkCollision(ax1,ay1,aw,ah, bx1,by1,bw,bh)
  local ax2,ay2,bx2,by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
  return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end

-- Tweeting your score opens Twitter's share URL.
function openURL()

  -- The message is just encoded in the URL.
  url = "https://twitter.com/intent/tweet?text=I+just+scored+".. player.score .."+points+playing+Kaboom.+http%3A%2F%2Fkellishaver.com/kaboom"

  -- And the manner in which we open that URL differs a bit
  -- depending on the host operating system.
  local os1 = love._os
  if os1 == "OS X" then
     os.execute("open "..url)
  elseif os1 == "Windows" then
     os.execute("start "..url)
  elseif os1 == "Linux" then
     os.execute("xdg-open "..url)
  end
end
