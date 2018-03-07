# BrowserCore

This is a full functional browser. It includes, tabs/private tabs, history and back and forward, along with the UI necessary for these features. 

## Why should you look into it?

If you are interested in recording history using the UIWebView or the WKWebView, here I attempt to show one way that can be done. Also, maybe you want to see how you can build a browser. This might help you get the idea. 

## Idea 

Both webviews keep a list of the back and forward items. These items can be seen as history entries. The key idea is to map this list of back and forward items to a general history list.
