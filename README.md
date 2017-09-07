# REDCap - Calculated Values (Difference Detector)

This repository is a Ruby library intended to assist you in identifying differences between values in Case Report Form versus Data Exports in a particular project.

**Please note that this tool identifies problems with calculated values differently from REDCap's "Find Calculation Errors in Projects" tool or running "Rule H" in Data Quality.**

This tool scrapes data from the live Case Report Form and compares it against an export file that you provide.


## Why are there differences between Case Report Form and Exported Data?

You might be wondering why there are problems with calculated values in REDCap.

Differences arise between the two for various reasons, **including, but not limited to:**

- Bugs from previous versions of REDCap saved incorrect / inaccurate values
- Inherent challenges with saving values of date-dependent calculations

## Why not use Rule H or "Find Calculation Errors in Projects" tool?

As a first line of defense, they are good tools.  

But there were some projects at our institution that had calculated value errors that were not caught by either tool.  

This tool catches every instance where there is a discrepancy between the Case Report Form and the Exported Data.


## Current Compatibility

This library is currently only tested against REDCap 7.1.2.  This is the only version that will work for analysis out of the box.  

However, it was designed to be easily extensible to support additional versions in the future.

To add compatibility to another version of REDCap, you'll need to create a version file within the following folder:

```
##THIS_REPOSITORY_FOLDER##/library/redcap_versions/
```

For REDCap 7.1.2, the file is called redcap_712.rb and the class that is instantiated is Redcap712.  

To add compatibility for a different version, you'll need to create a file respective to the desired version and adjust the methods to parse the table data correctly.

Depending upon the version, it might be the case that no changes are necessary.  If you are interested in helping with other versions, please contact aldefouw@medicine.wisc.edu or submit a pull request.


# Example Usage


Please note that everything within the library needs to exist within folders labeled with the project ID that you are analyzing. 


## Step 1 - Configure REDCap User

The script requires a **Super Administrator** account to access REDCap for analysis purposes.  If you do not know how to create this account - or can't - then this script probably isn't for you.

Because of the sensitivity of user credentials, it is recommended that you create a service account for this script specifically.


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


- **redcap_url**
- **redcap_version**
- **browser_options**
- **project_id**
- **threads**

Outside of **threads**, the values for all of the above should be obvious.  

If you have multiple processors or cores, you can increase **threads** number to increase the speed at which the values are scraped from the case report forms.  If you have a single processor or only a single core, decrease the number of threads to something lower.

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
