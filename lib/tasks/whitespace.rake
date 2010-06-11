desc 'Removes trailing whitespace'
task :whitespace do
  sh %{find . -name '*.rb' -exec sed -i '' 's/ *$//g' {} \\;}
end