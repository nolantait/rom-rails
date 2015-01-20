module ROM
  module Model
    class Form
      include Charlatan.new(:params)

      class << self
        attr_reader :params, :validator, :commands, :key
      end

      def self.primary_key(key)
        @primary_key = key
        self
      end

      def self.input(&block)
        @params = Class.new {
          include ROM::Model::Params
        }
        @params.class_eval(&block)
        self
      end

      def self.validations(&block)
        @validator = Class.new {
          include ROM::Model::Validator
        }
        @validator.class_eval(&block)
        self
      end

      def self.inject_commands_for(*names)
        @commands = names
        names.each { |name| attr_reader(name) }
        self
      end

      def self.build(input = {})
        commands = self.commands.each_with_object({}) { |name, h|
          h[name] = rom.command(name)
        }
        new(params.new(input), commands)
      end

      def self.rom
        ROM.env
      end

      attr_reader :params, :result

      def initialize(params = {}, options = {})
        super
        @params = params
        @result = nil
        options.each do |key, value|
          instance_variable_set("@#{key}", value)
        end
      end

      def model_name
        self.class.params.model_name
      end

      def to_key
        self.class.key || [:id]
      end

      def commit
        raise NotImplementedError
      end

      def save
        @result = commit
        self
      end

      # FIXME: we need inheritance (probably) here where:
      #        Form::New#persisted? => false
      #        Form::Update#persisted? => true
      def persisted?
        false
      end

      def success?
        errors.nil?
      end

      def errors
        result && result.error
      end
    end
  end
end
