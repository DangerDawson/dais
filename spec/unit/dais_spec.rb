require 'spec_helper'
RSpec.describe Dais do
  let(:inputs) { [:one, two: 2] }
  let(:call_args) { {one: 1} }

  let(:klass_eval) do
    proc do |input_args, &block|
      Class.new do
        include Dais
        inputs(*input_args)
        def call
          one * two
        end
      end
    end
  end

  describe "get_deps" do
    let!(:klass) { klass_eval.call(inputs) }
    let(:get_deps) { klass.new(call_args).get_deps }
    it "returns no dependencies" do
      expected = { }
      expect(get_deps).to eq expected
    end

    context "with a dep" do
      let(:klass_eval) do
        proc do |input_args, dep_one, &block|
          Class.new do
            include Dais
            inputs(*input_args) do
              dep :dep_one, dep_one.call
            end
            def call
              dep_one.call(three: one)
            end
          end
        end
      end

      let(:dep_eval) do
        proc do |input_args|
          Class.new do
            include Dais
            inputs(*input_args)
            def call
              24 * three * four
            end
          end
        end
      end
      let(:inputs2) { [:three, four: 4] }
      let!(:dep) { dep_eval.call(inputs2) }

      let!(:klass) { klass_eval.call(inputs, dep_arg) }
      let(:dep_arg) { -> { dep } }

      it "returns a dependency" do
        expected = { dep_one: dep }
        expect(get_deps).to eq expected
      end

      context "with a dep that is passed in via the call" do
        let(:another_dep) { proc { |params| params[:three] * 100 } }
        before do
          dep_one_params = { dep_one: another_dep }
          call_args.merge!(dep_one_params)
        end
        it "calculates the correct amount" do
          expected = { dep_one: another_dep }
          expect(get_deps).to eq expected
        end
      end

      context "with a dep that is curried and passed in via the call" do
        let(:another_dep) { dep.curry.call(four: 100) }
        before do
          call_args.merge!(dep_one: another_dep)
        end
        it "calculates the correct amount" do
          expected = { dep_one: another_dep }
          expect(get_deps).to eq expected
        end
      end

      context "with a dep that is curried" do
        let(:another_dep) { dep.curry.call(four: 100) }
        let(:dep_arg) { -> { another_dep } }

        it "calculates the correct amount" do
          expected = { dep_one: another_dep }
          expect(get_deps).to eq expected
        end
      end

      context "with a dep that needs to be lazy loaded" do
        let(:another_dep) { proc { |params| params[:three] * 2 } }
        let(:dep_arg) { -> { another_dep } }

        it "calculates the correct amount" do
          expected = { dep_one: another_dep }
          expect(get_deps).to eq expected
        end
      end
    end
  end

  describe "call" do
    let!(:klass) { klass_eval.call(inputs) }
    subject { klass.call(call_args) }

    it "calculates the correct amount" do
      # 1 * 2 
      expect(subject).to eq  2
    end

    context "with a dep" do
      let(:klass_eval) do
        proc do |input_args, dep_one, &block|
          Class.new do
            include Dais
            inputs(*input_args) do
              dep :dep_one, dep_one.call
            end
            def call
              dep_one.call(three: one)
            end
          end
        end
      end

      let(:dep_eval) do
        proc do |input_args|
          Class.new do
            include Dais
            inputs(*input_args)
            def call
              24 * three * four
            end
          end
        end
      end
      let(:inputs2) { [:three, four: 4] }
      let!(:dep) { dep_eval.call(inputs2) }

      let!(:klass) { klass_eval.call(inputs, dep_arg) }
      let(:dep_arg) { -> { dep } }

      it "calculates the correct amount" do
        # 24 * 1 * 4
        expect(klass.call(call_args)).to eq  96
      end

      context "with a dep that is passed in via the call" do
        before do
          dep_one_params = { dep_one: proc { |params| params[:three] * 100  } }
          call_args.merge!(dep_one_params)
        end
        it "calculates the correct amount" do
          expect(klass.call(call_args)).to eq 100
        end
      end

      context "with a dep that is curried and passed in via the call" do
        before do
          call_args.merge!(dep_one: dep.curry.call(four: 100))
        end
        it "calculates the correct amount" do
          expect(klass.call(call_args)).to eq  2400
        end
      end

      context "with a dep that is curried" do
        let(:dep_arg) { -> { dep.curry.call(four: 100) } }

        it "calculates the correct amount" do
          # 24 * 1 * 100
          expect(klass.call(call_args)).to eq  2400
        end
      end

      context "with a dep that needs to be lazy loaded" do
        let(:dep_arg) { -> { proc { |params| params[:three] * 2 }  } }

        it "calculates the correct amount" do
          expect(klass.call(call_args)).to eq  2
        end
      end

      context "with a dep that takes a param from the inputs" do

        let(:klass_eval) do
          proc do |input_args, &block|
            Class.new do
              include Dais
              inputs(*input_args) do
                dep :dep_one, one
              end
              def call
                dep_one * 2
              end
            end
          end
        end
        let!(:klass) { klass_eval.call(inputs) }

        it "calculates the correct amount" do
          expect(klass.call(call_args)).to eq  2
        end
      end
    end

    context "with a dep that takes a param from another dep" do
      let(:klass_eval) do
        proc do |input_args, &block|
          Class.new do
            include Dais
            inputs(*input_args) do
              dep :dep_one, 2
              dep :dep_two, dep_one
            end
            def call
              dep_one * dep_two * 2
            end
          end
        end
      end
      let!(:klass) { klass_eval.call(inputs) }

      it "calculates the correct amount" do
        expect(klass.call(call_args)).to eq  8
      end
    end
  end

  context "dep called outside the block" do
    let(:klass_eval) do
      proc do |input_args|
        Class.new do
          include Dais
          inputs(*input_args)
          dep :dep_one, 1
        end
      end
    end

    it "calculates the correct amount" do
      expect { klass_eval.call(inputs) }.to raise_error(NoMethodError)
    end
  end
end
