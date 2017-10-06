require 'gruff'

class GraphDrawer

	def initialize()
	end

	# Accumulate an array and a symbolList into a hash. The symbollist contains all symbols we want to accumulate over (this is used so we can also have symbols with 0 elements in our graph).
	# The cutoff is used to bound the size of the array. The resulting array is at most cutoffSize.
	# Note that any symbols contained in the symbollist are guaranteed to occur in the accumulation hash, unless the cutoff is too low, in which case there will simply be an 'other' field for the ones
	# that did not fit.
	def accumulateArray(array, symbolList, cutoffSize)
		accumulation = {}
		for s in symbolList
			accumulation[s.intern] = 0 # call intern because better safe than sorry.
		end
		for el in array
			if !accumulation.has_key? el.intern
				accumulation[el.intern] = 0
			end
			accumulation[el.intern] += 1
		end

		# If the array has too much length, we employ an "other" field. The fields in the hash that don't have enough elements of the array simply get dropped.
		# We first assign 0 to the :other field, so it gets removed for sure and later reinsert it.
		#
		if accumulation.size >= cutoffSize
			otherField = accumulation[:other]
			otherField ||= 0
			accumulation[:other] = 0
			sortedArray = accumulation.sort_by { |key, value| -value } # sortedArray is something like [[:key1, 555], [:key2, 400], [:key3, 100], [:key2, 42], [:other, 0]]
			# For every element in the array after the cutoff, fill the other field.
			for keyvalPair in sortedArray[cutoffSize...sortedArray.length]
				otherField += keyvalPair[1]
			end

			# Finally, let our accumulation be the array, except with the other field instead of all the elements after the cutoff.
			sortedArray = sortedArray[0...cutoffSize]
			accumulation = Hash[*sortedArray.flatten] # thx stackoverflow
			accumulation[:other] = otherField
		end
		return accumulation
	end

	# Takes as an argument some data in the form of a (label, data)-Hash and a graph title. Note that the elements of the Hash, i.e. `data`, are integers indicating the number of responses for that answer
	def getStandardBarGraph(accumulatedDataHash, title)
		graph = Gruff::Bar.new
		graph.hide_legend = false
		graph.show_labels_for_bar_values = true
		# dejavusansmono is the objectively best font
		if File.exists? "/usr/share/fonts/TTF/DejaVuSansMono.ttf"
			graph.font = "/usr/share/fonts/TTF/DejaVuSansMono.ttf"
		end

		# If the Hash's keys are only integers, perform a sort. If not, don't.
		doSorting = true
		for key, el in accumulatedDataHash
			isInteger = key.to_s.to_i.to_s == key.to_s # dear god.
			if !isInteger
				doSorting = false
				break
			end
		end
		if doSorting
			graphData = accumulatedDataHash.sort.to_h
		else
			graphData = accumulatedDataHash
		end

		# Set graph attributes. Always set font size before title so the title can be linebreak'ed at the appropriate places
		graph.labels = {0 => "Amount of answers"}
		graph.title_font_size = 16.0
		graph.title_margin = 30;
		graph.title = title
		graph.minimum_value = 0
		graph.maximum_value = getMaxY(accumulatedDataHash.values.max)
		graphData.each {|key, element| graph.data(key, element)}
		return graph
	end

	# Returns the max value of the y-axis the graph should have.
	private def getMaxY(answersAmount)
		# This basically makes sure that our max Y is always a nice value. "A nice value" means a digit followed by either 0 or 5. (or just a number between 1 and 10)
		# e.g. for parameter 26 returns 30, for 34 35, for 104 150, for 1670 2000 etc.
		# Additionally, if the first digit is already >5, the returned value will always be a digit followed by 0.
		# e.g. 780 => 800, 720 => 800, 640 => 700, 8398 => 9000 etc..
		if answersAmount < 10
			return answersAmount
		end
		magnitude = 10 ** Math.log10(answersAmount).to_i
		secondDigit, firstDigit = answersAmount.digits[-2,2]
		if firstDigit >= 5 || secondDigit >= 5
			return (firstDigit + 1) * magnitude
		else
			# firstDigit is <5 and secondDigit is <5
			return firstDigit * magnitude + magnitude / 2
		end
	end

	def evaluateStudyplaceData(file)
		data = []
		for line in file.readlines
			data << line.chomp
		end

		data = accumulateArray(data, [], 4)
		graph = getStandardBarGraph(data, "Where are you studying?")
		return graph
	end

	def evaluateStudyfieldData(file, formatLine)
		data = []
		for line in file.readlines
			data << line.chomp
		end
		data = accumulateArray(data, [], 9)
		graph = getStandardBarGraph(data, "What are you studying?")
		return graph
	end

	def evaluatePlainData(file, formatLine)
		data = []
		for line in file.readlines
			line.chomp!
			if line =~ /^\s*$/
				next
			end
			data << line
		end
		return data
	end

	# Evaluate a multiple choice question.
	def evaluateMultNData(file, i, formatLine)

		# Read the datalines from file. There is no check here, so if your file contains something
		# other than numbers or "o_"-fields that's probably bad. Don't feed this script garbage pls :D
		data = []
		for line in file.readlines
			line.chomp!
			if line == ""
				next
			end
			lineParts = line.split
			for linePart in lineParts
				if linePart =~ /o_.*/
					data << "other"
				else
					data << linePart
				end
			end
		end
		
		# The formatLine determines how the data is accumulated. The formatLine is something like
		# questionTitle_answer1:asnwer2:o_otherfieldIdentifier
		formatParts = formatLine.split("_")
		graphTitle = formatParts[0]
		labels = []

		# If the formatline contains labels for our answers, put the labels into data instead. 
		# I.e. the question answers are not numeric anymore, instead they have explicit names such as "Disagree", "Somewhat agree", "Agree".
		if formatParts[1]
			labels = formatParts[1].split(":").map {|s| s.chomp.to_sym}
			newData = []
			for el in data
				if el == "other"
					newData << "other"
				else
					newData << labels[el.to_i - 1]
				end
			end
			data = newData
		else
			# If we don't have explicit labels, just use the multiple choice numbers. Resorting is not necessary, since the question files already are in this format.
			for j in (1..i)
				labels << j.to_s.to_sym
			end
		end
		# Accumulate the array into a Hash.
		data = accumulateArray(data, labels, 9)
		graph = getStandardBarGraph(data, graphTitle)
		return graph
	end

end
