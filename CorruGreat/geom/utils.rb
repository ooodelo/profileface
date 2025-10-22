# frozen_string_literal: true

module CorruGreat
  module Geom
    module Utils
      extend self

      def centroid(face)
        points = face.vertices.map(&:position)
        return ::Geom::Point3d.new(0, 0, 0) if points.empty?

        sum = points.inject(::Geom::Point3d.new(0, 0, 0)) do |acc, point|
          ::Geom::Point3d.new(acc.x + point.x, acc.y + point.y, acc.z + point.z)
        end
        scale = 1.0 / points.length
        ::Geom::Point3d.new(sum.x * scale, sum.y * scale, sum.z * scale)
      end

      def ensure_length(value, fallback)
        return fallback if value.nil?
        return value if value.respond_to?(:to_f)

        fallback
      end

      def safe_normalize(vector)
        return ::Geom::Vector3d.new(1, 0, 0) if vector.nil? || vector.length.zero?

        vector.normalize
      end

      def valid_face?(face)
        face.is_a?(Sketchup::Face) && face.valid? && !face.deleted?
      end
    end
  end
end
