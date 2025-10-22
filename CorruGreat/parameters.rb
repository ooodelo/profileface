# frozen_string_literal: true

require 'json'

module CorruGreat
  # Parameters describes the sine profile configuration.
  class Parameters
    DEFAULT_AMPLITUDE = 50.mm
    DEFAULT_PITCH = 200.mm
    DEFAULT_SEGMENTS = 16

    attr_accessor :direction, :amplitude, :pitch, :segments_per_period, :thickness

    def initialize(direction: :u, amplitude: DEFAULT_AMPLITUDE, pitch: DEFAULT_PITCH,
                   segments_per_period: DEFAULT_SEGMENTS, thickness: nil)
      @direction = (direction || :u).to_sym
      @amplitude = amplitude
      @pitch = pitch
      @segments_per_period = [segments_per_period.to_i, 3].max
      @thickness = thickness
    end

    def clone
      self.class.new(
        direction: direction,
        amplitude: amplitude,
        pitch: pitch,
        segments_per_period: segments_per_period,
        thickness: thickness
      )
    end

    def direction=(value)
      @direction = (value || :u).to_sym
    end

    def amplitude=(value)
      @amplitude = value
    end

    def pitch=(value)
      @pitch = value
    end

    def segments_per_period=(value)
      @segments_per_period = [value.to_i, 3].max
    end

    def thickness=(value)
      @thickness = value
    end

    def flip_direction!
      @direction = (@direction == :u ? :v : :u)
    end

    def to_h
      {
        'direction' => direction.to_s,
        'amplitude' => amplitude,
        'pitch' => pitch,
        'segments_per_period' => segments_per_period,
        'thickness' => thickness
      }
    end

    def to_json(*_args)
      JSON.generate(to_h)
    end

    def self.from_payload(payload)
      data = payload.is_a?(String) ? JSON.parse(payload) : payload
      new(
        direction: (data['direction'] || 'u').to_sym,
        amplitude: parse_length(data['amplitude'], DEFAULT_AMPLITUDE),
        pitch: parse_length(data['pitch'], DEFAULT_PITCH),
        segments_per_period: (data['segments_per_period'] || DEFAULT_SEGMENTS).to_i,
        thickness: parse_optional_length(data['thickness'])
      )
    end

    def self.resolve_length(value, fallback)
      parse_length(value, fallback)
    end

    def self.resolve_optional_length(value)
      parse_optional_length(value)
    end

    def formatted
      {
        direction: direction.to_s,
        amplitude: Sketchup.format_length(amplitude),
        pitch: Sketchup.format_length(pitch),
        segments_per_period: segments_per_period,
        thickness: thickness ? Sketchup.format_length(thickness) : ''
      }
    end

    def self.parse_length(value, fallback)
      parsed = Sketchup.parse_length(value)
      parsed.nil? ? fallback : parsed
    end
    private_class_method :parse_length

    def self.parse_optional_length(value)
      return nil if value.nil? || value.to_s.strip.empty?

      Sketchup.parse_length(value)
    end
    private_class_method :parse_optional_length
  end
end
