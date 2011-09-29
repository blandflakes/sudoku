require 'java'
load 'sudoku.rb'
load 'util.rb'
include_class 'java.awt.event.ActionListener'
include_class 'java.awt.event.KeyListener'
include_class 'java.awt.event.KeyEvent'
include_class 'java.awt.Color'
include_class 'java.awt.Font'
include_class 'javax.swing.JFrame'
include_class 'javax.swing.JOptionPane'
include_class 'javax.swing.JPanel'
include_class 'javax.swing.JButton'
include_class 'java.awt.Dimension'
include_class 'javax.swing.UIManager'
include_class 'javax.swing.JFileChooser'


#Represents a cell containing a value in the Sudoku GUI
class SudokuCell
    def initialize(value, color)
        @value = value
        @color = color
    end
    attr_accessor :value, :color
end

#All the action listeners get a reference to the GUI callback
class GUIActionListener
    include ActionListener
    def initialize(gui)
        @gui = gui
    end
end

#Listens for keystrokes on the drawing panel, moves box (or deletes values) as appropriate
class InputListener
    include KeyListener
    def initialize(gui)
        @gui = gui
        @directions = {'w' => :up,
            's' => :down,
            'a' => :left,
            'd' => :right
            }
    end
    
    def keyTyped(event)
        if (event.getID == KeyEvent::KEY_TYPED)
            char = event.getKeyChar.chr
            case char
            when 'w', 'a', 's', 'd'
                @gui.move_box(@directions[char])
            when '1', '2', '3', '4', '5', '6', '7', '8', '9'
                @gui.enter_value(char.to_i)
            else if char[0].ord == 127
                    @gui.delete_current
                end
            end
        end
        @gui.update
    end
    
    def keyReleased(event)
    end
    
    def keyPressed(event)
    end
end

class ClearAction < GUIActionListener
    def actionPerformed(event)
        @gui.clear_puzzle
        @gui.update
    end
end

class ResetAction < GUIActionListener
    def actionPerformed(event)
        @gui.reset_puzzle
        @gui.update
    end
end

class GenerateAction < GUIActionListener
    def actionPerformed(event)
        @gui.generate_puzzle
        @gui.update
    end
end

class LoadPuzzleAction < GUIActionListener
    def actionPerformed(event)
        file_chooser = JFileChooser.new
        #todo extension or something for validity checks
        ret = file_chooser.showDialog(nil, 'Open puzzle')
        if ret == JFileChooser::APPROVE_OPTION
            @gui.load_puzzle(file_chooser.getSelectedFile.getCanonicalPath)
        end
        @gui.update
    end
end

class SavePuzzleAction < GUIActionListener
    def actionPerformed(event)
        file_chooser = JFileChooser.new
        #todo extension or something for validity checks
        ret = file_chooser.showDialog(nil, 'Save puzzle')
        if ret == JFileChooser::APPROVE_OPTION
            path = file_chooser.getSelectedFile.getCanonicalPath
            @gui.save_puzzle(path)
        end
        @gui.update        
    end
end

class SolveAction < GUIActionListener
    def actionPerformed(event)
        @gui.solve_current
        @gui.update
    end
end

class CheckAction < GUIActionListener
    def actionPerformed(event)
        @gui.check_entries
        @gui.update
    end
end
    
