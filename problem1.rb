#just added this to be able to run the rspec tests

#This method returns a string version of the collection of values passed in (and originally had an extra comma after the last item)
def something_unusual(values)
  values.to_s
end

describe "something_unusual" do
  context "when values is empty" do
    it "returns []" do
      something_unusual([]).should eq("[]")
    end
  end

  context "when values has a single element" do
    it "returns [el] (no commas)" do
      something_unusual([1]).should eq("[1]")
    end
  end

  context "when values has a multiple elements" do
    it "returns [el1, el2]" do
      something_unusual([1, 2]).should eq("[1, 2]")
    end
  end
end