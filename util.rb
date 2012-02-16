module Util
    class Point
        def initialize(x, y)
          @x = x
          @y = y
        end
        
        def eql?(other)
            return other.x ==@x && other.y == @y
        end
        
        def hash
            return "#{x}0#{y}".to_i
        end
        attr_accessor :x, :y
    end
end