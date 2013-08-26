
The core anlua code https://bitbucket.org/xixs/anlua although this was
originally designed and implimented on top of app engine it has slowly
shifted into an nginx and openresty based web framework.

Google App Engine probably still works, but I no longer care. Sorry
but it makes more sense to fire up an amazon instance and run the nginx
version. Even in its currently hacked together state it's more stable
and delivers faster responses for any medium size website.

Yeah it don't scale but I will welcome that problem when I hit it. :)

Actually I figure amazon is too expensive but you get the idea.

The old appengine code has been removed to reduce confusion, as I am 
no longer interested in even testing if it still works. Either look 
in the history of this project or visit the old google code 
repository at

https://code.google.com/p/aelua/


The basic idea of anlua is producing a number of mods which are then 
stuck together on a single website (each one living at a different 
dir) depending on your needs. so for instance /thumbcache is where 
some simple image caching code for thumbnails exists. The main 
module is waka which is a wiki like html page creation/editing module.

Look inside the mods directory for more information about what each
module is trying to achieve and if it is a good idea to use it.

All of my websites are now contained within the apps/wet directory
with virtual hosts support to run different bits from different
domains. This is actually my live config, all secrets are added
via the website and the admin module.

Places to see this code run are...

http://gamecake.4lfa.com/
http://dime.lo4d.net/
http://hoe.4lfa.com/
http://4lfa.com/


Finally.

 All content is MIT licenesed unless explicitly stated otherwise.

 Copyright (c) 2010 www.wetgenes.com

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.

