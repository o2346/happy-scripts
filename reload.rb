#!/usr/bin/env ruby
# watch.rb by Brett Terpstra, 2011 <http://brettterpstra.com>
# with credit to Carlo Zottmann <https://github.com/carlo/haml-sass-file-watcher>
#s022 tmp.PDljJ4Zk% osascript -e \
#'tell application "Safari" to set URL of current tab of front window to "file:///foo.html"'
# https://coderwall.com/p/wkz4cq/reload-current-browser-tab-from-the-terminal
# https://brettterpstra.com/2011/03/07/watch-for-file-changes-and-refresh-your-browser-automatically/
# https://stackoverflow.com/questions/5588658/auto-reload-browser-when-i-save-changes-to-html-file-in-chrome
trap("SIGINT") { exit }

if ARGV.length < 2
  puts "Usage: #{$0} watch_folder keyword"
  puts "Example: #{$0} . mywebproject"
  exit
end

dev_extension = 'dev'
filetypes = ['css','html','htm','php','rb','erb','less','js']
watch_folder = ARGV[0]
keyword = ARGV[1]
puts "Watching #{watch_folder} and subfolders for changes in project files..."

while true do
  files = []
  filetypes.each {|type|
    files += Dir.glob( File.join( watch_folder, "**", "*.#{type}" ) )
  }
  new_hash = files.collect {|f| [ f, File.stat(f).mtime.to_i ] }
  hash ||= new_hash
  diff_hash = new_hash - hash

  unless diff_hash.empty?
    hash = new_hash

    diff_hash.each do |df|
      puts "Detected change in #{df[0]}, refreshing"
      %x{osascript << ENDGAME
        tell application "Google Chrome"
          set windowList to every window
          repeat with aWindow in windowList
            set tabList to every tab of aWindow
            repeat with atab in tabList
              if (URL of atab contains "#{keyword}") then
                tell atab to reload
              end if
            end repeat
          end repeat
        end tell
        tell application "Google Chrome"
          delay 5
          activate
          tell application "System Events"
            tell process "Google Chrome"
              keystroke "r" using {command down, shift down}
            end tell
          end tell
        end tell
        tell application "Terminal" to activate
ENDGAME
      }
    end
  end

  sleep 1
end
#       tell application "Google Chrome"
#         reload active tab of window 1
#       end tell
