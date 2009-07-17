# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.dirname(__FILE__) + "/../config/environment" unless defined?(RAILS_ROOT)
require 'spec/autorun'
require 'spec/rails'

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  # 
  # For more information take a look at Spec::Runner::Configuration and Spec::Runner
end




<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
        <title>spec at golden from pixels-and-bits's strappy - GitHub</title>
    <link rel="search" type="application/opensearchdescription+xml" href="/opensearch.xml" title="GitHub" />
    <link rel="fluid-icon" href="http://github.com/fluidicon.png" title="GitHub" />

    
      <link href="http://assets0.github.com/stylesheets/bundle.css?4e4549ef242cc20be2f40fdf0f47baaa74c05405" media="screen" rel="stylesheet" type="text/css" />
    

    
      
        <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>
        <script src="http://assets3.github.com/javascripts/bundle.js?4e4549ef242cc20be2f40fdf0f47baaa74c05405" type="text/javascript"></script>
      
    
    
  
    
  

  <link href="http://github.com/feeds/pixels-and-bits/commits/strappy/golden" rel="alternate" title="Recent Commits to strappy:golden" type="application/atom+xml" />

  <META NAME="ROBOTS" CONTENT="NOINDEX, FOLLOW">  <meta name="description" content="Bootstrap a Rails 2.3 app with user authentication (Authlogic, Clearance, restful_authentication)" />


    

    <script type="text/javascript">
      github_user = null
    </script>
  </head>

  

  <body>
    

    <div id="main">
      <div id="header" class="">
        <div class="site">
          <div class="logo">
            <a href="http://github.com"><img src="/images/modules/header/logov3.png" alt="github" /></a>
          </div>
          
            <div class="topsearch">
  <form action="/search" id="top_search_form" method="get">
    <input type="search" class="search" name="q" /> <input type="submit" value="Search" />
    <input type="hidden" name="type" value="Everything" />
    <input type="hidden" name="repo" value="" />
    <input type="hidden" name="langOverride" value="" />
    <input type="hidden" name="start_value" value="1" />
  </form>
  <div class="links">
    <a href="/repositories">Browse</a> | <a href="/guides">Guides</a> | <a href="/search">Advanced</a>
  </div>
</div>
          
          
            <div class="actions">
              <a href="http://github.com">Home</a>
              <a href="/plans"><b><u>Pricing and Signup</u></b></a>
              <a href="http://github.com/popular/forked">Repositories</a>
              
              <a href="/blog">Blog</a>
              <a href="https://github.com/login">Login</a>
            </div>
          
        </div>
      </div>

      
        
    <div id="repo_menu">
      <div class="site">
        <ul>
          
            <li class="active"><a href="http://github.com/pixels-and-bits/strappy/tree/golden">Source</a></li>

            <li class=""><a href="http://github.com/pixels-and-bits/strappy/commits/golden">Commits</a></li>

            
            <li class=""><a href="/pixels-and-bits/strappy/network">Network (15)</a></li>

            

            
              
              <li class=""><a href="/pixels-and-bits/strappy/issues">Issues (0)</a></li>
            

            
              
              <li class=""><a href="/pixels-and-bits/strappy/downloads">Downloads (0)</a></li>
            

            
              
              <li class=""><a href="http://wiki.github.com/pixels-and-bits/strappy">Wiki (1)</a></li>
            

            <li class=""><a href="/pixels-and-bits/strappy/graphs">Graphs</a></li>

            

          
        </ul>
      </div>
    </div>

  <div id="repo_sub_menu">
    <div class="site">
      <div class="joiner"></div>
      

      

      

      
        <ul>
          <li>
            <a class="active" href="/pixels-and-bits/strappy/tree/golden">golden</a>
          </li>
          <li>
            <a href="#">all branches</a>
            <ul>
              
                
                  <li><a href="/pixels-and-bits/strappy/tree/authlogic">authlogic</a></li>
                
              
                
                  <li><a href="/pixels-and-bits/strappy/tree/choosy">choosy</a></li>
                
              
                
                  <li><a href="/pixels-and-bits/strappy/tree/golden">golden</a></li>
                
              
                
                  <li><a href="/pixels-and-bits/strappy/tree/master">master</a></li>
                
              
                
                  <li><a href="/pixels-and-bits/strappy/tree/restful_authentication">restful_authentication</a></li>
                
              
            </ul>
          </li>
          <li>
            <a href="#">all tags</a>
            
          </li>
        </ul>

      
    </div>
  </div>

  <div class="site">
    







<div id="repos">
  


<script type="text/javascript">
  GitHub.currentCommitRef = "golden"
  GitHub.currentRepoOwner = "pixels-and-bits"
  GitHub.currentRepo = "strappy"
  
