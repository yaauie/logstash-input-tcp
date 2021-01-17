# encoding: utf-8

##
# The `Chooser` provides a safe way to provide multiple distinct sets of behaviours,
# exactly one of which will be selected at runtime.
#
# @api internal
class LogStash::Inputs::Tcp::Chooser
  ##
  # @param supported_choices [Array[Symbol]]
  def initialize(supported_choices)
    @supported_choices = supported_choices.dup.freeze
  end

  ##
  # @param choice [Symbol]
  # @param error_name [#to_s] the name of this choice, to be used in case of an error
  # @param error_class [Exception] the exception class to use in case of an error
  # @return [Choice]
  def choose(choice, error_name="choice", error_class=ArgumentError)
    if !@supported_choices.include?(choice)
      message = sprintf("unsupported %s `%s`; expected one of %s", error_name, choice.to_s, @supported_choices.map(&:to_s))
      logger.error(message)
      fail(error_class, message)
    end

    Choice.new(self, choice)
  end

  ##
  # Used when making a choice, ensures that the providing code supplies all possible choices.
  # @see Choice#value_from
  # @api private
  def validate!(defined_choices)
    missing = @supported_choices - defined_choices
    fail(ArgumentError, "missing required options #{missing}") if missing.any?

    unknown = defined_choices - @supported_choices
    fail(ArgumentError, "unsupported options #{unknown}") if unknown.any?
  end

  ##
  # A `Choice` represents a chosen value from the set supported by its `Chooser`.
  # It can be used to safely select a value from a mapping at runtime using `Choice#value_from`.
  class Choice

    ##
    # @api private
    # @see Chooser#choice
    #
    # @param chooser [Chooser]
    # @param choice [Symbol]
    def initialize(chooser, choice)
      @chooser = chooser
      @choice = choice
    end

    ##
    # With the current choice value, select one of the provided options.
    # @param options [Hash{Symbol=>Object}]: the options to chose between.
    #                                        it is an `ArgumentError` to provide a different set of
    #                                        options than those this `Chooser` was initialized with.
    #                                        This ensures that all reachable code implements all
    #                                        supported options.
    # @return [Object]
    def value_from(options)
      @chooser.validate!(options.keys)
      options.fetch(@choice)
    end
    alias_method :[], :value_from
  end
end
