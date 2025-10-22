# frozen_string_literal: true

module CorruGreat
  module Loader
    extend self

    def load
      return if defined?(@loaded) && @loaded

      base = File.dirname(__FILE__)
      Sketchup.require File.join(base, 'version')
      Sketchup.require File.join(base, 'parameters')
      Sketchup.require File.join(base, 'geom', 'utils')
      Sketchup.require File.join(base, 'geom', 'frame')
      Sketchup.require File.join(base, 'geom', 'sine_surface')
      Sketchup.require File.join(base, 'ops', 'clipper')
      Sketchup.require File.join(base, 'ops', 'apply')
      Sketchup.require File.join(base, 'ui', 'dialog')
      Sketchup.require File.join(base, 'tool', 'draw_helper')
      Sketchup.require File.join(base, 'tool', 'face_picker')
      Sketchup.require File.join(base, 'commands')

      CorruGreat::Commands.register

      @loaded = true
    end
  end
end

CorruGreat::Loader.load
