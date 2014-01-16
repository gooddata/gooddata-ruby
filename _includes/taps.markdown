<h2>Taps</h2>

In BAM, a <b>tap</b> is a source of data. Currently, BAM supports two types of taps: Salesforce and File.

<h3>Common properties</h3>

Each tap definition contains the source of the data and an internal identifier. 

<ul>
  <li>The source identifies where to collect the data for the ETL. Sources can be CSV files or Salesforce data.
    <li>Depending on the type of tap, the tap definition may vary.</li>
  </li>
  <li>The ID field is the unique identifier for the tap. This identifier can be referenced elsewhere in your BAM project. It must be unique among the tap identifiers in your project. </li>
</ul>

<h3>Salesforce</h3>

The Salesforce tap connects to SalesForce using credentials referenced in the params.json file in your BAM project. 

<ul>
  <li>The Object value indicates for the downloader the Salesforce object to extract.</li>
  <li>You can specify the fields from the object that you wish to acquire.</li>
</ul>

{% highlight ruby %}
{
   "source" : "salesforce"
  ,"object" : "User"
  ,"id"     : "user"
  ,"fields" : [
    {
      "name" : "Id"
    },
    {
      "name" : "FirstName"
    },
    {
      "name" : "LastName"
    },
    {
      "name" : "Region"
    },
    {
      "name" : "Department"
    }
  ]
}
{% endhighlight %}

<h4>Defining limits</h4>

Sometimes, it may useful to limit the number of collected values. For example, if you are testing your ETL, you may wish to limit the number of collected records to 100.

{% highlight json %}
{
   "source" : "salesforce"
  ,"object" : "User"
  ,"id"     : "user"
  ,"fields" : [
    {
      "name" : "Id"
    }
    .
    .
    .
  ]
  ,"limit": 100
}
{% endhighlight %}

<h4>Acts As references</h4>

In some cases, you may need to reference a single field in a source of data several different places in your ETL. Or, your ETL may rely on a specific name of a field, so you need to be able to define a reference to a differently named field. 

These use cases can be addressed through the <em>Act as</em> declaration:

{% highlight json %}
{
   "source" : "salesforce"
  ,"object" : "User"
  ,"id"     : "user"
  ,"fields" : [
    {
      "name" : "Id", "acts_as" : ["Id", "Name"]
    },
    {
      "name" : "Custom_Amount__c", "acts_as" : ["RenamedAmount"]
    }
  ]
}
{% endhighlight %}

In the above declaration, the field Id is routed to both Id and Name. The Custom_Amount_c field is called RenamedAccount.

Be careful using <em>acts_as</em>. It is primarily used for feeding a field into ETL that has a different source name than the name used in the ETL. If the source name is to be propagated in the GoodData project, please verify that the name is applied in the tap and in the sink of the ETL.

<b>NOTE:</b> Even if you have applied <em>acts_as</em> to a field, the field is stored in its intermediary storage under its original name. If you need to change the name again, intermediary storage is not affected.

<h4>Condition</h4>

In the tap definition, you may specify a condition to apply during download. A <b>condition</b> is a Boolean test that is applied to one or more fields in the dataset. 

<b>NOTE:</b> It should be used only if it can significantly reduce the data transmitted over the network. Otherwise, conditional filtering should be applied elsewhere in your ETL.

{% highlight json %}
{
  "type": "tap",
  "source": "salesforce",
  "object": "Task",
  "id": "task",
  "fields": [{
    "name": "Id"
  }],
  "condition": "IsDeleted = false"
}
{% endhighlight %}

<h4>Taps validation</h4>

Fail early. Wherever possible, you should design your ETL to fail as soon as possible. 

When you develop your taps, you should design BAM to connect and validate that all requested fields are present. Failures here can simplify debugging later.

<h4>Mandatory fields</h4>

In your tap definition, you can define whether a field is mandatory or not. If you mark a field as not mandatory, then the rest of the dataset can continue to be processed without generating an error and failing. 

In Salesforce in particular, fields and their locations are modified frequently, so building this kind of check into your BAM can assist in managing change.

<h3>Files</h3>

BAM taps can also be designed to read from files. A <b>file</b> is any flat file that is stored locally or is accessible via HTTP. CloudConnect can handle both.

<h4>Local file</h4>

To acquire files from your local file system, you can specify relative (<em>./</em>) and absolute (<em>/</em>) paths. 

<b>NOTE:</b> The local file options are not supported when the BAM project is deployed to the GoodData platform.

{% highlight json %}
{
   "source" : "/"
  ,"id"     : "user"
  ,"fields" : [
    {
      "name" : "Id"
    },
    {
      "name" : "FirstName"
    },
    {
      "name" : "LastName"
    },
    {
      "name" : "Region"
    },
    {
      "name" : "Department"
    }
  ]
}
{% endhighlight %}

<h4>Remote file</h4>

In your tap definition, you can reference remote files by setting the value for <em>source</em> to be the URL to access. This method enables you to access files in GoodData project-specific storage. 

{% highlight json %}
{
   "source" : "https://example.com/abc.txt"
  ,"id"     : "user"
  ,"fields" : [
    {
      "name" : "Id"
    },
    {
      "name" : "FirstName"
    },
    {
      "name" : "LastName"
    },
    {
      "name" : "Region"
    },
    {
      "name" : "Department"
    }
  ]
}
{% endhighlight %}

<h4>Encoding</h4>

You can specify different encoding for a file. Use <em>charset</em> property in the tap to define correct encoding.

<h3>Incremental</h3>

By default everything is pushed to intermediary storage. If for whatever reason you do not want this set <em>direct</em> property to true, then the data is will not be downloaded to intermediary storage.

{% highlight json %}
{
   "source" : "https://example.com/abc.txt"
  ,"id"     : "user"
  ,"direct" : "true"
  ,"fields" : [
    {
      "name" : "Id"
    }  
  ]
}
{% endhighlight %}

Advantages of using intermediary storage is that all the history is kept and you can us the tap DSL to read out snapshots and do other cool things. Everything is backed up automatically.

<ul>
<li><a href="/recipe/2013/06/16/limitation-of-event-store.html">Limitations of Event Store</a></li>
<li>Incremental grabbing of data from the source still enables rebuilding of the entire history. </li>
<li>Less stress on the source system.</li>
</ul>