#The panel for drawing the grid.
#Handles grid outline, writing and coloring of values, selection box
class GridPanel < JPanel
    include Util
    def initialize
        super
        @font = Font.new(nil, Font::PLAIN, 22)
        @current_box = Point.new(0, 0);
    end
  
    #listeners/gui will update this as it changes
    attr_accessor :current_box
    
    #cell_width is the starting point for all calcs
    #side_length is the width and height of the drawing panel
    def set_sizes(cell_width, side_length)
        @cell_width = cell_width
        #calculate other sizes
        @cell_container_length = cell_width * 3
        @inner_grid_length =  @cell_container_length + 2
        @grid_side = @inner_grid_length * 3
        @buffer = (side_length - @grid_side)/2
        #puts "cw: #{@cell_width}, inner_in: #{@inner_grid_inside}, inner_out: #{@inner_grid_outer}, @grid_side: #{@grid_side}, buffer: #{@buffer}"
    end
    
    #draws a rectangle with width greater than 1 - g is the page to draw on, x and y are top left corner,
    #width is outside width and height is outside height.
    #thickness: number of rectangles thick to draw it
    def draw_thick_rectangle(g, x, y, width, height, thickness)
        thickness.times do |level|
            g.drawRect(x + level, y + level, width - 2 * level, height - 2 * level)
        end
    end
    
    #color_map is a grid of SudokuCells that are read when filling the grid
    def color_map= (map)
        @color_map = map
    end
    
    def paintComponent(g)
        super(g)
        g.setFont(@font)
        #paint largest rectangle - have to paint first white rectangle because
        #playing with the background yielded nothing - how
        #is my super class nil if I extend JPanel?  Got that working, but I probably don't need to change this.
        g.setColor(Color::WHITE)
        g.fillRect(@buffer, @buffer, @grid_side, @grid_side)
        g.setColor(Color::BLACK)
        g.drawRect(@buffer, @buffer, @grid_side, @grid_side)
        #end paint largest rectangle
       
        #paint 9 inner grids, 3 squares for each one for a thick line
        3.times do |inner_row|
            3.times do |inner_column|
                #outer_[x|y] is the top left corner of each inner grid
                outer_x = @buffer + inner_column * @inner_grid_length
                outer_y = @buffer + inner_row * @inner_grid_length
                draw_thick_rectangle(g, outer_x, outer_y, @inner_grid_length,
                    @inner_grid_length, 3)
                #cell_start[x|y] is top left of each inner grid that can have cells drawn at (starting point for cells)
                cell_start_x = outer_x + 2
                cell_start_y = outer_y + 2
                3.times do |cell_row|
                    3.times do |cell_column|
                        #check to paint current_box over cell instead of black square.  I could write it over after, but I wasn't smart enough to get the coordinates right.
                        if inner_row * 3 + cell_row == @current_box.y && inner_column * 3 + cell_column == @current_box.x
                            g.setColor(Color::ORANGE)
                            draw_thick_rectangle(g, cell_column * @cell_width + cell_start_x,
                            cell_row * @cell_width + cell_start_y,
                            @cell_width, @cell_width, 3)
                            g.setColor(Color::BLACK)
                        else
                            g.drawRect(cell_column * @cell_width + cell_start_x,
                                cell_row * @cell_width + cell_start_y,
                                @cell_width, @cell_width)
                        end
                    end
                end                
            end
        end
        
        #paint values entered
        x = y = nil
        9.times do |row|
            9.times do |col|
                x = @buffer + col*@cell_width + 2 + (@cell_width - @font.getSize)/2
                y = @buffer + row*@cell_width + 2 + @font.getSize + (@cell_width - @font.getSize)/2
                if @color_map[row][col].value != 0
                    g.setColor(@color_map[row][col].color)
                    g.drawString("#{@color_map[row][col].value}", x, y)
                end
            end
        end
        self.requestFocus
    end
end

