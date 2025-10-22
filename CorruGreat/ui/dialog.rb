# frozen_string_literal: true

require 'json'

module CorruGreat
  module UI
    # Dialog wraps the HtmlDialog used for parameter editing.
    class Dialog
      WIDTH = 360
      HEIGHT = 360

      def initialize(tool)
        @tool = tool
        @pending_params = nil
        build_dialog
      end

      def show(params)
        @pending_params = params.clone
        @dialog.show
        deliver_pending
      end

      def update(params)
        @pending_params = params.clone
        deliver_pending if @dialog.visible?
      end

      def close
        @dialog.close if @dialog.visible?
      end

      private

      def build_dialog
        options = {
          dialog_title: CorruGreat::EXTENSION_NAME,
          preferences_key: 'CorruGreatSineDialog',
          resizable: true,
          width: WIDTH,
          height: HEIGHT,
          style: ::UI::HtmlDialog::STYLE_DIALOG
        }
        @dialog = ::UI::HtmlDialog.new(options)
        @dialog.set_file(html_path)
        register_callbacks
      end

      def register_callbacks
        @dialog.add_action_callback('apply') { |_, payload| @tool.on_dialog_apply(payload) }
        @dialog.add_action_callback('preview') { |_, payload| @tool.on_dialog_preview(payload) }
        @dialog.add_action_callback('cancel') { |_context, _payload| @tool.on_dialog_cancel }
        @dialog.add_action_callback('ready') { deliver_pending }
      end

      def deliver_pending
        return unless @pending_params

        payload = JSON.generate(@pending_params.formatted)
        script = "window.CorruGreatDialog && window.CorruGreatDialog.setParameters(#{payload});"
        begin
          @dialog.execute_script(script)
          @pending_params = nil
        rescue StandardError
          # Keep payload to retry when the dialog signals readiness again.
        end
      end

      def html_path
        File.join(__dir__, 'dialog.html')
      end
    end
  end
end
