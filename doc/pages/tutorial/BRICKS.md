# @title Executing ruby on GoodData plaform

You can run Ruby on GoodData platform. Let's have a look at the platform and walk step by step through doing the simplest possible deployment and then move to more advanced tasks.

## Not reinventing the wheel

The main idea is that only minority of people should be forced to write code. The others should be happy running them without understanding the details. Soon we will introduce better UI to do just that. Until then it is more programatic but if you are not scared read on.

## Setting up the stage

GoodData Ruby SDK stack is built so you can easily develop things locally and deploy them when you have tested them and are happy with how they work. You need to set up an environment first.

### Prerequisites

 * Git
 * Ruby (JRuby recommended)
 * Ruby Gems

Go ahead and run

    git clone https://github.com/gooddata/app_store.git

We just cloned the remote repository which contains information about the used libraries and also contains some stuff that others created. We will investigate that later. Let's continue with setting things up.

Run

    gem install bundler

This will install bundler which is a useful package installation tool. Let's use it

    cd local_repo
    bundle install --binstubs

This will ensure that you have installed exactly what we have on the production machines. This should mitigate bugs caused by slightly different versions of libraries and incompatible APIs.

You are ready to go.

## Running your first brick

The small pieces of ruby that are run on the platform are called bricks. Nobody knows where and why this name emerged but there are rumors that it is supposed to reference the fact that out of brick just laid together you can create a solid wall.

If you open the repository you will see there some directories. Find directory called misc/hello_world and open it. It contains only one file. Do not open it yet.

Run this in console.

    bundle exec gooddata -l -Uname@gooddata.com -Pmy_pass run_ruby -p project_pid -d hello_world_brick --name "some_deploy" --remote

It will take some time but after a while you should see green DONE on your console and a link for the log. Open it in your browser and you should see there something like this. On one of the lines there should be hello world. Great you just ran your first ruby brick.

### Looking inside Hello World

Let's see what is happening inside. Open the main.rb file in your favorite editor. You should see something like this.

    require 'gooddata'
    require 'logger'

    module GoodData::Bricks
        class HelloWorldBrick

            def call(params)
                logger = Logger.new(params[:GDC_LOGGER_FILE])
                logger.info "Hello world"
            end

        end
    end

    GoodData::Bricks::HelloWorldBrick.new

This is all. Let's dissect it. The interface is very simple. You have to provide an instance of an object that responds to a message :call (in other words does implement method call). This method takes one parameter and that is a hash map of parameters.

You can see that we have implemented such a class and returning an instance of that class. The method accepts params and you can see that we immediately make use of them when grabbing logger and the writing to it. Platform does the heavy lifting on the back and you have already seen the result.

## Digging deeper

It might be surprising if I tell you that this is not exactly how majority of the real bricks are implemented. What we showed you is fine and this is how we started but after we implemented some bricks we found out that we are repeating ourselves a lot. So we tried to come up with something better.

remark: If you know how Rack or any similar framework works for abstracting web applications you would be right at home since that is where most of the inspiration came from.

We introduced three concepts.

 * _Application_ - This part is responsible for doing the core of the task you are interested in. Structure of an app is pretty much what you have already seen.
 * _Middleware_ - very similar to app. The main difference is that you can chain them together. The main similarity is that it has the same interface as an app
 * _Pipelines_ - If you chain multiple middleweres and applications it creates a pipeline.

Let's have a look how it works visually.

