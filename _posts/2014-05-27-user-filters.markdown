---
layout: post
title:  "Creating User Filters"
date:   2014-05-27 12:30:00
categories: recipe
pygments: true
perex: Here we will build project end-to-end with the SDK ultimately applying Mandatory User Filters and Variable filters to the project.
---

# Part I - Project, Model, and Uploading
## Overview
This tutorial walks you through the entire process, step-by-step, from creating a project and model to defining and assigning both Variable User Filters and Mandatory User Filters. 

## Requirements

###Demo Project
To follow along with this guide, we suggest you clone this demo project from the git repository https://github.com/thnkr/gooddata-brick-filters-project or you can download a zip file directly here.

###GoodData Ruby SDK
You will need to Ruby 1.9.3 or greater. If you are using Mac OS 10.4+ this is already included. Running the command “gem install gooddata” will bring in the latest version of the SDK.

###GoodData Developer Token
Each project can only be created with a developers token. Get a free token as part of the  Developer Program.

###Demo Project
Go ahead and open of file. You will see three directories data, model, and zip. The data directory contains the data files for any project, the model directory has a ruby script in it which defines how the model of the project should look. In addition, you will notice a Goodfile document in the home directory. This file contains meta information useful for running your brick but we won’t edit it yet. The zip directory simply contains a duplicate zip of the demo project and is simply for those who want to access the project without github.
Optional: You can also scaffold your own project any time by running this in command line:
 gooddata scaffold project my_project_name
The scaffolding will include, basic structure, example data (easily removed), and the Goodfile. 
Building A Project
Designing The Model 
The core part of any project is it’s data model. Included in the demo project is a small model example (model/model.rb). There are three key components you need to know about modeling things in Ruby: 

*_add_anchor_*: An anchor is similar to an attribute except that, as you can see in the project you use this to connect datasets to each-other within the model. This is similar to assigning a connection point in Cloud Connect. 

*_add_attribute_*: Defines a traditional GoodData attribute.

*_add_fact_*: Defines a traditional GoodData attribute.

*_add_label_*: This method takes a hash which includes the reference attribute that the label refers too. 

*_add_reference_*: This works in tandem with add anchor and allows you to reference another dataset to define where it’s values are associated.

If any of this is unclear make sure you review the example contained within model/model.rb of your project and compare that with the data included in the data direct.  
Uploading The Project
Next we will make sure your project and the relevant data gets created and placed in your GoodData account. For this, you will need your login information as well as a developer token which you can get for 60 days for free from our Developer Program.

