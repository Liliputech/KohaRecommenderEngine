# KohaRecommenderEngine

This Koha Plugin is an attempt at creating a "crowd-sourced" recommendation engine.<br>
At the time of writing it is a collaborative-filtering based recommender system.<br>
Similar references are linked to each others by patron issues.<br>
It can easily be extended to support content based filters as well (have a look at the code).<br>

## How it works?
I made this little sketch to try to explain things.
![How it works](recommendationsSketch.png)

## Want to learn more about Recommender Systems?
Here is a list of links about the theory beyond the code :
 * https://en.wikipedia.org/wiki/Recommender_system
 * https://en.wikipedia.org/wiki/Collaborative_filtering
 * http://ijcai13.org/files/tutorial_slides/td3.pdf
 * http://em.iism.kit.edu/research/projects/reckvk/index.php?language=en&id=Summary
 * https://core.ac.uk/display/19915480
 * http://onlinelibrary.wiley.com/doi/10.1002/meet.2011.14504801289/full
 * http://www.dlib.org/dlib/may08/monnich/05monnich.html
 * http://dl.acm.org/citation.cfm?doid=2637002.2637015

## To install the plugin
First you have to modify koha-conf.xml and set enableplugins to 1 (it is set to 0 by default).<br>
Then check in Koha Administration panel, search for the UseKohaPlugins variable, and set this to Enable.<br>
Finally go to the Reports panel and click on "Report Plugins".<br>
On the top left corner you'll see an "Upload a plugin" link, which will enable you to install the KPZ file.<br>

## Integration to OPAC
To document...

```
```

## How to use
Easy! Click on "Run report" and type in a biblionumber.<br>
You'll then be rewarded by a list of references which were top issued by patrons.<br>

## To Do
-Integrate into Opac (in progress!)<br>
-Fasten/Optimize query<br>
-Any other idea is welcome<br>

## Greetings
- Mr Kyle Hall who developped Koha Plugin functionnality and provided the community with running examples.
- Lyon 3 Koha Team for their "knowledge sharing" values and for giving me the necessary pre-requisite for having fun while coding in Perl and JS.
