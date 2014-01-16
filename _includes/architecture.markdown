<div class="navbar navbar-inverse navbar-fixed-top">
  <div class="navbar-inner">
    <div style="margin-left: 100px;">
      <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
      <a class="brand" href="./index.html">BAM!</a>
      <div class="nav-collapse collapse container">
        <ul class="nav">
          <li class="">
            <a href="{{ site.url }}/">Home</a>
          </li>
          <li class="">
            <a href="{{ site.url }}/getting-started">Get started</a>
          </li>
          <li class="active">
            <a href="{{ site.url }}/architecture">Architecture</a>
          </li>
          <li class="">
            <a href="{{ site.url }}/tutorials">Tutorials</a>
          </li>
          <li class="">
            <a href="{{ site.url }}/docs">Docs</a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</div>

<div class="container-narrow" style="margin-top: 30px;">
<h3>Overview of BAM</h3>

BAM is a set of tools to enable ETL developers to build reliable ETL from building blocks. Users are provided with this additional abstraction layer to guide in how to lay out the application from independently operating pieces, which creates a simpler and more manageable result.

<h3>Leveraging GoodData Know-How</h3>

Typical ETL tools are blank slates from which you build from the ground up. 

BAM, however, is purpose-built to support ETL integration with the GoodData platform. As a result, BAM integrates some GoodData best practices and defines boundaries to the ETL that you can create, so that your generated output works easily with the GoodData platform. 

These boundaries are not fixed. BAM does provide the means of straying from the recommended pathway, and there may be times when that is the best choice. 

<h3>Tap/Flow/Sink abstraction</h3>

BAM definitions utilize an abstraction layer composed of three elements: tap, flow and sink. They elements are analogous to a water flow: Data comes out of the tap to create a flow, which fills a sink. 

During the flow, a variety of activities may occur. This flexibility enables BAM to deliver a higher level of functionality to ETL than CloudConnect currently offers. 

Eventually, successful BAM definitions will become a library of patterns from which developers can select the best approaches to addressing a particular ETL problem.

In this manner, ETL projects in GoodData become a matter of configuration, instead of low-level development.

<h3>Utilizing CloudConnect</h3>

GoodData's CloudConnect Designer delivers a graphical tool for assembling ETL projects. Built on a stable and proven ETL technology, CloudConnect Designer enables development of ETL at a deep level. 

BAM attempts to stand on the shoulders of what has been developed in CloudConnect. Utilizing many of the same structures and components of CloudConnect ETL, BAM simplifies the ETL process through abstraction and aggregation of functions. 

When a BAM project is compiled, it is rendered into a CloudConnect project, which means that your compiled BAM project can be run it within the GoodData infrastructure without additional modification, which delivers lower development and operations costs to implementation teams. 

In some cases, you can utilize the CloudConnect GUI for some configuration tasks to your BAM project. 

<div><img class="centered" src="https://dl.dropboxusercontent.com/s/nwwdgzxzocc375q/BAM-lifecycle.png?token_hash=AAEW34Fe5Hr-JM7FEX4nBLnw4Z05zKAPvH61Uh99LG499Q" width="300">
</div>

<h3>Integrated Backup</h3>

When configured properly, each data source that you use in your BAM project is automatically backed up using the Amazon S3 storage. Automated backups allow you to access your data in raw form whenever it is needed.

<h3>Reliable Runs</h3>

BAM provides more reliable ETL execution runs. If some parts of the ETL do not work as expected, the project can sleep until the issue is addressed. For example, if your ETL cannot access a source system, the ETL is automatically configured to sleep for a period of time before retrying the run. 

Such integrated failure management reduces the number of real emergenices - and provides more and better sleep at night.

<h3>Intermediary Storage</h3>

Two truths of the BI space: data is messy, and everything eventually changes. 

For years, developers have been aware of the first issue. Messy data needs to be addressed at the front of the ETL process. It must be cleansed, de-duped, and consolidated. 

The modern truth is that there are more and more data sources, which are in a greater state of flux. These data sources may provide feeds that are incremental, columnar, or full. Schedules may not sync correctly. These dynamics can negatively impact your ETL.

BAM fundametally addresses these problems as separate issues. The data acquisition stage and the transformation stage are explicitly separated into taps and flows, and between them sits intermediary storage. <em>Intermediary storage</em> provides a layer of insulation between these two stages. When data has been extracted, it is written to this commonly referenceble storage area, where any consuming flows can access and process it. 

The primary benefit is to modularize taps, flows, and sinks. If a flow is referencing data in intermediary storage, the source tap or taps for the data are irrelevant. 

Additionally, intermediary storage enables multiple developers to work on separate stages of an ETL process.

<div><img class="centered" src="https://dl.dropboxusercontent.com/s/3lwe9kitvyap1v3/BAM-Ecosystem.png?token_hash=AAEIbQkWAbUoxQZDqP9Ejp72VbzkrI38yao90Rsw_EzXAg" >
</div>

