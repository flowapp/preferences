module Preferences
  # Represents the definition of a preference for a particular model
  class PreferenceDefinition
    # The data type for the content stored in this preference type
    attr_reader :type, :name

    def initialize(name, *args) #:nodoc:
      options = args.extract_options!
      options.assert_valid_keys(:default, :group_defaults)

      type = args.first ? args.first.to_sym : :boolean
      type = :string if @type == :any

      @type = ActiveRecord::Type.lookup(type)
      @name = name
      @default = options[:default]

      @group_defaults = (options[:group_defaults] || {}).inject({}) do |defaults, (group, default)|
        defaults[group.is_a?(Symbol) ? group.to_s : group] = type_cast(default)
        defaults
      end
    end

    # The default value to use for the preference in case none have been
    # previously defined
    def default_value(group = nil)
      @group_defaults.include?(group) ? @group_defaults[group] : @default
    end

    # Determines whether column backing this preference stores numberic values
    def number?
      @type.is_a?(ActiveRecord::Type::Integer)
    end

    # Typecasts the value based on the type of preference that was defined.
    def type_cast(value)
      @type.deserialize(value)
    end

    # Typecasts the value to true/false depending on the type of preference
    def query(value)
      if !(value = type_cast(value))
        false
      elsif number?
        !value.zero?
      else
        !value.blank?
      end
    end
  end
end
