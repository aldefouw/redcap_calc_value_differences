# REDCap - Calculated Values (Difference Detector)

This repository is a Ruby library intended to assist you in identifying differences between values in Case Report Form versus Data Exports in a particular project.

**Please note that this tool identifies calculated value differences using a completely separate and isolated method versus REDCap's built-in "Find Calculation Errors in Projects" tool or running "Rule H" in Data Quality.**

The chosen method for this tool is to scrape data from the live Case Report Forms and compare the calculated values from the form against an export file that you provide.


## Why are there differences between the Case Report Form and Exported Data?

In our experience, differences arise between the two for various reasons, **including, but not limited to:**

- Bugs from previous versions of REDCap saved incorrect / inaccurate values
- Inherent challenges with saving values of date-dependent calculations

## Why not use "Rule H" or "Find Calculation Errors in Projects" tool?

As a first line of defense, they are good tools.  

That said, there were some projects at our institution that had calculated value errors that were not caught by either tool.  We identified this as a major problem because many of our PIs were incorrectly assuming that the data they exported exactly matched the Case Report Form they were referencing on screen.  In many cases, that was not true.

The purpose of this tool is to catch every instance where there is a difference between a calculated value field on the Case Report Form and that same calculated value field as seen in the Exported Data.

Something to keep in mind is that a difference between the respective values doesn't necessarily mean that REDCap incorrectly calculated the value.  (Although it does mean that in some cases.  It's just that it's not always a calculation bug - in some cases, the saved value might just be old or it was a date calculation that was saved on a previous date.)  Nonetheless, this tool will help you identify where the differences are.  

## Data Resolution ##

At this point, the tool does not correct any of the saved data that doesn't match the Case Report Form.  Dependent upon our feedback from PIs and other REDCap consortium members, we might add a feature to save the Case Report Form, however.  

## Current Compatibility

**This library is currently only tested against REDCap 7.1.2.  This is the only version that will work for analysis out of the box.**

However, the library was designed to be easily extensible and support additional versions.

## Extending Compatibility to Additional Versions

To extend compatibility to another version of REDCap, you'll need to create a version file within the following folder:

```
##THIS_REPOSITORY_FOLDER##/library/redcap_versions/
```

For **REDCap 7.1.2**, the file is called **redcap_712.rb** and the module that is instantiated is **Redcap712**.  

**To add compatibility for a different version, you'll need to create a file respective to the desired version and adjust the methods to parse the table data correctly.**  (For instance, for version **7.2.0**, you'd create a module called **Redcap720** and put it inside a file called **redcap_720.rb.**)

Depending on the changes that happened in the version you're on versus 7.1.2, there might not be any code changes necessary at all.  You might be able to drop the code inside the Redcap712 module into your version's module.  It all depends on whether the tables within the **Record Status Dashboard** and **Define Events** page changed at all versus the 7.1.2 version that this script comes bundled with.

If this script is found to be useful, there is a possibility that we will add additional parsers for additional versions of REDCap as our institution's REDCap version moves forward.

If you create a parser for a particular version of REDCap that you're on and have verified that it is working well, please contact aldefouw@medicine.wisc.edu or submit a pull request so that we can add your version to the master repository.  

*Note: Adding a parser for a particular version of REDCap isn't as hard as it may sound.  We are using the XML/HTML parser library known as **Nokogiri**.*

*It is lightning-quick and easy to learn.  The source code for version 7.1.2 (of our parser code, that is - not Nokogiri) is here:*

https://github.com/aldefouw/redcap_calc_value_differences/blob/master/library/redcap_versions/redcap_712.rb


## Technical Requirements ##

**ChomeDriver**

This script uses **ChromeDriver** to scrape each Case Report Form.  Installation of ChromeDriver is necessary, but the steps to install it fall outside the scope of this document.  

For information about how to install ChromeDriver, please visit:

https://github.com/SeleniumHQ/selenium/wiki/ChromeDriver

Because of the hundreds of different setups that ChromeDriver can run on, we cannot guarantee that the ChromeDriver will behave the same as it did on our platform that we developed on.

**Ruby**

Our Gemfile calls for Ruby version 2.3.1, and that is the platform we tested on.

It is recommended to use RVM or equivalent to manage your Ruby version, but installation is outside of the scope of this guide.  

For information about RVM and installing Ruby on your machine, please visit:

https://rvm.io/



# Example Usage

