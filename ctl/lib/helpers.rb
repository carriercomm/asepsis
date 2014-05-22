def colorize(code, string)
    $colors_supported = (ENV['TERM'] and (`tput colors`.to_i > 8)) unless defined? $colors_supported
    return string unless $colors_supported
    "\033[#{code}m#{string}\033[0m"
end

def out(cmd)
    puts colorize("33", "> #{cmd}")
end

def say(what)
    puts colorize("34", what)
end

def say_red(what)
    puts colorize("31", what)
end

def sys(cmd)
    out(cmd)
    $stdout.flush
    if not system(cmd) then
        puts colorize("31", "failed with code #{$?}")
        exit $?.exitstatus
    end
end

def sys!(cmd)
    out(cmd)
    $stdout.flush
    if not system(cmd) then
      $forced_exit_code = 1
    end
end

def die(message, code=1)
    say_red message
    exit code
end

def set_permanent_sysctl(name, value="1", path = "/etc/sysctl.conf")
    system("touch \"#{path}\"") unless File.exists? path
    lines = []
    r = Regexp.new(Regexp.escape(name))
    set = false
    replacement = "#{name}=#{value} \# added by asepsis.binaryage.com\n"
    File.open(path, "r") do |f|
        f.each do |line|
            if line =~ r then
               line = replacement
               set = true
            end
            lines << line
        end
    end
    lines << replacement unless set
    File.open(path, "w") do |f|
        f << lines.join
    end
end

def remove_permanent_sysctl(name, path = "/etc/sysctl.conf")
    return unless File.exists? path
    lines = []
    r = Regexp.new(Regexp.escape(name))
    File.open(path, "r") do |f|
        f.each do |line|
            if line =~ r then
                next
            end
            lines << line
        end
    end
    File.open(path, "w") do |f|
        f << lines.join
    end
end

def lions?
  `sw_vers -productVersion|grep '10\\.\\(7\\|8\\)'`
  $?==0
end

def codesign_check()
  res = `which codesignx`.strip
  die("Asepsis requires working codesign command for this operation. Please install codesign to /usr/bin/codesign.\nInstall Xcode command-line tools: http://osxdaily.com/2014/02/12/install-command-line-tools-mac-os-x") if res.size==0
end

def os_version_check()
  `sw_vers -productVersion|grep '10\\.\\(7\\|8\\|9\\)'`
  die("Asepsis #{ASEPSISCTL_VERSION} can be only installed under OS X versions 10.7, 10.8 and 10.9\nCheck out http://asepsis.binaryage.com for updated version.") if $?!=0
end

def desktopservicespriv_wrapper?(file)
  # this is simple and stupid test: our wrapper library is small, under 100kb
  File.size(file) <= 100*1024
end