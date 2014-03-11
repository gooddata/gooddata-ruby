There are several ways how to express a model and create it in GoodData. The most prominent way to do it is the visual modeler that is part of the CloudConnect package. There are clear advantages like being visual but there are also drawbacks. It is not repeatable, it is not programmable and it is not text based. Let's have a look how to create a simple model using Ruby SDK.

## The model
The model we will be creating is this

## The code
Create a file called model.rb and put this inside.

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
    end

Hopefully the model is self descriptive and if you are not strong on terminology like label, anchor etc please refer to "Building a model with GD".

## Some rules

Please note several things

  * we are trying to apply several conventions if you follow them it will be less typing for you but you can always override them.
  * in all the cases where you type a name it is a string that will be used to create a technical name in gooddata also called identifier on the API. The user visible name which we call title will be inferred if not provided. The inferring process is simple. We expect you to provide name in the snake case (as is typical in ruby, this means things like close_date, opportunity_dimension etc). These will be translated int human readable strings (Close date, Opportunity dimension). If you do not like the title you can specify it directly via :title => "My own title"`
  * the names are also used as reference names in the model. Notice how the date is using name of the close_date dimension and also the user_id reference is using reference users

## Executing the model

    gooddata --username joe@example.com --password my_secret_pass --token my_token  project build model.rb

## Loading data
As part of the process we allow you to load data since sometimes some initial datasets should be part of the model and not ETL. The typical usecase is for the sake of defining reports which are filtered on certain values these values have to be present.

### Loading data given inline

    p.upload([["id", "name"],
              ["1", "Tomas"],
              ["2", "Petr"]], :dataset => 'users')


### Loading data given by filename

    p.upload("/some/local_file.csv", :dataset => "users")

### Loading data given by web file

    p.upload("http://www.example.com/some/remote_file.csv", :dataset => "users")

In all cases the file has to have headers that has the same name as the name of the particular columns (not necessarily in the same order).

<div class="section-nav">
  <div class="left align-right">
      <a href="/docs/file/doc/pages/tutorial/YOUR_FIRST_PROJECT.md" class="prev">
        Back
      </a>
  </div>

  <div class="right align-left">

      <a href="/docs/file/doc/pages/tutorial/CRUNCHING_NUMBERS.md" class="next">
        Next
      </a>

  </div>
  <div class="clear"></div>
</div>