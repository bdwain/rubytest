# Instructions for this test:
# 1. Please clone this gist as a git repo locally
# 2. Create your own github repo called 'rubytest' (or a name of your choice) and add this repo as a new remote to the cloned repo
# 3. Edit this file to answer the questions, and push this file with answers back out to your own 'rubytest' repo.

# Problem 1. Explain briefly what this code does. Create a RSpec unit test for
# it, fix any bugs, then clean up the syntax to be more idiomatic Ruby and make
# sure your tests still pass.
#
# Your spec should have at least 3 contexts/conditional tests (what are they?)


#This method returns a string version of the collection of values passed in (and originally had an extra comma after the last item)
#no reason to manually make the string as arrays can use to_s
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

# Problem 2. This is a piece of code found in a fictional Rails controller and model
# for simulating problems while driving a car.
#
# Point out any bugs or security problems in the code, fix them, and refactor the code to
# make it cleaner.
#
# Hint: this controller is way too intimate with the functionality of the car. What happens
# when we want to reuse the logic for simulating a wheel breakage somewhere else?

#the functionality for breaking wheels belongs in the car model, not the controller
#if rand returns 1.0, it would try to break @wheels[4], which should not exist
#the sql query was vulnerable to a SQL injection attack before
#also, where does not return a Car. it returns an array of cars. You need to add .first to the result to get the actual car

class CarSimulationController
 def break_random_wheel
   @car = Car.where("name = ? AND user = ?", params[:name], params[:user_id]).first
   @car.break_random_wheel
 end
end

class Car < ActiveRecord::Base
 has_many :components

 def break_random_wheel
  wheels = components.find(:all, :conditions => "type = 'wheel'")
  wheels.sample.break!
  functioning_wheels -= 1
 end

 #it seems error prone to store functioning_wheels as a value. it should look at the count of non-broken wheels, like this
 #although if searching through all components was too time consuming, this could be problematic as well
 def better_functioning_wheels
  wheels = components.find(:all, :conditions => "type = 'wheel'")
  wheels.select { |wheel| !wheel.broken? }.length
 end
end

class User < ActiveRecord::Base
end

# Problem 3. You are running a Rails application with 2 workers (two unicorn processes, two passenger workers, etc).
# You have code that looks like this

class CarsController
 def start_engine
  #@car = Car.first # bonus: there is a bug here. what is it?
  @car = Car.find(params[:id]) #this makes more sense
  @car.start_engine
 end
end

class Car
 def start_engine
  api_url = "http://my.cars.com/start_engine?id={self.id}" #a # is missing before the {
  RestClient.post api_url
 end
end

# 3a. Explain what possible problems could arise when a user hits this code.
#assuming the missing # is a typo and it actually has the right car id in the url, 2 people could try to start the engine of a car at the same time
#and we might want to prevent multiple attempts at doing so

# 3b. Imagine now that we have changed the implementation:

class CarsController
 def start_engine
  sleep(30)
 end
 def drive_away
  sleep(10)
 end
 def status
  sleep(5)
  render :text => "All good!"
 end
end

# Continued...Now you are running your 2-worker app server in production.
#
# Let's say 5 users (call them x,y,z1,z2,z3), hit the following actions in
# order, one right after the other.
#
# x: goes to start_engine
# y: goes to drive_away
# z1: goes to status
# z2: goes to status
# z3: goes to status
#
# Explain approximately how long it will take for each user to get a response back from the server.
#
# Example: user 'x' will take about 30 seconds. What about y,z1,z2,z3?

#user x will take 30 seconds to get a response
#user y will take 10 seconds to get a response
#user z1 will take 15 seconds (y's worker will be freed after 10)
#user z2 will take 20 seconds (z1's worker will be freed after 15)
#user z3 will take 25 seconds (z2's worker will be freed after 20)


# Approximately how many requests/second can your cluster process for the
# action 'start_engine'? What about 'drive_away'?  What could you do to
# increase the throughput (requests/second)?

# start_engine can handle 1 request every 15 seconds. drive_away can handle 1 request every 5 seconds
#to increase throughput, besides the obvious make the requests take less time, you could add always more workers
#another option is to make the servers multithreaded #with config.threadsafe!, and then allow those actions in the controller to be done in background threads


# Problem 4. Here's a piece of code to feed my pets. Please clean it up as you see fit.

class Pet
  def feed(food)
    if(food == get_food_type)
      puts "thanks!"
    else
      puts "gross!"
    end
  end

  def get_food_type
    raise NotImplementedError.new("You must implement get_food_type")
  end
end

class Cat < Pet
  def get_food_type
    :milk
  end
end

class Dog < Pet
  def get_food_type
    :dogfood
  end
end

class Cow < Pet
  def get_food_type
    :grass
  end
end

my_pets = [Cat.new, Dog.new, Cow.new]

my_pets.each do |pet|
  pet.feed(pet.get_food_type)
end

# Problem 5. Explain in a few sentences the difference between a ruby Class and
# Module and when it's appropriate to use either one.

#a class defines a type of object that you can instantiate and use in your program. classes can also inherit from other classes.
#modules define sets of functionality that can be included in a class (or another module). you can't instantiate a module, or inherit modules
#classes should be used when you want an object that can have actions taken on it and be passed around. Modules should be used when you want to define
#a common set of functionality that can be mixed in to multiple classes

# Problem 6. Explain the problem with this code
#it selects every user into memory and filters in rails instead of letting the database do the filtering (with a where clause)
#the request will probably be slower than necessary if there are a lot of inactive users
#also, assuming the plan is to pass this to a view, it doesn't allow access to the list of active users by placing it in an instance variable (@active_users = blahblah)
class UsersController
 def find_active_users
  #User.find(:all).select {|user| user.active?}
  @active_users = User.where("active = true") #better
 end
end

# Problem 7. Here's a piece of code that does several actions. You can see that it has duplicated
# error handling, logging, and timeout handling. Design a block helper method that will remove
# the duplication, and refactor the code to use the block helper.

def helper(logger, startString, timeout)
  logger.info startString
  Timeout::timeout(timeout) do
    begin
      yield
    rescue => e
      logger.error "Got error: #{e.message}"
    end
  end
end

helper(logger, "About to do action1", 5) {action1}
helper(logger, "About to do action2", 10) {action2}
helper(logger, "About to do action3", 7) {action3}
