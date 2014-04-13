require "spec_helper"

describe Scrawl do
  let(:input) { { a: 1 } }
  let(:trees) { [input] }
  let(:scrawl) { described_class.new(*trees) }
  let(:internal_tree) { scrawl.instance_variable_get(:@tree) }

  describe ".new" do
    context "with single" do
      shared_examples "setup single" do
        it "sets internal tree to that hash" do
          expect(internal_tree).to eq(input)
        end
      end

      context "hash object" do
        include_examples "setup single"
      end

      context "scrawl object" do
        let(:tree) { Scrawl.new(*trees) }

        include_examples "setup single"
      end
    end

    context "with multiple" do
      let(:merged_input) { { a: 1, b: 2 } }

      shared_examples "setup all" do
        it "merges all arguments into a single tree" do
          expect(internal_tree).to eq(merged_input)
        end
      end

      context "hashes objects" do
        let(:trees) { [{ a: 1 }, { b: 2 }] }
      end

      context "scrawl objects" do
        let(:trees) { [Scrawl.new(a: 1), Scrawl.new(b: 2)] }
      end

      context "hash and scrawl objects" do

      end
    end
  end

  describe "#merge" do
    let(:merge) { scrawl.merge(compared) }

    shared_examples "merges" do
      it "combines with the internal tree" do
        expect(merge).to eq(a: 1, b: 2)
      end
    end

    context "with hash" do
      let(:compared) { { b: 2 } }

      include_examples "merges"
    end

    context "with scrawl object" do
      let(:compared) { Scrawl.new(b: 2) }

      include_examples "merges"
    end
  end

  describe "#inspect" do
    let(:stream) { "a=1" }
    let(:namespace) { nil }
    let(:inspect) { scrawl.inspect(namespace) }

    context "with a single pair" do
      it "joins the key value together with an ="  do
        expect(inspect).to eq(stream)
      end

      context "and text value" do
        let(:input) { { a: "example" } }

        it "escapes the value" do
          expect(inspect).to include("\"example\"")
        end
      end

      context "and a proc value" do
        let(:input) { { a: -> { "example#{rand(1..10_000)}" } } }

        it "evaluate the proc" do
          expect(inspect).to include("example")
        end

        it "never stores the value" do
          first = scrawl.inspect
          second = scrawl.inspect
          expect(first).to_not eq(second)
        end
      end

      context "and a number value" do
        it "returns just the number" do
          expect(inspect).to include("=1")
        end
      end

      context "and a symbol value" do
        let(:input) { { a: :example } }
        it "returns the escaped string equivelent" do
          expect(inspect).to include("\"example\"")
        end
      end
    end

    context "with multiple pairs" do
      let(:input) { { a: 1, b: 2 } }
      let(:stream) { "a=1 b=2" }

      it "delimits key value pairs with space" do
        expect(inspect).to eq(stream)
      end
    end

    context "with a given namespace" do
      let(:namespace) { "b" }
      let(:stream) { "b.a=1" }

      it "prefixes the namespace to the key" do
        expect(inspect).to eq(stream)
      end
    end

    context "with nested hash tree" do
      let(:input) { { a: { b: 1, c: 2 } } }
      let(:stream) { "a.b=1 a.c=2" }

      it "namespaces the nested pairs" do
        expect(inspect).to eq(stream)
      end
    end
  end

  describe "#tree"do
    let(:tree) { scrawl.tree }

    it "returns the internal tree" do
      expect(tree).to eq(internal_tree)
    end
  end

  describe "#to_h" do
    let(:to_h) { scrawl.to_h }

    it "returns the internal tree" do
      expect(to_h).to eq(internal_tree)
    end
  end

  describe "#to_hash"do
    let(:to_hash) { scrawl.to_hash }

    it "returns the internal tree" do
      expect(to_hash).to eq(internal_tree)
    end
  end

  describe "#=="
end