## Step 1 - Configure REDCap User

The script requires a **Super Administrator** account to access REDCap for analysis purposes.  If you do not know how to create this account - or can't - then this script probably isn't for you.

Because of the sensitivity of user credentials, it is recommended that you create a service account for this script specifically.

A service account is also helpful versus your own administrative account in the event of an audit because you would be able to demonstrate that the service account was making reads to the page via a script to identify calculated value differences.


Create a **config.yml** file at the following path:
```
##THIS_REPOSITORY_FOLDER##/config/config.yml
```

A template is provided for you to get started in the **config.yml.example** file.  


Alternatively you can copy and paste the template below into your **config.yml**:
```
redcap_user:
  username: your_user_here
  password: your_password_here
```





## Step 2 - Create Project Folder

Create a project folder in the **/project_exports**/ folder with the same ID as your project.  

For our example, we'll use project ID 25.

```
##THIS_REPOSITORY_FOLDER##/project_exports/25/
```

## Step 3 - Add Data, Data Dictionary, Event Forms


### Download Data ###

Download the complete **raw data** from your project in REDCap.  

It is **extremely** important to use the **raw data** data export.  **The script will not work with data that contains labels.**

Put your Data in the following location: 

```
##THIS_REPOSITORY_FOLDER##/project_exports/25/data.csv
```

### Download Data Dictionary ###

Download your complete Data Dictionary for the project.

Put your Data Dictionary in the following location: 

```
##THIS_REPOSITORY_FOLDER##/project_exports/25/data-dictionary.csv
```



### Download Events ###

**If you are working with a longitudinal project, you'll need to download your Events.**  This file is not necessary for a standard REDCap project.

Download your Events from the **Define my Event** tab.

Put your Events in the following location: 

```
##THIS_REPOSITORY_FOLDER##/project_exports/25/event-forms.csv
```


## Step 4 - Create Your Project Script

To run the analysis on your project, you'll need to create a file to instantiate the DifferenceDetector.

Included for your convenience is a file called "project.rb.example" to get you started.  You can remove the .example from the end of the file to get started.

Then, fill in the appropriate values for the following:

- **redcap_url** - the URL for your REDCap instance.  Example: https://your-redcap-server-url.here

- **redcap_version** - your REDCap version.  Example: 7.1.2  

- **browser_options** - a Selenium web driver object.  You can set the array of arguments with the "add_argument" method.  See the example "Project Analysis Template" below.  A common argument you may want to toggle is the "--headless" option.  For instance, you might not want the browser to run in headless mode if you are troubleshooting why a page isn't being scraped.

- **project_id** - your Project ID.  Example: 25

- **threads** - the number of threads you want to run.  A higher number will mean you can do more work / analysis at the same time.  If you have multiple processors or cores, you can this number to increase the speed at which the values are scraped from the case report forms.  If you have a single processor or only a single core, decrease the number of threads to something lower. In testing, Parallel didn't allow more threads than our processor(s) can handle.


Below is example code that you could use to analyze a project with ID of 25 running on version 7.1.2 of REDCap.

Project Analysis Template:
```
require "#{Dir.getwd}/library/difference_detector"

url = "https://your-redcap-server-url.here"

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--headless')
options.add_argument('--ignore-certificate-errors')
options.add_argument("--disable-notifications")
options.add_argument('--disable-translate')

detector = DifferenceDetector.new(redcap_url: url,
                                  redcap_version: "7.1.2",
                                  browser_options: options,
                                  project_id: 25,
                                  threads: 8)
detector.run
```

## Step 5 - Install Gems

**Important Note:** It is recommended to use RVM or equivalent to manage your Ruby version.  Installation is outside of the scope of this guide.  For information about RVM, please visit https://rvm.io/.


To install the gems, first download bundler.

```
gem install bundler
```

After you've downloaded bundler, you'll need to install the rest of the gems.  To do this, issue the **bundle install** command.

```
bundle install
```




## Step 6 - Run Script

On a Unix-based machine, you'll need to issue a command like the following to run the script:

```
ruby project.rb
```

Errors are reported to the bash window.  They are also reported to a CSV file and log files.


CSV Errors: 

```
##THIS_REPOSITORY_FOLDER##/errors/25/errors.csv
```

Logging: 

```
##THIS_REPOSITORY_FOLDER##/logs/25/info.log
##THIS_REPOSITORY_FOLDER##/logs/25/errors.log
```


