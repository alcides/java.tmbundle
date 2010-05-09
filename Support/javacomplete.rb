#!/usr/bin/env ruby

require ENV['TM_SUPPORT_PATH'] + "/lib/exit_codes"
require "#{ENV['TM_SUPPORT_PATH']}/lib/escape"


def pop_up(candidates, searchTerm, call = true)
  prettyCandidates = candidates.sort {|x,y| x.size <=> y.size }
  if prettyCandidates.size > 1
    show_dialog(prettyCandidates)
  else
    return candidates[0]
  end
end

def show_dialog(prettyCandidates)
  require "#{ENV['TM_SUPPORT_PATH']}/lib/osx/plist"
  pl = {'menuItems' => prettyCandidates.map { |pretty| { 'title' => pretty, 'cand' => pretty} }}
  io = open('|"$DIALOG" -u', "r+")
  io <<  pl.to_plist
  io.close_write
  res = OSX::PropertyList::load(io.read)
  if res.has_key? 'selectedMenuItem'
    res['selectedMenuItem']['cand']
  else
    "$0"
  end
end

def candidates_or_exit(methodSearch, list, fileNames, notif = false)
  x = candidate_list(methodSearch, list, fileNames, notif)
  TextMate.exit_show_tool_tip "No completion available" if x.empty?
  return x
end

def candidate_list(methodSearch, list, fileNames, notif = false)
  f = open("#{ENV['TM_BUNDLE_SUPPORT']}/classlist.txt","r")
  list = []
  f.each_line do |line|
    next unless line.include? "."
    klass = line.split(".").last.strip
    packaged = line.strip
    if klass == methodSearch
      list << packaged
    elsif klass.start_with? methodSearch
      list << klass
    end
  end
  return list.uniq
end


word = ENV['TM_SELECTED_WORD'] || ENV['TM_CURRENT_WORD']
candidates = candidates_or_exit(word, nil, "classlist.txt"  )
res = pop_up(candidates, word)
TextMate.exit_discard if res == "$0"
$stdout.write res