# Caution: This file does not describe current status... YET

The following examples of shell commands illustrate the desired use of the `gooddata` binary to be provided by this gem.

This file is intended to be renamed to `README.md` in the future.

$ **mkdir MyDataProject**
$ **cd MyDataProject/**

$ **gooddata configure-csv 'My Data Set' \--file=/tmp/mydataset.csv**
_Setting up CSV connector to file /tmp/mydataset.csv
Guessing data types for mydataset.csv column: 
&nbsp;id.......... connection point  
&nbsp;name .... attribute 
&nbsp;type....... attribute 
&nbsp;impact.... attribute 
&nbsp;created... date 
&nbsp;closed.... date 
&nbsp;value...... fact 
Writing guessed columns into model/MyDataSet.xml 
Done. 
ATTENTION: Don't forget to review guessed data types and edit the model/MyDataSet.xml when necessary\!_

$ **vim model/MyDataSet.xml&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;** <font color="blue"><-\- _Note: would be nice to provide an option to open an editor automatically by the provious command_ </font>


$ **gooddata diff**
_No remote project associated\!
+ MyDataSet.xml
\+&nbsp;&nbsp; id: connection point
\+&nbsp;&nbsp; name: attribute
...
\+&nbsp;&nbsp; value: fact_

$ **gooddata create-remote 'My Data Project'**
_Creating remote project
Project hash wrtqwtbenhac36thgsdghhhjhjjsdfa stored in model/remote/main.pid
Creating data sets:
&nbsp;'My Data Set' using model/MyDataSet.xml
Populating data sets:
&nbsp;'My Data Set' from /tmp/mydataset.csv (incremental)
Done._

$ **gooddata refresh**
_Comparing the remote and local data sets.
Populating data sets:
&nbsp;'My Data Set' from /tmp/mydataset.csv (incremental)_

$ **gooddata configure-csv 'My Data Set' \--file=/tmp/mydataset_enriched.csv**
_'My Data Set' data set exists already, scanning for changes
Removed fields
&nbsp; impact
Guessing data types for new fields:
&nbsp; industry... attribute
&nbsp; score....... fact
Saving original version into model/bk/MyDataSet.xml.1
Writing guessed columns into model/MyDataSet.xml
Done.
ATTENTION: Don't forget to review guessed data types and edit the model/MyDataSet.xml when necessary\!_

$ **gooddata refresh 'My Data Set'**
_Comparing the remote and local data sets.
ERROR: We need to alter the structure of the server-side dataset. Consequently, we need to
fully reload the data. Since you are updating the 'My Data Set' data set in the incremental mode,
please use the \--full-load switch to confirm your data file contains the full load. Alternatively, you
can specify an alternative data file using the \--file parameter

Example: $ gooddata refresh 'My Data Set' \--full \--file=/tmp/full.csv_

$ **gooddata refresh 'My Data Set' \--full \--file=/tmp/mydataset-full.csv**
_Comparing the remote and local data sets.
Generating remote model alteration script into
Populating data sets:
&nbsp;'My Data Set' from /tmp/mydataset.csv (incremental)
Done._

$
