# frozen_string_literal: true

module CorruGreat
  module Ops
    # Clipper trims generated meshes by the boundary of the source face.
    module Clipper
      extend self

      ALLOWED_CLASSIFICATIONS = [
        Sketchup::Face::PointInside,
        Sketchup::Face::PointOnFace,
        Sketchup::Face::PointOnEdge,
        Sketchup::Face::PointOnVertex
      ].freeze

      def clip_to_face!(group, source_face)
        return unless CorruGreat::Geom::Utils.valid_face?(source_face)

        parent_entities = parent_entities_for(group)
        cutter = parent_entities.add_group
        cutter_entities = cutter.entities

        face = build_face_copy(cutter_entities, source_face)
        return unless face

        depth = [source_face.bounds.diagonal, source_face.normal.length * 2.0].max
        normal = source_face.normal.clone.normalize
        offset = normal.clone
        offset.length = depth / 2.0
        offset.reverse!
        cutter.transform!(::Geom::Transformation.translation(offset))
        face.pushpull(depth)

        group.entities.intersect_with(true, group.transformation, group.entities, group.transformation, false, cutter_entities)
        prune_outside_faces(group, source_face)
        remove_orphan_edges(group)
      ensure
        cutter.erase! if cutter && cutter.valid?
      end

      private

      def parent_entities_for(group)
        parent = group.parent
        return parent if parent.is_a?(Sketchup::Entities)
        return parent.entities if parent.respond_to?(:entities)

        group.model.active_entities
      end

      def build_face_copy(entities, source_face)
        outer_points = source_face.outer_loop.vertices.map(&:position)
        base_face = entities.add_face(outer_points)
        return base_face unless base_face

        source_face.loops.each do |loop|
          next if loop == source_face.outer_loop
          next if loop.respond_to?(:outer?) && loop.outer?

          points = loop.vertices.map(&:position)
          hole = entities.add_face(points)
          hole&.erase!
        end
        base_face
      end

      def prune_outside_faces(group, source_face)
        plane = source_face.plane
        group.entities.grep(Sketchup::Face).each do |face|
          centroid = CorruGreat::Geom::Utils.centroid(face)
          projected = centroid.project_to_plane(plane)
          classification = source_face.classify_point(projected)
          next if ALLOWED_CLASSIFICATIONS.include?(classification)

          face.erase!
        end
      end

      def remove_orphan_edges(group)
        group.entities.grep(Sketchup::Edge).each do |edge|
          edge.erase! if edge.faces.empty?
        end
      end
    end
  end
end
