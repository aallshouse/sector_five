require 'gosu'
require_relative 'player'
require_relative 'enemy'
require_relative 'bullet'
require_relative 'explosion'
require_relative 'credit'

class GameService
  def initialize(window)
    @window = window
  end

  def create_enemy(frequency, enemies, enemy_count)
    if rand < frequency
      enemies.push Enemy.new(@window)
      enemy_count += 1
    end
  end

  def create_power_up(frequency, power_ups)
    if rand < frequency
      power_ups.push PowerUp.new(@window)
    end
  end

  def move_enemies(enemies)
    enemies.each do |enemy|
      enemy.move
    end
  end

  def move_bullets(bullets)
    bullets.each do |bullet|
      bullet.move
    end
  end

  def move_power_ups(power_ups)
    power_ups.each do |power_up|
      power_up.move
    end
  end

  def execute_power_ups(power_ups, player)
    power_ups.dup.each do |power_up|
      distance = Gosu.distance(power_up.x, power_up.y, player.x, player.y)
      if distance < player.radius + power_up.radius
        power_ups.delete power_up
        player.turn_shield_on
      end
    end
  end

  def execute_bullets_on_enemies(enemies, bullets, explosions, enemies_destroyed, explosion_sound)
    enemies.dup.each do |enemy|
      bullets.dup.each do |bullet|
        distance  = Gosu.distance(enemy.x, enemy.y, bullet.x, bullet.y)
        if distance < enemy.radius + bullet.radius and !bullet.is_nuke?
          enemies.delete enemy
          bullets.delete bullet
          explosion = Explosion.new(@window, enemy.x, enemy.y)
          explosions.push explosion
          enemies_destroyed += 1
          explosion_sound.play
        end
      end
    end
  end

  def execute_enemy_explosions(explosions, enemies, enemies_destroyed, explosion_sound)
    explosions.dup.each do |explosion|
      enemies.dup.each do |enemy|
        explosion_kill_distance = Gosu.distance(enemy.x, enemy.y, explosion.x, explosion.y)
        if explosion_kill_distance < enemy.radius + explosion.radius and enemy.y > 20
          enemies.delete enemy
          explosion2 = Explosion.new(@window, enemy.x, enemy.y)
          explosions.push explosion2
          enemies_destroyed += 1
          explosion_sound.play
        end
      end
      explosions.delete explosion if explosion.finished
    end
  end

end

class SectorFive < Gosu::Window
  WIDTH = 800
  HEIGHT = 600
  ENEMY_FREQUENCY = 0.05 #0.05
  POWER_UP_FREQUENCY = 0.004
  MAX_ENEMIES = 400 #100
  #TODO: Do not allow enemies off screen to explode

  def initialize
    super(WIDTH, HEIGHT)
    self.caption = 'Sector Five'
    @background_image = Gosu::Image.new('images/start_screen.png')
    @scene = :start

    @game = GameService.new(self)
  end

  def initialize_game
  	@player = Player.new(self)
    @enemies = []
    @bullets = []
    @explosions = []
    @power_ups = []
    @scene = :game
    @enemies_appeared = 0
    @enemies_destroyed = 0
    @explosion_sound = Gosu::Sample.new('sounds/explosion.ogg')
    @shooting_sound = Gosu::Sample.new('sounds/shoot.ogg')
  end

  def initialize_end(fate)
  	case fate
  	when :count_reached
  	  @message = "You made it!  You destroyed #{@enemies_destroyed} ships"
  	  @message2 = "and #{MAX_ENEMIES - @enemies_destroyed} reached the base."
  	when :hit_by_enemy
  	  @message = "You were struck by an enemy ship."
  	  @message2 = "Before your ship was destroyed, "
  	  @message2 += "you took out #{@enemies_destroyed} enemy ships."
    when :off_top
  	  @message = "You got too close to the enemy mother ship."
  	  @message2 = "Before your ship was destroyed, "
  	  @message2 += "you took out #{@enemies_destroyed} enemy ships."
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

  def update_game
  	@player.turn_left if button_down?(Gosu::KbLeft)
  	@player.turn_right if button_down?(Gosu::KbRight)
  	@player.accelerate if button_down?(Gosu::KbUp)
  	@player.move

    #TODO: Ruby is pass by value and NOT pass by reference
    #Need to pass below instance objects and update them
    #Create a game state object to track below objects and to update them
  	@game.create_enemy(ENEMY_FREQUENCY, @enemies, @enemies_appeared)
    @game.create_power_up(POWER_UP_FREQUENCY, @power_ups)
  	@game.move_enemies(@enemies)
  	@game.move_bullets(@bullets)
    @game.move_power_ups(@power_ups)
    @game.execute_power_ups(@power_ups, @player)
    @game.execute_bullets_on_enemies(@enemies, @bullets, @explosions, @enemies_destroyed, @explosion_sound)
    @game.execute_enemy_explosions(@explosions, @enemies, @enemies_destroyed, @explosion_sound)
  	
  	
  	@enemies.dup.each do |enemy|
  	  if enemy.y > HEIGHT + enemy.radius
  	  	@enemies.delete enemy
  	  end
  	end
  	@bullets.dup.each do |bullet|
  	  @bullets.delete bullet unless bullet.onscreen?

      if bullet.is_nuke? and bullet.paces == 50
        @bullets.delete bullet
        explosion = Explosion.new(self, bullet.x, bullet.y)
        @explosions.push explosion
        
        @enemies.dup.each do |enemy|
          @enemies.delete enemy
          explosion = Explosion.new(self, enemy.x, enemy.y)
          @explosions.push explosion
          @enemies_destroyed += 1
          @explosion_sound.play
        end
      end
  	end
  	initialize_end(:count_reached) if @enemies_appeared > MAX_ENEMIES
  	@enemies.dup.each do |enemy|
  	  distance = Gosu.distance(enemy.x, enemy.y, @player.x, @player.y)
  	  if distance < @player.radius + enemy.radius
        @enemies.delete enemy
        explosion = Explosion.new(self, enemy.x, enemy.y)
        @explosions.push explosion
        @enemies_destroyed += 1
        @explosion_sound.play
        if @player.shield_on?
          @player.shield_hit!
        else
          initialize_end(:hit_by_enemy)
        end
      end
  	end
  	initialize_end(:off_top) if @player.y < -@player.radius
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
  	@player.draw
  	@enemies.each do |enemy|
  	  enemy.draw
  	end
  	@bullets.each do |bullet|
  	  bullet.draw
  	end
  	@explosions.each do |explosion|
  	  explosion.draw
  	end
    @power_ups.each do |power_up|
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
  	  @bullets.push Bullet.new(self, @player.x, @player.y, @player.angle)
  	  @shooting_sound.play(0.3)
  	end

    if id == Gosu::KbN
      bullet = Bullet.new(self, @player.x, @player.y, @player.angle)
      bullet.make_nuke
      @bullets.push bullet
      @shooting_sound.play(0.3)
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