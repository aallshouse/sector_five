require 'gosu'
require_relative 'player'
require_relative 'enemy'
require_relative 'bullet'
require_relative 'explosion'
require_relative 'credit'
require_relative 'game_service'

class SectorFive < Gosu::Window
  WIDTH = 800
  HEIGHT = 600
  #TODO: Do not allow enemies off screen to explode

  def initialize
    super(WIDTH, HEIGHT)
    self.caption = 'Sector Five'
    @background_image = Gosu::Image.new('images/start_screen.png')
    @scene = :start

    @game = GameService.new(self)
  end

  def initialize_game
    @scene = :game
    @game = GameService.new(self)
  end

  def initialize_end(fate)
  	case fate
  	when :count_reached
  	  @message = "You made it!  You destroyed #{@game.enemies_destroyed} ships"
  	  @message2 = "and #{@game.max_enemies - @game.enemies_destroyed} reached the base."
  	when :hit_by_enemy
  	  @message = "You were struck by an enemy ship."
  	  @message2 = "Before your ship was destroyed, "
  	  @message2 += "you took out #{@game.enemies_destroyed} enemy ships."
    when :off_top
  	  @message = "You got too close to the enemy mother ship."
  	  @message2 = "Before your ship was destroyed, "
  	  @message2 += "you took out #{@game.enemies_destroyed} enemy ships."
  	end
  	@bottom_message = "Press P to play again, or Q to quit."
  	@message_font = Gosu::Font.new(28)
  	@credits = []
  	y = 700
  	File.open('credits.txt').each do |line|
  	  @credits.push(Credit.new(self, line.chomp, 100, y))
  	  y += 30
  	end
  	@scene = :end
  end

  def draw
  	case @scene
  	when :start
  	  draw_start
  	when :game
  	  draw_game
  	when :end
  	  draw_end
  	end
  end

  def update
  	case @scene
  	when :game
  	  update_game
  	when :end
  	  update_end
  	end
  end

  def player
    @game.player
  end

  def enemies
    @game.enemies
  end

  def bullets
    @game.bullets
  end

  def explosions
    @game.explosions
  end

  def shooting_sound
    @game.shooting_sound
  end

  def explosion_sound
    @game.explosion_sound
  end

  def power_ups
    @game.power_ups
  end

  def update_game
  	player.turn_left if button_down?(Gosu::KbLeft)
  	player.turn_right if button_down?(Gosu::KbRight)
  	player.accelerate if button_down?(Gosu::KbUp)
  	player.move

    #TODO: Ruby is pass by value and NOT pass by reference
    #Need to pass below instance objects and update them
    #Create a game state object to track below objects and to update them
  	@game.create_enemy
    @game.create_power_up
  	@game.move_enemies
  	@game.move_bullets
    @game.move_power_ups
    @game.execute_power_ups
    @game.execute_bullets_on_enemies
    @game.execute_enemy_explosions

  	@game.delete_offscreen_enemies(HEIGHT)

  	bullets.dup.each do |bullet|
  	  bullets.delete bullet unless bullet.onscreen?

      if bullet.is_nuke? and bullet.paces == 50
        @game.detonate_nuke(bullet)        
      end
  	end

  	initialize_end(:count_reached) if @game.enemies_appeared > @game.max_enemies
  	@game.check_and_perform_player_enemy_collision
  	initialize_end(:off_top) if player.y < -player.radius
  end

  def update_end
  	@credits.each do |credit|
  	  credit.move
  	end
  	if @credits.last.y < 150
  	  @credits.each do |credit|
  	  	credit.reset
  	  end
  	end
  end

  def button_down(id)
  	case @scene
  	when :start
  	  button_down_start
  	when :game
  	  button_down_game(id)
  	when :end
  	  button_down_end(id)
  	end
  end

  def draw_start
  	@background_image.draw(0,0,0)
  end

  def draw_game
  	player.draw
  	enemies.each do |enemy|
  	  enemy.draw
  	end
  	bullets.each do |bullet|
  	  bullet.draw
  	end
  	explosions.each do |explosion|
  	  explosion.draw
  	end
    power_ups.each do |power_up|
      power_up.draw
    end
  end

  def draw_end
  	clip_to(50, 140, 700, 360) do
  	  @credits.each do |credit|
  	  	credit.draw
  	  end
  	end
  	draw_line(0, 140, Gosu::Color::RED, WIDTH, 140, Gosu::Color::RED)
  	@message_font.draw(@message, 40, 40, 1, 1, 1, Gosu::Color::FUCHSIA)
  	@message_font.draw(@message2, 40, 75, 1, 1, 1, Gosu::Color::FUCHSIA)
  	draw_line(0, 500, Gosu::Color::RED, WIDTH, 500, Gosu::Color::RED)
  	@message_font.draw(@bottom_message, 180, 540, 1, 1, 1, Gosu::Color::AQUA)
  end

  def button_down_start
  	initialize_game
  end

  def button_down_game(id)
  	if id == Gosu::KbSpace
  	  bullets.push Bullet.new(self, player.x, player.y, player.angle)
  	  shooting_sound.play(0.3)
  	end

    if id == Gosu::KbN
      bullet = Bullet.new(self, player.x, player.y, player.angle)
      bullet.make_nuke
      bullets.push bullet
      shooting_sound.play(0.3)
    end
  end

  def button_down_end(id)
  	if id == Gosu::KbP
  	  initialize_game
  	elsif id == Gosu::KbQ
  	  close
  	end
  end
end

window = SectorFive.new
window.show
