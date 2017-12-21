require 'socket'
require 'json'
require 'io/console'

team_name = 'harada'
$color_name = team_name

# サーバ接続 OPEN
sock = TCPSocket.open("localhost", 20000)
#sock = TCPSocket.open("192.168.12.21", 20000)

#チーム名要求
puts sock.gets

# チーム名の通知
sock.puts JSON.generate({"team_name" => team_name})
puts team_name
sock.flush

# ハンドシェイク
puts "ハンドシェイク", sock.gets

# 操作説明
puts "Zでユニット選択、Xで移動先選択、Vで行動(何も選択せずにVでデータ送信)"
#puts "例外処理はしていないので変な事したら高確率で止まる"

def printBoard(board, printclear)
    # 盤面宣言
    map = Array.new(20).map{ Array.new(20, nil) }

    # ユニットの位置をjsonから配列に変換
    board[:units].each{ |unit|
      map[unit[:locate][:y]][unit[:locate][:x]] = unit;
    }

    # 出力を上に戻す
    if(printclear == true)then
      printf "\e[#{board[:height]}A"
      #a = gets.to_i
      #sleep 0.5
    end

    # マップ出力
    i = 0;
    map.flatten.each{ |unit|
      #p unit
      if(unit != nil) then
        if( unit[:type] == "end" and unit[:hp] == 2)
          print "\e[45m\e[30m"
          print unit[:unit_id]
          print "\e[0m"
        elsif( unit[:type] == "end" and unit[:hp] != 2)
          s = unit[:unit_id].split("")
          print "\e[45m\e[30m"
	  print s[0]+s[1]
          print "\e[0m"
          print s[2]+s[3]

        elsif(unit[:hp] == 2)then
          print "\e[42m\e[30m" if(unit[:team] == $color_name)
          print "\e[43m\e[30m" if(unit[:team] != $color_name)
          print unit[:unit_id]
          print "\e[0m"
        else
          s = unit[:unit_id].split("")
          print "\e[42m\e[30m" if(unit[:team] == $color_name)
          print "\e[43m\e[30m" if(unit[:team] != $color_name)
	  print s[0]+s[1]
          print "\e[0m"
          print s[2]+s[3]
        end
      else
        print "____"
      end

      i = i + 1
      if(i%20 == 0)then print "\n"
      else print " "
      end
    }
    STDOUT.flush

end


def moveHuman( team_name, board)

  m_units = Array.new # ユニット選択用
  action = Array.new # 行動用

  while 1 do
    m_units = selectUnit( team_name, board) # 行動するユニットと移動先の選択
    locate = m_units.pop() # 移動先がくっついてるので取り出す
    break if(m_units[0] == nil)
    # 移動と自動攻撃の選択
    m_units.sort!{ |a,b|
      tempA = ((a[:locate][:x] - locate[:x]).abs + (a[:locate][:y] - locate[:y]).abs)
      tempB = ((b[:locate][:x] - locate[:x]).abs + (b[:locate][:y] - locate[:y]).abs)
      tempA <=> tempB
    }
    m_units.each{|my|
      act = action_select( board, my, locate)
      change_board( board, act)
      action.push(act) 
      printBoard( board, true) # 描画
      sleep 0.2
    }

    printBoard( board, true) # 描画
  end

  return action
end

# 一回の行動毎にマップを更新
def change_board( board, act)

  # 行動するユニットの位置を変更
  board[:units].each{|unit|
    if(act[:unit_id] == unit[:unit_id])then
      unit[:locate] = act[:to]
      unit[:type] = "end"
    end

    # 殴られた敵のHP変更
    unit[:hp] -= 1 if(act[:unit_id] != unit[:unit_id] and unit[:locate] == act[:atk])
    
=begin
    if(act["unit_id"] == unit[:unit_id])then
      unit[:locate][:x] = act["to"]["x"]
      unit[:locate][:y] = act["to"]["y"]
      unit[:type] = "end"
    end

    # 殴られた敵のHP変更
    if(act["to"] != act["atk"] and unit[:locate][:x] == act["atk"]["x"] and unit[:locate][:y] == act["atk"]["y"])then
      unit[:hp] -= 1
    end
=end
  }

  board[:units].select!{|unit| unit[:hp] != 0}
end

# 行動するユニットと移動先の選択
def selectUnit( team_name, board)

  # バーの位置をmapの[0,0]
  printf "\e[#{1}A"
  printf "\e[#{4}C"
  m_units = Array.new
  locate = {:x=>0, :y=>19}
  command = ""

  #sleep 0.5

  while (key = STDIN.getch) != "\C-c"
    command += key

    if( command == "v") then
      printf "\e[#{1*(19-locate[:y])}B" if(1*(19-locate[:y]) > 0)
      printf "\e[#{5*locate[:x]}D" if(locate[:x] > 0)

      printf "\e[#{4}D"
      printf "\e[#{1}B"
      break
    elsif( command == "x") then # 移動先の選択
      to = (Marshal.load(Marshal.dump(locate)))
      print "\e[44m \e[0m"
      printf "\e[#{1}D"
      command = "" 
   elsif( command == "z") then # 行動するユニットの選択
      m_units.push(Marshal.load(Marshal.dump(locate)))
      print "\e[41m \e[0m"
      printf "\e[#{1}D"
      command = "" 
    elsif( command == "\e[A") then #上移動
      locate[:y] -= 1
      printf "\e[#{1}A"
      command = "" 
    elsif( command == "\e[B") then #下
      locate[:y] += 1 
      printf "\e[#{1}B"
      command = "" 
    elsif( command == "\e[C") then #右
      locate[:x] += 1 
      printf "\e[#{5}C"
      command = "" 
    elsif( command == "\e[D") then #左
      locate[:x] -= 1 
      printf "\e[#{5}D"
      command = "" 
    end

  end

  if(m_units == [])then # 選択がなかったら[nil,nil]を返す
    #printf "\e[#{1*(19-locate[:y])}B" if(1*(19-locate[:y]) > 0)
    #printf "\e[#{5*locate[:x]}D" if(locate[:x] > 0)
    #printf "\e[#{1}B"
    #printf "\e[#{4}D"
    return [nil,nil]
  end

  return board[:units].select{|unit| m_units.select{|locate| locate == unit[:locate]} != []}.push(to)
