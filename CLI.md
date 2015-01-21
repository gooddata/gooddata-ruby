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
   
```
tomaskorcak@kx-mac:~/$ gooddata api info
GoodData API
  Version: N/A
  Released: N/A
  For more info see N/A
nil

```

## auth

Work with your locally stored credentials

### auth store

Store your credentials to ~/.gooddata so client does not have to ask you every single time

```
tomaskorcak@kx-mac:~/$ gooddata auth store
Enter your GoodData credentials.
Email
tomas.korcak@gooddata.com
Password
xxxxxxxxxxxxxxxx
Authorization Token
ABCDEF123
Overwrite existing stored credentials (y/n)
y

```

## console

Interactive session with gooddata sdk loaded

## domain

Manage domain

### domain add_user

Add user to domain

```
tomaskorcak@kx-mac:~/$ gooddata domain add_user gooddata-tomas-korcak joe doe joe.doe@example.com password
```

### domain list_users

List users in domain

```
tomaskorcak@kx-mac:~/$ gooddata domain list_users gooddata-tomas-korcak
Tomas,Korcak,tomas.korcak@gooddata.com
tomas,korcak,korczis@gmail.com
joe,doe,joe.doe@example.com
```

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

```
tomaskorcak@kx-mac:~/$ gooddata -p tk6192gsnav58crp6o1ahsmtuniq8khb process list
{"processes"=>
  {"items"=>
    [{"process"=>
       {"type"=>"GRAPH",
        "name"=>"Training March",
        "graphs"=>["Training March/graph/graph.grf"],
        "executables"=>["Training March/graph/graph.grf"],
        "links"=>
         {"self"=>
           "/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/dataload/processes/f12975d2-5958-4248-9c3d-4c8f2e1f067d",
          "executions"=>
           "/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/dataload/processes/f12975d2-5958-4248-9c3d-4c8f2e1f067d/executions",
          "source"=>
           "/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/dataload/processes/f12975d2-5958-4248-9c3d-4c8f2e1f067d/source"}}}],
   "links"=>
    {"self"=>
      "/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/dataload/processes"}}}

```

## project

Manage your project

### project build

If you are in a gooddata project blueprint it will apply the changes. If you do not provide a project id it will build it from scratch and create a project for you.

### project clone

Clones a project. Useful for testing

```
tomaskorcak@kx-mac:~/$ gooddata -p uq7vmjkmfj86jihofsavdxgtfmxwofrh project clone
```

### project create

Create a gooddata project

```
tomaskorcak@kx-mac:~/$ gooddata project create
Project name
Test Project
Project summary  ||
Test Project Summary Text
Project template

token
SUPERSECRETTOKENHERE
Project 'Test Project' with id /gdc/projects/uq7vmjkmfj86jihofsavdxgtfmxwofrh created successfully!

```

### project delete

Delete a project. Be careful this is impossible to revert

```
tomaskorcak@kx-mac:~/$ gooddata -p uq7vmjkmfj86jihofsavdxgtfmxwofrh project delete
```

### project invite

Invites user to project

```
tomaskorcak@kx-mac:~/$ gooddata -p tk6192gsnav58crp6o1ahsmtuniq8khb project invite tomas.korcak@gooddata.com admin
Inviting tomas.korcak@gooddata.com, role: /gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/roles/2
```

### project jack_in

If you are in a gooddata project blueprint or if you provide a project id it will start an interactive session inside that project

### project list_users

List users

```
tomaskorcak@kx-mac:~/$ gooddata -p tk6192gsnav58crp6o1ahsmtuniq8khb project list_users
Korcak,Tomas,tomas.korcak@gooddata.com,/gdc/account/profile/c6f1b9dc57a3aac97ed70e467b27bbd9
```

### project roles

Roles

```
tomaskorcak@kx-mac:~/$ gooddata -p tk6192gsnav58crp6o1ahsmtuniq8khb project roles
/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/roles/2,Admin
/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/roles/7,Connectors System User
/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/roles/5,Editor
/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/roles/3,Embedded Dashboard Only
/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/roles/1,Unverified Admin
/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/roles/4,Viewer

```

### project show

Shows basic info about a project

```
tomaskorcak@kx-mac:~/$ gooddata -p tk6192gsnav58crp6o1ahsmtuniq8khb project show
{"content"=>
  {"cluster"=>"",
   "authorizationToken"=>"IOUYYUY8786",
   "guidedNavigation"=>"1",
   "isPublic"=>"0",
   "driver"=>"Pg",
   "state"=>"ENABLED"},
 "links"=>
  {"ldm_thumbnail"=>
    "/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/ldm?thumbnail=1",
   "self"=>"/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb",
   "clearCaches"=>"/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/clearCaches",
   "invitations"=>"/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/invitations",
   "users"=>"/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/users?link=1",
   "uploads"=>
    "https://secure-di.gooddata.com/project-uploads/tk6192gsnav58crp6o1ahsmtuniq8khb/",
   "ldm"=>"/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/ldm",
   "metadata"=>"/gdc/md/tk6192gsnav58crp6o1ahsmtuniq8khb",
   "publicartifacts"=>
    "/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/publicartifacts",
   "roles"=>"/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/roles",
   "dataload"=>"/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/dataload",
   "connectors"=>"/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/connectors",
   "execute"=>"/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/execute",
   "schedules"=>"/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/schedules",
   "templates"=>"/gdc/md/tk6192gsnav58crp6o1ahsmtuniq8khb/templates",
   "eventstores"=>
    "/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb/dataload/eventstore/stores"},
 "meta"=>
  {"created"=>"2014-03-03 14:24:51",
   "summary"=>"",
   "updated"=>"2014-03-03 14:24:51",
   "author"=>"/gdc/account/profile/c6f1b9dc57a3aac97ed70e467b27bbd9",
   "title"=>"Training March",
   "contributor"=>"/gdc/account/profile/c6f1b9dc57a3aac97ed70e467b27bbd9"}}

```

