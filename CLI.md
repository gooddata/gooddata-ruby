# gooddata-ruby CLI 

## api

Some basic API stuff directly from CLI

### api get

GET request on our API

```
tomaskorcak@kx-mac:~/$ gooddata api get /gdc
{"about"=>
  {"summary"=>"Use links to navigate the services.",
   "category"=>"GoodData API root",
   "links"=>
    [{"link"=>"/gdc/", "summary"=>"", "category"=>"home", "title"=>"home"},
     {"link"=>"/gdc/account/token",
      "summary"=>"Temporary token generator.",
      "category"=>"token",
      "title"=>"token"},
     {"link"=>"/gdc/account/login",
      "summary"=>"Authentication service.",
      "category"=>"login",
      "title"=>"login"},
     {"link"=>"/gdc/md",
      "summary"=>"Metadata resources.",
      "category"=>"md",
      "title"=>"metadata"},
     {"link"=>"/gdc/xtab2",
      "summary"=>"Report execution resource.",
      "category"=>"xtab",
      "title"=>"xtab"},
     {"link"=>"/gdc/availableelements",
      "summary"=>
       "Resource used to determine valid attribute values in the context of a report.",
      "category"=>"availablelements",
      "title"=>"AvailableElements"},
     {"link"=>"/gdc/exporter",
      "summary"=>"Report exporting resource.",
      "category"=>"report-exporter",
      "title"=>"exporter"},
     {"link"=>"/gdc/account",
      "summary"=>"Resource for logged in account manipulation.",
      "category"=>"account",
      "title"=>"account"},
     {"link"=>"/gdc/projects",
      "summary"=>"Resource for user and project management.",
      "category"=>"projects",
      "title"=>"projects"},
     {"link"=>"/gdc/tool",
      "summary"=>"Miscellaneous resources.",
      "category"=>"tool",
      "title"=>"tool"},
     {"link"=>"/gdc/templates",
      "summary"=>"Template resource - for internal use only.",
      "category"=>"templates",
      "title"=>"templates"},
     {"link"=>"/gdc/releaseInfo",
      "summary"=>"Release information.",
      "category"=>"releaseInfo",
      "title"=>"releaseInfo"},
     {"link"=>"https://secure-di.gooddata.com/uploads",
      "summary"=>"User data staging area.",
      "category"=>"uploads",
      "title"=>"user-uploads"}]}}

```

### api info

Info about the API version etc
    
## auth

Work with your locally stored credentials

### api store

Store your credentials to ~/.gooddata so client does not have to ask you every single time

## console

Interactive session with gooddata sdk loaded

## domain

Manage domain

### domain add_user

Add user to domain

### domain list_users

List users in domain

## help

Shows a list of commands or help for one command

## process

Work with deployed processes

### process deploy

Deploys provided directory to the server

### process get

Gives you some basic info about the process

### process list

Lists all user's processes deployed on the plaform

## project

Manage your project

### project build

If you are in a gooddata project blueprint it will apply the changes. If you do not provide a project id it will build it from scratch and create a project for you.

### project clone

Clones a project. Useful for testing

### project create

Create a gooddata project

### project delete

Delete a project. Be careful this is impossible to revert

### project invite

Invites user to project

### project jack_in

If you are in a gooddata project blueprint or if you provide a project id it will start an interactive session inside that project

### project list_users

List users

### project roles

Roles

### project show

Shows basic info about a project

### project update

If you are in a gooddata project blueprint it will apply the changes. If you do not provide a project id it will build it from scratch and create a project for you.

### project validation

You can run project validation which will check RI integrity and other problems.

## projects

Manage your projects

### list

Lists user's projects

## role

Basic Role Management

### list

List roles

## run_ruby

Run ruby bricks either locally or remotely deployed on our server

## scaffold

Scaffold things

### brick

Scaffold a gooddata ruby brick. This is a piece of code that you can run on our platform

### project

Scaffold a gooddata project blueprint

## user

User management

### show

Show your profile
