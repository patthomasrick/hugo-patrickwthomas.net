---
title: "Using PyPy with Shared Hosting"
date: 2020-08-15T13:58:28-04:00
draft: false
---

[HostGator](https://www.hostgator.com/), the people who host this website, offer a shared hosting plan. This plan has several distinct advantages in that getting started is very easy as well as hosting and domain name registration is relatively cheap, especially for long term plans. However, this comes at the cost of customization, especially with regards to the software the comes installed. At the time of writing, the newest version of PHP available on a shared plan is PHP 7.1.14, which came out in early 2018. This is still usable by all means, however, installing the newest frameworks and plugins can be painful. This also applies to Python, where the newest versions of Python 2 and 3 installed are versions 2.6.6 and 3.2.3 respectively. This presents challenges when you want to use the most up-to-date and shiny software, and this is compounded by the fact that you can’t directly install Python or anything needed to build Python (ruling out solutions like [pyenv](https://github.com/pyenv/pyenv)). However, I was able to get a version of [PyPy](https://www.pypy.org/) working on a shared server environment and serving a simple [Flask](https://flask.palletsprojects.com/en/1.1.x/) webpage.

# Introduction

The approach that I used was to get PyPy working on a local machine, and then I copied all of the PyPy files (along with its necessary libraries) to the shared server. **Note that this tutorial assumes you are working in Linux and have a Linux shared hosting server.** You might have to get a VirtualMachine running with some recent desktop version of Linux, like Ubuntu or Manjaro.

First, I downloaded PyPy from PyPy’s website: <https://www.pypy.org/download.html#python-3-6-compatible-pypy3-6-v7-3-1>. At the time of writing, this happened to be PyPy3.6 v7.3.1, and you need to get a version that you will run on your server. Thus, since my shared hosting server ran x86-64 Linux, I downloaded the x86-64 version of PyPy.

Next, untar the PyPy binaries into some directory:

```sh
cd ~/Downloads # or wherever you downloaded the PyPy tarball
tar xvf "pypy3.6-v7.3.1-linux64.tar.bz2"
```

For me, this creates a new directory pypy3.6-v7.3.1-linux64. Ensure that PyPy downloaded correctly and has all of the necessary libraries by running PyPy:

```sh
pypy3.6-v7.3.1-linux64/bin/pypy3
```

Which should give you an interactive Python prompt like below:

```
Python 3.6.9 (2ad108f17bdb, Apr 07 2020, 02:59:05)
[PyPy 7.3.1 with GCC 7.3.1 20180303 (Red Hat 7.3.1-5)] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>>
```

Now that we have verified that this works, we can now copy over the files. This can be done one of two ways: `scp` or `tar` then `scp`. I will do this via `tar` and `scp`. However, you can skip the `tar` portion if wanted.

```sh
tar cvfh pypy.tar pypy3.6-v7.3.1-linux64 # creates a tar archive named 
# pypy.tar that contains all of the pypy files, INCLUDING DEREFERENCED 
# SYMLINKED FILES
scp pypy.tar username@yourhost.com:~/ # copies pypy.tar to your 
# remote home directory
ssh username@yourhost.com
tar xvf pypy.tar # extract pypy
```

Now PyPy should be extracted to your home directory. Next, you’ll want to add PyPy to your `PATH`. For bash, which is what HostGator uses, I will add the following paths to my `PATH`:

```sh
export PATH="$PATH:$HOME/.pypy/bin:$HOME/.local/bin"
```

This will add both PyPy as well as any install pip packages to your PATH.
Now, after closing your SSH session and SSHing back in, you can test PyPy and install Flask:

```sh
pypy3 --versionpypy3 -m pip install flask --user # forces usage of pypy's pip
```

# Configuring Flask

Now since Flask is installed, we can configure a simple web service that employs Flask. First, get a simple Flask app from their own [getting started tutorial](https://flask.palletsprojects.com/en/1.1.x/quickstart/#a-minimal-application):

```py
from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello_world():
    return 'Hello, World!'
```

I named this file `app.py` and placed in my (now empty) `public_html`, or whatever is the front-facing public folder that is served at your address. Now we need to configure a CGI file, and I did this following another Flask tutorial. I created a file named `app.cgi` and placed the following inside:

```py
#!/path/to/.pypy/bin/pypy3
from wsgiref.handlers import CGIHandler
from app import app
CGIHandler().run(app)
```

Lastly, create a `.htaccess` file with the following contents that is also from the tutorial:

```
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f # Don't interfere with static files
RewriteRule ^(.*)$ /path/to/public_html/app.cgi/$1 [L]
```

# Ending Remarks

You’ll want to add a lot more to your `.htaccess` if you want to use this seriously; the current `.htaccess` file allows for direct access to your code, which you may not want.

I think it would be possible to also use Django in this way, and I definitely know it is possible to install Django through PyPy’s `pip`, start a project with `django-admin startproject myapp`, and then run that Django project in a development setting. However, how that would work with CGI is left as an exercise to the reader (HostGator does not support WSGI, so you would have to patch support for FastCGI back into Django).
