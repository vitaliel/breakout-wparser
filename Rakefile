task :default => :run

task :run do
  sh "ragel -R -F1 wiki_parser.rl"
  #sh "ruby wiki_parser_test.rb -n test_ticket_template"
  sh "ruby wiki_parser_test.rb"
end

task :dot do
  sh "ragel -V -p wiki_parser.rl >parser.dot"
  sh "dotty parser.dot"
end
