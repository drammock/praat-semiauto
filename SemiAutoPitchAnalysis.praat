# ########################################################################################################################### #
# PRAAT SCRIPT "SEMI-AUTO PITCH EXTRACTOR"
# This script semi-automates measuring pitch from sound files with labeled TextGrids.  It cycles through a directory
# of TextGrids, finds associated sound files, opens them one at a time, puts the cursor at the midpoint of each labeled
# interval on the specified tier, and prompts the user to either (1) accept the pitch measurement (2) adjust the pitch
# floor/ceiling or cursor position and recalculate, or (3) mark the interval as unmeasurable, before continuing on to the
# next interval or file.  Pitch at cursor, mean pitch in interval, current floor/ceiling settings, timepoint, percent 
# through interval, filename, interval label, and notes are all written to the output file.  By default, the script will
# show a narrowband spectrogram and a pitch track while running, but will not show formants, pulses, intensity, etc.  If
# you want to see additional analyses, change the arguments of the line that starts "Show analyses" (lines 153 & 156).
# VERSION 0.4 (2012 05 25)
#
# CHANGELOG
# VERSION 0.4:  No significant code changes.  Minor changes to documentation.  License changed from CC to GPL.
# VERSION 0.3:	Major code changes to make the script to be LongSound compatible (this also increases efficiency by only
# 		calculating pitch objects for the intervals analysed, instead of whole files).  Added the ability to specify
# 		the length of the viewing window instead of the previous two options of "interval" or "whole file."  Various
# 		minor code improvements.
# VERSION 0.2:	Added option to append to a pre-existing output file, and to start at an arbitrary point in the file list.
# 		Added the ability to move to different locations besides the interval midpoint during analysis.  Added file
# 		number, pitch ceiling/floor, position in interval to the output file.  Added running count of file number and
# 		total files to the analysis dialog.  Minor improvements to code and comments.
#
# AUTHOR: DANIEL MCCLOY: (drmccloy@uw.edu)
# LICENSED UNDER THE GNU GENERAL PUBLIC LICENSE v3.0 OR HIGHER: http://www.gnu.org/licenses/gpl.html
# DEVELOPMENT OF THIS SCRIPT WAS FUNDED BY THE NATIONAL INSTITUTES OF HEALTH, GRANT # 10186254 TO PAMELA SOUZA
# ########################################################################################################################### #

# COLLECT ALL THE USER INPUT
form Select directories for TextGrids and Sound files
	sentence Textgrid_directory /home/dan/Desktop/textgrids/
	sentence Sound_directory /home/dan/Desktop/sounds/
	sentence Sound_extension .wav
	comment Which TextGrid tier contains your segment labels?
	integer Label_tier 1
	comment You can pick up where you left off if you like:
	integer Starting_file_number 1
	comment How many seconds of the sound file do you want to
	comment see during analysis? (enter "0" to view the entire file)
	real Zoom_duration 6
	comment Full path of the output file:
	sentence Output_file /home/dan/Desktop/PitchAnalysisResults.txt
	comment Default pitch analysis settings (you can adjust them file by file):
	integer Default_min_pitch 75
	integer Default_max_pitch 500
endform

# BE FORGIVING IF THE USER FORGOT TRAILING PATH SLASHES OR LEADING FILE EXTENSION DOTS
call cleanPath 'textgrid_directory$'
textgrid_dir$ = "'cleanPath.output$'"
call cleanPath 'sound_directory$'
sound_dir$ = "'cleanPath.output$'"
call cleanExtn 'sound_extension$'
sound_extn$ = "'cleanExtn.output$'"

# INITIATE THE OUTPUT FILE
if fileReadable (output_file$)
	beginPause ("The output file already exists!")
		comment ("The output file already exists!")
		comment ("You can overwrite the existing file, or append new data to the end of it.")
	overwrite_setting = endPause ("Append", "Overwrite", 1)
	if overwrite_setting = 2
		filedelete 'output_file$'
		call initializeOutfile
	endif
else
	# THERE IS NOTHING TO OVERWRITE, SO CREATE THE HEADER ROW FOR THE NEW OUTPUT FILE
	call initializeOutfile
