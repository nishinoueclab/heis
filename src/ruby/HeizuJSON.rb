require 'json'

module HeizuJSON
  def team_name(name)
    return JSON.generate({"your_team" => name}).to_s
  end
  
end