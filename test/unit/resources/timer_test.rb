require File.join(File.dirname(__FILE__), "..", "..", "test_helper")

class TimerTest < Test::Unit::TestCase

  def setup_resources
    attrs = {
      :id => 1,
      :hours => 5,
      :client => 'Iridesco',
      :project => 'Harvest',
      :task => 'Backend Programming',
      :notes => 'Test api support'
    }
    @timer_xml    =  {:day_entry => attrs}.to_xml(:root => "timer")
    @task         =  {:id => 1, :name => "Backend Programming"}.to_xml(:root => "task")
    @tasks        = [{:id => 1, :name => "Backend Programming"}].to_xml(:root => "tasks") 
    @project_xml  =  {:id => 1, :name => "Harvest"}.to_xml(:root => "project")
    @projects     = [{:id => 1, :name => "Harvest"}].to_xml(:root => "projects")
  end

  def mock_responses
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get    "/daily/show/1",        {}, @timer_xml,   200
      mock.post   "/daily/add",           {}, @timer_xml,   201, "Location" => "/daily/show/2"
      mock.post   "/daily/update/1",      {}, nil,          200
      mock.delete "/daily/delete/1",      {}, nil,          200

      mock.get    "/projects.xml",        {}, @projects
      mock.get    "/projects/1.xml",      {}, @project_xml

      mock.get    "/tasks.xml",           {}, @tasks
      mock.get    "/tasks/1.xml",         {}, @task
    end
  end

  context "Timer CRUD actions -- " do
    setup do
      setup_resources
      mock_responses
    end

#    should "get index" do
#      Harvest::Resources::Daily.find(:all)
#      expected_request = ActiveResource::Request.new(:get, "/daily/#{@day}/#{@year}")
#      assert ActiveResource::HttpMock.requests.include?(expected_request)
#    end

    should "get a single timer" do
      Harvest::Resources::Timer.find(1)
      expected_request = ActiveResource::Request.new(:get, "/daily/show/1")
      assert ActiveResource::HttpMock.requests.include?(expected_request)
    end

    should "create a new timer" do
      timer = Harvest::Resources::Timer.new(:hours => 5)
      timer.save
      expected_request = ActiveResource::Request.new(:post, "/daily/add")
      assert ActiveResource::HttpMock.requests.include?(expected_request)
    end

    should "update an existing timer" do
      timer = Harvest::Resources::Timer.find(1)
      timer.hours = 10
      timer.save
      expected_request = ActiveResource::Request.new(:post, "/daily/update/1")
      assert ActiveResource::HttpMock.requests.include?(expected_request)
    end

    should "delete an existing timer" do
      Harvest::Resources::Timer.delete(1)
      expected_request = ActiveResource::Request.new(:delete, "/daily/delete/1")
      assert ActiveResource::HttpMock.requests.include?(expected_request)
    end

    should "delete an existing timer using an instance" do
      timer = Harvest::Resources::Timer.find(1)
      timer.destroy
      expected_request = ActiveResource::Request.new(:delete, "/daily/delete/1")
      assert ActiveResource::HttpMock.requests.include?(expected_request)
    end

    should "load attributes from the day_entry element" do
      timer = Harvest::Resources::Timer.find(1)
      assert !timer.id.nil?
    end

    should "output XML per Harvest's spec" do
      timer = Harvest::Resources::Timer.find(1)
      xml = <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <request>
          <notes>Test api support</notes>
          <hours>5</hours>
          <project_id type="integer">1</project_id>
          <task_id type="integer">1</task_id>
          <spent_at type="date">#{Date.today.strftime("%a, %e %b %Y")}</spent_at>
        </request>
      XML
      expected = Hash.from_xml(xml)
      real = Hash.from_xml(timer.encode)
      assert_equal expected, real
    end
  end

  context "Projects" do
    setup do
      setup_resources
      mock_responses
    end

    should "provide access to the project when set with an id" do
      timer = Harvest::Resources::Timer.new(:project => 1)
      assert timer.project.is_a?(Harvest::Resources::Project)
      assert_equal 1, timer.project.id
      assert_equal 'Harvest', timer.project.name
    end

    should "provide access to the project when set with a string" do
      timer = Harvest::Resources::Timer.new(:project => "Harvest")
      assert timer.project.is_a?(Harvest::Resources::Project)
      assert_equal 1, timer.project.id
      assert_equal 'Harvest', timer.project.name
    end
  end

  context "Tasks" do
    setup do
      setup_resources
      mock_responses
    end

    should "provide access to the task when set with an id" do
      timer = Harvest::Resources::Timer.new(:task => 1)
      assert timer.task.is_a?(Harvest::Resources::Task)
      assert_equal 1, timer.task.id
      assert_equal 'Backend Programming', timer.task.name
    end

    should "provide access to the task when set with a string" do
      timer = Harvest::Resources::Timer.new(:task => "Backend Programming")
      assert timer.task.is_a?(Harvest::Resources::Task)
      assert_equal 1, timer.task.id
      assert_equal 'Backend Programming', timer.task.name
    end
  end
end
