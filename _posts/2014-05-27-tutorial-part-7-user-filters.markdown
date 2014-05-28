---
layout: tutorial
title:  "Part VII - Creating user filters"
date:   2014-01-19 13:56:30
categories: tutorial
pygments: true
prev_section: tutorial/tutorial-part-6-updating-column
perex: Here we will build project end-to-end with the SDK ultimately applying Mandatory User Filters and Variable filters to the project.
---
## Introduction to Filters
This tutorial defines among many, the two most common ways to assign filters. Filters allow you to assign rules on what content a user has access to within your project and are very helpful at helping a user to see content only relevant to them.

Before setting up Mandatory User Filters or Variable User Filters you need to set the user privileges.

For this guide we will use the sample project provided through the scaffolding tool.

gooddata scaffold project my_test_project

In terms of the demo project, each developer wants to only see their commits. For this use case we can easily add Mandatory User Filters to ensure see the see only the relevant information.

If we open up the file *_data/commits.csv_*, you will notice that the developer id and the repo id are assigned to two columns. 

##### commits.csv
    lines_changed,committed_on,dev_id,repo_id
    1,01/01/2014,1,1
    3,01/02/2014,2,2
    5,05/02/2014,3,1

Looking at the *_repo_id_* we can infer that the final did git in easy row  has a username in the second to east row. At this point we can begining setting up the CSV using the email of the user and the attribute value of the filtered attribute. This is simply outlined in CSV, in this case we are assuming the username is the email but you are welcome to use an unique attribute describing the user. 

##### privileges_example.csv
    username,commit_id
    paul@company.com, 1
    kara@company.com, 2
    caitlin@company.com,1

As you can see we mapped the *_commit_id_* to the user email associated with the developer.

In the above example privileges are imported in rows, but in many cases there will are multiple attributes you are filtering for a given user. In these cases you can import the privileges in *_column_* format as well.

##### privileges_example_columns.csv
    paul@states.com,california,arizona,oregon
    kara@states.com,colorado,nevada
    caitlin@states.com,kansas,oklahoma,ohio
    patrick@states.com,michigan,maine
    bob@states.com,maine,
    amanda@states.com,florida

In the *_column_* format the user email is first, followed by the regions they are permitted to see. Either format (row or column based) can be used, the SDK will automatically determine the format during import.

## Mandatory User Filters
### Getting started
Creating Mandatory User Filters is done without the web interface (cool!). Unlike Variable Filters, you do not need to create the filter first.

1. URI of the Attribute
Extracting the URI of the Variable Filter is an easy process. Simply, “jack_in” to your project with this command:

    gooddata -U username -P password -p project_id project jack_in

Then, go ahead and list the number of attributes with this command.

    GoodData::Attribute.all

From the list of attributes select the one you are interested filters and get the attribute identifier.

    GoodData::Attribute['ATTRIBUTE_IDENTIFIER'].labels[0]

Now select the value in the uri field which is the label uri from above. Generally it is the first label, but if this is not the label you are interested in, you can browse all of the labels by just removing the “[0]”.

  GoodData::Attribute['ATTRIBUTE_IDENTIFIER'].labels

2. A CSV file containing the the login (generally email) of the user you are filtering, label URI of the attribute being filtered and the value of the attribute you are filtering on.

### Executing
Once you have the Attribute Label URI and the CSV file containing the user logins you are ready to start applying filters. Based on the demo project, we have set up an example script to go through the process.

    def mandatory_example
      GoodData.logging_on

      # csv = IO.read(‘data/commits.csv’)
      csv = "login,commit_id\paul@company.com,1\n"

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

## Advanced Options
### Variable Filters
Before using the brick you will need to choose the attributes you would like to add variable filters to, then based on those create the variable filters using the project’s web interface at https://secure.gooddata.com. 

1. Go to your project’s interface at https://secure.gooddata.com and click on *_Manage_*.
2. Select *_Variables_* from the left hand side navigation bar.
3. Fill out the variable information, naming the variable and be certain to check the *_Variable Filter_* instead of the default *_Numerical Filter_* option. 

Remember the name of the filter you assign as we will use it to look up the URI in later steps. 

Referring the example script above, we have modified it to now apply the the variable attribute. 

    def variable_example
      GoodData.logging_on

      var = VARIABLE_URI
      # csv = IO.read(‘data/commits.csv’) 
      csv = "login,commit_id\paul@company.com,1\n"

      filters = GoodData::UserFilterBuilder::get_filters(csv, {
        :type => :filter,
        :labels => [
           {:label => {:uri => "ATTRIBUTE_LABEL_URI"}, :column => 'COLUMN'}
        ]
      })
      GoodData::UserFilterBuilder.execute_variables(filters, var)
    end
