RSpec.describe "Instrument" do
  let(:asset) { {
    uri: "file:///foo.js",
    data: "function foo() { return 1; }",
  } }
  let(:processor) { Sprockets::Js::Coverage::Processor }


  it "instruments" do
    covered_source = processor.call(asset)
    expect(covered_source).to start_with('function cov_')
  end

  it "uses window as global object" do
    covered_source = processor.call(asset)
    expect(covered_source).to include(';var global=window;')
  end

  it "uses __coverage__ as global coverage object" do
    covered_source = processor.call(asset)
    expect(covered_source).to include(';var gcv="__coverage__";')
  end

  it "has proper path" do
    covered_source = processor.call(asset)
    expect(covered_source).to include('{var path="/foo.js";')
  end

  it "works with imports" do
    source = "import { foo } from './bar';\nfunction baz() { return foo(); }"
    covered_source = processor.call(asset)
    expect(covered_source).to start_with('function cov_')
  end

  it "outputs error message" do
    data = "function foo() { return 1"
    expect {
      covered_source = processor.call(asset.merge(data: data))
      expect(covered_source).to eq(data)
    }.to output("Error instrumenting /foo.js: SyntaxError: /foo.js: Unexpected token (1:25)\n").to_stderr
  end

  it "skips unwanted files" do
    Sprockets::Js::Coverage::Processor.configure do |config|
      config.should_process = ->(path) {
        return false if path.match?(/vendor\/assets\//)
        return true
      }
    end

    data = double(path: "vendor/assets/foo.js")
    covered_source = processor.call(asset.merge(data: data))
    expect(covered_source).to eq(data)

    Sprockets::Js::Coverage::Processor.configure do |config|
      config.should_process = nil
    end
  end
end
