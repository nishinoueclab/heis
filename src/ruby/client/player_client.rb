require 'socket'
require 'json'

Thread.abort_on_exception = true

team_name = 'foo'

# サーバ接続 OPEN
sock = TCPSocket.open("localhost", 20000)

#チーム名要求
puts sock.gets

# チーム名の通知
sock.puts JSON.generate({"team_name" => team_name})
puts team_name
sock.flush

# ハンドシェイク
puts "ハンドシェイク", sock.gets

# 盤面情報
loop do
  puts board = JSON.parse(sock.gets)

  break if(board["finished"])

  # 自分のターンのとき
  if(board["turn_team"] == team_name)
    puts "my turn"
    # 実際には行動JSONを送る
    sock.puts '{"a": "b"}'
    sock.flush

    # 結果を取得
    puts result = JSON.parse(sock.gets)
  end
end

# ソケット CLOSE
sock.close
