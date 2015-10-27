class Explosion
  attr_reader :finished, :x, :y, :radius

  def initialize(window, x, y)
  	@x = x
  	@y = y
  	@radius = 30
  	@images = Gosu::Image.load_tiles('images/explosions.png', 60, 60)
  	@image_index = 0
  	@finished = false
    @frame_count = 0
    @images_count = @images.count * @frame_count
  end

  def draw
  	if @frame_count == 0 or @frame_count == 3
      if @image_index < @images.count
  	  @images[@image_index].draw(@x - @radius, @y - @radius, 2)
  	  @image_index += 1
      @frame_count = 0 if @frame_count == 3
  	  else
  	    @finished = true
  	  end
    end
    @frame_count += 1
  end
end