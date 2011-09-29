module Sudoku
load 'util.rb'
include Util
require 'set'
class GridLocation
    def initialize(x, y, n, grid, row, column)
        @x = x
        @y = y
        @n = n
        @grid = grid
        @row = row
        @column = column
    end
    
    attr_reader :x, :y, :row, :grid, :column
    def to_s
        "(#{@x}, #{@y})"
    end
    
    def allowed_vals
        @grid & @column & @row
    end
    
    def <=> (other)
        return self.allowed_vals.size <=> other.allowed_vals.size
    end
end

class Puzzle
    include Util
    def self.get_grid(file_path)
        open(file_path, 'r').readlines.map {|line| line.split(',').map {|str_val| str_val.to_i}}
    end
    
    def self.save(grid, file_path)
        file = open(file_path, 'w')
        n = grid.size
        n.times do |row|
            n.times do |col|
                val = grid[row][col]
                file.print val.to_s unless val == 0
                if col != n - 1
                    file.print ','
                end
            end
            file.print "\n"
        end
        file.close
    end
    
    def self.check(grid)
        discrepencies = Set.new
        n = grid.size
        divisor = Math.sqrt(n).to_i
        inner_grids= Array.new(n) {|i|Hash.new}
        rows = Array.new(n) {|i|Hash.new}
        columns = Array.new(n) {|i|Hash.new}
        val = nil
        grid_loc = nil
        gap_exists = false
        0.upto(n - 1) do |row|
            0.upto(n - 1) do |col|
                val = grid[row][col]
                if val == 0
                    gap_exists = true
                    next
                end
                #check grid
                grid_loc = col/divisor + divisor*(row/divisor)
                if inner_grids[grid_loc].has_key?(val)
                    discrepencies << inner_grids[grid_loc][val]
                    discrepencies << Point.new(col, row)
                else
                    inner_grids[grid_loc][val] = Point.new(col, row)
                end
                #check col
                if columns[col].has_key?(val)
                    discrepencies << columns[col][val]
                    discrepencies << Point.new(col, row)
                else
                    columns[col][val] = Point.new(col, row)
                end
                #check row
                if rows[row].has_key?(val)
                    discrepencies << rows[row][val]
                    discrepencies << Point.new(col, row)
                else
                    rows[row][val] = Point.new(col, row)
                end
            end
        end
        discrepencies = discrepencies.to_a
        return { :discrepencies => discrepencies,
            :gaps => gap_exists,
            :win => (!gap_exists and discrepencies.empty?)}
    end
    
    
    def initialize(grid, file_path = nil)
        #file should be a csv
        if grid.empty?
            @grid = get_grid(file_path)
        else
            @grid = grid
        end
        n = @grid.size
        @inner_grids = Array.new(n) {|index| (1..n).to_a}
        @rows = Array.new(n) {|index| (1..n).to_a}
        @columns = Array.new(n) {|index| (1..n).to_a}
        @blank_locations = Array.new
        to_reject = nil
        @divisor = Math.sqrt(n).to_i
        0.upto(n - 1) do |y_val|
            0.upto(n - 1) do |x_val|
                to_reject = @grid[y_val][x_val]
                if to_reject != 0 then
                    @inner_grids[x_val / @divisor + @divisor * (y_val / @divisor)].delete(to_reject)
                    @rows[y_val].delete(to_reject)
                    @columns[x_val].delete(to_reject)
                else
                    @blank_locations << GridLocation.new(x_val, y_val, n, @inner_grids[x_val / @divisor + @divisor * (y_val / @divisor)], @rows[y_val], @columns[x_val])
                end
            end
        end
    end
    
    
    def blanks
        @blank_locations
    end

    def set_val(x, y, val)
        @grid[y][x] = val
        @inner_grids[x / @divisor + @divisor * (y / @divisor)].delete(val)
        @rows[y].delete(val)
        @columns[x].delete(val)
        @blank_locations.reject! {|blank| blank.x == x and blank.y == y}
    end
    
    def unset_val(x, y, val)
        @grid[y][x] = 0
        @inner_grids[x / @divisor + @divisor * (y / @divisor)] << val
        @rows[y] << val
        @columns[x] << val
        @blank_locations << GridLocation.new(x, y, @grid.size, @inner_grids[x / @divisor + @divisor * (y / @divisor)], @rows[y], @columns[x])
    end
    
    attr_reader :grid, :inner_grids, :rows, :columns, :blank_locations
end

def generate_puzzle_grid(n, valid)
    used = []
    grid =  Array.new(n) {|i| Array.new(n, 0)}
    inner_grids = Array.new(n) {|index| (1..n).to_a}
    rows = Array.new(n) {|index| (1..n).to_a}
    columns = Array.new(n) {|index| (1..n).to_a}
    divisor = Math.sqrt(n).to_i
                
    count = 0
    num_wanted = rand(10) + 25
    pos = nil
    while count < num_wanted
        y = rand(n)
        x = rand(n)
        while used.include?(Point.new(x, y))
            y = rand(n)
            x = rand(n)
        end
        used << Point.new(x, y)
        #would use sample, but JRuby doens't like it and won't run in 1.9 mode
        #val = rows[y] & columns[x] & inner_grids[x / divisor + divisor * (y / divisor)].sample
        pos = rows[y] & columns[x] & inner_grids[x / divisor + divisor * (y / divisor)]
        val = pos[rand(pos.size)]
        inner_grids[x / divisor + divisor * (y / divisor)].delete(val)
        rows[y].delete(val)
        columns[x].delete(val)
        grid[y][x] = val
        count += 1
    end
    
    #in ruby 1.8, clone isn't a deep copy, so we just clone ourselves.
    clone = []
    grid.each do |row|
        new_row = []
        row.each do |col|
            new_row << col
        end
        clone << new_row
    end
    
    if !solve(Puzzle.new(clone))
        grid =  generate_puzzle_grid(n, valid)
    end
    return grid
end

def solve(puzzle, indent = 0)
    tabs = get_tabs(indent)
    if puzzle.blanks.size == 0
#        puts "Puzzle solved!"
        return puzzle
    end
    most_constrained = puzzle.blanks.sort[0]
#    puts "#{tabs}#######################################################"
#    puts "#{tabs}Attempting to find a value for (#{most_constrained.x}, #{most_constrained.y})"
#    puts "#{tabs}Possible values: #{most_constrained.allowed_vals}"
    success = false
    most_constrained.allowed_vals.each do |val|
        puzzle.set_val(most_constrained.x, most_constrained.y, val)
#        puts "#{tabs}Attempting value: #{val}"
        success = solve(puzzle, indent + 1)
        if success then break end
#        puts "#{tabs}Recursive call with #{val} unsuccessful, unsetting."
        puzzle.unset_val(most_constrained.x, most_constrained.y, val)
    end
    return success
end

def get_tabs(indent)
    str = ""
    1.upto(indent) do |index|
        str += "\t"
    end
    return str
end



def print_solution(puzzle)
    puzzle.grid.each do |line|
        line.each do |value|
            print value
            if value != line[-1]
                print ','
            else
                print "\n"
            end
        end
    end
end

end		
#print_solution(solve(Puzzle.new('test_puzzle2.txt')))