<h3>Fixing Errors</h3>

<h3>Maintenance is hard</h3>

After an ETL project has been successfully implemented, it is only a matter of time before the source or the target project changes, resulting in a maintenance cycle for the ETL process that populates it. In some cases, maintenance can consume more time than actual development.

BAM provides several useful mechanisms to accelerate maintenance cycles. A vital component of maintenance is enabled by <em>incremental data</em>, which is best illustrated by the following simple example. 

Suppose you have a dataset User:

{% highlight ruby %}
Id,FirstName,LastName
1,Tomas,Svarovsky
2,Petr,Olmer
3,Pavel,Kolesnikov
4,Petr,Cvengros
{% endhighlight %}

From this dataset, you wish to extract the following output:

{% highlight ruby %}
Id,Name
1,Tomas Svarovsky
2,Petr Olmer
3,Pavel Kolesnikov
4,Petr Cvengros
{% endhighlight %}

Below, you can see how to do this transformation in CloudConnect:

<div><img class="centered" src="https://dl.dropboxusercontent.com/s/3e1c5byqz5fs5h4/CC-metadata.png?token_hash=AAHvRl4McQbowUg735ruE5Ug8-ntUQAYjfpFBkAoYfj96A" >
</div>

In CloudConnect, the metadata are defined in the edges of the components. In the above, the two metadata are marked by dashed lines, between which is a component, called a mapper, that performs the actual mapping. In pseudocode, the ID value is passed, and FirstName and LastName are concatenated to produce Name. 

The above works fine. However, suppose that the input changes to the following: 

{% highlight ruby %}
Id,FirstName,LastName,State
1,Tomas,Svarovsky,California
2,Petr,Olmer,Washington
3,Pavel,Kolesnikov,Florida
4,Petr,Cvengros,Texas
{% endhighlight %}


One field has been added. From the above, the desired output is the following:

{% highlight ruby %}
Id,Name,State
1,Tomas Svarovsky,California
2,Petr Olmer,Washington
3,Pavel Kolesnikov,Florida
4,Petr Cvengros,Texas
{% endhighlight %}

Below, you can see how the ETL needs to be changed:

<div><img class="centered" src="https://dl.dropboxusercontent.com/s/okmhamd4egwjizg/CC-metadata-with-state.png?token_hash=AAFnNuvExkGCJbf7yesVCG8csAYRlC_8JnMtUXiQkT4I3A" >
</div>

In the above, all three need to be modified. In a much larger ETL, the number of modifications could be significantly higher and more complex. 

<div><img class="centered" src="https://dl.dropboxusercontent.com/s/pzo2up36t5gur0a/BAM-metadata.png?token_hash=AAFyq-85q92IQvfG-cfwFkw_kRBTzgEKdACncNar9aIolQ" >
</div>

In DFD, you define in the source the fields that are expected. In the mapper, you identify the following: 
<pre>Name=FirstName + LastName</pre>

However, no mapping is provided between Id and ID. Instead, you can use the following syntax to map input names as the output names:
<pre>*=*</pre>

In the flow, you define the metadata, as an incremental change from the previous step. This metadata specifies that FirstName and LastName are going to be removed, with Name added as a new field. When the changes are applied:

<div><img class="centered" src="https://dl.dropboxusercontent.com/s/tvb6hm4lea6fh28/BAM-metadata-with-state.png?token_hash=AAFXX8TfSKU5D--ZwxInTQ1GYqKv0KtbgsVbW5s7tzKwdw" >
</div>

In the above, the initial definition of the input is specified. Since it is not defined within the specific flow, you do not need to modify the flow definition, which reduces the chances of causing an issue.

<h3>Typing</h3>

Built on Java, the CloudConnect engine utilizes statically typing, and its internal CTL transformation language shares similarities with Java, too. 

Static type checks can prevent errors, which are generally understood. However, in the following areas, they may be problematic:

<ul>
  <li>In some ETL projects in CloudConnect, you must convert from one type to another because the component expects data in a specific format. This tedious problem is local to specific components. 
  </li>
  <li>Typing in CloudConnect replicates ETL for BI application. Types common in the BI world, like fact and attribute, are part of the CloudConnect specification.
  </li>
</ul>

In BAM, all data is treated as string data. While some conversion tasks may be required to get your data into strings, your data is in a consistent format throughout the ETL process, and common CloudConnect data conversions are hidden in BAM.

<h3>Speed</h3>

BAM has been designed under the <a href="http://c2.com/cgi/wiki?MakeItWorkMakeItRightMakeItFast">"Make it work make it right make it fast"</a> principles. 

So far, BAM has performed well in small- to medium-sized projects, up to millions of rows. Some accelerations have been applied without breaking any abstractions. Performance improvements are being consistently applied to the toolset. 

Over time, BAM will be tested and improved on larger and larger projects, as we move the envelope of how big projects can be successfully done with BAM! and the ecosystem of these tools that it surrounds. Please provide feedback on how BAM can be enhanced. 

</div>
</div>