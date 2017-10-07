# Evaluby

Evaluby, pronounced eva-looby (/ɛvɑ'lu:bj/), is a piece of software written in Ruby that makes it easier to evaluate surveys. It is mainly meant for evaluating surveys on paper that you can digitalize by typing them into the running Evaluy application. In other words, Evaluby hopefully makes it a bit easier for you to digitalize paper surveys and later do a small amount of graphing for "presenting" the results of your questionnaires:

![evaluby.jpg](evaluby.jpg)

The resulting format is a pdf, but it's just composed of individual markdown, latex and png files that get merged together with pandoc.
Evaluby uses `gruff` as the underlying graphing tool.

## Note

Please use my own fork of the `gruff` project available at [https://github.com/PawkyPenguin/gruff](https://github.com/PawkyPenguin/gruff). As of now, I have some pull requests pending for bugfixes and new features.

## Installation

Download my fork of the `gruff` project. Then, install the library with rake so that you can use it. 
*Note*: Unfortunately, the `gruff` project on Github seems to be dead. If this remains the case for a long time, I will probably create my own gem at some point. However, as of now, rake is the way to go for installing my fork.
- `git clone git@github.com:PawkyPenguin/gruff.git`
- `cd gruff && rake install`
- `cd .. && git clone git@github.com:PawkyPenguin/evaluby.git`

## Usage
Evaluby needs to things before you can start digitalizing your surveys: A template and a format (completely arbitrarily named). Let's go through an example with a survey called `mysurvey`.
- Into `templates/`, place two files: `mysurvey.tp` and `mysurvey.fmt`. These are the template- and format file that Evaluby needs to know how your survey looks like
- Into `mysurvey.fmt`, put your survey questions, line by line. For multiple choice questions, put the possible answers (keep these short, they will appear in the legend of the graph. Something like 'disagree' and 'agree' is ideal).
- Into `mysurvey.tp`, put the *kind* of question. For example, there are multiple choice questions (`multN`), plain text questions (`plain`) and some others. Again, just specify your questions line by line.
- You can now start digitalizing: execute `questionnaireReader.rb`. Evaluby will tell you the format of each question and will refuse to continue if you make a mistake. For example, when you type `5` in a multiple choice question with just 3 answers (`mult3`), it won't enter that wrong number and you'll instead have to retype it. For multiple choice questions, just type the number of the choice that person ticked (first choice is `1`). If multiple answers are allowed, just enter each number with spaces in between.
- Execute `./digitalize.rb`, then choose `mysurvey` by entering the according number. Evaluby will start looping through the questions and you can start typing answers. Hit Ctrl-C once you are done.
- Execute `./statisticalEvaluation.rb`. Choose the survey you want evaluated. The evaluated surveys will land in `evaluation`. Execute `./build.sh` if you want to merge them to a pdf (requires pandoc).

## Question Types
Next, we go over question types Evaluby supports. Question types are used for the `*.tp` files. These determine which answers Evaluby allows during digitalization. 
- `plain`: Question with a plaintext answer, e.g. "What was your opinion?". When digitalizing, enter plaintext.
- `multN`: Multiple choice question with *N* answers. When digitalizing this question, enter a number.
- `multNOtherM`: Multiple choice question with *N* answers, where the *M*th field is an "Other" field where people can give their own answer. When digitalizing, enter a number or type "o\_" followed by some text to make use of the "other" field.
- `manyN`: Similar to `multN`, except that people answering your survey can check multiple answers. When digitalizing, just separate the numbers by a space.
- `manyNOtherM`: Similar to `multNOtherM`, except that people answering your survey can check multiple answers. When digitalizing, just separate the numbers by a space and type "o\_" followed by some text to make use of the "other" field.
- `studyplace` and `studyfield` are for questions asking participants about where and what they study because this software was originally made for evaluation of surveys at a university. These are probably not too helpful for you, but if you need them, you may find it helpful to add in some other answers to `QuestionnaireConstants.rb`.
