# frozen_string_literal: true

module CorruGreat
  module Tool
    # DrawHelper renders face highlights using Tool#draw.
    module DrawHelper
      extend self

      FILL_COLOR = Sketchup::Color.new(40, 200, 120, 96)
      OUTLINE_COLOR = Sketchup::Color.new(220, 40, 40, 255)

      def draw_face(view, face)
        draw_fill(view, face)
        draw_outline(view, face)
      end

      def draw_preview(view, polylines)
        return if polylines.nil? || polylines.empty?

        view.line_width = 1
        view.drawing_color = Sketchup::Color.new(40, 120, 220, 180)
        polylines.each do |polyline|
          next if polyline.length < 2

          view.draw(GL_LINE_STRIP, polyline)
        end
      end

      private

      def draw_fill(view, face)
        mesh = face.mesh 7
        triangles = []
        mesh.polygons.each do |polygon|
          points = polygon.each_with_object([]) do |index, acc|
            next if index.zero?

            acc << mesh.point_at(index.abs)
          end
          next unless points.length >= 3

          triangles.concat(points.take(3))
        end
        view.drawing_color = FILL_COLOR
        view.draw(GL_TRIANGLES, triangles) unless triangles.empty?
      end

      def draw_outline(view, face)
        view.drawing_color = OUTLINE_COLOR
        view.line_width = 3
        face.loops.each do |loop|
          points = loop.vertices.map(&:position)
          points << points.first if points.length > 2
          view.draw(GL_LINE_STRIP, points)
        end
      end
    end
  end
end