From within the demo project directory run {{gooddata -U username -P password -t token project build}}, replacing the username, password, and token with your own. Once that process has finished open your web browser and go to (https://secure.gooddata.com) to make sure your project was successfully uploaded.

Uploading Data
After you have set up the model and successful uploaded the project it’s time to use a very helpful tool within the GoodData SDK called “jack_in” which is based on the Ruby gem “pry”. What jack_in allows you to do is build a programmatic interface without building a complete script. It’s extremely helpful for doing quick and modular tasks like uploading data to your project. 

To jack into your project, you will need your login information and your project id. 

    gooddata -U username -P password -p project_id project jack_in

After you have “jacked in” we need to run a command to pair the data set for the file you want to upload. In our case that file can be found at “data/employees.csv”. The employees CSV correlates with the employees dataset we set up in our model.rb file. 

Associate these documents and then upload the file using these commands. 

    employees = find_dataset(‘employees’)
    employees.upload(‘data/employees.csv’)

If an error is thrown and it’s unclear turn on advanced debugging by entering: 

    GoodData::logging_on

Now double check that your data has been uploaded by visting the project on https://secure.gooddata.com and then choosing “Manage”. The Datasets link on the left side navigation should already be selected and from here you can click on the Employees data set and make the upload.zip file exists.

Congratulations! You are done with Part 1. In Part 2, we will learn how assign Variable User Filters and Mandatory User Filters.

# Part II - Variable User Filters & Mandatory User Filters
## Introduction to Filters
This tutorial defines among many, the two most common ways to assign filters. Filters allow you to assign rules on what content a user has access to within your project and are very helpful at helping a user to see content only relevant to them.

Before setting up Mandatory User Filters or Variable User Filters you need to set the user privaleges.

In terms of the demo project, each employee should only be able can only the sales specific to their department. If we open up the file *_data/employees.csv_*, you will notice the department column. This as you may recall is the the attribute we would like to filter.

#### employees.csv
	user_id,name,department
	1,paul,engineering
	2,kara,engineering
	3,caitlin,marketing
	4,patrick,engineering
	5,bob,sales
	6,amanda,sales

Using the email of the user we assign the department they can view based on their username. This is simply outlined in CSV, in this case we are assuming the username is the email but you are welcome to use an unique attribute describing the user.

#### privileges_example.csv
    username,department
    paul@company.com,engineering
    kara@company.com,engineering
    caitlin@company.com,marketing
    patrick@company.com,engineering
    bob@company.com,sales
    amanda@company.com,sales

 In the above example privileges are imported in rows, but in many cases there will are multiple attributes you are filtering for a given user. In these cases you can import the privileges in *_column_* format as well.

####privileges_example_columns.csv
    paul@states.com,california,arizona,oregon
    kara@states.com,colorado,nevada
    caitlin@states.com,kansas,oklahoma,ohio
    patrick@states.com,michigan,maine
    bob@states.com,maine,
    amanda@states.com,florida

In the *_column_* format the user email is first, followed by the regions they are permitted to see. Either format (row or column based) can be used, the SDK will automatically determine the format during import.

## Variable User Filters
### Requirements
Before using the brick you will need to choose the attributes you would like to add variable filters to, then based on those create the variable filters using the project’s web interface at https://secure.gooddata.com. 

1. Go to your project’s interface at https://secure.gooddata.com and click on *_Manage_*.
2. Select *_Variables_* from the left hand side navigation bar.
3. Fill out the variable information, naming the variable and be certain to check the *_Variable Filter_* instead of the default *_Numerical Filter_* option. 

Remember the name of the filter you assign as we will use it to look up the URI in later steps. 

### Getting Started
Assigning Variable Filters with the Filters Brick is very easy. There are two requirements before we look at the example code.

1. URI of the Variable Filter
Extracting the URI of the Variable Filter is an easy process. Simply “jack_in” to your project with this command:
    gooddata -U username -P password -p project_id project jack_in 

Then...

    GoodData::Variable.all

...be sure to select the URI or “link” of the Variable you assigned. 

2. A CSV file containing the the login (generally email) of the user you are filtering, label URI of the attribute being filtered and the value of the attribute you are filtering on.

The key to importing, the correct item from the default data is the use of cameras. I would even spend time making sure the sounds line up to the correct device and to ignore them if they are not adding to the complexity of the text.

### Executing
Now that you have everything set up, let’s take a look at some code samples to create your filters programmatically with the SDK.

    def variable_example
      GoodData.logging_on

      var = VARIABLE_URI
      # csv = IO.read(‘data/employees.csv’)
      csv = "login,department\paul@company.com,sales\n"

      filters = GoodData::UserFilterBuilder::get_filters(csv, {
        :type => :filter,
        :labels => [
           {:label => {:uri => "ATTRIBUTE_LABEL_URI"}, :column => 'COLUMN'}
        ]
      })
      GoodData::UserFilterBuilder.execute_variables(filters, var)
    end

Let’s break this script down, the first thing to notice is we have commented out the *_employees.csv_* file and replaced it with one line. The next thing is the variable URI from requirement one above is listed as **var**.

Finally, let’s take is **:uri** is defined as the label uri of the attribute we are filtering. In order to insure the data remains organized in a human readable form each of your attributes have a label they are associated with.

For a filter to be applied, we add it specifically to the attribute’s label, not the uri of the attribute. Extracting the label URI is no problem using the “jack_in” SDK feature.

    gooddata -U username -P password -p product_id project jack_in

Then, go ahead and list the number of attributes with this command.

    GoodData::Attribute.all

From the list of attributes select the one you are interested filters and get the attribute identifier (in our case it’s *_attr.employees.department_*).

    GoodData::Attribute['attr.employees.department'].labels[0]

Next select the value in the uri field which is the label uri from above. Generally it is the first label, but if this is not the label you are interested in, you can browse all of the labels by just removing the “[0]”.

	GoodData::Attribute['attr.employees.department'].labels

### Summary
- Created a Variable filter in the GoodData dashboard. 
- Located the URI of the Variable, and referenced directly above in the script.
    var = GoodData::Variable.all[0]
- Imported the privileges CSV from the beginning of the tutorial which defined what each username (employee) was able to see. 
- Defined the column and attribute URI in the final step of the script before ultimately executing the filters. 

## Mandatory User Filters
### Getting started
Creating Mandatory User Filters is done without the web interface (cool!). Unlike Variable Filters, you do not need to create the filter first.

1. URI of the Attribute
Extracting the URI of the Variable Filter is an easy process. Simply “jack_in” to your project with this command:
    gooddata -U username -P password -p project_id project jack_in

Then, go ahead and list the number of attributes with this command.

    GoodData::Attribute.all

From the list of attributes select the one you are interested filters and get the attribute identifier (in our case it’s *_attr.employees.department_*).

    GoodData::Attribute['attr.employees.department'].labels[0]

Now select the value in the uri field which is the label uri from above. Generally it is the first label, but if this is not the label you are interested in, you can browse all of the labels by just removing the “[0]”.

	GoodData::Attribute['attr.employees.department'].labels

2. A CSV file containing the the login (generally email) of the user you are filtering, label URI of the attribute being filtered and the value of the attribute you are filtering on.

### Executing
Once you have the Attribute Label URI and the CSV file containing the user logins you are ready to start appliying filters. Based on the demo project, we have set up an example script to go through the process.

    def mandatory_example
      GoodData.logging_on

      # csv = IO.read(‘data/employees.csv’)
      csv = "login,department\paul@company.com,sales\n"

      filters = GoodData::UserFilterBuilder::get_filters(csv, {
        :type => :filter,
        :labels => [
           {:label => {:uri => "ATTRIBUTE_LABEL_URI"}, :column => 'COLUMN'}
        ]
      })

      GoodData::UserFilterBuilder.execute_mufs(filters, :dry_run => true)
    end

Let's break this script down. First notice that we have commented out the reader for the file in place of an example so you can see the format.

From above, replace ATTRIBUTE_LABEL_URI with the label URI you added in step one and that is it. 

To confirm a Mandatory User Filter was assigned, go to your web dashboard at https://secure.gooddata.com 


### Getting Started
1. The login (generally email) of the user you are filtering.
2. Label URI of the attribute.
3. The value of the attribute you are filtering on.
