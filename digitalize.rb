#!/bin/ruby

require "./QuestionnaireReader.rb"

# Try to create directory. If a file with the same name already exists, put an error message
def create_dir(dirname)
	if File.exists?(dirname) && !File.directory?(dirname)
		puts "Could not create #{dirname} directory. Make sure there exists no file with the same name"
		return false
	end
	if !File.exists?(dirname)
		Dir.mkdir(dirname)
	end
	return true
end

# Check whether everything is okay for the survey `name`. Put error messages if something is wrong.
def survey_files_correct?(name)
	full_path = "templates/#{name}"
	if !File.exists?("#{full_path}.fmt") || File.directory?("#{full_path}.fmt")
		# If the format file doesn't exist, return false
		puts "Warning, file '#{full_path}.fmt' is missing. Skipping survey..."
		return false
	elsif !File.exists?("#{full_path}.tp") || File.directory?("#{full_path}.tp")
		# If the template file doesn't exist, return false
		puts "Warning, file '#{full_path}.tp' is missing. Skipping survey..."
		return false
	end

	# Get length for files
	File.foreach("#{full_path}.tp") {}
	template_length = $.
	File.foreach("#{full_path}.fmt") {}
	format_length = $.

	# If lengths don't match, return false
	if (template_length != format_length)
		puts "Warning: Template and format file for survey '#{full_path}' do not have the same length. Skipping survey..."
		return false
	else
		return true
	end
end

# Exit if the directories for the data or templates can't be created.
Process.exit(1) unless create_dir('templates')
Process.exit(1) unless create_dir('data')

# Get all survey files that we have.
survey_files = Dir.glob('templates/*.tp')
survey_files += Dir.glob('templates/*.fmt')
# Take only the basenames to make it a bit easier.
survey_files = survey_files.map{|f| File.basename(f, File.extname(f))}.uniq

# For all survey files, try to create directories in `data/`.
survey_files.each do |filename|
	create_dir("data/#{filename}")
	if survey_files_correct?(filename)
		Process.exit(1) unless create_dir("data/#{filename}")
	end
end

# Start reading the questionnaire.
questionnaireReader = QuestionnaireReader.new
questionnaireReader.startReading(survey_files)
