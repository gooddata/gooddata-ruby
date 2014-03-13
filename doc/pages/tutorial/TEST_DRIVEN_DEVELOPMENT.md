# @title Test Driven Development

Test driven development is a holy grail for many developers. It gives you an additional sense of security and you can rely on the test suite to give you a safety net when you are refactoring and tweaking existing code. Testing reports was hard until now.

## The model
Let's reuse the model that we have from model. Create a file called model.rb and put this inside.

    GoodData::Model::ProjectBuilder.create("gooddata-ruby test #{Time.now.to_i}") do |p|
      p.add_date_dimension("closed_date")

      p.add_dataset("users") do |d|
        d.add_anchor("id")
        d.add_label("name", :reference => 'id')
      end

      p.add_dataset("regions") do |d|
        d.add_anchor("id")
        d.add_attribute("name")
      end

      p.add_dataset("opportunities") do |d|
        d.add_fact("amount")
        d.add_date("closed_date", :dataset => "closed_date")
        d.add_reference("user_id", :dataset => 'users', :reference => 'id')
        d.add_reference("region_id", :dataset => 'regions', :reference => 'id')
      end

      p.add_metric({
        "title": "Sum Amount",
        "expression": "SELECT SUM(#\"amount\") + 1",
        "extended_notation": true
      })

      p.upload([["id", "name"],
                ["1", "Tomas"],
                ["2", "Petr"]], :dataset => 'users')

      p.upload([["id", "name"],
                ["1", "Tomas"],
                ["2", "Petr"]], :dataset => 'regions')
    end

## The test
Let's say that you have some not so simple metric and you want to test it so you make sure it works as expected. The easiest way to do it is create a testing project and prepare some made up data and then spin it. You already know how to create a model and load data let's talk about how to define test cases.

The trick is to use assert_report helper. This means that the report will be executed and if the result will be different it will fail. The helper takes 2 parameters. First is a report definition second is the result expected. Currently it stops on the first failure but this will change soon and we will run all the tests and collect the results.

    p.assert_report({:top => [{:type => :metric, :title => "Sum Amount"}]}, [["3"]])


Go ahead and test it out

    gooddata --username joe@example.com --password my_secret_pass --token my_token  project build model.rb


## Production

The way we have it set up right now nothing forces us to use the same metrics to build the report. This is a problem. Ideally we wanna make sure that the same report in test project is then used in production and if somebody changes the project because the business requirements changes we want the same report to be used in the test and if something fails we want to know.

This is easiest to achieve by extracting the metrics and the model to separate file that can later be used when describing the project. You can then reference the same file form your production and testing project and make sure they are build using the same source.

The description might look something like this

    GoodData::Model::ProjectBuilder.create("gooddata-ruby test #{Time.now.to_i}") do |p|
      p.add_date_dimension("closed_date")

      p.add_dataset("users") do |d|
        d.add_anchor("id")
        d.add_label("name", :reference => 'id')
      end

      p.add_dataset("regions") do |d|
        d.add_anchor("id")
        d.add_attribute("name")
      end

      p.add_dataset("opportunities") do |d|
        d.add_fact("amount")
        d.add_date("closed_date", :dataset => "closed_date")
        d.add_reference("user_id", :dataset => 'users', :reference => 'id')
        d.add_reference("region_id", :dataset => 'regions', :reference => 'id')
      end

      p.load_metrics('https://bit.ly/gd_demo_1_metrics')

      p.upload([["id", "name"],
                ["1", "Tomas"],
                ["2", "Petr"]], :dataset => 'users')

      p.upload([["id", "name"],
                ["1", "Tomas"],
                ["2", "Petr"]], :dataset => 'regions')

      p.upload([["amount", "closed_date", "user_id", "region_id"],
                ["1", "2001/01/01", "1", "1"],
                ["1", "2001/01/01", "1", "2"]], :dataset => 'opportunities')

      p.assert_report({:top => [{:type => :metric, :title => "Sum Amount"}]}, [["3"]])

    end

Here we are externalizing only the metrics but you can hopefully see that it might make sense to do it for the model as well.

# Rinse repeat
If you have any experience with TDD you know that your tests have to run daily to have any effect. This is TBD :-)

<div class="section-nav">
  <div class="left align-right">
      <a href="/docs/file/doc/pages/tutorial/CRUNCHING_NUMBERS.md" class="prev">
        Back
      </a>
  </div>
  <div class="right align-left">
      <a href="/docs/file/doc/pages/tutorial/BRICKS.md" class="next">
        Next
      </a>
  </div>
  <div class="clear"></div>
</div>

