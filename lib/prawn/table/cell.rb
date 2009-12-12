# encoding: utf-8   

# cell.rb: Table cell drawing.
#
# Copyright December 2009, Gregory Brown and Brad Ediger. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
module Prawn
  class Document
    def cell(options={})
      at = options[:at] || [0, cursor]
      cell = Table::Cell.new(self, at, options)
      cell.draw
      cell
    end
  end

  class Table
    class Cell

      attr_reader :padding

      attr_writer :width, :height

      def initialize(pdf, point, options={})
        @pdf       = pdf
        @point     = point

        @width     = options[:width]
        @height    = options[:height]
        @padding   = interpret_padding(options[:padding])

        @font_size  = options[:font_size]
        @font_style = options[:font_style]

        @borders      = options[:borders] || [:top, :bottom, :left, :right]
        @border_width = options[:border_width] || 1
        @border_color = options[:border_color]

        @content   = options[:content]
      end

      # Returns the cell's width in points, inclusive of padding.
      #
      def width
        @width ||= (content_width + left_padding + right_padding)
      end

      # Returns the width of the bare content in the cell, excluding padding.
      #
      def content_width
        if @width # manually set
          return @width - left_padding - right_padding
        end

        @pdf.width_of(@content, :size => @font_size)
      end

      # Returns the cell's height in points, inclusive of padding.
      #
      def height
        @height ||= (content_height + top_padding + bottom_padding)
      end

      # Returns the height of the bare content in the cell, excluding padding.
      #
      def content_height
        if @height # manually set
          return @height - top_padding - bottom_padding
        end

        height = nil

        if @font_size
          @pdf.font_size(@font_size) do
            height = @pdf.height_of(@content, :width => content_width)
          end
        else
          height = @pdf.height_of(@content, :width => content_width)
        end

        height
      end

      # Draws the cell onto the document.
      #
      def draw
        draw_borders
        draw_content
      end

      private

      def draw_borders
        return if @border_width <= 0
        margin = @border_width / 2

        @pdf.mask(:line_width, :stroke_color) do
          @pdf.line_width   = @border_width
          @pdf.stroke_color = @border_color if @border_color

          @borders.each do |border|
            from, to = case border
                       when :top
                         [[x, y], [x+width, y]]
                       when :bottom
                         [[x, y-height], [x+width, y-height]]
                       when :left
                         [[x, y+margin], [x, y-height-margin]]
                       when :right
                         [[x+width, y+margin], [x+width, y-height+margin]]
                       end
            @pdf.stroke_line(from, to)
          end
        end
      end

      def draw_content
        @pdf.bounding_box([x + left_padding, y - top_padding], 
                          :width  => content_width,
                          :height => content_height) do
          text_options = {}
          text_options[:size] = @font_size if @font_size
          text_options[:style] = @font_style if @font_style
          @pdf.text(@content, text_options)
        end
      end

      def x
        @point[0]
      end

      def y
        @point[1]
      end

      def interpret_padding(pad)
        case
        when pad.nil?
          [0, 0, 0, 0]
        when Numeric === pad # all padding
          [pad, pad, pad, pad]
        when pad.length == 2 # vert, horiz
          [pad[0], pad[1], pad[0], pad[1]]
        when pad.length == 4 # top, right, bottom, left
          [pad[0], pad[1], pad[2], pad[3]]
        else
          raise ArgumentError, ":padding must be a number or an array [v,h] " +
            "or [t,r,b,l]"
        end
      end

      def top_padding
        @padding[0]
      end

      def right_padding
        @padding[1]
      end

      def bottom_padding
        @padding[2]
      end

      def left_padding
        @padding[3]
      end

    end
  end
end
