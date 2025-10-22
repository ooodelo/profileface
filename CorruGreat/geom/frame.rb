# frozen_string_literal: true

module CorruGreat
  module Geom
    # Frame builds an orthonormal basis for a face.
    class Frame
      attr_reader :origin, :u_axis, :v_axis, :normal, :transformation, :inverse

      def initialize(face, direction: :u)
        @face = face
        @normal = face.normal.clone.normalize
        @origin = plane_origin
        base_u = determine_primary_axis
        base_v = (@normal.cross(base_u)).normalize

        if direction.to_sym == :v
          @u_axis = base_v
          @v_axis = (@normal.cross(@u_axis)).normalize
        else
          @u_axis = base_u
          @v_axis = base_v
        end

        @transformation = Geom::Transformation.axes(@origin, @u_axis, @v_axis, @normal)
        @inverse = @transformation.inverse
      end

      def world_to_local(point)
        point.transform(@inverse)
      end

      def local_to_world(point)
        point.transform(@transformation)
      end

      def bounds_uv
        u_min = Float::INFINITY
        u_max = -Float::INFINITY
        v_min = Float::INFINITY
        v_max = -Float::INFINITY

        @face.vertices.each do |vertex|
          local = world_to_local(vertex.position)
          u_min = [u_min, local.x].min
          u_max = [u_max, local.x].max
          v_min = [v_min, local.y].min
          v_max = [v_max, local.y].max
        end

        {
          u: [u_min, u_max],
          v: [v_min, v_max]
        }
      end

      private

      def plane_origin
        @face.bounds.center.project_to_plane(@face.plane)
      end

      def determine_primary_axis
        longest_edge = @face.edges.max_by(&:length)
        axis = longest_edge ? longest_edge.line[1] : fallback_axis
        axis = axis.clone
        axis.normalize!
        axis = fallback_axis if axis.length.zero? || axis.parallel?(@normal)
        axis
      end

      def fallback_axis
        candidates = [
          Geom::Vector3d.new(1, 0, 0),
          Geom::Vector3d.new(0, 1, 0),
          Geom::Vector3d.new(0, 0, 1)
        ]
        candidates.find { |vector| !vector.parallel?(@normal) } || Geom::Vector3d.new(1, 0, 0)
      end
    end
  end
end
