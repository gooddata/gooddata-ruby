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

Mandatory User Filters allow you to restrict access to data in your account or ensure that only relevant data is presented to the users. As you are the *_only_* user in this demo project, in this tutorial you will learn how to assign a Mandatory User Filter to yourself but the process doing so you will clearly see how to apply filters to others.

Let's say that you are the owner of a specific repository so we will be filtering away the other repositories so you cannot see them.

If we open up the file *_data/commits.csv_*, you will notice that the developer id and the repo id are assigned to two columns.

##### data/repos.csv
    repo_id,name
    1,gooddata-gem
    2,gooddata-platform

Looking at the *_repo_id_* we can infer that the final has a username in the second to east row. At this point we can begining setting up the CSV using you email value and the repo you are owner of.

##### privileges.csv
    username,repo_id
    YOUR_EMAIL,1

As you can see we mapped the *_repo_id_* to your email. Tradiationally, this file would be much longer containing the privelages for other users and what repos they own or participate in.

##### privileges_other_users.csv
    username,repo_id
    YOUR_EMAIL,1
    user1@example.com,2
    user2@example.com,2
    user3@example.com,1

    etc..

In the above example privileges are imported in rows, but in many cases there will are multiple attributes you filter on for a given user. In these cases you can import the privileges in *_column_* format as well. You might have a situation where users are in multiple repositories. In this case you could make the privileges file like this:

##### privileges_example_columns.csv
    user1@example,1,2,3
    user2@example.com,2
    user3@example,1
    user4@example.com,1,3

    etc...

In the *_column_* format the user email is first, followed by the repositories they are permitted to see. Either format (row or column based) can be used, the SDK will automatically determine the format during import.

## Mandatory User Filters
### Getting started
To get started applying the Mandatory User Filters you will need to get the identifier of the **repos** attribute.

1. URI of the Attribute
Extracting the URI of the filter is an easy process. Simply, “jack_in” to your project with this command:

    gooddata -U username -P password -p project_id project jack_in

Then, go ahead and list the number of attributes with this command.

    GoodData::Attribute.all

From the list of attributes select the one you are interested filters and get the attribute identifier.

    GoodData::Attribute['ATTRIBUTE_IDENTIFIER'].labels[0]

Now select the value in the uri field which is the label uri from above. Generally it is the first label, but if this is not the label you are interested in, you can browse all of the labels by just removing the “[0]”.

  GoodData::Attribute['ATTRIBUTE_IDENTIFIER'].labels

2. A CSV file containing the the login (generally email) of the user you are filtering, label URI of the attribute being filtered and the value of the attribute you are filtering on.

### Executing
Once you have the Attribute Label URI and the CSV file contiaining your email and the repository id you own, you are read to apply the filter. Based on the demo project, we have set up an example script.

    def mandatory_example
      GoodData.logging_on

      # csv = IO.read(‘data/commits.csv’)
      csv = "login,repo_id\YOUR_EMAIL,1\n"

      filters = GoodData::UserFilterBuilder::get_filters(csv, {
        :type => :filter,
        :labels => [
           {:label => "ATTRIBUTE_IDENTIFIER"}, :column => 'COLUMN'}
        ]
      })

      GoodData::UserFilterBuilder.execute_mufs(filters)
    end

Let's break this script down. First notice that we have commented out the reader for the file in place of an example so you can see the format.

From above, replace ATTRIBUTE_LABEL with the label identifier you added in step one. In addition to using the identifier, you could also use the object id, or the identifier in it's place. 

Take the case of this Attribute:

   {"link"=>"/gdc/md/tk0wjpqnx3l1kscdrorzzkizgh7wd2kh/obj/398",
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
     "contributor"=>"/gdc/account/profile/876ec68f5630b38de65852ed5d6236ff"},

Using..

    orderdate.year
    /gdc/md/tk0wjpqnx3l1kscdrorzzkizgh7wd2kh/obj/398
    398

All of these are acceptable ways to idenfity the Attribute for use in the filter.



## Validation

To confirm a Mandatory User Filter was assigned, go to your web dashboard at https://secure.gooddata.com, and then take a look at ## WHAT WOULD THEY SEE?