![Example pipeline consisting of 3 middlewares](https://dl.dropboxusercontent.com/s/g5rymdmmx97hc61/middlewares.png?token_hash=AAE7qAjkOxA6tQGDk8UY17ltRu0ZG5UqwSJ_8ZtAl7ZNaA)

This is a simple pipeline with 2 middlewares and one app. The arrows depict how the execution order would flow.

### Executing a pipeline
Your pipeline is executed. First middleware is called then the second and third. Then your app is called it does what it needs to and then the call goes back through the middlewares (so they can actually act twice).

This probably does not seem that much useful so let's have a look at couple of examples where you might use it.

Plumbing -  just the plumbing. Did you notice how we had to set up the logger in our Hello World example? It is not a lot of code but imagine that you need to do 10 things like this. It can bog you down. There are couple of middlewares that try to help you with similar stuff. It is similar to what AOP style of programming tries to do.

Examples

 * log in to various systems and prepeare for action
 * Set up loggers

Decorators - Imagine that you have done something great. For example computing hierarchy of people from some information. It is so much useful that you would like to let other people use it. But everybody has slightly different use case. Somebody wants to output it to web dav or s3 storage. Somebody want's to tweet about that it finished somebody might want to store this file into vertica. Implementing serialization in a separate middlewere means that you do not need to touch the actually code that.

 * measuring time
 * serializing stuff to various places
 * letting other people know

### First pipeline

Ok let's create our first pipeline. Let's open misc/hello_world_pipeline_brick in your browser

You will see two files. Let's check the hello_world.rb first.

    module MyFirstBrick

        class HelloWorldBrick
            def call(params)
                logger = params[:gdc_logger]
                logger.info "Hello world"
            end
        end

    end

It looks exactly the same as in previosus case except for the logger setting up. Let's look at the other file main.rb

You see that at the top we are requiring the hello_world.rb and then we are setting up the pipeline. You can see that even this basic example uses quite a bit of middleare but hopefully their names are fairly self describing. Logging will hook up a logger. GoodData logs you in to GD and hooks the library to the logger if you want to. Timinng will simply measure the execution of the app itself.

Notice several things. Pipeline has exactly one app. It also has to be the last one in the pipeline. It has zero or more middlewares. When constructong a pipeline you can specify a stage either via a class or an instance. If it is a class we instatntiate it for you (without parameters). This is useful if you want to parametrize the middleware somehow.

## Middlewares
Let's have a look at some middlewares
App was not very challenging from programming perspective (which is the goal) and you will see that middleware is not any more complicated. There are generally two types of middleares. First is a middleware that wants to act only once. It is like fire and forget. For example setting up logger. You just create it and do not care. There is a second type and that is a middleware that wants to act twice. Once before the app itself was called. Second after an app was called. Typical example might be time measuring. You want to start your clock before the app itself is called but then you have to stop them sometimes. The difference is absolutely minimal let's walk through both of them.

### Logger middleware
    require 'logger'

    module GoodData::Bricks
      class LoggerMiddleware < GoodData::Bricks::Middleware

        def call(params)
          logger = params[:gdc_logger] = params[:GDC_LOGGER_FILE].nil? ? Logger.new(STDOUT) : Logger.new(params[:GDC_LOGGER_FILE])
          logger.info("Pipeline starts")

          returning(@app.call(params)) do |result|
            logger.info("Pipeline ending")
          end
        end

      end
    end

### Benchmarking middleware

    require 'benchmark'

    module GoodData::Bricks

      class BenchMiddleware < GoodData::Bricks::Middleware

        def call(params)
          puts "Starting timer"
          result = nil
          report = Benchmark.measure { result = @app.call(params) }
          puts "Stopping timer"
          pp report
          result
        end

      end
    end

You see there are really only minimal changes. Let's walk through the couple of important points more carefully. As we stated before difference between app and a middleware is mainly in the fact that you can chain middlewares. Thus middleware has to know who is the next on in the chain and at some point it is going to call him. That is the `@app.call(params)`. Notice how we are still using the same interface. This way it is no difference if the next guy is app or middleware. The second important piece might be the returning function but that is just a way how to be more dry. Returning will take one param evaluate it store it you can do some stuff on it and then its value is returned. These things are equivalent.

    returning(Person.new) do |o|
      p.name = "Tomas"
    end

    p = Person.new
    p.name = "Tomas"
    p

### Passing values

We haven't talk much explicitly about passing values. The recommended way how to pass parameters is through the `:call(params)` methods parameters. You can see example of that for example in the logger middleware. It creates a logger and puts it into the param object. All following middlewares that are called can benefit from it. You can again see the usage in the HelloWorld.

### Providing initial sets of parameters

When deploying you will have to either provide parameters during execution or to the scheduler. Since we are developing locally it would be great to have similar functionality during local execution. This is exactly what `--params` parameter does.

    bundle exec gooddata -v run_ruby --remote asdas/asdadas --params path_to_params_file.json

The file is simple JSON file. This file is used in both local or remote execution.

    {
      "param1" : "value1",
      "param2" : "value2"
    }

### Return parameters

## Local harness
Let's talk a little about the harness that makes it possible to test things locally. It tries to run your bricks in similar environment as it would run on the server. This mainly means that you will get the same parameters etc. The goal is to provide you environment to debug and test before you deploy.


### Run locally

The most complete command

    bundle exec gooddata -l -s https://secure.gooddata.com -Uname@gooddata.com -Pmy_pass -w https://secure-di.getgooddata.com run_ruby -p rjzbt1shubkj9c8es6f75t2avke748mj -d brick_test --name "some_deploy"

looks intimidating but let's break it down. Many of these can be omitted and are there in case you can override everything.

    bundle exec

means you are executing it with exact the same libraries as you would on the server (we are expecting that your local repo is up to date).

    -l

Means that HTTP communication will be logged to STDOUT.

    -s https://secure.gooddata.com

Means which datacenter you are connecting to. If you are not going against something special you should be able to leave this out

    -w https://secure-di.getgooddata.com

File staging area used for uploading the files for execution. Similar case as for he server. By default you should not be forced to use it.

    -p PID

Currently only execution context we have is project context. You have to specify a project PID to be abel to run your brick

    -d path_to_brick

This tells the tool where brick lives. It expect the directory where the main.rb lives. Do not point this directly to a file.

    --name some_name

Used when deployed to name the process so later you can identify it

### Run remotely

The only change to do when you are running things remotely is to add `--remote` to the command. Everything else should remain the same.

<div class="section-nav">
  <div class="left align-right">
      <a href="/docs/file/doc/pages/tutorial/TEST_DRIVEN_DEVELOPMENT.md" class="prev">
        Back
      </a>
  </div>
  <div class="right align-left">

      <span class="next disabled">Next</span>

  </div>
  <div class="clear"></div>
</div>