#Actual GUI class.  Contains methods for manipulating GUI items, calls Sudoku methods to perform work on puzzle.
class SudokuGUI < JFrame
    include Sudoku
    CELL_SIDE = 60
    GUI_WIDTH = 630
    PUZZLE_PANEL_HEIGHT = 35
    SOLUTION_PANEL_HEIGHT = 35
    DRAW_HEIGHT = GUI_WIDTH
    GUI_HEIGHT = DRAW_HEIGHT + PUZZLE_PANEL_HEIGHT + SOLUTION_PANEL_HEIGHT + 30
    
  def initialize(title, puzzle = Array.new(@n) {|i| Array.new(@n)})
    super(title)
    if (puzzle)
      self.set_puzzle(puzzle)
    end
    @color_map = init_color_map(puzzle)
    @n = 9
    init_components
  end
  
  #sets up a new color_map assuming puzzle is the initial state.  All given values are black.
  def init_color_map(puzzle)
    n = puzzle.size
    map = Array.new(n) {|i| Array.new(n)}
    0.upto(n - 1) do |y_val|
        0.upto(n - 1) do |x_val|
            map[y_val][x_val] = SudokuCell.new(puzzle[y_val][x_val], 
                Color::BLACK)
        end
    end
    return map
  end

  #method for redrawing the GUI - updates the grid state and asks the draw panel to repaint
  def update
    @draw_panel.color_map = @color_map
    @draw_panel.repaint
  end
  
  #updates current puzzle to the grid located at file_path.  Could blow up - there's really no checking done here.
  def load_puzzle(file_path)
    set_puzzle(Puzzle.get_grid(file_path))
  end
  
  #updates the starting state puzzle to the new puzzle and resets the color map
  def set_puzzle(new_puzzle)
    @current_initial = new_puzzle
    @color_map = init_color_map(@current_initial)
  end
  
  #when the user enters a number, updates the color_map (if the number isn't part of the initial state)
  def enter_value(val)
    pos = @draw_panel.current_box
    if @current_initial[pos.y][pos.x] == 0
        @color_map[pos.y][pos.x] = SudokuCell.new(val, Color::BLUE)
    end
  end
  
  #deletes the value in the selected cell (if the number isn't part of the initial state)
  def delete_current
    pos = @draw_panel.current_box
    if @current_initial[pos.y][pos.x] == 0
        @color_map[pos.y][pos.x] = SudokuCell.new(0, Color::BLACK)
    end
  end

  #clears all user entered values, restoring initial state of the puzzle
  def reset_puzzle
    @color_map = init_color_map(@current_initial)
  end
  
  #changes the selected cell.
  def move_box(direction)
    case direction
    when :left
        @draw_panel.current_box.x -= 1 unless @draw_panel.current_box.x == 0
    when :right
        @draw_panel.current_box.x += 1 unless @draw_panel.current_box.x == 8
    when :up
        @draw_panel.current_box.y -= 1 unless @draw_panel.current_box.y == 0
    when :down
        @draw_panel.current_box.y += 1 unless @draw_panel.current_box.y == 8
    end
  end

  #wipes all values from the grid, leaving an empty sudoku
  def clear_puzzle
      map = Array.new(@n) {|i| Array.new(@n)}
      set_puzzle(map)
  end
  
  #generates a puzzle randomly.  puzzle is guaranteed to have at least 1 solution.
  def generate_puzzle(valid = false)
    self.set_puzzle(generate_puzzle_grid(@n, valid))
  end
  
  #collects the 2d array of values from the color map
  def get_current_grid
    @color_map.collect {|row| row.collect {|cell| cell.value}}
  end
  
  #writes the current puzzle to a file
  def save_puzzle(file_path)
    Puzzle.save(self.get_current_grid, file_path)
  end
  
  #checks that the current puzzle has no conflicts, then attempts to solve it, displaying results in green.
  def solve_current
    check_result = check_entries
    if !check_result[:discrepencies].empty?
        return
    end
    result = solve(Puzzle.new(self.get_current_grid))
    if !result
      JOptionPane.showMessageDialog(nil, "No solution exists from this point!")
    else
      color_differences(@color_map, result.grid, Color::GREEN)
      @current_puzzle = result
    end
  end
  
  #Finds any new values in "new" and updates them with color in color_map.
  def color_differences(color_map, new, color)
    n = color_map.size
    n.times do |row|
        n.times do |col|
            if color_map[row][col].value != new[row][col]
                color_map[row][col] = SudokuCell.new(new[row][col], color)
            end
        end
    end
  end                

  #checks for invalid entries (two or more of the same value in a given grid, row, or column.  Discrepencies are set to red.  Returns Hashmap of results (:win -> bool, :discrepencies -> errors, :gaps-> any gaps exist?)
  def check_entries
    result = Puzzle.check(self.get_current_grid)
    
    if result[:win]
        JOptionPane.showMessageDialog(nil, "You win!")
    else
        result[:discrepencies].each do |location|
            if @color_map[location.y][location.x].color == Color::BLUE
                @color_map[location.y][location.x].color = Color::RED
            end
        end
    end
    return result
  end
  
  #initializes layout and components of the GUI
  def init_components
    #create buttons, listeners
    clear_button = JButton.new('Clear')
    clear_button.addActionListener(ClearAction.new(self))
    reset_button = JButton.new('Reset puzzle')
    reset_button.addActionListener(ResetAction.new(self))
    gen_button = JButton.new('Generate puzzle')
    gen_button.addActionListener(GenerateAction.new(self))
    load_button = JButton.new('Load puzzle')
    load_button.addActionListener(LoadPuzzleAction.new(self))
    save_button = JButton.new('Save puzzle')
    save_button.addActionListener(SavePuzzleAction.new(self))
    solve_button = JButton.new('Solve it!')
    solve_button.addActionListener(SolveAction.new(self))
    check_button = JButton.new('Check it!')
    check_button.addActionListener(CheckAction.new(self))
    
    #create container object to hold control panel and draw panel
    @container = JPanel.new
    @container.setPreferredSize(Dimension.new(GUI_WIDTH, GUI_HEIGHT))

    #puzzle_control_panel holds buttons for manipulating puzzle state
    @puzzle_control_panel = JPanel.new
    @puzzle_control_panel.setPreferredSize(Dimension.new(GUI_WIDTH, PUZZLE_PANEL_HEIGHT))

    #add buttons to puzzle control panel
    @puzzle_control_panel.add(clear_button)
    @puzzle_control_panel.add(reset_button)
    @puzzle_control_panel.add(gen_button)
    @puzzle_control_panel.add(load_button)
    @puzzle_control_panel.add(save_button)
    
    #solution_control_panel holds controls for solving puzzle or checking answers
    @solution_control_panel = JPanel.new
    @solution_control_panel.setPreferredSize(Dimension.new(GUI_WIDTH, SOLUTION_PANEL_HEIGHT))
    
    #add buttons to solution control panel
    @solution_control_panel.add(solve_button)
    @solution_control_panel.add(check_button)
    
    #draw panel is where the sudoku grid will be drawn
    @draw_panel = GridPanel.new
    @draw_panel.set_sizes(CELL_SIDE, GUI_WIDTH)
    @draw_panel.setPreferredSize(Dimension.new(GUI_WIDTH, DRAW_HEIGHT))
    @draw_panel.addKeyListener(InputListener.new(self))
    @draw_panel.color_map = @color_map
    @container.add(@puzzle_control_panel)
    @container.add(@draw_panel)
    @container.add(@solution_control_panel)
    
    self.setSize(Dimension.new(GUI_WIDTH, GUI_HEIGHT))

    add(@container)
    pack

    self.setDefaultCloseOperation(JFrame::EXIT_ON_CLOSE)
    #UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
    @draw_panel.setFocusable(true)
    @draw_panel.requestFocus
  end
end

SudokuGUI.new('Sudoku', Sudoku::Puzzle.get_grid('test_puzzle.txt')).setVisible(true)
