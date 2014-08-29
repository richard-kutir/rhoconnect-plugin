#RhoConnect Plugins in Ruby

*This the first of three articles on how RhoConnect can be combined with various platforms such as Ruby on Rails, Java, and .NET.*


The Rho platform was developed as a cross-platform solution that offers powerful tools for uniting enterprise data with mobile devices.  One key part of that strategy is the RhoConnect sync server platform.  RhoConnect offers an easy-to-implement way of keeping the data on the mobile device and your back end storage synchronized.

As Motorola states:

> RhoConnect is the first of a new category of “mobile app integration” servers. 
> Using RhoConnect drastically simplifies the development of connectivity to an 
> enterprise backend app. The RhoConnect server and built-in RhoConnect client in 
> the smartphone app perform all the work to get data down to the device. This 
> eliminates 50 to 80 percent of the development effort in enterprise smartphone 
> apps: performing the backend application integration.

-- http://docs.rhomobile.com/en/5.0.0/rhoconnect/introduction

There are several ways to interface your back end systems to RhoConnect (and indirectly your mobile devices).  It's up to you, as the developer, to choose the best method suited to your needs:

### 1. RhoConnect REST API

[RhoConnect has a REST API](http://docs.rhomobile.com/en/5.0.0/rhoconnect/rest-api) that allows direct and custom services to be developed with it as the platform.  The API allows you to tie in complicated back end systems by giving you direct control of the RhoConnect service.  This means your solution can be as simple or as complicated as you wish it to be.

### 2. RhoConnect Source Adapters

A [RhoConnect source adapter](http://docs.rhomobile.com/en/5.0.0/rhoconnect/source-adapters-intro) gives you a framework that encapsulates the RhoConnect API, but gives you the leeway to include your own business logic through models and controllers.  The source adapter is a good choice if you wish to have a framework to automate the actual communication with RhoConnect, yet maintain the ability to inject custom business logic into the process.

### 3. RhoConnect Plugins

From Motorola: 

> Rhoconnect Plugins allow you to connect your backend apps seamlessly with 
> rhoconnect. You can write the source (query, create, update and delete 
> operations) into a backend application, and use a RhoConnect plugin in the 
> language that matchs your backend application, such as Java or .NET."

A [Rhoconnect plugins](http://docs.rhomobile.com/en/5.0.0/rhoconnect/plugin-intro)  encapsulates the integration of your back end solution and RhoConnect in a library that handles the communication seamlessly.  You simply implement your application's models and through the plugin RhoConnect will automatically synchronize your data across your mobile devices.

![RhoConnect plugin](https://s3.amazonaws.com/rhodocs/rhoconnect-service/intro-plugin.png) 
-- image source Motorola: (http://docs.rhomobile.com/en/4.1.0/rhoconnect/plugin-intro)


In this article we're going to examine how to implement a RhoConnect plugin using [Ruby on Rails](http://rubyonrails.org) as the back end application.  Ruby on Rails provides an excellent framework for rapidly developing applications that can communicate with a variety of database platforms, including MySQL, PostgreSQL, and MS SQL Server.  The RhoConnect plugin will connect our Rails application data to a Rhodes mobile application transparently.

To demonstrate RhoConnect plugins we're going to use three different apps:
* A RhoConnect server
* A Rails 4 app with the [Rhoconnect-rb gem](https://github.com/chronosafe/rhoconnect-rb)
* A Rhodes mobile app (using the iOS simulator)

We're using a Mac as the development platform in this excersize but Windows is also supported.  Install the [RhoMobile Suite](http://docs.rhomobile.com/en/5.0.0/guide/welcome) to get the toolchain you need to follow this post.

For our example we're going to set up a very simple address book.  It will allow the end user to view a set of addresses, along with names and email addresses associated with those addresses.  We will be able to update this list of names from both the mobile device and the Rails back end.  Let's get started!

## The Setup

We're going to emulate the Internet on our local computer, meaning our applications will all be on `localhost`.  In a production or staging environment your RhoConnect and Rails app will be hosted on an application server, while your Rhodes app will reside on a mobile device such as an iPhone or Android device.  Let's create a root directory and create all of our applications as subdirectories from this root.

```
mkdir plugins
cd plugins
```

The first application we're going to configure is the RhoConnect service itself.  You can install it by using the command:


````
gem install rhoconnect
```

This will install the RhoConnect service gem on our computer.  Next we need to install [redis](http://redis.io):

````
rhoconnect redis-install
rhoconnect dtach-install  <--- install this as well on a Mac
```

Finally we can create our RhoConnect app:

```
rhoconnect app address_server
cd address_server
```

In the `settings/settings.yml` add the `:sources:` section and add the `adapter_url` line to the development section: 

```
:development:
  :licensefile: settings/license.key
  :redis: localhost:6379
  :syncserver: http://localhost:9292
  :push_server: http://someappname@localhost:8675/
  :api_token: my-rhoconnect-token  
  :adapter_url: http://localhost:3000
```

The `adapter_url` line will point to our Rails app.  In development Rails apps by default use port 3000 on `localhost`.  This line allows our RhoConnect app to know where the data resides when synchronizing with mobile apps.

Note the `api_token` is set to `my-rhoconnect-token`.  This token will be used with the Rails app to create a shared token between the apps.  In a production environment you'll want to use a more secure token.

Note also that the sync server is running on `localhost` at port 9292.  This is the URL and port of your RhoConnect server.  In production this would point to the IP on the Internet where your application is installed.  


## Create the Ruby on Rails back end app using the RhoConnect Plugin

Next we'll create our Rails back end application.  Here we're using Rails 4, as it's the latest version of the framework available.  Rails 3 will also work; as a matter of fact it's the version that the plugin supports by default.

```
rails new address_book
cd address_book
```

The official gem doesn't support Rails 4 yet, so I had to fork it to add support for that version of Rails.

Edit the Gemfile and add:

```
gem 'rhoconnect-rb', github: 'chronosafe/rhoconnect-rb'
```

If you're using Rails 3 instead, use:

```
gem 'rhoconnect-rb'
```

This gem is the actual plugin and provides the glue between the app and RhoConnect.  Behind the scenes it builds controllers and routes to your app to support communication with your RhoConnect app transparently.


Next we need to add the model for the address book:

```
rails g scaffold Address name address email
```

This creates the store for our addresses.  Note that we're using SQLite3 for our data store as it is the default for Rails and requires no configuration.

Run the rake task to process the migration:

```
rake db:migrate
```

This will create our database for us.

Next we need to add an initializer to the `config/initializers` directory.  This will allow us to configure our communication with RhoConnect.  Create a file in `config/initializers` named `rhoconnect.rb` and add the following:

```
Rhoconnectrb.configure do |config|
  config.uri    = "http://localhost:9292"
  config.token  = "my-rhoconnect-token"
  config.app_endpoint = "http://localhost:3000"
  config.authenticate = lambda { |credentials|
    # User.authenticate(credentials[:login], credentials[:password])
    true
  }
end
```

The `config.uri` line points to our RhoConnect application.  The `config.app_endpoint` strangely enough points back to the Rails app itself.

Notice the `config.token` line.  This token matches the token we created in our RhoConnect app.  We can create an authentication system for our application here as well.  RhoConnect will pass the user that is attempting to access the back end.  We can authenticate this user using normal Rails authentication.  I've commented this out for our simple example and just return `true`, meaning everyone is authenticated.

Next we need to make some changes to the `app/models/address.rb` file to add the support for RhoConnect:

```
class Address < ActiveRecord::Base
	include Rhoconnectrb::Resource

  # RhoConnect partition
  def partition
  	:app
  end

  def self.rhoconnect_query(partition, options={})
    all
  end
end

```

The `include` statement adds the RhoConnect plugin as a module to our model's class. This module includes all the functionality to enable this model to be updated (and to update) RhoConnect through the plugin.

Each model that supports the plugin must also implement two functions.  The first function is named `partition` and allows us to uniquely identify the scope of the data to be queried.  For example, you could define the partition to be the username used by the requesting mobile app.  In our case we're simply going to use `:app`, which means a global scope.

Next we must define a class method named `rhoconnect_query`.  This method is used by the plugin to actually query the database for a recordset when it needs to retrieve data.  Notice you're passed in the partition to use as a scope, as well a s a hash of options that can further refine the query.  For our example we're going to return `all`, which means the entire list of addresses.

With these modifications our Rails app is ready to communicate with RhoConnect.

## Create a Rhodes App

In order to test our architecture based on the plugin we're going to create a simple Rhodes app to display and update the list of addresses.  From our `/plugins` root directory do:

```
rhodes app addresses
cd addresses
```

Add an Address model:

```
rhodes model address name,address,email
```

Be sure not to add spaces between the fields.  This will create the files we need to support our Address model.

Edit the `app/Address/address.rb` to enable sync:

```
# The model has already been created by the framework, and extends Rhom::RhomObject
# You can add more methods here
class Address
  include Rhom::PropertyBag

  # Uncomment the following line to enable sync with Address.
  enable :sync

  #add model specific code here
end
```

Edit the `rhomobile.txt` to point to the sync (RhoConnect) server:
```
syncserver = 'http://localhost:9292'
```

Also change the start path for the app to display our list of addresses:
```
start_path = '/app/Address'
```

And we're done!


## Testing the Apps

In order to test the app's ability to talk to each other we'll launch them all in separate shell (or command) windows.

### Start up the services:

Start redis:
```
cd address_server
rhoconnect redis-start

```
Open a new shell and start Rhoconnect from the same folder:
```
cd address_server
rhoconnect start
```

### Start the Rails app in another shell window:

```
cd address_book
rails server
```

### Start the Rhodes app in the simulator (iPhone simulator):

If using the iPhone simulator you'll need to update the version in the sdk in the `build.yml` file (it defaults to iOS 6):

```
iphone:
  configuration: Release
  sdk: iphonesimulator7.0
```

Run the simulator:

```
cd contacts
rake run:iphone
```

Enter any username you wish and tap go to login.

### Testing the synchronization

Open a new shell and go to the Rails app:

```
cd address_book
rails console
```

This will open the rails console for the app.  Add a record to the database:

```
> Address.create(name: 'Abraham Lincoln', address: '1600 Pennsylvania Ave.', email: 'alincoln@whitehouse.gov')
> Address.all.count
```

The mobile device should show 1 entry.  

![Imgur](http://i.imgur.com/eWud2d3.png)

On the mobile app enter:

```
Name: Winston Churchill
Address: 10 Downing St.
Email: wchurhill@gov.uk
```

You should now see 2 listings on the mobile app.  

![Imgur](http://i.imgur.com/Oz8l96b.png)

Press the sync button and return to the Rails app console:

```
> Address.all.count
```

Should now return 2.

A quick scaffold shows the data on the Rails side at `http://localhost:3000`:

![rails data](http://i.imgur.com/6Xms5ws.png)

That's it! Your Rails `Address` model is exposed to the Rhodes app for synchronization.  Data will automatically be updated on both ends whenever it changes on either end.

## Conclusion

RhoConnect plugins are a fast way to enable a back end to hook into the RhoMobile framework.  In this example we used Ruby on Rails as the back end platform, but it could have been any other platform that is supported by the plugin architecture.  

The next time you need to tie in a Rails app to your RhoMobile application take a look at the RhoConnect plugin system.  It could be the perfect fit for your solution.

This is a cross-post from Motorola's Launchpad Blog: https://developer.motorolasolutions.com/community/rhomobile-suite/rhomobile-community/rhomobile-blogs/blog/2014/08/29/rhoconnect-plugins-in-ruby