endif

# MAKE A LIST OF ALL TEXTGRIDS IN THE FOLDER
Create Strings as file list... list 'textgrid_dir$'*.TextGrid
file_list = selected("Strings")
file_count = Get number of strings

# LOOP THROUGH THE LIST OF FILES...
for current_file from starting_file_number to file_count

	# READ IN THE TEXTGRID & CORRESPONDING SOUND...
	select Strings list
	gridname$ = Get string... current_file
	Read from file... 'textgrid_dir$''gridname$'
	filename$ = selected$ ("TextGrid", 1)
	Open long sound file... 'sound_dir$''filename$''sound_extn$'
	total_duration = Get total duration

	# THIS IS A BOOLEAN TO PREVENT OPENING MULTIPLE EDITOR WINDOWS FOR THE SAME LONGSOUND
	new_file = 1

	# FIND THE LABELED INTERVAL...
	select TextGrid 'filename$'
	num_intervals = Get number of intervals... label_tier
	for interval to num_intervals
		select TextGrid 'filename$'
		label$ = Get label of interval... label_tier interval

		# IF THE LABEL IS NON-EMPTY, GET ITS ENDPOINTS
		if label$ <> ""
			start = Get starting point... label_tier interval
			end = Get end point... label_tier interval
			midpoint = (start+end)/2

			# PREVENT ZOOM DURATION FROM EXTENDING BEYOND THE ENDS OF THE FILE
			# BUT TRY TO MAINTAIN THE DESIRED WINDOW SIZE
			if not zoom_duration = 0
				left_edge = midpoint - zoom_duration/2
				right_edge = midpoint + zoom_duration/2
				right_excess = right_edge - total_duration

				if left_edge < 0
					zoom_start = 0
					if zoom_duration > total_duration
						zoom_end = total_duration
					else
						zoom_end = zoom_duration
					endif
				elif right_edge > total_duration
					zoom_end = total_duration
					if left_edge > right_excess
						zoom_start = zoom_end - zoom_duration
					else
						zoom_start = 0
					endif
				else
					zoom_start = left_edge
					zoom_end = right_edge
				endif
			else
				zoom_start = 0
				zoom_end = total_duration
			endif

			if new_file = 1
				# SHOW THE EDITOR WINDOW
				select LongSound 'filename$'
				plus TextGrid 'filename$'
				View & Edit

				# WE'RE IN THE FIRST LABELED INTERVAL, SO SET ALL THE SETTINGS
				editor TextGrid 'filename$'
					# FIRST, HIDE THE SPECTROGRAM ETC TO PREVENT ANNOYING FLICKERING
					Show analyses... no no no no no 10
					Zoom... zoom_start zoom_end

					# NOW SET ALL THE RELEVANT SETTINGS AND DISPLAY NARROWBAND SPECTROGRAM AND PITCH
					Spectrogram settings... 0 2000 0.025 50
					Advanced spectrogram settings... 1000 250 Fourier Gaussian yes 100 6 0
					Pitch settings... default_min_pitch default_max_pitch Hertz autocorrelation automatic
					Advanced pitch settings... 0 0 no 15 0.03 0.45 0.01 0.35 0.14
					Move cursor to... midpoint
					if not zoom_duration = 0
						# MAKE SURE THE "MAX ANALYSIS" SETTING IS LONG ENOUGH SO THE SPECTROGRAM ACTUALLY SHOWS UP
						Show analyses... yes yes no no no zoom_duration+1
					else
						# THE USER SPECIFED "WHOLE FILE" SO WE ASSUME THE FILES ARE SHORT AND 10 SECONDS SHOULD BE ENOUGH
						Show analyses... yes yes no no no 10
					endif
				endeditor
			else
				# WE'RE NOT IN THE FIRST LABELED INTERVAL, SO ALL THE SETTINGS ARE ALREADY SET
				editor TextGrid 'filename$'
					Zoom... zoom_start zoom_end
					Move cursor to... midpoint
				endeditor
			endif
			new_file = 0

			# INITIALIZE SOME VARIABLES FOR THE U.I.
			clicked = 1
			min_pitch = default_min_pitch
			max_pitch = default_max_pitch
			time_point = 50

			# SHOW A U.I. WITH PITCH SETTINGS.  KEEP SHOWING IT UNTIL THE USER ACCEPTS OR CANCELS
			repeat
				beginPause ("Adjust pitch analysis settings")
					comment ("File 'filename$' (file number 'current_file' of 'file_count')")
					comment ("You can change the pitch settings if the pitch track doesn't look right.")
					integer ("New_min_pitch", min_pitch)
					integer ("New_max_pitch", max_pitch)
					integer ("Percent_through_interval", time_point)
					comment ("Clicking REDRAW will redraw the pitch contour with the settings above;")
					comment ("clicking OVERRIDE will manually specify the pitch as whatever is in the")
					comment ("box below (useful for, e.g., marking unmeasurable segments as zero).")
					real ("Manual_override", 0)
					sentence ("Notes_or_comments", "")
				clicked = endPause ("Redraw", "Accept", "Override", 2)
				min_pitch = new_min_pitch
				max_pitch = new_max_pitch
				time_point = percent_through_interval
				editor TextGrid 'filename$'
					Pitch settings... min_pitch max_pitch Hertz autocorrelation automatic
					Move cursor to... start + (end-start)*time_point/100
				endeditor
			until clicked >1

			# IF THE USER MANUALLY OVERRIDES...
			if clicked = 3
				# WRITE OVERRIDE VALUES
				fzero = manual_override
				fzero_mean = manual_override
				measurement_time = start + (end-start)*time_point/100
				
			# IF THE USER ACCEPTS THE PITCH...
			elif clicked = 2
				# CREATE A PITCH OBJECT WITH THE CURRENT PITCH SETTINGS AND TAKE THE MEASUREMENT
				select LongSound 'filename$'
				Extract part... start end yes
				select Sound 'filename$'
				To Pitch... 0 min_pitch max_pitch
				select Pitch 'filename$'
				measurement_time = start + (end-start)*time_point/100
				fzero = Get value at time... measurement_time Hertz Linear
				fzero_mean = Get mean... start end Hertz

				# REMOVE THE EXTRACTED SOUND AND PITCH OBJECT, SINCE LATER INTERVALS
				# IN THIS FILE MAY GET DIFFERENT SETTINGS AND THUS GET EXCTRACTED ANEW
				plus Sound 'filename$'
				Remove
			endif

			# WRITE TO FILE
			resultline$ = "'current_file''tab$''filename$''tab$''label$''tab$''fzero''tab$''fzero_mean''tab$''min_pitch''tab$''max_pitch''tab$''measurement_time''tab$''time_point''tab$''notes_or_comments$''newline$'"
			fileappend "'output_file$'" 'resultline$'
		endif
	endfor

	# REMOVE ALL THE OBJECTS FOR THAT FILE AND GO ON TO THE NEXT ONE
	select LongSound 'filename$'
	plus TextGrid 'filename$'
	Remove
	select Strings list
endfor

# REMOVE THE STRINGS LIST AND GIVE A SUCCESS MESSAGE
select Strings list
Remove
clearinfo
files_read = file_count - starting_file_number + 1
printline Done! 'files_read' files read.'newline$'

# FUNCTIONS (A.K.A. PROCEDURES) THAT WERE CALLED EARLIER
procedure cleanPath .input$
	if not right$(.input$, 1) = "/"
		.output$ = "'.input$'" + "/"
	else
		.output$ = "'.input$'"
	endif
endproc

procedure cleanExtn .input$
	if not left$(.input$, 1) = "."
		.output$ = "." + "'.input$'"
	else
		.output$ = "'.input$'"
	endif
endproc

procedure initializeOutfile
	headerline$ = "number'tab$'filename'tab$'label'tab$'fzero'tab$'fzero_mean'tab$'pitch_floor'tab$'pitch_ceiling'tab$'measurement_time'tab$'percent_through_interval'tab$'notes'newline$'"
	fileappend "'output_file$'" 'headerline$'
endproc
