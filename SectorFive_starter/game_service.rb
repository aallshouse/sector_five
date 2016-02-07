class GameService
  ENEMY_FREQUENCY = 0.05 #0.05
  POWER_UP_FREQUENCY = 0.004
  MAX_ENEMIES = 200 #100

  attr_accessor :enemies, :bullets, :power_ups, :player,
                :explosions, :shooting_sound, :explosion_sound

  attr_reader :max_enemies, :enemies_appeared, :enemies_destroyed

  def initialize(window)
    @window = window
    @player = Player.new(window)
    @enemies = []
    @enemies_appeared = 0
    @power_ups = []
    @bullets = []
    @explosions = []
    @enemies_destroyed = 0
    @explosion_sound = Gosu::Sample.new('sounds/explosion.ogg')
    @shooting_sound = Gosu::Sample.new('sounds/shoot.ogg')
    @update_cycles = 0
    @update_cycle_index_end = -1
    @end_message = ''
  end

  def start_game
    #move initialize game method logic here
    #all instance variables should be part of this class
  end

  def create_enemy
    if rand < ENEMY_FREQUENCY
      @enemies.push Enemy.new(@window)
      @enemies_appeared += 1
    end
  end

  def create_power_up
    if rand < POWER_UP_FREQUENCY
      @power_ups.push PowerUp.new(@window)
    end
  end

  ENEMY_SHOOTING_FREQUENCY = 0.06
  def move_enemies
    @enemies.each do |enemy|
      enemy.move

      if enemy.is_shooter and rand < ENEMY_SHOOTING_FREQUENCY
        @bullets.push Bullet.new(@window, enemy.x, enemy.y, 180, true)
      end
    end
  end

  def move_bullets
    @bullets.each do |bullet|
      bullet.move
    end
  end

  def move_power_ups
    @power_ups.each do |power_up|
      power_up.move
    end
  end

  def execute_power_ups
    @power_ups.dup.each do |power_up|
      distance = Gosu.distance(power_up.x, power_up.y, @player.x, @player.y)
      if distance < @player.radius + power_up.radius
        @power_ups.delete power_up
        @player.turn_shield_on
      end
    end
  end

  def execute_bullets_on_enemies
    @enemies.dup.each do |enemy|
      @bullets.dup.each do |bullet|
        distance  = Gosu.distance(enemy.x, enemy.y, bullet.x, bullet.y)
        if !bullet.from_enemy? and distance < enemy.radius + bullet.radius and !bullet.is_nuke?
          @enemies.delete enemy
          @bullets.delete bullet
          explosion = Explosion.new(@window, enemy.x, enemy.y)
          @explosions.push explosion
          @enemies_destroyed += 1
          @explosion_sound.play
        end
      end
    end
  end

  def execute_enemy_explosions
    @explosions.dup.each do |explosion|
      @enemies.dup.each do |enemy|
        explosion_kill_distance = Gosu.distance(enemy.x, enemy.y, explosion.x, explosion.y)
        if explosion_kill_distance < enemy.radius + explosion.radius and enemy.y > 20
          @enemies.delete enemy
          explosion2 = Explosion.new(@window, enemy.x, enemy.y)
          @explosions.push explosion2
          @enemies_destroyed += 1
          @explosion_sound.play
        end
      end
      @explosions.delete explosion if explosion.finished
    end
  end

  def max_enemies
    MAX_ENEMIES
  end

  def enemies_destroyed_increment
    @enemies_destroyed += 1
  end

  def delete_offscreen_enemies(screen_height)
    @enemies.dup.each do |enemy|
      if enemy.y > screen_height + enemy.radius
        @enemies.delete enemy
      end
    end
  end

  def detonate_nuke(bullet)
    @bullets.delete bullet
    explosion = Explosion.new(self, bullet.x, bullet.y)
    @explosions.push explosion

    @enemies.dup.each do |enemy|
      @enemies.delete enemy
      explosion = Explosion.new(self, enemy.x, enemy.y)
      @explosions.push explosion
      enemies_destroyed_increment
      @explosion_sound.play
    end
  end

  #TODO: Make bullets from enemies go towards the player, enemies can shoot down, towards player, or
  #(left diagonal, right diagonal, and straight down)
  #TODO: Create method for performing enemy bullet/player collisions, similar to below

  def check_and_perform_player_bullet_collision
    @bullets.dup.each do |bullet|
      if bullet.from_enemy?
        distance = Gosu.distance(bullet.x, bullet.y, player.x, player.y)
        if distance < player.radius + bullet.radius
          if @player.shield_on?
            perform_shield_hit(@bullets, bullet)
            @player.shield_hit!
          else
            perform_player_killed(@bullets, bullet, :hit_by_enemy_bullet)
          end
        end
      end
    end
  end

  def increment_update_cycles
    @update_cycles += 1
  end

  def perform_end?
    if(@update_cycle_index_end != -1 and @update_cycles > @update_cycle_index_end)
      @window.initialize_end(@end_message)
    end
  end

  def perform_shield_hit(arr, item)
    arr.delete item
    explosion = Explosion.new(self, item.x, item.y)
    @explosions.push explosion
    @explosion_sound.play
  end

  def perform_player_killed(arr, item, message)
    arr.delete item
    @player.kill!
    explosion = Explosion.new(self, player.x, player.y)
    @explosions.push explosion
    @explosion_sound.play

    @end_message = message
    @update_cycle_index_end = @update_cycles + 100
  end

  def check_and_perform_player_enemy_collision
    @enemies.dup.each do |enemy|
      distance = Gosu.distance(enemy.x, enemy.y, player.x, player.y)
      if distance < player.radius + enemy.radius
        @enemies.delete enemy
        explosion = Explosion.new(self, enemy.x, enemy.y)
        @explosions.push explosion
        enemies_destroyed_increment
        @explosion_sound.play
        if @player.shield_on?
          perform_shield_hit(@enemies, enemy)
          @player.shield_hit!
        else
          perform_player_killed(@enemies, enemy, :hit_by_enemy)
        end
      end
    end
  end

end