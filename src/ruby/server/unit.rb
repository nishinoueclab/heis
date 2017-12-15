require 'json'

=begin
1つのユニットをあわらすクラス。ほとんどの処理をボードに委譲している。
=end

class Unit
  def initialize(board, id, player, hp = 2, type ="heis")
    @board = board
    @id = id
    @hp = hp
    @player = player
    @type = type
  end

  attr_reader :player, :hp, :type

  protected def damage(atk = 1)
    @hp -= atk
    @board.remove_unit(self) if !self.alive?
  end

  def unit_id
    @player.name[0..1] + sprintf("%02d", @id.to_i)
  end

  def to_s
    unit_id
  end

  # 自身の位置を盤面に問い合わせてHashで返却
  def locate
    @board.locate(self)
  end

  def atk(other)
    other.damage
  end

  def atkable?(other)
    return false if other.nil?
    return other.player != self.player && self.distance(other) == 1
  end

  # 他のユニットマンハッタン距離を求めます。
  def distance(other)
    s = self.locate
    o = other.locate
    return (s[:x] - o[:x]).abs + (s[:y] - o[:y]).abs
  end

  # to = {:x => xxx, :y => yyy}
  # distance = 2
  def move_to?(to, distance = 3)
    locate = self.locate()
    return ftmove_to?(locate, to, distance)
  end

  private def ftmove_to?(from, to, distance)
    return false if distance < 0
    return false if (from[:x] < 0 || @board.width <= from[:x] || from[:y] < 0 || @board.height <= from[:y])
    return false if (to[:x] - from[:x]).abs + (to[:y] - from[:y]).abs > distance
    
    from_unit = @board.get_unit_by_locate(from)
    
    if (from_unit == nil)
      return true if from[:x] == to[:x] && from[:y] == to[:y]
    elsif from_unit == self
      return true if from[:x] == to[:x] && from[:y] == to[:y]
    elsif from_unit != nil
      return false if @board.get_unit_by_locate(from).player != self.player
    end

    return [{:x => 1, :y => 0}, {:x => -1, :y => 0}, {:x => 0, :y => 1}, {:x => 0, :y => -1}].map {|dire|
      ftmove_to?({:x => from[:x] + dire[:x], :y => from[:y] + dire[:y]}, to ,distance - 1)
    }.reduce(false) {|result, b| result || b}
  end

  def alive?
    @hp > 0
  end

  def to_hash
    json = {}
    json[:type] = @type
    json[:unit_id] = unit_id
    json[:hp] = @hp
    json[:team] = @player.name
    json[:locate] = locate
    return json
  end
end