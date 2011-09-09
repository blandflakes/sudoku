module Sudoku
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
	def initialize(file_path)
		#file should be a csv
		@grid = open(file_path, 'r').readlines.map {|line| line.split(',').map {|str_val| str_val.to_i}}
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
	
	def save(file_path)
        file = open(file_path, 'w')
        @rows.each do |row|
            row.each do |val|
                file.print val.to_s
                if val != row[-1]
                    file.print ','
                end
            end
            file.print '\n'
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

def solve(puzzle, indent = 0)
    tabs = get_tabs(indent)
    if puzzle.blanks.size == 0
	    puts "Puzzle solved!"
	    return puzzle
    end
    most_constrained = puzzle.blanks.sort[0]
    puts "#{tabs}#######################################################"
    puts "#{tabs}Attempting to find a value for (#{most_constrained.x}, #{most_constrained.y})"
    puts "#{tabs}Possible values: #{most_constrained.allowed_vals}"
    success = false
    most_constrained.allowed_vals.each do |val|
	    puzzle.set_val(most_constrained.x, most_constrained.y, val)
	    puts "#{tabs}Attempting value: #{val}"
	    success = solve(puzzle, indent + 1)
	    if success then break end
	    puts "#{tabs}Recursive call with #{val} unsuccessful, unsetting."
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
