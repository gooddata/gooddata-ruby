---
layout: post
title:  "Your first project"
date:   2014-01-19 13:56:00
categories: recipe
pygments: true
perex: Let's spin up a project that will be the basis for other tutorials. It will take only 5 mins. Promise.
---

Ok welcome. Let's spin up a example project that we created so you can explore and see SDK in action. It is super simple. Since you are probably a developer we created simple project about developers.

###What we want to measure
Imagine you have a small dev shop. You have couple of developers. They crank out code. You also have couple of repositories for products. You want to measure how many lines of code each of the devs create. you wanna be able to track it by time by repository and by person. You want to see how many lines of code they committed.

###Model
This is how the model looks.

###Spinning it up
Let's do this. I assume you have gooddata SDK installed and working. Run

    gooddata scaffold project my_test_project

go to the directory

    cd my_test_project

and build project

    gooddata -U username -P pass -t token project build

If everything goes ok it will give you a PID also called a project_id. Open the my_test_project directory in your favorite text editor and open file called Goodfile. It should look like this

    {
      "model" : "./model/model.rb",
      "project_id"   : ""
    }

Put your freshly acquired pid into an empty slot after "project_id". It should look like this.

    {
      "model" : "./model/model.rb",
      "project_id"   : "HERE_COMES_YOUR NEW_TOKEN"
    }

You are done. If you go to https://secure.gooddata.com you should be able to see your new project. Also locally you are ready for other tutorials