### project update

If you are in a gooddata project blueprint it will apply the changes. If you do not provide a project id it will build it from scratch and create a project for you.

### project validation

You can run project validation which will check RI integrity and other problems.

```
tomaskorcak@kx-mac:~/$ gooddata -p tk6192gsnav58crp6o1ahsmtuniq8khb project validation
{"projectValidateResult"=>
  {"error_found"=>0,
   "fatal_error_found"=>0,
   "results"=>
    [{"body"=>{"error"=>0, "log"=>[]}, "from"=>"pdm"},
     {"body"=>{"error"=>0, "log"=>[]}, "from"=>"pdm::transitivity"},
     {"body"=>{"error"=>0, "log"=>[]}, "from"=>"pdm::elem_validation"},
     {"body"=>{"error"=>0, "log"=>[]}, "from"=>"metric_filter"},
     {"body"=>{"error"=>0, "log"=>[]}, "from"=>"ldm"},
     {"body"=>{"error"=>0, "log"=>[]}, "from"=>"invalid_objects"},
     {"body"=>{"error"=>0, "log"=>[]}, "from"=>"pdm::pdm_vs_dwh"},
     {"body"=>{"error"=>0, "log"=>[]}, "from"=>"pdm::pk_fk_consistency"}],
   "meta"=>{"start_time"=>1398202260, "finished_time"=>1398202262}}}

```

## projects

Manage your projects

### projects list

Lists user's projects

```
tomaskorcak@kx-mac:~/$ gooddata projects list
/gdc/projects/la84vcyhrq8jwbu4wpipw66q2sqeb923,GoodSales Demo
/gdc/projects/pouwty5dezpuib8nil16fv4i1jz80oju,GoodSample Demo
/gdc/projects/tk6192gsnav58crp6o1ahsmtuniq8khb,Training March

```

## role

Basic Role Management

### role list

List roles

```
tomaskorcak@kx-mac:~/$ gooddata -p pouwty5dezpuib8nil16fv4i1jz80oju role list
dashboardOnlyRole,/gdc/projects/pouwty5dezpuib8nil16fv4i1jz80oju/roles/3
readOnlyUserRole,/gdc/projects/pouwty5dezpuib8nil16fv4i1jz80oju/roles/4
```

## run_ruby

Run ruby bricks either locally or remotely deployed on our server

## scaffold

Scaffold things

### scaffold brick

Scaffold a gooddata ruby brick. This is a piece of code that you can run on our platform

```
tomaskorcak@kx-mac:~/$ gooddata scaffold brick mybrick

tomaskorcak@kx-mac:~/$ ls -la mybrick/
total 16
drwxr-xr-x   4 tomaskorcak  staff   136 Apr 22 14:10 .
drwxr-xr-x  31 tomaskorcak  staff  1054 Apr 22 14:10 ..
-rw-r--r--   1 tomaskorcak  staff   103 Apr 22 14:10 brick.rb
-rw-r--r--   1 tomaskorcak  staff   179 Apr 22 14:10 main.rb

tomaskorcak@kx-mac:~/$ cat mybrick/brick.rb 
class MyBrick < GoodData::Bricks::Brick

    def call(params)
        # do something here
    end

end

tomaskorcak@kx-mac:~/$ cat mybrick/main.rb 
require_relative '../../gooddata/bricks/bricks'

require_relative './mybrick'


```

### scaffold project

Scaffold a gooddata project blueprint

```
tomaskorcak@kx-mac:~/$ gooddata scaffold project myproj

tomaskorcak@kx-mac:~/$ ls -la myproj/
total 8
drwxr-xr-x   5 tomaskorcak  staff   170 Apr 22 14:13 .
drwxr-xr-x  31 tomaskorcak  staff  1054 Apr 22 14:13 ..
-rw-r--r--   1 tomaskorcak  staff    53 Apr 22 14:13 Goodfile
drwxr-xr-x   5 tomaskorcak  staff   170 Apr 22 14:13 data
drwxr-xr-x   3 tomaskorcak  staff   102 Apr 22 14:13 model

```

## user

User management

### user show

Show your profile

```
tomaskorcak@kx-mac:~/$ gooddata user show
{"accountSetting"=>
  {"country"=>nil,
   "firstName"=>"Tomas",
   "ssoProvider"=>nil,
   "timezone"=>nil,
   "position"=>nil,
   "authenticationModes"=>[],
   "companyName"=>"GoodData",
   "login"=>"tomas.korcak@gooddata.com",
   "email"=>"tomas.korcak@gooddata.com",
   "created"=>"2014-03-03 11:28:51",
   "updated"=>"2014-04-22 22:58:51",
   "lastName"=>"Korcak",
   "phoneNumber"=>"00420775995881",
   "links"=>
    {"self"=>"/gdc/account/profile/c6f1b9dc57a3aac97ed70e467b27bbd9",
     "projects"=>
      "/gdc/account/profile/c6f1b9dc57a3aac97ed70e467b27bbd9/projects"}}}

```
