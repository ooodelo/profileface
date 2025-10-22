# frozen_string_literal: true

module CorruGreat
  module Commands
    extend self

    MENU_PATH = ['Extensions', 'CorruGreat'].freeze

    def register
      return if defined?(@registered) && @registered

      @command = UI::Command.new(CorruGreat::EXTENSION_NAME) { activate_tool }
      @command.tooltip = 'CorruGreat — Face→Профлист (синус)'
      @command.status_bar_text = 'Convert a planar face into a corrugated sine-wave sheet.'
      @command.set_validation_proc { tool_active? ? MF_CHECKED : MF_ENABLED }

      menu = UI.menu(MENU_PATH.first)
      submenu = MENU_PATH.drop(1).inject(menu) { |current, name| current.add_submenu(name) }
      submenu.add_item(@command)

      @registered = true
    end

    def activate_tool
      model = Sketchup.active_model
      model.select_tool(CorruGreat::Tool::FacePicker.new(last_params.clone))
    end

    def store_last_params(params)
      @last_params = params.clone
    end

    def last_params
      @last_params ||= CorruGreat::Parameters.new
    end

    def tool_active?
      tool = Sketchup.active_model.tools.active_tool
      tool.is_a?(CorruGreat::Tool::FacePicker)
    rescue StandardError
      false
    end
  end
end
