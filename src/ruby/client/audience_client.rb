require 'socket'

# サーバ接続 OPEN
sock = TCPSocket.open("localhost", 20001)

loop do
  print board = sock.gets
  break if board == "finished\n"
end

# ソケット CLOSE
sock.close