</script>



  <div class="repo public" id="repo_details">
    <div class="title">
      <div class="path">
        <a href="/pixels-and-bits">pixels-and-bits</a> / <b><a href="http://github.com/pixels-and-bits/strappy/tree">strappy</a></b>

        

          <span id="edit_button" style="display:none;">
            <a href="/pixels-and-bits/strappy/edit"><img alt="edit" class="button" src="http://assets0.github.com/images/modules/repos/edit_button.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></a>
          </span>

          
            <span id="pull_request_button" style="display:none;">
              <a href="/pixels-and-bits/strappy/pull_request/" class="pull_request_button"><img alt="pull request" class="button" src="http://assets3.github.com/images/modules/repos/pull_request_button.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></a>
            </span>
            
            <span id="fast_forward_button" style="display:none;">
              <a href="/pixels-and-bits/strappy/fast_forward" id="ff_button"><img alt="fast forward" class="button" src="http://assets2.github.com/images/modules/repos/fast_forward_button.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></a>
            </span>

            <span id="fork_button">
              <a href="/pixels-and-bits/strappy/fork"><img alt="fork" class="button" src="http://assets3.github.com/images/modules/repos/fork_button.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></a>
            </span>
          

          <span id="watch_button">
            <a href="/pixels-and-bits/strappy/toggle_watch" class="toggle_watch"><img alt="watch" class="button" src="http://assets3.github.com/images/modules/repos/watch_button.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></a>
          </span>
          
          <span id="unwatch_button" style="display:none;">
            <a href="/pixels-and-bits/strappy/toggle_watch" class="toggle_watch"><img alt="watch" class="button" src="http://assets2.github.com/images/modules/repos/unwatch_button.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></a>
          </span>

          
            <a href="#" id="download_button" rel="pixels-and-bits/strappy"><img alt="download tarball" class="button" src="http://assets1.github.com/images/modules/repos/download_button.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></a>
          
        
      </div>

      <div class="security private_security" style="display:none">
        <a href="#private_repo" rel="facebox"><img src="/images/icons/private.png" alt="private" /></a>
      </div>

      <div id="private_repo" class="hidden">
        This repository is private.
        All pages are served over SSL and all pushing and pulling is done over SSH.
        No one may fork, clone, or view it unless they are added as a <a href="/pixels-and-bits/strappy/edit">member</a>.

        <br/>
        <br/>
        Every repository with this icon (<img src="/images/icons/private.png" alt="private" />) is private.
      </div>

      <div class="security public_security" style="">
        <a href="#public_repo" rel="facebox"><img src="/images/icons/public.png" alt="public" /></a>
      </div>

      <div id="public_repo" class="hidden">
        This repository is public.
        Anyone may fork, clone, or view it.

        <br/>
        <br/>
        Every repository with this icon (<img src="/images/icons/public.png" alt="public" />) is public.
      </div>

      

        <div class="flexipill">
          <a href="/pixels-and-bits/strappy/network">
          <table cellpadding="0" cellspacing="0">
            <tr><td><img alt="Forks" src="http://assets0.github.com/images/modules/repos/pills/forks.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></td><td class="middle"><span>15</span></td><td><img alt="Right" src="http://assets1.github.com/images/modules/repos/pills/right.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></td></tr>
          </table>
          </a>
        </div>

        <div class="flexipill">
          <a href="/pixels-and-bits/strappy/watchers">
          <table cellpadding="0" cellspacing="0">
            <tr><td><img alt="Watchers" src="http://assets3.github.com/images/modules/repos/pills/watchers.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></td><td class="middle"><span>74</span></td><td><img alt="Right" src="http://assets1.github.com/images/modules/repos/pills/right.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /></td></tr>
          </table>
          </a>
        </div>
      </div>

    <div class="meta">
      <table>
        
        <tr>
          <td class="label">Description:</td>
          <td>
            <span id="repository_description" rel="/pixels-and-bits/strappy/edit/update">Bootstrap a Rails 2.3 app with user authentication (Authlogic, Clearance, restful_authentication)</span>
            <a href="#description" class="edit_link action" style="display:none;">edit</a>
          </td>
        </tr>

        
            <tr>
              <td class="label">Homepage:</td>
              <td>
                                
                <span id="repository_homepage" rel="/pixels-and-bits/strappy/edit/update">
                  <a href="http://"></a>
                </span>
                <a href="#homepage" class="edit_link action" style="display:none;">edit</a>
              </td>
            </tr>

          
            <tr>
              <td class="label"><span id="public_clone_text" style="display:none;">Public&nbsp;</span>Clone&nbsp;URL:</td>
              
              <td>
                <a href="git://github.com/pixels-and-bits/strappy.git" class="git_url_facebox" rel="#git-clone">git://github.com/pixels-and-bits/strappy.git</a>
                      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
              width="110"
              height="14"
              class="clippy"
              id="clippy" >
      <param name="movie" value="/flash/clippy.swf"/>
      <param name="allowScriptAccess" value="always" />
      <param name="quality" value="high" />
      <param name="scale" value="noscale" />
      <param NAME="FlashVars" value="text=git://github.com/pixels-and-bits/strappy.git">
      <param name="bgcolor" value="#F0F0F0">
      <param name="wmode" value="opaque">
      <embed src="/flash/clippy.swf"
             width="110"
             height="14"
             name="clippy"
             quality="high"
             allowScriptAccess="always"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer"
             FlashVars="text=git://github.com/pixels-and-bits/strappy.git"
             bgcolor="#F0F0F0"
             wmode="opaque"
      />
      </object>

                <div id="git-clone" style="display:none;">
                  Give this clone URL to anyone.
                  <br/>
                  <code>git clone git://github.com/pixels-and-bits/strappy.git </code>
                </div>
              </td>
            </tr>
          
          
          <tr id="private_clone_url" style="display:none;">
            <td class="label">Your Clone URL:</td>
            
            <td>

              <div id="private-clone-url">
                <a href="git@github.com:pixels-and-bits/strappy.git" class="git_url_facebox" rel="#your-git-clone">git@github.com:pixels-and-bits/strappy.git</a>
                <input type="text" value="git@github.com:pixels-and-bits/strappy.git" style="display: none;" />
                      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
              width="110"
              height="14"
              class="clippy"
              id="clippy" >
      <param name="movie" value="/flash/clippy.swf"/>
      <param name="allowScriptAccess" value="always" />
      <param name="quality" value="high" />
      <param name="scale" value="noscale" />
      <param NAME="FlashVars" value="text=git@github.com:pixels-and-bits/strappy.git">
      <param name="bgcolor" value="#F0F0F0">
      <param name="wmode" value="opaque">
      <embed src="/flash/clippy.swf"
             width="110"
             height="14"
             name="clippy"
             quality="high"
             allowScriptAccess="always"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer"
             FlashVars="text=git@github.com:pixels-and-bits/strappy.git"
             bgcolor="#F0F0F0"
             wmode="opaque"
      />
      </object>

              </div>

              <div id="your-git-clone" style="display:none;">
                Use this clone URL yourself.
                <br/>
                <code>git clone git@github.com:pixels-and-bits/strappy.git </code>
              </div>
            </td>
          </tr>
          
          

          

          
      </table>

          </div>
  </div>






