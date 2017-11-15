class Player
  def initialize(name, sock = nil)
    @name = name
    @sock = sock
  end
  
  attr_reader :name, :sock

  
  
end