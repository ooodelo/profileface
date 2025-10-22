# frozen_string_literal: true

module CorruGreat
  module Geom
    # SineSurface builds polygon meshes for corrugated panels.
    module SineSurface
      extend self

      def build(face, params)
        frame = Frame.new(face, direction: params.direction)
        uv_bounds = frame.bounds_uv
        mesh = ::Geom::PolygonMesh.new

        u_range = expand_range(uv_bounds[:u], params.pitch)
        v_range = expand_range(uv_bounds[:v], params.pitch / 2.0)

        u_step = compute_u_step(u_range, params)
        v_step = compute_v_step(v_range, params)

        u_count = steps_count(u_range, u_step)
        v_count = steps_count(v_range, v_step)

        indices = Array.new(u_count) { Array.new(v_count) }
        period = normalized_period(params.pitch)

        (0...u_count).each do |iu|
          u = u_range.first + iu * u_step
          (0...v_count).each do |iv|
            v = v_range.first + iv * v_step
            height = wave_height(params.amplitude, u, period)
            local_point = ::Geom::Point3d.new(u, v, height)
            world_point = frame.local_to_world(local_point)
            indices[iu][iv] = mesh.add_point(world_point)
          end
        end

        add_faces(mesh, indices)

        mesh
      end

      def preview_paths(face, params, samples: 6)
        frame = Frame.new(face, direction: params.direction)
        uv_bounds = frame.bounds_uv
        u_min, u_max = uv_bounds[:u]
        v_min, v_max = uv_bounds[:v]
        return [] if u_min.nan? || v_min.nan?

        samples = [[samples, 2].max, 24].min
        paths = []
        v_step = samples > 1 ? (v_max - v_min) / (samples - 1).to_f : 0.0
        sample_u_step = params.pitch / params.segments_per_period.to_f
        sample_u_step = (u_max - u_min) / 20.0 if sample_u_step <= 0.0
        count_u = ((u_max - u_min) / sample_u_step).ceil + 1
        count_u = [[count_u, 2].max, 512].min
        period = normalized_period(params.pitch)

        (0...samples).each do |i|
          v = v_min + v_step * i
          polyline = []
          (0...count_u).each do |j|
            u = u_min + sample_u_step * j
            height = wave_height(params.amplitude, u, period)
            point = frame.local_to_world(::Geom::Point3d.new(u, v, height))
            polyline << point
          end
          paths << polyline
        end

        paths
      end

      private

      def normalized_period(pitch)
        value = pitch.respond_to?(:to_f) ? pitch.to_f : pitch
        value = 1.0 if value.nil? || value.abs < 1.0e-9
        value
      end

      def wave_height(amplitude, u, period)
        return 0.0 if amplitude.nil? || amplitude.to_f.abs < 1.0e-9

        ratio = u.respond_to?(:to_f) ? u.to_f / period : u / period
        amplitude * Math.sin(2.0 * Math::PI * ratio)
      end

      def expand_range(range, padding)
        min, max = range
        span = max - min
        pad = padding.nil? ? span * 0.1 : padding
        pad = span * 0.1 if pad.to_f.zero?
        [min - pad, max + pad]
      end

      def compute_u_step(range, params)
        span = range[1] - range[0]
        desired = params.pitch / params.segments_per_period.to_f
        return span if span <= 0.0
        return span / 2.0 if desired <= 0.0

        [[desired, span / 100.0].max, span].min
      end

      def compute_v_step(range, params)
        span = range[1] - range[0]
        return span if span <= 0.0

        target = params.pitch / 2.0
        target = span / 20.0 if target <= 0.0
        [[target, span / 60.0].max, span].min
      end

      def steps_count(range, step)
        span = range[1] - range[0]
        return 2 if span <= 0.0 || step <= 0.0

        [[(span / step).ceil + 1, 2].max, 512].min
      end

      def add_faces(mesh, indices)
        (0...indices.length - 1).each do |iu|
          (0...indices[iu].length - 1).each do |iv|
            a = indices[iu][iv]
            b = indices[iu + 1][iv]
            c = indices[iu + 1][iv + 1]
            d = indices[iu][iv + 1]
            mesh.add_polygon(a, b, c)
            mesh.add_polygon(a, c, d)
          end
        end
      end
    end
  end
end