end

# 移動探索
def action_select( board, my_unit, to)
  # 距離の差
  dis_x = (my_unit[:locate][:x] - to[:x])
  dis_y = (my_unit[:locate][:y] - to[:y])
  dis_sum = dis_x.abs + dis_y.abs
  dis_sum = 3 if(dis_sum > 3)

  # 可能な全移動を導出用
  move_array = Array.new

  # 移動できるか判断
  move = [my_unit[:locate][:x], my_unit[:locate][:y]]

  # 移動先の選択
  move_array = all_move( board[:turn_team], board, my_unit[:locate], to, dis_sum).flatten
  move_array.select!{|temp| # nilを除く
    temp != nil
  }
  move_array.uniq! # 同じ要素の排除
  move_array.push(my_unit[:locate]) # 自身の場所も入れる
  move = move_most( move_array, to) # 最も目的地に近づく移動を選択

  atk = {:x => 0, :y => 0} # 攻撃用
  atk = can_atk?( board[:turn_team], board, {:x => move[:x], :y=> move[:y]}) # 周りに攻撃できる敵がいるかチェック
  #puts "test"
  #sleep 0.1
  return {:unit_id=> my_unit[:unit_id], :to=>{:x=> move[:x],:y=> move[:y]}, :atk=>{:x=>atk[:x],:y=>atk[:y]}}
end

# 移動を全探索
def all_move( team_name, board, from, to, distance)
  # 現在のマスについて
  now_move = from

  return nil if (from[:x] < 0 || board[:width] <= from[:x] || from[:y] < 0 || board[:height] <= from[:y]) # 盤外
  #return [nil,nil] if ((to[:x] - from[:x]).abs + (to[:y] - from[:y]).abs) > distance # 離れる移動
  return nil if (distance < 0) # 4歩目
  board[:units].each{ |unit|
    return nil if (unit[:team] != team_name && unit[:locate] == from) # 敵がいるマス
    return nil if ( distance == 0 && from[:x] == to[:x] && from[:y] == to[:y] && unit[:locate] == from) # 移動終了,味方がいるマス
    now_move = nil if ( unit[:locate] == from) # 味方がいるマス
  }

  # すべての移動,移動可,移動不可を入れる配列
  move = Array.new
  move.push([{:x => 1, :y => 0}, {:x => -1, :y => 0}, {:x => 0, :y => 1}, {:x => 0, :y => -1}].map {|dire|
    all_move( team_name, board, {:x => from[:x] + dire[:x], :y => from[:y] + dire[:y]}, to ,distance - 1)
  })

  # 再起先の移動情報と現在の移動を返す
  return move.push(now_move)
end

# 目的地に近づく移動先の選択
def move_most( move_array, to)

  move = [0,0]
  most = 40

  # 最も目的地に近い移動先の探索  
  move_array.each{ |m|
    if(most > ((to[:x] - m[:x]).abs + (to[:y] - m[:y]).abs))then
      most = ((to[:x] - m[:x]).abs + (to[:y] - m[:y]).abs)
      move = m
    end
  }

  return move
end

# 攻撃できるか判断
def can_atk?( team_name, board, my)

  # 四方を見て攻撃できるか判断する
  board[:units].each{ |unit|
    if (unit[:team] != team_name)then
      if (unit[:locate] == {:x => my[:x]+1, :y => my[:y]})then
        return unit[:locate]
      elsif (unit[:locate] == {:x => my[:x]-1, :y => my[:y]})then
        return unit[:locate]
      elsif (unit[:locate] == {:x => my[:x], :y => my[:y]+1})then
        return unit[:locate]
      elsif (unit[:locate] == {:x => my[:x], :y => my[:y]-1})then
        return unit[:locate]
      end
    end
  }

  return my
end

# 送信データをjson化する
def sendMassege( name, move)
  return JSON.generate({"turn_team" => name, "contents" => move })
end


# 盤面情報
loop do
  board = JSON.parse(sock.gets, {:symbolize_names => true})

  break if(board[:finished])

  # 自分のターンのとき
  if(board[:turn_team] == team_name)

    # マップの描画
    printBoard(board, false) if(board[:count] <= 1)
    printBoard(board, true) if(board[:count] > 1)

    # 実際には行動JSONを送る
    move = moveHuman( team_name, board) # 行動の生成
    sock.puts sendMassege( team_name, move) # jsonデータの送信

    # 実際には行動JSONを送る
    #sock.puts '{"a": "b"}'
    sock.flush

    # 結果を取得
    result = JSON.parse(sock.gets)
  end
end

# ソケット CLOSE
sock.close
