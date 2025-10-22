# frozen_string_literal: true

module CorruGreat
  module Ops
    # Apply orchestrates the geometry creation and clipping.
    module Apply
      extend self

      ATTR_DICTIONARY = 'corrugreat_profile'.freeze

      def perform(face, params)
        return unless CorruGreat::Geom::Utils.valid_face?(face)

        model = face.model
        model.start_operation('CorruGreat Face', true)

        group = build_group(face, params)
        CorruGreat::Ops::Clipper.clip_to_face!(group, face)
        soften_internal_edges(group)
        transfer_attributes(group, face, params)
        erase_source_face(face)

        model.commit_operation
        group
      rescue StandardError => e
        model.abort_operation
        ::UI.messagebox("CorruGreat failed: #{e.message}")
        raise e
      end

      private

      def build_group(face, params)
        parent_entities = face_parent_entities(face)
        group = parent_entities.add_group
        mesh = CorruGreat::Geom::SineSurface.build(face, params)
        group.entities.add_faces_from_mesh(mesh)
        group
      end

      def face_parent_entities(face)
        parent = face.parent
        return parent if parent.is_a?(Sketchup::Entities)
        return parent.entities if parent.respond_to?(:entities)

        face.model.active_entities
      end

      def soften_internal_edges(group)
        group.entities.grep(Sketchup::Edge).each do |edge|
          next unless edge.faces.length == 2

          edge.soft = true
          edge.smooth = true
        end
      end

      def transfer_attributes(group, face, params)
        group.name = 'CorruGreat Sine Panel'
        group.material = face.material if face.material
        if group.respond_to?(:back_material=) && face.respond_to?(:back_material) && face.back_material
          group.back_material = face.back_material
        end
        group.layer = face.layer if face.respond_to?(:layer) && face.layer
        dictionary = group.attribute_dictionary(ATTR_DICTIONARY, true)
        params.to_h.each_pair { |key, value| dictionary[key] = attribute_value(value) }
      end

      def attribute_value(value)
        value.respond_to?(:to_f) ? value.to_f : value
      end

      def erase_source_face(face)
        face.erase! if face.valid?
      end
    end
  end
end
