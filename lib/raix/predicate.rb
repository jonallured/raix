# frozen_string_literal: true

module Raix
  # A module for handling yes/no questions using AI chat completion.
  # When included in a class, it provides methods to define handlers for
  # yes and no responses. All handlers are optional. Any response that
  # does not begin with "yes, " or "no, " will be considered a maybe.
  #
  # @example
  #   class Question
  #     include Raix::Predicate
  #
  #     yes? do |explanation|
  #       puts "Yes: #{explanation}"
  #     end
  #
  #     no? do |explanation|
  #       puts "No: #{explanation}"
  #     end
  #
  #     maybe? do |explanation|
  #       puts "Maybe: #{explanation}"
  #     end
  #   end
  #
  #   question = Question.new
  #   question.ask("Is Ruby a programming language?")
  module Predicate
    extend ActiveSupport::Concern
    include ChatCompletion

    def ask(question, openai: false)
      raise "Please define a yes and/or no block" if self.class.yes_block.nil? && self.class.no_block.nil?

      transcript << { system: "Always answer 'Yes, ', 'No, ', or 'Maybe, ' followed by a concise explanation!" }
      transcript << { user: question }

      chat_completion(openai:).tap do |response|
        if response.downcase.start_with?("yes,")
          instance_exec(response, &self.class.yes_block) if self.class.yes_block
        elsif response.downcase.start_with?("no,")
          instance_exec(response, &self.class.no_block) if self.class.no_block
        elsif self.class.maybe_block
          instance_exec(response, &self.class.maybe_block)
        else
          puts "[Raix::Predicate] Unhandled response: #{response}"
        end
      end
    end

    # Class methods added to the including class
    module ClassMethods
      attr_reader :yes_block, :no_block, :maybe_block

      def yes?(&block)
        @yes_block = block
      end

      def no?(&block)
        @no_block = block
      end

      def maybe?(&block)
        @maybe_block = block
      end
    end
  end
end
