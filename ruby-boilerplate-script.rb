#!/usr/bin/env ruby

=begin
	Author: Wayne Schmidt
	Email: wayne.kirk.schmidt@gmail.com	
	GitHub URL: https://github.com/wayne-kirk-schmidt/ruby-projects
	Exaplanation: 
			Sample Script which stores information into a log file.
			This showcases methods, data structures, and features of Ruby.
	License: GPLv3
	
=end

require 'optparse'
require 'awesome_print'
require 'pathname'
require 'rbconfig'
require 'sys-filesystem'
require 'sys-cpu'

now 	= Time.now
mydir	= (Pathname.new(".")).realpath.to_s
mycfg	= ((Pathname.new(__FILE__)).realpath.sub_ext '.cfg').to_s

DEFAULT = {
	date: now.strftime("%Y%m%d"), 
	time: now.strftime("%H%M%S"),
	node: ENV['NAME'],
	verb: 'AUDIT',
	file: File.join(mydir,'sample-application.txt'),
	conf: mycfg,
	showenv: 'hide',
	showman: 'hide'
}

def print_man
	mylines = File.read(__FILE__)
	mymanpage = mylines.match(/=begin(.*?)=end/m)[1]
	puts mymanpage
end

def print_env
	myenv = ENV.select{|key,value| key =~ /^(HOME|NAME)$/ }
	myenv.each { |akey, avalue| printf "%s: %s\n", akey, avalue }
	printf "\nPATH:\n"
	patharray = ENV["PATH"].split(":")
	patharray.each_with_index do |i|
		printf "\tITEM: %s\n", i
	end
end

options = {}

OptionParser.new do |opt|
	opt.on('-d', '--date DATE') { |o| options[:date] = o }
	opt.on('-t', '--time TIME') { |o| options[:time] = o }
	opt.on('-n', '--node NODE') { |o| options[:node] = o }
	opt.on('-f', '--file FILE') { |o| options[:file] = o }
	opt.on('-v', '--verb VERB') { |o| options[:verb] = o }
	opt.on('-c', '--conf CONF') { |o| options[:conf] = o }
	opt.on('-e', '--env') 		{ |o| options[:showenv] = 'show' }	
	opt.on('-m', '--man') 		{ |o| options[:showman] = 'show' }
end.parse!

initialized = DEFAULT.merge(options)

if options[:showenv] == 'show'
	print_env
	ap options
	ap initialized
	exit
end

if options[:showman] == 'show'
	print_man
	exit
end

tagname =  [ initialized[:node], initialized[:verb], initialized[:date], initialized[:time], 'log' ].join(".")
logfile =  File.join(mydir,tagname)

if File.exist?(logfile) 
	printf "Removing: %s\n", logfile
	File.delete(logfile)
end

hostname = initialized[:node]

memhash = Hash.new
meminfo = File.read('/proc/meminfo')
meminfo.each_line do |i| 
	key, val = i.split(':')
	if val.include?('kB') then val = val.gsub(/\s+kB/, ''); end
	memhash["#{key}"] = val.strip
end
totalMem = memhash["MemTotal"].to_i

printf "Writing: %s\n", logfile

open(logfile, 'w') { |f|
	f.printf "Date-Run: %s\n", initialized[:date]
	f.printf "Time-Run: %s\n", initialized[:time]
	f.printf "HostName: %s\n", hostname
	f.printf "HostOS: %s\n", RUBY_PLATFORM
	Sys::CPU.processors.each_with_index do |i|
		f.printf "CPU%s: %s\n", i[:processor], i[:model_name]
	end
	f.printf "TotalMemory: %s\n", totalMem
}

printf "Complete: %s\n", logfile
