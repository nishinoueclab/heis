require 'json'

=begin

=end

class Unit
  def initialize(id, player, hp = 2, type ="heizu")
    @id = id
    @hp = hp
    @player = player
    @type = type
  end

  def unit_id
    @player.name[0..1] + sprintf("%02d", @id.to_i)
  end

  def to_s
    unit_id
  end
  
  # 自身の位置を盤面に問い合わせてHashで返却
  def locate
    
  end
  
  def move_to?()
    
  end

  def to_hash
    json = {}
    json[:type] = @type
    json[:unit_id] = unit_id
    json[:hp] = @hp
    json[:team] = @player.name
    return json
  end
end