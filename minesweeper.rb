require 'byebug'
require "YAML"

class Board
  def initialize(board_size = 9, num_bombs = 10)
    @grid = Array.new(board_size) { Array.new(board_size) }
    @num_bombs = num_bombs
  end

  def display
    grid.each_with_index do |row, row_i|
      row.each_index do |col_i|
        pos = [row_i, col_i]
        if self[pos].flagged?
          print "F"
        elsif (lost? || won?) && self[pos].bomb?
          print "X"
        elsif self[pos].revealed? && self[pos].adjacent_bombs > 0
          print self[pos].adjacent_bombs
        elsif self[pos].revealed?
          print "O"
        else
          print "-"
        end
      end

      print "\n"
    end
  end

  def lost?
    grid.flatten.any? { |val| val.revealed? && val.bomb? }
  end

  def won?
    !grid.flatten.any? { |val| !val.revealed? && !val.bomb? }
  end

  def populate
    grid.each_with_index do |row, row_i|
      row.each_index do |col_i|
        pos = [row_i, col_i]
        self[pos] = Square.new
      end
    end
    add_bombs
  end

  def get_bomb_positions
    bomb_positions = []

    while bomb_positions.length < num_bombs
      row, col = rand(grid.length), rand(grid.length)
      bomb_positions << [row, col] unless bomb_positions.include?([row, col])
    end

    bomb_positions
  end

  def add_bombs
    get_bomb_positions.each do |pos|
      self[pos].set_bomb
      get_neighbors(pos).each do |neighbor_pos|
        self[neighbor_pos].adjacent_bombs += 1
      end
    end
  end

  def [](pos)
    x, y = pos
    grid[x][y]
  end

  def []=(pos, mark)
    x, y = pos
    grid[x][y] = mark
  end


  def reveal_empty_to_fringe(pos)
    current_tile = self[pos]

    if !current_tile.flagged?
      current_tile.reveal
      unless current_tile.adjacent_bombs > 0
        get_neighbors(pos).each do |neighbor_pos|
          reveal_empty_to_fringe(neighbor_pos) unless self[neighbor_pos].revealed?
        end
      end
    end
  end

  def get_neighbors(pos)
    x, y = pos
    neighbors = []

    (-1..1).each do |row_i|
      (-1..1).each do |col_i|
        new_x = x + row_i
        new_y = y + col_i
        new_pos = [new_x, new_y]
        unless new_pos == pos || new_x < 0 || new_y < 0 || new_x >= grid.length || new_y >= grid.length
          neighbors << new_pos
        end
      end
    end

    neighbors
  end

  private
  attr_reader :num_bombs, :grid
end


class Square
  attr_accessor :adjacent_bombs, :revealed


  def initialize
    @bomb = false
    @flag = false
    @adjacent_bombs = 0
    @revealed = false
  end

  def flagged?
    @flag
  end

  def flag
    if @flag == true
      @flag = false
    else
      @flag = true
    end
  end

  def revealed?
    @revealed
  end

  def reveal
    @revealed = true
  end

  def bomb?
    @bomb
  end

  def set_bomb
    @bomb = true
  end
end

class Game
  def initialize(board_size = 9, num_bombs = 10)
    @board = Board.new(board_size, num_bombs)
    board.populate
  end

  def get_guess
    puts "Please enter tile you would like to select row, column"
    user_input = gets.chomp
    if user_input == "save"
      save_game
    elsif user_input == "load"
      load_game
    else
      user_pos = user_input.split(", ").map(&:to_i)
      puts "Please enter your action (S/F)"
      user_action = gets.chomp

      [user_pos, user_action]
    end
  end

  def play_turn
    user_input = get_guess
    if user_input[1] == "F"
      board[user_input[0]].flag
    else
      board.reveal_empty_to_fringe(user_input[0])
    end
  end

  def play
    puts "If you would ever like to save your game or load a previous one,
    just type 'save' or 'load'."
    sleep(3)
    until board.won? || board.lost?
      system("clear")
      board.display
      play_turn
    end

    board.display

    if board.won?
      print "You are the winner!"
    else
      print "Sorry--you lost!"
    end
  end

  def save_game
    File.write("saved_game" , YAML.dump(board))
    play
  end

  def load_game
    self.board = YAML.load_file("saved_game")
    play
  end

  private
  attr_accessor :board
end


game = Game.new(9, 10)
game.play
