# frozen_string_literal: true

module CorruGreat
  module Tool
    # FacePicker drives the interactive workflow.
    class FacePicker

      TRANSPARENT_CURSOR_PATH = File.expand_path(File.join(__dir__, '..', 'ui', 'transparent_cursor.png'))
      CURSOR_HOTSPOT = [0, 0].freeze
      CURSOR_FILL_COLOR = Sketchup::Color.new(255, 214, 0, 255)
      CURSOR_OUTLINE_COLOR = Sketchup::Color.new(150, 100, 0, 255)

      class << self
        def transparent_cursor_id
          return @transparent_cursor_id if defined?(@transparent_cursor_id)

          @transparent_cursor_id = begin
            if File.exist?(TRANSPARENT_CURSOR_PATH)
              UI.create_cursor(TRANSPARENT_CURSOR_PATH, CURSOR_HOTSPOT[0], CURSOR_HOTSPOT[1])
            end
          rescue StandardError
            nil
          end
        end
      end

      def initialize(default_params)
        @params = default_params.clone
        reset_state
      end

      def activate(view)
        @model = view.model
        view.invalidate
      end

      def deactivate(view)
        close_dialog
        reset_state
        view.invalidate
      end

      def resume(view)
        view.invalidate
      end

      def getExtents
        bbox = Geom::BoundingBox.new
        face = @selected_face || @hover_face
        if CorruGreat::Geom::Utils.valid_face?(face)
          face.vertices.each { |vertex| bbox.add(vertex.position) }
        end
        bbox
      end

      def onMouseMove(flags, x, y, view)
        update_hover_face(view, x, y)
        update_cursor_position(x, y)
        view.invalidate
      end

      def onLButtonDown(flags, x, y, view)
        update_cursor_position(x, y)
        return unless CorruGreat::Geom::Utils.valid_face?(@hover_face)

        @selected_face = @hover_face
        open_dialog
        rebuild_preview
        view.invalidate
      end

      def onKeyDown(key, repeat, flags, view)
        case key
        when CONSTRAIN_MODIFIER_KEY
          return if repeat.to_i > 1

          @params.flip_direction!
          CorruGreat::Commands.store_last_params(@params)
          rebuild_preview
          view.invalidate
        when VK_RETURN
          apply_current_selection
        when defined?(VK_ENTER) && VK_ENTER
          apply_current_selection
        when VK_ESCAPE
          reset_selection
          view.invalidate
        end
      end

      def onUserText(text, view)
        parts = text.split(/[;,]/).map(&:strip)
        begin
          @params.amplitude = CorruGreat::Parameters.resolve_length(parts[0], @params.amplitude) if parts[0]
          @params.pitch = CorruGreat::Parameters.resolve_length(parts[1], @params.pitch) if parts[1]
          @params.segments_per_period = [parts[2].to_i, 3].max if parts[2]
          CorruGreat::Commands.store_last_params(@params)
          rebuild_preview
          view.invalidate
          @dialog&.update(@params)
        rescue StandardError
          UI.beep
        end
      end

      def enableVCB?
        true
      end

      def draw(view)
        if CorruGreat::Geom::Utils.valid_face?(@hover_face) && @hover_face != @selected_face
          CorruGreat::Tool::DrawHelper.draw_face(view, @hover_face)
        end

        if CorruGreat::Geom::Utils.valid_face?(@selected_face)
          CorruGreat::Tool::DrawHelper.draw_face(view, @selected_face)
          CorruGreat::Tool::DrawHelper.draw_preview(view, @preview_paths)
        end

        draw_cursor_marker(view)
      end

      def close_dialog
        @dialog&.close
        @dialog = nil
      end

      def on_dialog_apply(payload)
        update_params(payload)
        apply_current_selection
      end

      def on_dialog_preview(payload)
        update_params(payload)
        rebuild_preview
        Sketchup.active_model.active_view.invalidate
      end

      def on_dialog_cancel
        reset_selection
        Sketchup.active_model.active_view.invalidate
      end

      def onSetCursor
        cursor_id = self.class.transparent_cursor_id
        return false unless cursor_id

        UI.set_cursor(cursor_id)
      end

      private

      def reset_state
        @model = nil
        @hover_face = nil
        @selected_face = nil
        @preview_paths = []
        @cursor_position = nil
      end

      def reset_selection
        @selected_face = nil
        @hover_face = nil
        @preview_paths = []
        close_dialog
      end

      def update_hover_face(view, x, y)
        ph = view.pick_helper
        ph.do_pick(x, y)
        face = ph.picked_face
        @hover_face = CorruGreat::Geom::Utils.valid_face?(face) ? face : nil
      end

      def open_dialog
        @dialog ||= CorruGreat::UI::Dialog.new(self)
        @dialog.show(@params)
      end

      def update_params(payload)
        @params = CorruGreat::Parameters.from_payload(payload)
        CorruGreat::Commands.store_last_params(@params)
      end

      def rebuild_preview
        return unless CorruGreat::Geom::Utils.valid_face?(@selected_face)

        @preview_paths = CorruGreat::Geom::SineSurface.preview_paths(@selected_face, @params)
      rescue StandardError
        @preview_paths = []
      end

      def apply_current_selection
        return unless CorruGreat::Geom::Utils.valid_face?(@selected_face)

        params_copy = @params.clone
        group = CorruGreat::Ops::Apply.perform(@selected_face, params_copy)
        CorruGreat::Commands.store_last_params(params_copy)
        reset_selection
        group
      rescue StandardError
        # Operation already aborted and message shown in Apply.perform
      ensure
        Sketchup.active_model.active_view.invalidate
      end

      def draw_cursor_marker(view)
        return unless @cursor_position

        scale = cursor_pixel_scale
        apex = Geom::Point3d.new(@cursor_position.x, @cursor_position.y, 0.0)
        base_right = Geom::Point3d.new(apex.x + 16.0 * scale, apex.y + 6.0 * scale, 0.0)
        base_left = Geom::Point3d.new(apex.x + 5.0 * scale, apex.y + 20.0 * scale, 0.0)

        view.drawing_color = CURSOR_FILL_COLOR
        view.draw2d(GL_TRIANGLES, apex, base_right, base_left)

        view.drawing_color = CURSOR_OUTLINE_COLOR
        view.line_width = 1
        view.draw2d(GL_LINE_LOOP, apex, base_right, base_left)
      end

      def update_cursor_position(x, y)
        @cursor_position = Geom::Point3d.new(x.to_f, y.to_f, 0.0)
      end

      def cursor_pixel_scale
        version_major = Sketchup.respond_to?(:version) ? Sketchup.version.to_i : 0
        return 1.0 unless version_major >= 25

        return 1.0 unless UI.respond_to?(:scale_factor)

        scale = UI.scale_factor.to_f
        return 1.0 unless scale.positive?

        1.0 / scale
      rescue StandardError
        1.0
      end
    end
  end
end
