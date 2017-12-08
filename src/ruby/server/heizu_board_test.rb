=begin
Heizuの単体テストコード
=end
PRJHOME = File.dirname('.')
$: << PRJHOME + '/src/ruby/server'

require 'test/unit'
require 'heizu_board'
require 'player'

class HeizuBoardTest < Test::Unit::TestCase
  def setup
    @player1 = Player.new("foo")
    @player2 = Player.new("goo")
    @board = HeizuBoard.new(@player1, @player2)
  end

  def test_get_unit
    assert_equal("fo00", @board.get_unit('fo00').to_s)
  end

  def test_get_unit_by_locate
    assert_equal("fo00", @board.get_unit_by_locate({:x => 14, :y => 0}).to_s)
  end

  def test_locate
    assert_equal({:x => 14, :y => 0} , @board.locate(@board.get_unit('fo00')))
    assert_equal({:x => 14, :y => 0} , @board.get_unit('fo00').locate)
  end

  def test_to_hash
    @board.to_hash
  end

  def test_move_unit
    ## 移動可能性のチェック
    # 移動できる場合
    assert_equal(true, @board.get_unit('fo00').move_to?({:x => 13, :y => 0}))
    assert_equal(true, @board.get_unit('fo00').move_to?({:x => 14, :y => 0}))
    assert_equal(true, @board.get_unit('fo00').move_to?({:x => 12, :y => 0}))
    assert_equal(true, @board.get_unit('fo00').move_to?({:x => 13, :y => 1}))
    assert_equal(true, @board.get_unit('fo00').move_to?({:x => 12, :y => 1}))
    assert_equal(true, @board.get_unit('fo00').move_to?({:x => 11, :y => 0}))
    ## 味方を飛び越える
    assert_equal(true, @board.get_unit('fo01').move_to?({:x => 13, :y => 0}))

    # 移動できない場合
    assert_equal(false, @board.get_unit('fo00').move_to?({:x => 15, :y => 0}))
    assert_equal(false, @board.get_unit('fo00').move_to?({:x => 16, :y => 0}))
    assert_equal(false, @board.get_unit('fo00').move_to?({:x => 15, :y => 1}))
    assert_equal(false, @board.get_unit('fo00').move_to?({:x => 0, :y => 0}))
    ## 敵を飛び越えない
    ### fo30とgo05を隣り合わせる。
    for i in 1..8 do
      assert_equal(true, @board.move_unit('fo30', {:x => 14 - i, :y => 5 + i}))
    end
    assert_equal(true, @board.move_unit('go05', {:x => 5, :y => 13}))
    assert_equal(false, @board.get_unit('fo30').move_to?({:x => 3, :y => 13}))

    # 移動できる場合
    ### 敵が死んだあとのマスへの移動
    assert_equal(true, @board.atk('fo30', {:x => 5, :y => 13}))
    assert_equal(true, @board.atk('fo30', {:x => 5, :y => 13}))
    assert_equal(true, @board.get_unit('fo30').move_to?({:x => 5, :y => 13}))

    ## 移動できる場合の移動
    assert_equal(true, @board.move_unit('fo00', {:x => 13, :y => 1}))
    assert_equal({:x => 13, :y => 1} , @board.locate(@board.get_unit('fo00')))

    # 同一の場所に移動する場合
    assert_equal(true, @board.move_unit('fo00', {:x => 13, :y => 1}))
    assert_equal({:x => 13, :y => 1} , @board.locate(@board.get_unit('fo00')))

  end

  def test_atk
    assert_equal(false, @board.get_unit('fo00').atkable?(@board.get_unit('fo01')))
    assert_equal(false, @board.get_unit('fo00').atkable?(@board.get_unit('go00')))

    # fo30とgo05を隣り合わせる。
    for i in 1..8 do
      assert_equal(true, @board.move_unit('fo30', {:x => 14 - i, :y => 5 + i}))
    end
    assert_equal(true, @board.move_unit('go05', {:x => 5, :y => 13}))

    # 攻撃可能か調べる
    assert_equal(true, @board.get_unit('fo30').atkable?(@board.get_unit('go05')))

    # 攻撃する
    assert_equal(true, @board.atk('fo30', {:x => 5, :y => 13}))
    assert_equal(1, @board.get_unit('go05').hp)

    # 攻撃できないところを指定する
    assert_equal(false, @board.atk('fo00', {:x => 5, :y => 13}))
    assert_equal(false, @board.atk('fo00', {:x => 0, :y => 0}))

  end

  def test_turn
    assert_equal({:result => []}, @board.turn({
      :turn_team => "foo",
      :contents => [
      {
      :unit_id => "fo00",
      :to => {
      :x=> 13,
      :y=> 0
      }
      }
      ]
    }))

    assert_equal({:result=>[{:error=>"Can't move this unit : fo00", :unit_id=>"fo00"}]}, @board.turn({
      :turn_team => "foo",
      :contents => [
      {
      :unit_id => "fo00",
      :to => {
      :x=> 1,
      :y=> 0
      }
      }
      ]
    }))

    assert_equal({:result => [{:unit_id => "fo00", :error => "Duplicate unit_id : fo00"}]}, @board.turn({
      :turn_team => "foo",
      :contents => [
      {
      :unit_id => "fo00",
      :to => {
      :x=> 13,
      :y=> 0
      }
      },
      {
      :unit_id => "fo00",
      :to => {
      :x=> 13,
      :y=> 0
      }
      }
      ]
    }))

  end

  def test_to_s
    @board.to_s
  end

end