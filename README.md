# BrowserCore

How can one record history using the UIWebView or the WKWebView? Here I attempt to show one way that can be done. 

## Idea 

Both webviews keep a list of the back and forward items. These items can be seen as history entries. The key idea is to map this list of back and forward items to a general history list.
