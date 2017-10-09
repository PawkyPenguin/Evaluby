# Read inputs from questionnaires 1-by-1 and save them in sensible spots

require "./QuestionnaireConstants.rb"

class String
	def represents_integer?
		self.to_i.to_s == self
	end
end

class QuestionnaireReader
	include QuestionnaireConstants

	# Returns the input and true iff the input is non-empty
	def plain(s)
		return !s.empty?, s
	end

	# This method is incredibly ugly. Basically what it does is take a string, attempt to convert it to integer and if it works, checks whether it is
	# within the bounds of the array PredefinedUnis. If it isn't, it will return true only if the string is NOT an integer (this adds a certain amount of fail-safety to user input).
	def studyplace(s)
		success = false
		university = case s
			     when /\s+/
				     success = true
				     "no"
			     else
				     s
			     end
		if s.represents_integer?
			i = s.to_i
			if (1..PredefinedUnis.length).member? i
				university = PredefinedUnis[i - 1]
				success = true
			end
		else
			success = !s.empty?
		end

		return success, university
	end
		
	def studyfield(s)
		return s == " " || Studyfields.member?(s), s
	end

	def multN(s, n)
		if s == "0"
			return true, ""
		end
		if s.represents_integer?
			i = s.to_i
		else
			i = 0
		end
		return (1..n).member?(i), s
	end

	# Returns the parsed input and true iff input is either a number within the range of choices and NOT equal to otherPosition, OR if the input is of the form "otherPosition STRING"
	def multNOtherN(s, amountOfChoices, otherPosition)
		if s == "0"
			return true, ""
		end
		isOther = false
		i = -1
		if s =~ /^#{otherPosition}(.*)$/
			isOther = true
			s = "o_#{$1}"
		else
			if s.represents_integer?
				i = s.to_i
			else
				i = -1
			end
		end
		return (i != otherPosition && (1..amountOfChoices).member?(i)) || isOther, s
	end

	def manyNOtherN(s, amountOfChoices, otherPosition)
		if s == "0"
			return true, ""
		end
		isOther = false
		correctFormat = true
		formattedOutput = ""
		stringParts = s.split
		for part in stringParts
			if part =~ /^#{otherPosition}(.*)$/ && !isOther
				isOther = true
				formattedOutput += "o_#{$1} "
			else
				if part.represents_integer?
					i = Integer(part)
					correctFormat = (1..amountOfChoices).member?(i)
					formattedOutput += "#{i} "
				else
					correctFormat = false
				end
			end
		end
		formattedOutput.chomp!
		return correctFormat, formattedOutput
	end


	def readQuestionnaire(template, outdir)
		i = 0
		for line in File.readlines(template)
			line = line.gsub(/#.*/, "")
			line.chomp!
			if line.empty? then next end
			answerCorrectFormat = false
			while !answerCorrectFormat
				answerCorrectFormat, formattedAnswer = case line
								       when "plain"
									       puts "plain:"
									       answer = gets.chomp
									       plain(answer)
								       when "studyplace"
									       puts "studyplace:"
									       answer = gets.chomp
									       studyplace(answer)
								       when "studyfield"
									       puts "studyfield: #{Studyfields}"
									       answer = gets.chomp
									       studyfield(answer)
								       when /mult([0-9]*)$/
									       puts "mult#{$1}:"
									       answer = gets.chomp
									       multN(answer, "#{$1}".to_i)
								       when /mult([0-9]*)Other([0-9]*)$/
									       puts "mult#{$1}Other#{$2}:"
									       answer = gets.chomp
									       multNOtherN(answer, "#{$1}".to_i, "#{$2}".to_i)
								       when /many([0-9]*)Other([0-9]*)$/
									       puts "many#{$1}Other#{$2}:"
									       answer = gets.chomp
									       manyNOtherN(answer, "#{$1}".to_i, "#{$2}".to_i)
								       else
									       puts "Error in template file: Unexpected literal"
									       exit 1
								       end
				if !answerCorrectFormat
					puts "Not correct format! Try again."
				end
			end
			outfile = outdir + "question#{i}"
			formattedAnswer.chomp!
			puts formattedAnswer + " into " + outfile
			open(outfile, 'a') do |file|
				file.puts formattedAnswer
			end
			i += 1
		end
		puts
		puts
	end

	# Parses the files in the evaluationFormat directory and generates question.fmt files that are used by
	# the GraphDrawer to get certain attributes, such as question labels.
	# The format files are placed in outdir, separated by question.
	def parseFormatFiles(formatFile, outdir)
		i = 0
		for line in formatFile.readlines
			line.chomp!
			outfile = File.open(outdir + "question#{i}.fmt", 'a')
			if outfile.zero?
				outfile.close
				next
			end
			choices = ""
			if line =~ /!!choices=(\[.*\])/
				choices = eval "#{$1}"
			end
			question = line.split("!!")[0]
			outfile.puts(question + choices)
			outfile.close
			i += 1
		end
	end

	# Admittedly, this name is somewhat misleading. This method is for letting the *user* input the results of his questionnaires into the program.
	def startReading(survey_files)
		puts "Select the type of questionnaire:"
		for filename, i in survey_files.each_with_index
			puts "#{i + 1}) #{filename}"
		end

		puts
		i = -1
		while !(1..survey_files.length).member? i
			puts "Enter your selection"
			i = gets.to_i
		end
		outdir = "data/#{survey_files[i - 1]}/"

		File.open("templates/#{survey_files[i - 1]}.tp", 'r') do |template|
			while true
				readQuestionnaire(template, outdir)
			end
		end
	end
end
