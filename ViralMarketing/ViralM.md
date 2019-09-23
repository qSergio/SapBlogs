---
title: "Viral Marketing"
author: "Sergio Nieto"
date: "21/9/2019"
output: 
  html_document:
    keep_md: true
---

<div class="jive-rendered-content"><p>Social Network Analysis (SNA) is a fundamental research field and the problem of finding the optimal strategy for the spread of information, in our case over an entire community inside the network, is called Viral Marketing.</p><p></p><p>Data scientists know that some of the key factors for an idea to go viral are: the rate at which people become &#8220;infected&rdquo;, the &#8220;connectedness&rdquo; of the network and how a target group of individuals, called &#8220;seed&rdquo;, who first become infected, are linked to the rest. This elements distinguish the networks you want to study but are not the only ones.</p><p></p><p>Our results are based on a &#8220;tipping model&rdquo; proposed by Shakarian et. Al [1]. They have found a way to identify a seed group that can spread a message across a network. For very large networks we have chosen the integration of SAP HANA with R as a useful research and development tool.</p><p></p><p>As the authors point out: &#8220;The problem is NP-Complete so approximation algorithms must be used&rdquo;. The method is based on the idea that an individual will eventually receive your information if a certain proportion of his or her friends already have that message. This proportion is called the &#8220;threshold&rdquo; and is a crucial parameter in the model. The next step is to examine the network and look for all those individuals who have more friends than this critical number and then remove those who exceed the threshold by the largest amount. Repeating this process leaves us with a group of people in the network who have more friends than the threshold. When this happens, whoever is left is the seed group. In the paper the authors also investigate the limitations of the tipping model, so this must be taken into account.</p><p></p><p>This is a simple-to-code way to find a set of nodes that causes the entire population to activate - but it is not necessarily of minimal size.</p><p></p><p>We have tested the algorithm in well known networks to see how it works. Integration of R with SAP HANA is crucial for optimization. Our examples come from the Stanford Large Network Dataset Collection [2]. 


The algorithm performs very well:</p><p></p><pre class="language-sql"><code>
--TippingImplementationOnSQLAndR
--Copyright (C) 2014 Sergio Samuel Nieto Mej&iacute;a
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU General Public License as published by
--the Free Software Foundation, either version 3 of the License, or
--(at your option) any later version.
--This program is distributed in the hope that it will be useful
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
--GNU General Public License for more details.
--You should have received a copy of the GNU General Public License
--along with this program. If not, see &lt;http://www.gnu.org/licenses/&gt;.
CREATE PROCEDURE schema.VIRALMarketing
(IN initial_data schema.Data, OUT viral_nodes schema.Data)
LANGUAGE RLANG SQL SECURITY INVOKER
AS BEGIN
tipp_model &lt;- function(Edges_Data, threshold){
&nbsp; library(igraph)
&nbsp; graph_Data &lt;- graph.data.frame(d=Edges_Data,directed=T)
Edges_Data[,1]&lt;-as.character(Edges_Data[,1])
&nbsp; Edges_Data[,2]&lt;-as.character(Edges_Data[,2])
&nbsp; inner_degree &lt;- degree(graph_Data, mode= "in", loops=T)
&nbsp; outer_degree &lt;- degree(graph_Data, mode="out", loops=T)
&nbsp; k &lt;- threshold*inner_degree
&nbsp; k2&lt;- threshold*outer_degree
&nbsp; dist_in &lt;- inner_degree - k
&nbsp; dist_out &lt;- outer_degree - k2
&nbsp; node_list &lt;- data.frame(d_in=dist_in, d_out=dist_out)
&nbsp; while (any(node_list$d_in&gt;=0)){
&nbsp;&nbsp;&nbsp; non &lt;- node_list$d_in&gt;=0
&nbsp;&nbsp;&nbsp; min_val &lt;- min(node_list$d_in[non])
&nbsp;&nbsp;&nbsp; remove &lt;- node_list$d_in==min_val
&nbsp;&nbsp;&nbsp; neigh &lt;- row.names(node_list[remove,])
&nbsp;&nbsp;&nbsp; m &lt;- Edges_Data[Edges_Data$[,2] %in% neigh,]
m$V1 &lt;- as.character(m$V1)
&nbsp;&nbsp;&nbsp; m$V2 &lt;- as.character(m$V2)
&nbsp;&nbsp;&nbsp; node_list &lt;- node_list[!remove,]
if (nrow(m)&gt;0){
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; m1 &lt;- m[1]
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; no_neg &lt;- m1[m1&gt;0]
&nbsp;&nbsp;&nbsp;&nbsp; neg &lt;- m1[m1&lt;=0]
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; node_list$d_in[row.names(node_list) %in% neg] &lt;- -Inf
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; node_list$d_in[row.names(node_list) %in% no_neg] &lt;- node_list$d_in[row.names(node_list) %in% no_neg]-1
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; }
&nbsp;
&nbsp; }
&nbsp; viral_nodes&lt;- rownames(node_list)
&nbsp; return(viral_nodes)
}
result &lt;- tipp_model(data,0.8)
resulting_viral_nodes &lt;- data.frame(A=result,B=result)
END;


</code></pre><p></p><p>1.- On the Facebook social network we analyzed a small network with 4,039 nodes and 88,234 edges and obtained the result:<span style="font-size: 10pt"> 170 viral nodes</span></p><p></p><p>2.- On the Twitter social network we analyzed a network with 70,097 nodes and 2,420,766 edges and obtained the result:<span style="font-size: 10pt"> 942 viral nodes</span></p><p></p><p>3.- On data crawled over the Amazon website we analyzed a product co-purchasing network with 403,394 nodes and 3,387,388 edges and obtained the result:<span style="font-size: 10pt"> 193,743 viral nodes</span></p><p></p><p>4.- On the Google+ social network we analyzed a network with 72,271 nodes and 30,494,866 edges and obtained the result:<span style="font-size: 10pt"> 2,496 viral nodes</span></p><p></p><p>(In all the networks we assume that the threshold value is 80% of the node degree, so the viral nodes are a small set in all networks)</p><p></p><p>We observe that the seed group scales with the size of the dataset almost linearly, but also processing time increases. Many of the datasets we used are very simple and not highly clustered, so the result is a very small seed set. In a future post we'll work on different applications of this implementation and improve the algorithm for better performance for high-clustered networks. The important conclusion is that R implementation with SAP HANA greatly improves efficiency and consistency of our data science algorithms.</p><p></p><p></p><p>REFERENCES</p><p></p><p></p><p>1. <a class="jive-link-external-small" href="http://arxiv.org/abs/1309.2963">[1309.2963] A Scalable Heuristic for Viral Marketing Under the Tipping Model</a></p><p><span>2. Leskovec, J.: Stanford network analysis project (SNAP) (2012). URL </span><a class="jive-link-external-small" href="http://snap.stanford.edu/index.html">http://snap.stanford.edu/index.html</a></p></div>

