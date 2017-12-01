require 'json'

class PlayerClientStab
  def initialize(name, add, port)
    @name = name
    @add = add
    @port = port
  end

  def run
    Thread.new {
      # サーバ接続 OPEN
      sock = TCPSocket.open(@add, @port)

      #チーム名要求
      puts "client_stab(#{@name}): #{sock.gets}"

      # チーム名の通知
      sock.puts JSON.generate({"team_name" => @name})
      puts "client_stab(#{@name}): " + @name
      sock.flush

      # 盤面情報
      loop do
        puts "client_stab(#{@name}): #{board = JSON.parse(sock.gets)}"

        break if(board["finished"])

        # 自分のターンのとき
        if(board["turn_team"] == @name)
          # 実際には行動JSONを送る
          sock.puts '{"turn_team":"#{@name}","contents":[]}'
          sock.flush

          # 結果を取得
          puts "client_stab(#{@name}): #{result = JSON.parse(sock.gets)}"
        end
      end

      # ソケット CLOSE
      sock.close
    }
  end
end