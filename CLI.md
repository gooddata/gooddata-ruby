# gooddata-ruby CLI 

## api

Some basic API stuff directly from CLI

### api get

GET request on our API

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
