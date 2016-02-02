class Bullet
  SPEED = 5

  attr_reader :x, :y, :radius, :paces

  def initialize(window, x, y, angle, from_enemy=false)
    @x = x
    @y = y
    @direction = angle
    @image = Gosu::Image.new('images/bullet.png')
    @radius = 3
    @window = window
    @is_nuke = false
    @paces = 0
    @from_enemy = from_enemy
  end

  def from_enemy?
    @from_enemy
  end

  def make_nuke
    @image = Gosu::Image.new('images/nuke.png')
    @is_nuke = true
  end

  def is_nuke?
    @is_nuke
  end

  def move
  	@x += Gosu.offset_x(@direction, SPEED)
  	@y += Gosu.offset_y(@direction, SPEED)
    @paces += 1
  end

  def draw
    @image.draw(@x - @radius, @y - @radius, 1)
  end

  def onscreen?
  	right = @window.width + @radius
  	left = -@radius
  	top = -@radius
  	bottom = @window.height + @radius
  	@x > left and @x < right and @y > top and @y < bottom
  end
end