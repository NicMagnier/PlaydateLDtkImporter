player = {}

function player.create()
	player.sprite = playdate.graphics.sprite.new( playdate.graphics.image.new( "images/player") )
	player.sprite:setCollideRect( 0,0, player.sprite:getSize() )
end

function player.init( ldtk_entity )
	player.sprite:setZIndex( ldtk_entity.zIndex )
	player.sprite:moveTo( ldtk_entity.position.x, ldtk_entity.position.y)
	player.sprite:setCenter( ldtk_entity.center.x, ldtk_entity.center.y )

	player.isGrounded = false
	player.justLanded = false
	player.bangCeiling = false
	player.groundedLast = 0
	player.lastJumpPress = live.jump_buffer
	player.jumpPressDuration = 0

	player.velocity = playdate.geometry.vector2D.new(0,0)

	player.sprite:setImageFlip( playdate.graphics.kImageUnflipped )
end

function player.update()
	local dt = 1 / playdate.display.getRefreshRate()

	-- Friction
	if player.isGrounded then
		if not playdate.buttonIsPressed( playdate.kButtonLeft | playdate.kButtonRight ) then
			player.velocity.x = approach(player.velocity.x, 0, live.player_ground_friction)
		end
		player.velocity.y = 0
	else
		if not playdate.buttonIsPressed( playdate.kButtonLeft | playdate.kButtonRight ) then
			player.velocity.x = approach(player.velocity.x, 0, live.player_air_friction)
		end

		if player.bangCeiling then
			player.velocity.y = 0
		end
	end

	-- move left/right
	if playdate.buttonIsPressed( playdate.kButtonLeft ) then
		player.velocity.x = approach(player.velocity.x, -live.player_speed, live.player_acc)
		player.sprite:setImageFlip(playdate.graphics.kImageFlippedX)
	end
	if playdate.buttonIsPressed( playdate.kButtonRight ) then
		player.velocity.x = approach(player.velocity.x, live.player_speed, live.player_acc) 
		player.sprite:setImageFlip(playdate.graphics.kImageUnflipped)
	end

	-- Jump
	player.groundedLast = player.groundedLast + dt
	if player.isGrounded then
		player.groundedLast = 0
	end

	player.lastJumpPress = player.lastJumpPress + dt
	if playdate.buttonJustPressed( playdate.kButtonA ) then
		player.lastJumpPress = 0
	end

	if player.jumpPressDuration>0 then
		if playdate.buttonIsPressed( playdate.kButtonA ) then
			player.velocity.y = live.jump_velocity
			player.jumpPressDuration = player.jumpPressDuration - dt
		else
			player.jumpPressDuration = 0
		end
	end

	if player.lastJumpPress < live.jump_buffer and player.groundedLast < live.jump_grace then
		player.velocity.y = live.jump_velocity
		player.isGrounded = false

		player.lastJumpPress = live.jump_buffer
		player.groundedLast = live.jump_grace
		player.jumpPressDuration = live.jump_long_press
	end

	-- Gravity	
	if player.velocity.y >= 0 then
		player.velocity.y = math.min( player.velocity.y + live.gravity_down * dt, live.player_max_gravity)
	else
		player.velocity.y = player.velocity.y + live.gravity_up * dt
	end

	local goalX = player.sprite.x + player.velocity.x
	local goalY = player.sprite.y + player.velocity.y

	local _, my = player.sprite:moveWithCollisions( player.sprite.x, goalY)
	local mx, _ = player.sprite:moveWithCollisions( goalX, player.sprite.y)

	local isGrounded = my~=goalY and player.velocity.y>0
	player.justLanded = isGrounded and not player.isGrounded
	player.isGrounded = isGrounded
	player.bangCeiling = my~=goalY and player.velocity.y<0

	-- check exit
	local left = player.sprite.x
	local right = player.sprite.x + player.sprite.width
	if left < 0 then
		goto_level( LDtk.get_neighbours( game.level_name, "west" )[1], "West")
	end
	if right > 400  then
		goto_level( LDtk.get_neighbours( game.level_name, "east" )[1], "East")
	end
end