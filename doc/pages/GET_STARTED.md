# @title Get Started

<div class="container-narrow">

<h1>Get Started</h1>

<p>
    You just installed the Ruby GEM and want to start playing around, right? Follow this guide to learn more about the
    basics and most common use cases.
</p>

<p>
    And what you will learn? You will learn how to:<br/><br/>
    <a class="topics" href="#login">Login to GoodData with gem</a><br/>
    <a class="topics" href="#direct">Direct Post Requests</a><br/>
    <a class="topics" href="#retrieve">Retrieving Objects</a><br/>
    <a class="topics" href="#metrics">Metrics (not only) Creation</a><br/>
    <a class="topics" href="#reports">Report Handling</a><br/>
    <a class="topics" href="#dashboards">Dashboard Operations</a><br/>
</p>

<h2>Install</h2>

<p>If you are using bundler. Add</p>
<pre>
gem "gooddata"
</pre>
<p>into Gemfile and run</p>
<pre>
bundle install
</pre>
<p>If you are using gems just</p>
<pre>
gem install gooddata --version0.6.0.pre9
</pre>

<a name="login"></a>

<h2>Logging in</h2>

<pre>
GoodData.connect( :login => 'svarovsky@gooddata.com',
                  :password => 'pass',
                  :server => "https://na1.secure.gooddata.com",
                  :webdav_server => "https://na1-di.gooddata.com",
                  :token => "asdasdas")
</pre>

<p>Picking project to work with. There are several ways how to do it.</p>

<pre>
GoodData.connect( :login => 'svarovsky@gooddata.com',
                  :password => 'pass',
                  :project => 'project_pid')

GoodData.project = 'project_pid'

GoodData.use = 'project_pid'
</pre>

<p>This will let you work with the project in a block. The project has the value you picked only inside the block
    afterwards it will reset the project value to whatever it was before.</p>

<pre>
GoodData.with_project('project_pid') do |project|
  puts project.uri
end
</pre>

<a name="direct"></a>

<h2>Directly accessing API</h2>

<p>This is the most crude method and while you can do anything with it is also most cumbersome. It is needed sometimes
    though so we are mentioneing it here. Gem will make sure that it does the plumbing like keeping you logged in etc
    and you can just use the HTTP methods you are used to</p>

<pre>
GoodData.get("uri")
GoodData.post("uri", {:name => "John Doe"})
GoodData.put("uri", {:name => "John Doe"})
GoodData.delete("uri")
</pre>

<p>Nothing surprising</p>

<a name="retrieve"></a>

<h2>Retrieving objects</h2>

<p>There are several wrappers for different types of objects. There are some common things you can do with them.</p>

<p>You can retrieve all objects of that type.</p>

<pre>
reports = GoodData::Report[:all]
</pre>

<p>You can retrieve specific one</p>

<pre>
report = GoodData::Report["/gdc/md/pid/12"]
report = GoodData::Report[12]
</pre>


<p>You can retrieve reports based on tags</p>

<pre>
reports = GoodData::Report.find_by_tag("some_tag")
</pre>

<p>You can retrieve an object based on a title</p>

<pre>
report = GoodData::Report.find_first_by_title('My first report')
</pre>

<p>You can set some basic things like summary and title</p>

<pre>
report.title = "New title"
report.summary = "This is some fancy description"
</pre>

<p>You can also save the object back to the server</p>

<pre>report.save</pre>

<p>And then you can delete it</p>

<pre>
report.delete
</pre>

<p>Since metadata about project is one big tree you can also ask which object are used by or using other objects. For
    example what reports are on a dashboard</p>

<pre>
report.get_used_by
report.get_using
</pre>

<p>What we just showed you can be done with all Metadata objects. These include Report, Dashboard, Metric, Attribute,
    Fact</p>

<a name="metrics"></a>

<h2>Metrics</h2>

<p>Probably the most useful and complex obect is a metric. For its definition we are using language called MAQL. There
    is one big drawback to current MAQL definition and that is how it reffers to another object. If you imagine a simple
    metric definition like 'sum of all amounts' it could be described like this "SELECT SUM(Amount)". The problem is
    that the proper maql definition is as follows

<pre>SELECT SUM([/gdc/md/project_id/obj/123])</pre>

</p>As you can see the reference to Amount fact is done via an URI. This has a big advantage of being unambiguous but it
has a bg drawback that t cannot be written buy hand and also it is not transferable between projects without some
translation.</p>

