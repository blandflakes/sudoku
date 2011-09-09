require 'java'
load 'sudoku.rb'

#include_package 'javax.swing'
#include_package 'javax.swing.event'
include_class 'java.awt.event.ActionListener'
include_class 'javax.swing.JFrame'
include_class 'javax.swing.JOptionPane'
include_class 'javax.swing.JPanel'
include_class 'javax.swing.JButton'
include_class 'java.awt.Dimension'
include_class 'javax.swing.UIManager'

#JButton = javax.swing.JButton
#ActionListener = java.awt.event.ActionListener
#JFrame = javax.swing.JFrame
#JOptionPane = javax.swing.JOptionPane
#JPanel = javax.swing.JPanel

class GridPanel < JPanel
end

class SudokuGUI < JFrame
  def initialize(title, puzzle = nil)
    super(title)
    if (puzzle)
      self.set_puzzle(puzzle)
    end
    init_components
  end
  
  def load_puzzle(file_path)
    set_puzzle(Puzzle.new(file_path))
  end
  
  def set_puzzle(new_puzzle)
    #TODO nullcheck
    @current_puzzle = @current_initial = new_puzzle
    #other default settings?
    #repaint
  end
  
  def reset_puzzle(puzzle)
    @current_puzzle = @current_initial
    #repaint
  end
  
  def generate_puzzle(valid = false)
    self.set_puzzle(Sudoku::generate_new_puzzle(valid))
  end
  
  def save_puzzle(file_path)
    @current_puzzle.save(file_path)
  end
  
  def solve
    result = Sudoku::solve(@current_puzzle)
    if !result
      JOptionPane.showMessageDialog(nil, "No solution exists from this point!")
    else
      @current_puzzle = result
      #repaint
    end
  end
  
  def init_components
    reset_button = JButton.new('Reset puzzle')
    gen_button = JButton.new('Generation new puzzle')
    load_button = JButton.new('Load puzzle from file')
    save_button = JButton.new('Save current puzzle')
    solve_button = JButton.new('Solve it!')
    
    container = JPanel.new
    container.setPreferredSize(Dimension.new(800, 700))
    
    control_panel = JPanel.new
    control_panel.add(reset_button)
    control_panel.add(gen_button)
    control_panel.add(load_button)
    control_panel.add(save_button)
    control_panel.add(solve_button)
    
    draw_panel = GridPanel.new
    
    draw_panel.setPreferredSize(Dimension.new(800, 650))
    control_panel.setPreferredSize(Dimension.new(800, 500))
    
    container.add(draw_panel)
    container.add(control_panel)
    
    self.setSize(Dimension.new(800, 700))

    add(container)
    pack
    #need control panel
    #need gridspace, draw puzzle
    self.setDefaultCloseOperation(JFrame::EXIT_ON_CLOSE)
    UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
  end
end

SudokuGUI.new('Sudoku').setVisible(true)
