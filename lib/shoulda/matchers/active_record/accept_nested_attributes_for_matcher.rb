module Shoulda
  module Matchers
    module ActiveRecord
      # The `accept_nested_attributes_for` matcher tests usage of the
      # `accepts_nested_attributes_for` macro.
      #
      #     class Car < ActiveRecord::Base
      #       accepts_nested_attributes_for :doors
      #     end
      #
      #     # RSpec
      #     RSpec.describe Car, type: :model do
      #       it { should accept_nested_attributes_for(:doors) }
      #     end
      #
      #     # Minitest (Shoulda) (using Shoulda)
      #     class CarTest < ActiveSupport::TestCase
      #       should accept_nested_attributes_for(:doors)
      #     end
      #
      # #### Qualifiers
      #
      # ##### allow_destroy
      #
      # Use `allow_destroy` to assert that the `:allow_destroy` option was
      # specified.
      #
      #     class Car < ActiveRecord::Base
      #       accepts_nested_attributes_for :mirrors, allow_destroy: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Car, type: :model do
      #       it do
      #         should accept_nested_attributes_for(:mirrors).
      #           allow_destroy(true)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class CarTest < ActiveSupport::TestCase
      #       should accept_nested_attributes_for(:mirrors).
      #         allow_destroy(true)
      #     end
      #
      # Use `reject_if` to assert that the `:reject_if` option was
      # specified, with a Proc (or lambda with an arity of 1) or a
      # plain object.
      #
      #     class Car < ActiveRecord::Base
      #       accepts_nested_attributes_for :mirrors,
      #         reject_if: proc { |obj| obj.count != 2 }
      #
      #       accepts_nested_attributes_for :mirrors,
      #         reject_if: :different_than_2?
      #
      #       def different_than_2?
      #         mirrors.count != 2
      #       end
      #     end
      #
      #     # RSpec
      #     describe Car do
      #       it do
      #         should accept_nested_attributes_for(:mirrors).
      #           reject_if(:different_than_2?)
      #       end
      #     end
      #
      #     # Test::Unit
      #     class CarTest < ActiveSupport::TestCase
      #       should accept_nested_attributes_for(:mirrors).
      #         reject_if(:different_than_2?)
      #     end
      #
      # ##### limit
      #
      # Use `limit` to assert that the `:limit` option was specified.
      #
      #     class Car < ActiveRecord::Base
      #       accepts_nested_attributes_for :windows, limit: 3
      #     end
      #
      #     # RSpec
      #     RSpec.describe Car, type: :model do
      #       it do
      #         should accept_nested_attributes_for(:windows).
      #           limit(3)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class CarTest < ActiveSupport::TestCase
      #       should accept_nested_attributes_for(:windows).
      #         limit(3)
      #     end
      #
      # ##### update_only
      #
      # Use `update_only` to assert that the `:update_only` option was
      # specified.
      #
      #     class Car < ActiveRecord::Base
      #       accepts_nested_attributes_for :engine, update_only: true
      #     end
      #
      #     # RSpec
      #     RSpec.describe Car, type: :model do
      #       it do
      #         should accept_nested_attributes_for(:engine).
      #           update_only(true)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class CarTest < ActiveSupport::TestCase
      #       should accept_nested_attributes_for(:engine).
      #         update_only(true)
      #     end
      #
      # @return [AcceptNestedAttributesForMatcher]
      #
      def accept_nested_attributes_for(name)
        AcceptNestedAttributesForMatcher.new(name)
      end

      # @private
      class AcceptNestedAttributesForMatcher
        def initialize(name)
          @name = name
          @options = {}
        end

        def allow_destroy(allow_destroy)
          @options[:allow_destroy] = allow_destroy
          self
        end

        def reject_if(reject_if)
          @options[:reject_if] = reject_if
          self
        end

        def limit(limit)
          @options[:limit] = limit
          self
        end

        def update_only(update_only)
          @options[:update_only] = update_only
          self
        end

        def matches?(subject)
          @subject = subject
          exists? &&
            allow_destroy_correct? &&
            reject_if_correct? &&
            limit_correct? &&
            update_only_correct?
        end

        def failure_message
          "Expected #{expectation} (#{@problem})"
        end

        def failure_message_when_negated
          "Did not expect #{expectation}"
        end

        def description
          description = "accepts_nested_attributes_for :#{@name}"
          if @options.key?(:allow_destroy)
            description += " allow_destroy => #{@options[:allow_destroy]}"
          end
          if @options.key?(:reject_if)
            description += " reject_if => #{@options[:reject_if]}"
          end
          if @options.key?(:limit)
            description += " limit => #{@options[:limit]}"
          end
          if @options.key?(:update_only)
            description += " update_only => #{@options[:update_only]}"
          end
          description
        end

        protected

        def exists?
          if config
            true
          else
            @problem = 'is not declared'
            false
          end
        end

        def allow_destroy_correct?
          failure_message = "#{should_or_should_not(@options[:allow_destroy])} allow destroy"
          verify_option_is_correct(:allow_destroy, failure_message)
        end

        def reject_if_correct?
          if @options.key?(:reject_if)
            @problem = nil
            problem_prefix =
              "reject_if should resolve to #{@options[:reject_if].inspect}"
            actual_option_value = config[:reject_if]

            case actual_option_value
            when Symbol
              if @subject.respond_to?(actual_option_value, true)
                resolved_option_value = @subject.send(actual_option_value)
              else
                @problem =
                  "#{problem_prefix}, but #{actual_option_value.inspect} " +
                  "does not exist on #{model_class.name}"
              end
            when Proc
              resolved_option_value = actual_option_value.call(@subject)
            else
              resolved_option_value = actual_option_value
            end

            if @problem
              false
            elsif @options[:reject_if] == resolved_option_value
              true
            else
              @problem =
                "#{problem_prefix}, got #{resolved_option_value.inspect}"
              false
            end
          else
            true
          end
        end

        def limit_correct?
          failure_message = "limit should be #{@options[:limit]}, got #{config[:limit]}"
          verify_option_is_correct(:limit, failure_message)
        end

        def update_only_correct?
          failure_message = "#{should_or_should_not(@options[:update_only])} be update only"
          verify_option_is_correct(:update_only, failure_message)
        end

        def verify_option_is_correct(option_name, failure_message)
          if @options.key?(option_name)
            if @options[option_name] == resolved_option_for(option_name)
              true
            else
              @problem = failure_message
              false
            end
          else
            true
          end
        end

        def resolved_option_for(option_name)
          option_value = config[option_name]

          case option_value
          when Symbol
            @subject.public_send(option_value)
          when Proc
            option_value.call(@subject)
          else
            option_value
          end
        end

        def config
          model_config[@name]
        end

        def model_config
          model_class.nested_attributes_options
        end

        def model_class
          @subject.class
        end

        def expectation
          "#{model_class.name} to accept nested attributes for #{@name}"
        end

        def should_or_should_not(value)
          if value
            'should'
          else
            'should not'
          end
        end
      end
    end
  end
end
