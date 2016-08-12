require 'pry'

task default: 'assets:precompile'

namespace :assets do
  desc 'Compile scss/coffee to css/js'
  task :precompile do
    # from scss to css
    file_list = FileList.new('assets/stylesheets/*.scss')
    file_list.each do |file|
      file_name = File.basename(file, ".*")
      file_ext = File.extname(file)

      if File.extname(file) == '.scss'
        `scss #{file}:public/css/#{file_name}.css --style compressed`
        `rm public/css/*.map`
      end
    end

    # from coffee script to javascript
    `coffee -o public/js -c assets/javascripts `
  end
end
