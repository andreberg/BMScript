Introduction
------------

BMScript is an Objective-C class set to make it easier to utilize the power and flexibility of a whole range of scripting languages that already come with modern Macs.  

BMScript does not favor any particular scripting language or UNIX™ command line tool for that matter, instead it was written as an abstraction layer to NSTask, and as such supports any command line tool, provided that it is available on the target system.

It provides support for launching scripts in a **blocking** (e.g. wait and block until the script has finished running) or **non-blocking** (e.g. asynchroneously in the background) execution mode just like NSTask does.   
Except you don't have to deal with all the subtleties that come with setting an NSTask up for background execution. 

Features
--------

In a nutshell BMScript sports the following features:

* Abstract interface to NSTask, dealing with language terms more suitable to scripters

* Supports blocking and non-blocking execution

* Each instance of BMScript caches script sources and the associated execution results

* NSTasks are normally not for re-use, but BMScript instances are re-usable (with or without alternating their script source)

* Supports a simple templating system (saturate tokens by positional or by keyword arguments)

* Provides extensive delegated customization (for things like validation)

* Easy to subclass when you need more extensive validation (for example, script sources come from endusers of your app).
  Details provided by a very simple protocol.

* Fully documented (uses a customizexd Doxygen template, resulting in a Xcode searchable DocSet)

* Support for DTrace/Instruments probes.

* Works with 10.5 and 10.6, 32 and 64-bit, with or without GC.

There are also some caveats:

* The initial code base comes from a while back from my very first attempt to write a "real world" Objective-C class

* BMScript is not threadsafe (yet). There is a define BMSCRIPT_THREAD_SAFE which if true employs locks in critical sections of the code and also sets BM_ATOMIC to true which in turn makes all the accessor methods atomic. But this is not really tested code! 
  For example stuff that deals with the instance local execution history could cause race conditions if two threads would try to access the execution result on the same instance at the same time.

* I tested what I could with the tools I have available (e.g. xcode + gdb, caveman debugging, dtrace, instruments) 
  but to date it hasn't been used in heavyweight code.

* Therefore: **Use at your own risk!** I'm just throwing it out there for whomever might find it useful.

  

Usage
-----

1. Add BMScript.m/.h to your project

2. Add BMScriptDefines.h to your project

3. Import BMScript.h in anywhere needed in your project.

4. If you do not want to use the dTrace probes leave BMSCRIPT_ENABLE_DTRACE at 0.
   If you _do_ however need the dTrace probes set the define to 1 and add the BMScriptProbes.d dTrace script to your Compile Sources phase.
   Xcode should automatically generate BMScriptProbes.h from that D script. If it doesn't, you can either use BMScriptProbes.h from this BMScript project or add a Run Script phase with the following code

        echo "Generating header files for dtrace probes matching pattern ${PROJECT_DIR}/DTrace/Probes/*Probes.d"
        dtrace -h -s "${PROJECT_DIR}"/DTrace/Probes/*Probes.d -o "${PROJECT_DIR}"/DTrace/Probes/BMScriptProbes.h
        
    Of course the run script phase has to come first before the compilation of your real app sources (drag it to the top of target build phases list).

5. Details on how to fully utilize BMScript can be found in it's documentation.

  
Acknowledgements
----------------

[RegexKit Framework](http://regexkit.sourceforge.net "RegexKit Framework Home Page")

I learnt a lot from being able to browse the source of this fantastic framework.  
Thanks a lot to John Engelhart 

License
-------

    Licensed under the Apache License, Version 2.0 (the "License");  
    you may not use this file except in compliance with the License.  
    You may obtain a copy of the License at  

      http://www.apache.org/licenses/LICENSE-2.0  

    Unless required by applicable law or agreed to in writing, software  
    distributed under the License is distributed on an "AS IS" BASIS,  
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  
    See the License for the specific language governing permissions and  
    limitations under the License.  

Copyright
---------

Copyright © 2009-2010, Andre Berg (Berg Media).  
All rights reserved.
