require 'java'
load 'sudoku.rb'

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

class SudokuCell
    def initialize(value, color)
        @value = value
        @color = color
    end
    attr_accessor :value, :color
end

class GUIActionListener
    include ActionListener
    def initialize(gui)
        @gui = gui
    end
end

class InputListener
    include KeyListener
    def keyTyped(event)
        if (event.getID == KeyEvent::KEY_TYPED)
            char = event.getKeyChar.chr
           JOptionPane.showMessageDialog(nil, char)
        end
    end
    
    def keyReleased(event)
    end
    
    def keyPressed(event)
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
    
        
class GridPanel < JPanel
    def initialize
    @font = Font.new(nil, Font::PLAIN, 22)
    end
    
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
    
    def draw_thick_rectangle(g, x, y, width, height, thickness)
        thickness.times do |level|
            g.drawRect(x + level, y + level, width - 2 * level, height - 2 * level)
        end
    end
    
    def color_map= (map)
        @color_map = map
    end
    
    def paintComponent(g)
        g.setFont(@font)
        #paint largest rectangle - have to paint first white rectangle because
        #playing with the background yielded nothing - how the fuck
        #is my super class nil if I extend JPanel?
        g.setColor(Color::WHITE)
        g.fillRect(@buffer, @buffer, @grid_side, @grid_side)
        g.setColor(Color::BLACK)
        g.drawRect(@buffer, @buffer, @grid_side, @grid_side)
        #end paint largest rectangle
       
        #paint 9 inner grids, 3 squares for each one for a thick line
        3.times do |inner_row|
            3.times do |inner_column|
                outer_x = @buffer + inner_column * @inner_grid_length
                outer_y = @buffer + inner_row * @inner_grid_length
                draw_thick_rectangle(g, outer_x, outer_y, @inner_grid_length,
                    @inner_grid_length, 3)
                cell_start_x = outer_x + 2
                cell_start_y = outer_y + 2
                3.times do |cell_row|
                    3.times do |cell_column|
                        g.drawRect(cell_column * @cell_width + cell_start_x,
                            cell_row * @cell_width + cell_start_y,
                            @cell_width, @cell_width)
                    end
                end                
            end
        end
        
        #paint colors
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

class SudokuGUI < JFrame
    include Sudoku
    CELL_SIDE = 60
    GUI_WIDTH = 630
    PUZZLE_PANEL_HEIGHT = 30
    SOLUTION_PANEL_HEIGHT = 30
    DRAW_HEIGHT = GUI_WIDTH
    GUI_HEIGHT = DRAW_HEIGHT + PUZZLE_PANEL_HEIGHT + SOLUTION_PANEL_HEIGHT + 20
    
  def initialize(title, puzzle = nil)
    super(title)
    if (puzzle)
      self.set_puzzle(puzzle)
    end
    @color_map = init_color_map(puzzle)
    init_components
  end
  
  def init_color_map(puzzle)
    n = puzzle.grid.size
    map = Array.new(n) {|i| Array.new(n)}
    0.upto(n - 1) do |y_val|
        0.upto(n - 1) do |x_val|
            map[y_val][x_val] = SudokuCell.new(puzzle.grid[y_val][x_val], 
                Color::BLACK)
        end
    end
    return map
  end
     
  def update
    @draw_panel.color_map = @color_map
    @draw_panel.repaint
  end
  
  def load_puzzle(file_path)
    set_puzzle(Puzzle.new(file_path))
    @color_map = init_color_map(@current_puzzle)
  end
  
  def set_puzzle(new_puzzle)
    #TODO nullcheck
    @current_initial = new_puzzle
    @current_puzzle = Marshal.load(Marshal.dump(@current_initial))
    #other default settings?
  end
  
  def reset_puzzle
    @current_puzzle = Marshal.load(Marshal.dump(@current_initial))
    @color_map = init_color_map(@current_puzzle)
  end
  
  def generate_puzzle(valid = false)
    self.set_puzzle(generate_new_puzzle(valid))
    @color_map = init_color_map(@current_puzzle)
  end
  
  def save_puzzle(file_path)
    @current_puzzle.save(file_path)
  end
  
  def solve_current
    result = solve(@current_puzzle)
    if !result
      JOptionPane.showMessageDialog(nil, "No solution exists from this point!")
    else
      color_differences(@color_map, result.grid, Color::GREEN)
      @current_puzzle = result
    end
  end
  
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
            
  def check_entries
    #get discrepancies
    #color each offending item
  end
  
  def init_components
    
    #create buttons, listeners
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
    @draw_panel.addKeyListener(InputListener.new)
    @draw_panel.color_map = @color_map
    @container.add(@puzzle_control_panel)
    @container.add(@draw_panel)
    @container.add(@solution_control_panel)
    
    self.setSize(Dimension.new(GUI_WIDTH, GUI_HEIGHT))

    add(@container)
    pack

    self.setDefaultCloseOperation(JFrame::EXIT_ON_CLOSE)
    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
    @draw_panel.setFocusable(true)
    @draw_panel.requestFocus
  end
end

SudokuGUI.new('Sudoku', Sudoku::Puzzle.new('test_puzzle.txt')).setVisible(true)
