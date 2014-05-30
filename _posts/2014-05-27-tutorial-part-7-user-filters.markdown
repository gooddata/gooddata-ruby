---
layout: tutorial
title:  "Part VII - Creating user filters"
date:   2014-01-19 13:56:30
categories: tutorial
pygments: true
prev_section: tutorial/tutorial-part-6-updating-column
perex: Here we will build project end-to-end with the SDK ultimately applying Mandatory User Filters and Variable filters to the project.
---

Mandatory User Filters allow you to restrict user access to data in your project or ensure that only relevant data is presented. As you are the only user in this demo project, for this tutorial you will learn how to assign a Mandatory User Filter to yourself but the process doing so you will clearly see how to apply filters to others.

### Getting Started

Let's say that you are the owner of a specific repository so we will add a filter to your account which hides the other repositories from your report. Don't worry it is easy to remove them!

If we look into the data at *data/repos.csv*, you will notice that each repo (gooddata-gem, gooddata-platform) has a unique id.

##### data/repos.csv
    repo_id,name
    1,gooddata-gem
    2,gooddata-platform

From *repo_id* we can filter repositories for all users in the project. Realizing this, we can set up a CSV filter you to one  at this point we can begining setting up the CSV using you email value and the repo you are owner of.

##### privileges.csv
    username,repo_id
    YOUR_EMAIL,1

Tradiationally, this file would be much longer containing the privelages for other users designating the repos they own or participate in.

##### privileges_other_users.csv
    username,repo_id
    YOUR_EMAIL,1
    user1@example.com,2
    user2@example.com,2
    user3@example.com,1

    etc..

In the above example privileges are imported in rows, but in many cases there will are multiple attributes you filter on for a given user. In these cases you can import the privileges in *column* format as well. You might have a situation where users are in multiple repositories. In this case you could make the privileges file like this:

##### privileges_example_columns.csv
    user1@example,1,2,3
    user2@example.com,2
    user3@example,1
    user4@example.com,1,3

    etc...

In the *column* format the user email is first, followed by the repositories they are permitted to see. Either format (row or column based) can be used, the SDK will automatically determine the format during import.

### Preparing the Data
To get started applying the Mandatory User Filters you will need to get the identifier of the **repos** attribute. Extracting the URI of the filter is an easy process. Simply, “jack_in” to your project with this command:

    gooddata -U username -P password -p project_id project jack_in

Then, go ahead and list the number of attributes with this command.

    GoodData::Attribute.all

From the list of attributes select the one you are interested filters and get the attribute identifier.

    GoodData::Attribute['attr.repos.repo_id'].labels[0]

This should print out the following information in the *meta* tag.

    {
      "author"=>"/gdc/account/profile/decd0b2e3077cf9c47f8cfbc32f6460e",
      "uri"=>"/gdc/md/p1vzlsvauy9zw886nvls3cfwtqavq1tv/obj/200",
      "tags"=>"",
      "created"=>"2014-05-30 20:20:35",
      "identifier"=>"label.repos.repo_id.name",
      "deprecated"=>"0",
      "summary"=>"",
      "title"=>"Name",
      "category"=>"attributeDisplayForm",
      "updated"=>"2014-05-30 20:20:35",
      "contributor"=>
      "/gdc/account/profile/decd0b2e3077cf9c47f8cfbc32f6460e"
    }

Now we can grab  in the uri field which is the label uri from above. Generally it is the first label, but if this is not the label you are interested in, you can browse all of the labels by just removing the “[0]”.

    GoodData::Attribute['attr.repos.repo_id'].labels

### Example Script

Breaking this down into steps, your script will first import the privileges from a CSV.

      csv = "login,repo_id\nYOUR_EMAIL,1\n"

Make sure you replace YOUR_EMAIL with your project's email. Next, using the label information we got from above we will call the *UserFilterBuilder* method.

      attr = GoodData::Attribute['attr.repos.repo_id'].labels[0]
      filters = GoodData::UserFilterBuilder::get_filters(csv, {
        :type => :filter,
        :labels => [
           {:label => attr}, :column => 'COLUMN'}
        ]
      })

For the last part of the script you will execute the Mandatory User Filters on the user (which in this case is you).

    GoodData::UserFilterBuilder.execute_mufs(filters)

All together your script should look something like this:

    csv = "login,repo_id\YOUR_EMAIL,1\n"

      attr = GoodData::Attribute['attr.repos.repo_id'].labels[0]
      filters = GoodData::UserFilterBuilder::get_filters(csv, {
        :type => :filter,
        :labels => [
           {:label => attr}, :column => 'COLUMN'}
        ]
      })

        GoodData::UserFilterBuilder.execute_mufs(filters)
      end

### Extracting Attributes

From above, replace ATTRIBUTE_LABEL with the label identifier you added in step one. In addition to using the identifier, you could also use the object id, or the identifier in it's place.

Take the case of this Attribute:

    {

     "link"=>"/gdc/md/tk0wjpqnx3l1kscdrorzzkizgh7wd2kh/obj/398",
     "locked"=>0,
     "author"=>"/gdc/account/profile/876ec68f5630b38de65852ed5d6236ff",
     "tags"=>"date year",
     "created"=>"2013-05-21 18:43:30",
     "identifier"=>"orderdate.year",
     "deprecated"=>"0",
     "summary"=>"Year",
     "title"=>"Year (OrderDate)",
     "category"=>"attribute",
     "updated"=>"2013-05-21 18:43:32",
     "unlisted"=>0,
     "contributor"=>"/gdc/account/profile/876ec68f5630b38de65852ed5d6236ff"

    },

Using..

    orderdate.year
    /gdc/md/tk0wjpqnx3l1kscdrorzzkizgh7wd2kh/obj/398
    398

All of these are acceptable ways to idenfity the Attribute for use in the filter.


## Validation

To confirm a Mandatory User Filter was assigned, go to your web dashboard at https://secure.gooddata.com, and then take a look at ## WHAT WOULD THEY SEE?

{{ Picture of Project Dashboard }}


