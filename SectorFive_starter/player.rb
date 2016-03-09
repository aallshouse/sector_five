require 'gosu'

class Player
  ROTATION_SPEED = 3
  ACCELERATION = 2
  FRICTION = 0.9

  attr_reader :x, :y, :angle, :radius

  def initialize(window)
  	@x = 200
  	@y = 700
  	@angle = 0
  	@image = Gosu::Image.new('images/ship.png')
    #Gosu::Image.new('images/ship.png')
  	@velocity_x = 0
  	@velocity_y = 0
  	@radius = 20
  	@window = window
    @shield_is_on = false
    @shield_hits = 0
    @is_dead = false
    @backwards = false
  end

  def shield_on?
    @shield_is_on
  end

  def shield_hit!
    @shield_hits += 1
    if @shield_hits == 3
      turn_shield_off
      @shield_hits = 0
    end
  end

  def is_dead?
    @is_dead
  end

  def kill!
    @is_dead = true
  end

  def turn_shield_on
    @image = Gosu::Image.new('images/ship_shield.png')
    @shield_is_on = true
    @shield_hits = 0
  end

  def turn_shield_off
    @image = Gosu::Image.new('images/ship.png')
    @shield_is_on = false
  end

  def draw
  	@image.draw_rot(@x, @y, 1, @angle)
  end

  def turn_right
  	@angle += ROTATION_SPEED
  end

  def turn_left
  	@angle -= ROTATION_SPEED
  end

  def go_backwards
    @backwards = true
    @velocity_x += Gosu.offset_x(-@angle, ACCELERATION)
    @velocity_y += Gosu.offset_y(-@angle, ACCELERATION)
  end

  def accelerate
    @backwards = false
    @velocity_x += Gosu.offset_x(@angle, ACCELERATION)
    @velocity_y += Gosu.offset_y(@angle, ACCELERATION)
  end

  def move
    if @backwards
      @x -= @velocity_x
      @y -= @velocity_y
    else
      @x += @velocity_x
      @y += @velocity_y
    end
  	@velocity_x *= FRICTION
  	@velocity_y *= FRICTION
  	if @x > @window.width - @radius
  	  @velocity_x = 0
  	  @x = @window.width - @radius
  	end
  	if @x < @radius
  	  @velocity_x = 0
  	  @x = @radius
  	end
  	if @y > @window.height - @radius
  	  @velocity_y = 0
  	  @y = @window.height - @radius
	  end
  end
end