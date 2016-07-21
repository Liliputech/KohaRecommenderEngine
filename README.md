# KohaReadSuggestion

This Koha Plugin is an attempt at creating a "crowd-sourced" suggestion engine.<br>
For a given Biblionumber reference it gives the 10 top issued references.<br>
Similar references are then linked to each others by patron issues.<br>

## To install the plugin
First you have to modify koha-conf.xml and set enableplugins to 1 (it is set to 0 by default).<br>
Then check in Koha Administration panel, search for the UseKohaPlugins variable, and set this to Enable.<br>
Finally go to the Reports panel and click on "Report Plugins".
On the top left corner you'll see an "Upload a plugin" link, which will enable you to install the KPZ file.

## How to use
Easy!
Click on "Run report" and type in a biblionumber.
You'll then get a rewarding list of references which were top issued by patrons.
Also results are filtered by their "statisticvalue" because we use this in my Library to fill in subject details (Geography, History, Social Science, etc...)

## To Do
-Integrate into Opac
-Fasten/Optimize query
