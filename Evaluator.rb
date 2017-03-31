require './QuestionnaireConstants.rb'
require './GraphDrawer.rb'

class Evaluator
	include QuestionnaireConstants

	def self.startEvaluating
		puts "Select the type of questionnaire:"
		filenames = Dir.open('data').find_all.to_a
		filenames.delete('.')
		filenames.delete('..')

		for filename, i in filenames.each_with_index
			puts "#{i + 1}) #{filename}"
		end
		puts "#{filenames.length + 1}) all"

		puts 
		i = -1
		while !(1..filenames.length + 1).member? i
			puts "Enter your selection"
			i = gets.to_i
		end
		if i <= filenames.length
			questionnaire = filenames[i - 1]
			evaluateQuestionnaire(questionnaire)
		else
			for questionnaire in filenames
				evaluateQuestionnaire(questionnaire)
				puts "#{questionnaire} done"
			end
		end
	end

	def self.evaluateQuestionnaire(questionnaire)
		questionnairePath = "data/#{questionnaire}/"
		templatePrefix = "templates/#{questionnaire}"
		evaluationPath = "evaluation/#{questionnaire}/"

		# The templateFile tells us what form the questions are in. I.e. are the questions multiple choice, plaintext or something else?
		templateFile = File.open("#{templatePrefix}.tp", 'r')
		# The formatFile tells us the title of the question and the answers the question has
		formatFile = File.open("#{templatePrefix}.fmt", 'r')

		graphDrawer = GraphDrawer.new()
		
		# Go through the template line by line and evaluate each question
		i = 0
		for line in File.readlines(templateFile)
			line = line.gsub(/#.*/, "").chomp
			if line.empty? then next end
			
			formatLine = formatFile.readline
			questionFilename = "question#{i}"
			File.open(questionnairePath + questionFilename, 'r') do 
				|questionFile|
				case line
				       when "plain" 
					       data = graphDrawer.evaluatePlainData(questionFile, formatLine)
					       self.writePlainquestionToFolder(data, questionFilename, evaluationPath, formatLine.to_s.chomp)
				       when "studyplace"
					       graph = graphDrawer.evaluateStudyplaceData(questionFile)
					       self.writeGraphToFolder(graph, questionFilename, evaluationPath)
				       when "studyfield" 
					       graph = graphDrawer.evaluateStudyfieldData(questionFile, formatLine)
					       self.writeGraphToFolder(graph, questionFilename, evaluationPath)
				       when /mult([0-9]*)$/ 
					       graph = graphDrawer.evaluateMultNData(questionFile, "#{$1}".to_i, formatLine)
					       self.writeGraphToFolder(graph, questionFilename, evaluationPath)
				       when /mult([0-9]*)Other([0-9]*)$/ 
					       graph = graphDrawer.evaluateMultNData(questionFile, "#{$1}".to_i, formatLine)
					       self.writeGraphToFolder(graph, questionFilename, evaluationPath)
				       when /many([0-9]*)Other([0-9]*)$/ 
					       graph = graphDrawer.evaluateMultNData(questionFile, "#{$1}".to_i, formatLine)
					       self.writeGraphToFolder(graph, questionFilename, evaluationPath)
				       else 
					       puts "Error in template file: Unexpected literal"
					       exit 1
				       end
			end
			i = i + 1
		end
		formatFile.close
		templateFile.close

		File.open("#{evaluationPath}start.tex", 'w') do |file|
			file.puts '\\usepackage{graphicx}'
			file.puts '\\usepackage{placeins}'
		end

		File.open("#{evaluationPath}build.sh", 'w') do |file|
			file.puts '#!/bin/sh'
			file.puts "pandoc --include-in-header start.tex *.md -o #{questionnaire}.pdf"
			file.chmod 0755
		end
	end

	def self.writeGraphToFolder(graph, filename, filepath)
			graph.write(filepath + filename + '.png')
			markdownGraphFile = File.open(filepath + filename + '.md', 'w')
			markdownGraphFile.puts "# #{graph.title.gsub('\n', '').chomp} #"
			markdownGraphFile.puts ""
			markdownGraphFile.puts "![#{filename}](#{filename + '.png'})"
			markdownGraphFile.puts "\\FloatBarrier"
			markdownGraphFile.puts ""
			markdownGraphFile.close
	end

	def self.writePlainquestionToFolder(data, filename, filepath, title )
		File.open(filepath + filename + '.md', 'w') do
			|outfile|
			outfile.puts("# #{title} #")
			for el in data
				outfile.puts("  - #{el.to_s}")
			end
		end
	end
end
