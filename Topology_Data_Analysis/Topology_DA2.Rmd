---
title: "Topology_DA2"
author: "Sergio Nieto"
date: "21/9/2019"
output: 
  html_document:
    keep_md: true
---

In this second part <strong>[1]</strong>, we use Topological Data Analysis (<strong>TDA</strong>) on a dataset consisting on spatial information related to traffic <strong>[3]</strong>. We'll compare to usual "<i>DBSCAN</i>" method from Machine Learning.

DBSCAN is a method for finding clusters in data. It means Density-Based Spatial Clustering of Applications with Noise. It usually<span style="font-size: 1rem"> requires two parameters and the data: a radius, known as <em>eps,</em> and the minimum number of points required to form a cluster, that is the "density" part. </span>

In any case, the parameters are unknown a priori. TDA in this case can help giving connected components as initial election of clusters and also, being robust against noise, these clusters will persist.

And a quick visualization of the dataset can be helpful for comparing these methods:

&nbsp;

<img src="https://blogs.sap.com/wp-content/uploads/2017/12/id2022_vis.png" width="707" height="364" />

&nbsp;

We can inmediately see some clusters given by traffic in this trajectory. The data is nested in a small range so the radius is gonna be 0.0005 and the minimal number of points we set it to 3 so that we can keep close gps positions.

&nbsp;
<pre class="language-sql"><code>-- In the standard PAL procedure we introduce the parameters we defined:
INSERT INTO DB_PARAMS VALUES ('THREAD_NUMBER', 2, null, null);
INSERT INTO DB_PARAMS VALUES ('DISTANCE_METHOD', 2, null, null);
INSERT INTO DB_PARAMS VALUES ('MINPTS', 3, null, null); 
INSERT INTO DB_PARAMS VALUES ('RADIUS', null, 0.0005, null); 
-- Remeber to call this procedure using a predefined view.
CALL _SYS_AFL.PAL_DB (DB_DATA, DB_PARAMS, DB_RESULTS) WITH OVERVIEW;</code></pre>
&nbsp;

The results can be visualized in <strong>R</strong> with the "dbscan" package and a very interesting idea that lets you see the convex hull of the clusters:

&nbsp;

<img src="https://blogs.sap.com/wp-content/uploads/2017/12/convex1.png" />

&nbsp;

We can see that the <em>eps</em> was too small and the algorithm detected to many clusters but it kept the ones corresponding to traffic. Taking a bigger parameter we can find better results:

&nbsp;

<img src="https://blogs.sap.com/wp-content/uploads/2017/12/convex2.png" />

&nbsp;

So the algorithm finds the traffic but it's sensitive to noise induced by the size of the eps and the fact that gps positions are not nicely distributed. So, to make a better approximation we turn to Topological Data Analysis expecting 4 clusters or more, but as connected components.

&nbsp;
<pre class="language-sql"><code>DROP PROCEDURE "TDA";
-- procedure with R script using TDA package
CREATE PROCEDURE "TDA" (IN gps_data "GPS_DATA", OUT persistence "PERSISTENCE")
LANGUAGE RLANG AS 
BEGIN
library(TDA)
persist &lt;- function(gps_data){
    #You can find how to construct this example in TDA package documentation

    gps_vector &lt;- cbind("V1" = gps_data$longitude, "V2" = gps_data$latitude)
    xlimit &lt;- c(-37.1, -37.0)
    ylimit &lt;- c(-11.0, -10.8)
    by &lt;- 0.0002
    x_step &lt;- seq(from = Xlim[1], to = Xlim[2], by = by)
    y_step &lt;- seq(from = Ylim[1], to = Ylim[2], by = by)
    grid &lt;- expand.grid(x_step, y_step)
    diag &lt;- gridDiag(X = gps_vector, FUN = distFct, lim = cbind(xlimit, ylimit), by = by,
                 sublevel = FALSE, library = "Dionysus", printProgress = FALSE)
    # Since gridDiag returns a list, we access this in any way we want:
    diagram &lt;- Diag[["diagram"]]
    topology &lt;- data.frame(cbind("dimension"=a[,1],"death"=a[,2],"birth"=a[,3]))
    return(topology)
    }
# Use the function
persistence &lt;- persist(gps_data)
END;
-- call to keep results in a table
CALL "TDA" ("VEHIC_DATA", "PERSISTENCE") WITH OVERVIEW;</code></pre>
&nbsp;

And the resulting <strong>barcode</strong> is the following:

&nbsp;

<img src="https://blogs.sap.com/wp-content/uploads/2017/12/tracks_barcode_0002.png" />

This is a very good result, we can explore datasets related to traffic by looking at its topological properties and extract information relevant to us, these are topological features. After finding these we can take a look at other tools in machine learning to have more detailed information.
<blockquote>In this case, topological information plays a crucial role since it gives geometric insight to start our research, it is a frame for machine learning and gives us mathematical support for the choice of the parameters usually given by a rule of thumb.</blockquote>
Topology has a big part to play in the development of Machine Learning in general and many different ideas are being explored, not only persistent homology <strong>[4]</strong>. Also, we are currently working on new applications of this tool <strong>[2]</strong>, so #KeepTheThread.

&nbsp;

<strong>References</strong>

1. <a href="https://blogs.sap.com/2017/12/14/using-topology-for-data-analysis/">https://blogs.sap.com/2017/12/14/using-topology-for-data-analysis/</a>

2. Otter, Nina; Porter, Mason A.; Tillmann, Ulrike; Grindrod, Peter; Harrington, Heather A. (2015-06-29). "<em>A roadmap for the computation of persistent homology</em>". <strong>arXiv:1506.08903</strong>

3. <a href="https://archive.ics.uci.edu/ml/datasets.html">https://archive.ics.uci.edu/ml/datasets.html</a>

4. <a href="https://arxiv.org/pdf/1609.08227.pdf">https://arxiv.org/pdf/1609.08227.pdf</a>