</div>


  <div id="commit">
    <div class="group">
        
  <div class="envelope commit">
    <div class="human">
      
        <div class="message"><pre><a href="/pixels-and-bits/strappy/commit/a04da2e2c093d735e393d61c7e898d71984d0570">update readme, have base exit with a message about moving the branch</a> </pre></div>
      

      <div class="actor">
        <div class="gravatar">
          
          <img alt="" height="30" src="http://www.gravatar.com/avatar/b6744f32209ffd0ad692936b4c10bf29?s=30&amp;d=http%3A%2F%2Fgithub.com%2Fimages%2Fgravatars%2Fgravatar-30.png" width="30" />
        </div>
        <div class="name"><a href="/UnderpantsGnome">UnderpantsGnome</a> <span>(author)</span></div>
          <div class="date">
            <abbr class="relatize" title="2009-05-15 19:44:00">Fri May 15 19:44:00 -0700 2009</abbr> 
          </div>
      </div>
  
      
  
    </div>
    <div class="machine">
      <span>c</span>ommit&nbsp;&nbsp;<a href="/pixels-and-bits/strappy/commit/a04da2e2c093d735e393d61c7e898d71984d0570" hotkey="c">a04da2e2c093d735e393d61c7e898d71984d0570</a><br />
      <span>t</span>ree&nbsp;&nbsp;&nbsp;&nbsp;<a href="/pixels-and-bits/strappy/tree/a04da2e2c093d735e393d61c7e898d71984d0570/public/stylesheets/sass" hotkey="t">71c30de50e3f70bd06ac694f2e87d4b553a461d1</a><br />
  
      
        <span>p</span>arent&nbsp;
        
        <a href="/pixels-and-bits/strappy/tree/acd641d8499f009ac4de5034be5984fbb80b521d/public/stylesheets/sass" hotkey="p">acd641d8499f009ac4de5034be5984fbb80b521d</a>
      
  
    </div>
  </div>

    </div>
  </div>



  
    <div id="path">
      <b><a href="/pixels-and-bits/strappy/tree">strappy</a></b> / spec
    </div>

    
      

  <script type="text/javascript">
    GitHub.currentTreeSHA = "bc86ea7df6f3669f4fb5b87752b7fda34e039e62"
    GitHub.commitSHA = "a04da2e2c093d735e393d61c7e898d71984d0570"
    GitHub.currentPath = "spec"
  </script>


