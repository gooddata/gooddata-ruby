---
layout: tutorial
title:  "Part VII - Creating user filters"
date:   2014-01-19 13:56:30
categories: tutorial
pygments: true
prev_section: tutorial/tutorial-part-6-updating-column
perex: Here we will build project end-to-end with the SDK ultimately applying Mandatory User Filters and Variable filters to the project.
---

Mandatory User Filters allow you to restrict user access to data within your project or to ensure that only relevant data is presented. As you are the only user in this demo project for this tutorial you will learn how to assign a Mandatory User Filter to yourself. In the process of doing so you will understand how apply filters to many users.

### Getting Started

Let's say that you are the owner of a specific repository so we will add a filter to your account which hides the other repositories from your report. Don't worry it is easy to remove the filter!

If we look into the data at *data/repos.csv*, you will notice that each repo (gooddata-gem, gooddata-platform) has a unique id.

##### data/repos.csv
    repo_id,name
    1,gooddata-gem
    2,gooddata-platform

From *repo_id* we can filter repositories for all users in the project. Realizing this, we can set up a CSV filter you to one at this point we can begining setting up the CSV using you email value and the repo_id you are responsible for.

##### privileges.csv
    username,repo_id
    YOUR_EMAIL,1

Traditionally, this file would be much longer containing the privelages for other users designating the repos they own or participate in.

##### privileges_other_users.csv
    username,repo_id
    YOUR_EMAIL,1
    user1@example.com,2
    user2@example.com,2
    user3@example.com,1

    ...

In the above example privileges are imported in rows, but in many cases there will are multiple attributes you filter on for a given user. In these cases you can import the privileges in *column* format as well. You might have a situation where users are in multiple repositories. In this case you could make the privileges file in the following format.

##### privileges_example_columns.csv
    user1@example,1,2,3
    user2@example.com,2
    user3@example,1
    user4@example.com,1,3

    ...

This *column* format or "adjacency list" shows the user email listed first followed by the repositories they are permitted to see. Either format (row or column based) can be used, the SDK will automatically determine the format during import.

### Preparing the Data

To get started applying the Mandatory User Filters find the URI of the filter through the "jack_in" tool.

    gooddata -U username -P password -p project_id project jack_in

Replace the username, password, and project_id with your own information. Once done, list the number of attributes with this command.

    GoodData::Attribute.all

From the list of attributes select the one you want to filter on and copy the attribute identifier, in our case it is *attr.repos.repo_id*.

    GoodData::Attribute['attr.repos.repo_id'].labels.map(&:title)

This should print out the following information in the *meta* tag.

    => ["Name", "Repo"]

We want to use filter on "Repo" label, so let's use the *label_by_name* method and we can assign the complete attribute.

    attr = GoodData::Attribute['attr.repos.repo_id'].label_by_name('Repo')

Note: In addition to using the identifier (attr.repos.repo_id), you can use the object id or the URI to reference the object label. Any of these are acceptable ways to idenfity the Attribute for use in the filter.

    "indentifier" => attr.repos.repod_id
    "link"        => /gdc/md/tk0wjpqnx3l1kscdrorzzkizgh7wd2kh/obj/398
    "object_id"   => 398


### Example Script

To put everything together, let's write out an example script which will assign the filter from your privileges CSV.

    csv = "login,repo_id\nYOUR_EMAIL,1\n"

Make sure you replace YOUR_EMAIL with your project's email. This is followed by the label of the attribute we are interesting in filtering.

    attr = GoodData::Attribute['attr.repos.repo_id'].label_by_name('Repo')

 Next, using the label information we got from above we will call the *UserFilterBuilder* method.

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

    attr = GoodData::Attribute['attr.repos.repo_id'].label_by_name('Repo')

    filters = GoodData::UserFilterBuilder::get_filters(csv, {
      :type => :filter,
      :labels => [
         {:label => attr}, :column => 'COLUMN'}
      ]
    })

      GoodData::UserFilterBuilder.execute_mufs(filters)

    end


## Validation

To confirm a Mandatory User Filter was assigned, go to your web dashboard at https://secure.gooddata.com, and then take a look at ## WHAT WOULD THEY SEE?

{{ Picture of Project Dashboard }}


