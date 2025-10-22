# frozen_string_literal: true

require 'sketchup.rb'
require 'extensions.rb'

module CorruGreat
  EXTENSION_ID = 'corrugreat_sine_profile'.freeze
  EXTENSION_NAME = 'CorruGreat'.freeze
  EXTENSION_VERSION = '1.0.0'.freeze
  EXTENSION_CREATOR = 'LittleCompany'.freeze

  unless file_loaded?(__FILE__)
    loader_path = File.join(__dir__, 'CorruGreat', 'loader')
    extension = SketchupExtension.new(EXTENSION_NAME, loader_path)
    extension.description = 'Convert planar faces into corrugated sine wave sheet metal with interactive controls.'
    extension.version = EXTENSION_VERSION
    extension.creator = EXTENSION_CREATOR
    Sketchup.register_extension(extension, true)
    file_loaded(__FILE__)
  end
end
