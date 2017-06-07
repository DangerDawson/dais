require 'dais/version'
module Dais
  def self.included(klass)
    define_inputs(klass)
  end

  def self.define_inputs(klass)
    klass.define_singleton_method(:inputs) do |*args|
      required = args.dup
      optional = required[-1].class == Hash ? required.pop : {}

      define_singleton_method(:incomplete?) do |params|
        !((params.keys & required).size == required.size)
      end

      currier = proc do |params, &currier_block|
        if incomplete?(params)
          raise 'blocks not supported unless all call arguments are complete' if currier_block
          proc do |params2, &currier_block2|
            currier.call(params.merge(params2), &currier_block2)
          end
        else
          if currier_block
            new(params).call(&currier_block)
          else
            new(params).call
          end
        end
      end

      define_singleton_method(:curry) do
        proc do |params, &xblock|
          params2 = optional.merge(params)
          currier.call(params2, &xblock)
        end
      end

      define_singleton_method(:call) do |params, &call_block|
        params = optional.merge(params)
        if call_block
          new(params).call(&call_block)
        else
          new(params).call
        end
      end

      dep_params = {}
      define_singleton_method(:dep) do |key, value|
        dep_params[key] = value
      end

      define_singleton_method(:get_deps) do
        dep_params
      end

    define_method(:expand) do |*construct_args|
        expand = construct_args.dup
        merge = expand[-1].class == Hash ? expand.pop : {}
        expand.inject({}) do |hash, arg|
          hash[arg] = send(arg)
          hash
        end.merge(merge)
      end

      define_method(:param) do |*param_args|
        key, value = param_args
        instance_variable_set("@#{key}", value)
        self.class.__send__(:attr_reader, key)
        self.class.__send__(:private, key)
      end

      define_method(:initialize) do |**initialize_args|
        combined = dep_params.merge(optional.merge(initialize_args))
        combined.each { |key, value| param(key, value) }

        missing = (required - initialize_args.keys).uniq
        if missing.any?
          message = "class: #{self.class}, missing keyword(s): #{missing.join(', ')}"
          raise(ArgumentError, message)
        end
      end
    end
  end
end
