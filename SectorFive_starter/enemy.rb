class Enemy
  SPEED = 2
  ENEMY_SHOOTER_FREQUENCY = 0.05

  attr_reader :x, :y, :radius, :is_shooter

  def initialize(window)
    @radius = 20
    @x = rand(window.width - 2 * @radius) + @radius
    @y = 0
    @image = Gosu::Image.new('images/enemy.png')

    @is_shooter = rand < ENEMY_SHOOTER_FREQUENCY
  end

  def move
  	@y += SPEED
  end

  def draw
  	@image.draw(@x - @radius, @y - @radius, 1)
  end
end

class PowerUp
  SPEED = 2

  attr_reader :x, :y, :radius

  def initialize(window)
    @radius = 20
    @x = rand(window.width - 2 * @radius) + @radius
    @y = 0
    @image = Gosu::Image.new('images/shield.png')
  end

  def move
    @y += SPEED
  end

  def draw
    @image.draw(@x - @radius, @y - @radius, 1)
  end
end