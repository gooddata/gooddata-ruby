# Caution: This file does not describe current status... YET<br>

The following examples of shell commands illustrate the desired use of the `gooddata` binary to be provided by this gem.<br>

This file is intended to be renamed to `README.md` in the future.<br>

$ **mkdir MyDataProject**<br>
$ **cd MyDataProject/**<br>

$ **gooddata configure-csv 'My Data Set' \--file=/tmp/mydataset.csv**<br>
_Setting up CSV connector to file /tmp/mydataset.csv<br>
Guessing data types for mydataset.csv column: <br>
&nbsp;id.......... connection point  <br>
&nbsp;name .... attribute <br>
&nbsp;type....... attribute <br>
&nbsp;impact.... attribute <br>
&nbsp;created... date <br>
&nbsp;closed.... date <br>
&nbsp;value...... fact <br>
Writing guessed columns into model/MyDataSet.xml <br>
Done. <br>
ATTENTION: Don't forget to review guessed data types and edit the model/MyDataSet.xml when necessary\!_<br>

$ **vim model/MyDataSet.xml&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;** <font color="blue"><-\- _Note: would be nice to provide an option to open an editor automatically by the provious command_ </font><br>


$ **gooddata diff**<br>
_No remote project associated\!<br>
+ MyDataSet.xml<br>
\+&nbsp;&nbsp; id: connection point<br>
\+&nbsp;&nbsp; name: attribute<br>
...<br>
\+&nbsp;&nbsp; value: fact_<br>

$ **gooddata create-remote 'My Data Project'**<br>
_Creating remote project<br>
Project hash wrtqwtbenhac36thgsdghhhjhjjsdfa stored in model/remote/main.pid<br>
Creating data sets:<br>
&nbsp;'My Data Set' using model/MyDataSet.xml<br>
Populating data sets:<br>
&nbsp;'My Data Set' from /tmp/mydataset.csv (incremental)<br>
Done._<br>

$ **gooddata refresh**<br>
_Comparing the remote and local data sets.<br>
Populating data sets:<br>
&nbsp;'My Data Set' from /tmp/mydataset.csv (incremental)_<br>

$ **gooddata configure-csv 'My Data Set' \--file=/tmp/mydataset_enriched.csv**<br>
_'My Data Set' data set exists already, scanning for changes<br>
Removed fields<br>
&nbsp; impact<br>
Guessing data types for new fields:<br>
&nbsp; industry... attribute<br>
&nbsp; score....... fact<br>
Saving original version into model/bk/MyDataSet.xml.1<br>
Writing guessed columns into model/MyDataSet.xml<br>
Done.<br>
ATTENTION: Don't forget to review guessed data types and edit the model/MyDataSet.xml when necessary\!_<br>

$ **gooddata refresh 'My Data Set'**<br>
_Comparing the remote and local data sets.<br>
ERROR: We need to alter the structure of the server-side dataset. Consequently, we need to<br>
fully reload the data. Since you are updating the 'My Data Set' data set in the incremental mode,<br>
please use the \--full-load switch to confirm your data file contains the full load. Alternatively, you<br>
can specify an alternative data file using the \--file parameter<br>

Example: $ gooddata refresh 'My Data Set' \--full \--file=/tmp/full.csv_<br>

$ **gooddata refresh 'My Data Set' \--full \--file=/tmp/mydataset-full.csv**<br>
_Comparing the remote and local data sets.<br>
Generating remote model alteration script into<br>
Populating data sets:<br>
&nbsp;'My Data Set' from /tmp/mydataset.csv (incremental)<br>
Done._<br>

$<br>