<div id="browser">
  <table cellpadding="0" cellspacing="0">
    <tr>
      <th></th>
      <th>name</th>
      <th>age</th>
      <th>
        <div class="history">
          <a href="/pixels-and-bits/strappy/commits/golden/spec">history</a>
        </div>
        message
      </th>
    </tr>

    
      <tr class="alt">
        <td> </td>
        <td> <a href="/pixels-and-bits/strappy/tree/golden">..</a> </td>
        <td> </td>
        <td> </td>
      </tr>
    

    
      <tr class="">
        <td class="icon"> <img alt="directory" src="http://assets2.github.com/images/icons/dir.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /> </td>
        <td class="content"> <a href="/pixels-and-bits/strappy/tree/a04da2e2c093d735e393d61c7e898d71984d0570/spec/controllers" id="3fb196bbe81174dd0c4b74665eeb77dbd555967a">controllers/</a></td>
        
        <td class="age">  </td>
        <td class="message"> <span id="loading_commit_data">Loading commit data... <img src="/images/modules/ajax/indicator.gif"/></span> </td>
      </tr>
    
      <tr class="alt">
        <td class="icon"> <img alt="directory" src="http://assets2.github.com/images/icons/dir.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /> </td>
        <td class="content"> <a href="/pixels-and-bits/strappy/tree/a04da2e2c093d735e393d61c7e898d71984d0570/spec/fixtures" id="f17feda5c0b3d4fbe1078d5d2822854115e06c69">fixtures/</a></td>
        
        <td class="age">  </td>
        <td class="message">  </td>
      </tr>
    
      <tr class="">
        <td class="icon"> <img alt="directory" src="http://assets2.github.com/images/icons/dir.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /> </td>
        <td class="content"> <a href="/pixels-and-bits/strappy/tree/a04da2e2c093d735e393d61c7e898d71984d0570/spec/helpers" id="fec55350f73979e8b7bed666015f10d9999ea428">helpers/</a></td>
        
        <td class="age">  </td>
        <td class="message">  </td>
      </tr>
    
      <tr class="alt">
        <td class="icon"> <img alt="file" src="http://assets3.github.com/images/icons/txt.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /> </td>
        <td class="content"> <a href="/pixels-and-bits/strappy/blob/a04da2e2c093d735e393d61c7e898d71984d0570/spec/rcov.opts" id="e3c4573d9580f6ce5d8ec954a7aef838199baf0e">rcov.opts</a></td>
        
        <td class="age">  </td>
        <td class="message">  </td>
      </tr>
    
      <tr class="">
        <td class="icon"> <img alt="directory" src="http://assets2.github.com/images/icons/dir.png?4e4549ef242cc20be2f40fdf0f47baaa74c05405" /> </td>
        <td class="content"> <a href="/pixels-and-bits/strappy/tree/a04da2e2c093d735e393d61c7e898d71984d0570/spec/views" id="a3a0dabdf61dc14ac315de3d0f756938d5cead76">views/</a></td>
        
        <td class="age">  </td>
        <td class="message">  </td>
      </tr>
    
  </table>
</div>
    
    
  



  



  

  </div>

      

      <div class="push"></div>
    </div>

    <div id="footer">
      <div class="site">
        <div class="info">
          <div class="links">
            <a href="http://github.com/blog/148-github-shirts-now-available">Shirts</a> |
            <a href="http://github.com/blog">Blog</a> |
            <a href="http://support.github.com/">Support</a> |
            <a href="http://github.com/training">Training</a> |
            <a href="http://github.com/contact">Contact</a> |
            <a href="http://groups.google.com/group/github/">Google Group</a> |
            <a href="http://develop.github.com">API</a> |
            <a href="http://twitter.com/github">Status</a>
          </div>
          <div class="company">
            <span id="_rrt" title="0.06667s from xc88-s00009">GitHub</span>&trade;
            is <a href="http://logicalawesome.com/">Logical Awesome</a> &copy;2009 | <a href="/site/terms">Terms of Service</a> | <a href="/site/privacy">Privacy Policy</a>
          </div>
        </div>
        <div class="sponsor">
          <a href="http://engineyard.com"><img src="/images/modules/footer/ey-rubyhosting.png" alt="Engine Yard" /></a>
        </div>
      </div>
    </div>

    <div id="coming_soon" style="display:none;">
      This feature is coming soon.  Sit tight!
    </div>

    
        <script type="text/javascript">
    var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
    document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
    </script>
    <script type="text/javascript">
    var pageTracker = _gat._getTracker("UA-3769691-2");
    pageTracker._initData();
    pageTracker._trackPageview();
    </script>

    
  </body>
</html>