<p>Here we introduce eXtended MAQL which tries to mitigate some of the drawbacks. The implementation acurrently relies
    on titles of objects and might change. In XMAQL there are only 4 additions<br/>
    1) fact is referenced like #"Amount"<br/>
    2) attribute like @"User Name"<br/>
    3) metric like ?"My metric"<br/>
    4) attribute value like $"United States"<br/>
</p>

<p>The aforementioned metric could be then expressed like this 'SELECT SUM(#"Amount")'. This allows to be explicit in
    what type you are reffering to since MAQL is fairly complex and allows you to write them by hand. Also transfering
    metrics nbetween objects is more transpoarent.</p>

<p>You can create a metric</p>

<pre>
m = Metric.create(:title => "My metric", :expression => 'SELECT SUM(["/gdc/md/1231231/obj/12"])')
m.save
</pre>

<p>If you want to use eXtended notation use xcreate or pass :extended => true option to the create method</p>

<pre>
m = Metric.create(:title => "My metric", :expression => 'SELECT SUM(#"Amount")', :extended => true)
m = Metric.xcreate(:title => "My metric", :expression => 'SELECT SUM(#"Amount")')
</pre>

<p>You can directly execute it which will return a number</p>

<pre>
m.execute
</pre>

<p>Note on executing metrics. Since GoodData currently cannot execute metric which is not saved there is some behavior
    that might surprise you when executing unsaved metrics on the fly. If you execute a metric or use a metric in a
    report it takes all unsaved metrics and saves them. After execution it takes those that it had to save and deletes
    them so they are not visible and cluttering the system. If you are creating a metric to be really saved do save it
    immediately. This will hopefully change as we will allow execution of metrics that are inlined in execution
    description.</p>

<a name="reports"></a>

<h2>Reports</h2>

<p>You can execute report</p>

<pre>
report = report = GoodData::Report["/gdc/md/pid/12"]
result = report.execute
</pre>

<p>with result you can print it (needs more work, it roughly works but attribute reports only do not work)</p>

<pre>
result.print
</pre>

<p>You can export it to a file. This needs some work so it warns you if it does not make sense to export you report in
    given format I think that our platfrom does not support all combinations. Currently there is :pdf, :png and :csv
    supported</p>

<pre>
File.open('dash.pdf', 'w') do |f|
  f.write(report.export(:pdf))
end
</pre>

<p>You can also create a report on the fly.</p>

<pre>
metric = GoodData::Metric.xcreate(:title => "My Metric", :expression => 'SELECT SUM(#"amount")')
metric.save

report = GoodData::Report.create(:title => "My report",:left => 'user', :top => metric)
report.save
</pre>

<p>There are some rules that need explanation. The report is structured a little different than in UI. You specify left
    and top. It can either be an attribute or a metric. There can be multiple metrics but all of those need to be either
    in top or left section. The objects can be specified in several ways. You can provide Attribute but remember that
    eventually GoodData needs Label information (on API you can hit name display form). If you provide attribute it will
    resolve to its first Label. If an attribute has more than one it will take the first.</p>

<p>1) MD object. Metric, Attribute and Label
    2) hash. If you do not have the object handy you can pass a hash structure like this <pre>{:type => :attribute, :title => 'some title'}</pre>. It will perform the lookup for you. This currently works for :attribute and :metric. If you want to
    perform the lookup through identifier you can do it as well. Since id is unique <pre>{:identifier => 'some id'}</pre>
    3) String. If you put there a string it is assumed it is a name of an attribute so 'some title' is equivalent with
    typing <pre>{:type => :attribute, :title => 'some title'}</pre></p>

<p>TODO
    Describe filtering</p>

<a name="dashboards"></a>

<h2>Dashboards</h2>

<p>You can export whole dashboards</p>

<pre>
dash = GoodData::Dashboard[33807]
File.open('dash.pdf', 'w') do |f|
  f.write(dash.export(:pdf))
end
</pre>

<p>or just a specific tab</p>

<pre>
dash = GoodData::Dashboard[33807]
File.open('dash.pdf', 'w') do |f|
  f.write(dash.export(:pdf, :tab => dash.tabs_ids.last))
end
</pre>

<p>
    Project
    create a project
    clone a project
    rename a project
    delete a project
    TBD - add a user
    TBD - remove a user

    Domain (Organization)
    Add a user to a domain

    Project Datasets
    Create a model
    Load data
</p>

<div class="section-nav">
    <div class="left align-right">

        <span class="prev disabled">Back</span>

    </div>
    <div class="right align-left">

        <a href="/docs/file/doc/pages/TUTORIALS.md" class="next">
            Next
        </a>

    </div>
    <div class="clear"></div>
</div>

</div>

</div>