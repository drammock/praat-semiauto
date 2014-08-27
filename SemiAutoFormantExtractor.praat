# ########################################################################################################################### #
# PRAAT SCRIPT "SEMI-AUTO FORMANT EXTRACTOR"
# This script semi-automates measuring formants from sound files with labeled TextGrids.  It is based on and similar to the
# script "SemiAutoPitchAnalysis" by Daniel McCloy.  This script cycles through a directory of TextGrids, finds associated
# sound files, opens them one at a time, displays a table of formant values for the interval at user-specified time points,
# and prompts the user to either (1) accept the formant measurements, (2) adjust the formant settings and recalculate, or
# (3) mark the interval as unmeasurable, before continuing on to the next interval or file.  
# 
# By default, the script will show a wideband spectrogram (from 0-5000Hz) and a formant track while running, but will
# not show pitch, pulses, intensity, etc.  If you want to see additional analyses, change the arguments of the line that starts
# "Show analyses" (lines 165 & 168).  If you want to change the underlying spectrogram settings, change lines 205-206.
# VERSION 0.3 (2012.05.05)
#
# CHANGELOG
# VERSION 0.3:	Major reorganization of code (several complex control structures moved into procedures). Bug fixed where
#               sometimes all time points through the interval were written out with values from the midpoint. Major
#               improvements to efficiency by using formant values drawn from the editor window (since it's already open
#               anyway) rather than extracting a sound slice and creating a formant object from it.
#
# VERSION 0.2:	No significant code changes.  Moderate improvements to documentation.  License changed from CC to GPL.
#
# AUTHORS: DANIEL MCCLOY: (drmccloy@uw.edu) & AUGUST MCGRATH
# LICENSED UNDER THE GNU GENERAL PUBLIC LICENSE v3.0 OR HIGHER: http://www.gnu.org/licenses/gpl.html
# DEVELOPMENT OF THIS SCRIPT WAS FUNDED BY THE NATIONAL INSTITUTES OF HEALTH, GRANT # R01DC006014 TO PAMELA SOUZA
# ########################################################################################################################### #

# COLLECT ALL THE USER INPUT
form Select directories for TextGrids and Sound files
	sentence Textgrid_directory ~/Desktop/textgrids/
	sentence Sound_directory ~/Desktop/sounds/
	sentence Sound_extension .wav
	comment Which TextGrid tier contains your segment labels?
	integer Label_tier 1
	comment You can pick up where you left off if you like:
	integer Starting_file_number 1
	comment How many seconds of the sound file do you want to
	comment see during analysis? (enter "0" to view the entire file)
	real Zoom_duration 1
	comment Full path of the output file:
	sentence Output_file /home/dan/Desktop/FormantAnalysisResults.txt
	comment Default formant tracker settings (you can adjust "max formant" and 
	comment "number of formants" later as you step through the intervals):
	positive Default_max_formant 5500
	integer Default_formant_number 5
	real Time_step 0.1
	real Preemphasis_from 50
	positive Window_length 0.025
	positive Dynamic_range 30
	positive Dot_size 0.6
	optionmenu Interval_measurement_option: 3
		option midpoint
		option onset, midpoint, offset
		option 20%, 50%, 80%
		option 25%, 50%, 75%
		option 10%, 30%, 50%, 70%, 90%
		option 5%, 10%, 20%, 50%, 80%, 90%, 95%
endform

# RUN SOME FUNCTIONS ON THE USER INPUT (TO BE USED LATER)
call pointsPerInterval

# BE FORGIVING IF THE USER FORGOT TRAILING PATH SLASHES OR LEADING FILE EXTENSION DOTS
call cleanPath 'textgrid_directory$'
textgrid_dir$ = "'cleanPath.out$'"
call cleanPath 'sound_directory$'
sound_dir$ = "'cleanPath.out$'"
call cleanExtn 'sound_extension$'
sound_extn$ = "'cleanExtn.out$'"

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

	# BOOLEAN TO PREVENT OPENING MULTIPLE EDITORS FOR THE SAME LONGSOUND
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

			# PREVENT ZOOM DURATION FROM EXTENDING BEYOND THE ENDS OF THE FILE, BUT TRY TO MAINTAIN THE DESIRED WINDOW SIZE
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
			else  ;  zoom_duration = 0
				zoom_start = 0
				zoom_end = total_duration
			endif  ;  zoom_duration

			if new_file = 1
				# IF THIS IS THE FIRST INTERVAL OF THE CURRENT FILE, SHOW THE EDITOR WINDOW
				select LongSound 'filename$'
				plus TextGrid 'filename$'
				View & Edit

				# SINCE WE'RE IN THE FIRST LABELED INTERVAL, SET ALL THE SETTINGS
				editor TextGrid 'filename$'
					# FIRST, HIDE THE SPECTROGRAM ETC TO PREVENT ANNOYING FLICKERING
					Show analyses... no no no no no 10
					Zoom... zoom_start zoom_end

					# NOW SET ALL THE RELEVANT SETTINGS AND DISPLAY WIDEBAND SPECTROGRAM
					Spectrogram settings... 0 5000 0.005 50
					Advanced spectrogram settings... 1000 250 Fourier Gaussian yes 100 6 0
					Formant settings... default_max_formant default_formant_number window_length dynamic_range dot_size
					Advanced formant settings... burg preemphasis_from

					# SHOW THE FORMANT TRACKS
					if not zoom_duration = 0
						# MAKE SURE THE "MAX ANALYSIS" SETTING IS LONG ENOUGH SO THE SPECTROGRAM ACTUALLY SHOWS UP
						Show analyses... yes no no yes no zoom_duration*2
					else
						# THE USER SPECIFED "WHOLE FILE" SO WE ASSUME THE FILES ARE SHORT AND 10 SECONDS SHOULD BE ENOUGH
						Show analyses... yes yes no yes no 10
					endif
				endeditor
				
			else
				# WE'RE NOT IN THE FIRST LABELED INTERVAL, SO EDITOR IS OPEN & SETTINGS ARE SET, SO JUST MOVE TO THE CURRENT INTERVAL
				editor TextGrid 'filename$'
					Zoom... zoom_start zoom_end
				endeditor
			endif
			new_file = 0

			# INITIALIZE SOME VARIABLES FOR THE PAUSE U.I.
			clicked = 0
			max_formant = default_max_formant
			formant_number = default_formant_number
			call getMeasureTimes
			call getFormants
			call makeFormantTable
			current_time_point = getMeasureTimes.time[1]
			current_interval_measurement = 1

			# PLACE CURSOR AT FIRST MEASUREMENT POINT
			editor TextGrid 'filename$'
				Move cursor to... current_time_point
			endeditor

			# SHOW A U.I. WITH FORMANT TRACKER SETTINGS & MEASURED FORMANT VALUES.
			# KEEP SHOWING IT UNTIL THE USER ACCEPTS OR CANCELS THE MEASUREMENT FOR THIS INTERVAL.
			repeat
				beginPause ("Adjust formant tracker settings")
					comment ("File 'filename$' (file number 'current_file' of 'file_count')")
					comment ("You can change these settings if the formant track doesn't look right.")
					integer ("New_max_formant", max_formant)
					integer ("New_number_formants", formant_number)
					comment ("Clicking PLAY will play the sound in the interval")
					comment ("Clicking REDRAW will redraw the formant tracks with the settings above")
					comment ("Cicking SKIP will record all formants as zero to mark for manual measurement")
					comment (" ")
					comment ("Formant measurements:")

					# CREATE THE FORMANT TABLE
					call getFormants
					call makeFormantTable
					comment ("'makeFormantTable.header$'")
					comment ("'makeFormantTable.f3$'")
					comment ("'makeFormantTable.f2$'")
					comment ("'makeFormantTable.f1$'")
					comment (" ")
					sentence ("Notes_or_comments", "")
				clicked = endPause ("Play", "Redraw", "Skip", "Accept", 4)

				# IF THEY CLICKED "PLAY"
				if clicked = 1
					editor TextGrid 'filename$'
						Play... start end
					endeditor

				# IF THEY CLICKED "REDRAW"
				elif clicked = 2
					max_formant = new_max_formant
					formant_number = new_number_formants
					editor TextGrid 'filename$'
						Formant settings... max_formant formant_number window_length dynamic_range dot_size
					endeditor
				endif

			until clicked >2
			# END OF THE PAUSE U.I.

			# THE USER HAS EITHER ACCEPTED OR SKIPPED, SO WRITE OUT THE VALUES 
			for i from 1 to pointsPerInterval.pts
				time = getMeasureTimes.time[i]
				percent = ((time-start)/(end-start))*100			
				if clicked = 3
					# MARK FOR HAND MEASUREMENT
					f1 = 0
					f2 = 0
					f3 = 0
				elif clicked = 4
					# GET MEASURED VALUES
					f1 = getFormants.f1[i]
					f2 = getFormants.f2[i]
					f3 = getFormants.f3[i]
				endif

				# WRITE OUT TO FILE
				resultline$ = "'current_file''tab$''filename$''tab$''label$''tab$''percent:0''tab$''time''tab$''f1''tab$''f2''tab$''f3''tab$''max_formant''tab$''formant_number''tab$''notes_or_comments$''newline$'"
				fileappend "'output_file$'" 'resultline$'
				
			endfor ; EACH POINT IN THE INTERVAL
			
		endif ; LABEL <> ""
		
	endfor ; EACH INTERVAL IN THE FILE

	# REMOVE ALL THE OBJECTS FOR THAT FILE AND GO ON TO THE NEXT ONE
	select LongSound 'filename$'
	plus TextGrid 'filename$'
	Remove
	select Strings list
	
endfor ; EACH FILE IN THE FOLDER

# REMOVE THE STRINGS LIST AND GIVE A SUCCESS MESSAGE
select Strings list
Remove
clearinfo
files_read = file_count - starting_file_number + 1
printline Done! 'files_read' files read.'newline$'


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# FUNCTIONS (A.K.A. PROCEDURES) THAT WERE CALLED EARLIER  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

procedure cleanPath .in$
	if not right$(.in$, 1) = "/"
		.out$ = "'.in$'" + "/"
	else
		.out$ = "'.in$'"
	endif
endproc

procedure cleanExtn .in$
	if not left$(.in$, 1) = "."
		.out$ = "." + "'.in$'"
	else
		.out$ = "'.in$'"
	endif
endproc

procedure initializeOutfile
	headerline$ = "number'tab$'filename'tab$'label'tab$'percent through interval'tab$'measurement time'tab$'F1'tab$'F2'tab$'F3'tab$'max formant'tab$'number of formants'tab$'notes'newline$'"
	fileappend "'output_file$'" 'headerline$'
endproc

procedure pointsPerInterval
# CALCULATE HOW MANY FORMANT MEASUREMENTS PER INTERVAL
	if interval_measurement_option = 1
		.pts = 1
	elif interval_measurement_option = 2 or interval_measurement_option = 3 or interval_measurement_option = 4
		.pts = 3
	elif interval_measurement_option = 5
		.pts = 5
	elif interval_measurement_option = 6
		.pts = 7
	endif
endproc

procedure getMeasureTimes
	# MIDPOINT ONLY
	if interval_measurement_option = 1
		.time [1] = midpoint

	# ONSET-MIDPOINT-OFFSET
	elif interval_measurement_option = 2
		.time [1] = start
		.time [2] = midpoint
		.time [3] = end

	# 20-50-80
	elif interval_measurement_option = 3
		.time [1] = start + 0.2*(end-start)
		.time [2] = midpoint
		.time [3] = start + 0.8*(end-start)

	# 25-50-75
	elif interval_measurement_option = 4
		.time [1] = start + 0.25*(end-start)
		.time [2] = midpoint
		.time [3] = start + 0.75*(end-start)

	# 10-30-50-70-90
	elif interval_measurement_option = 5
		.time [1] = start + 0.1*(end-start)
		.time [2] = start + 0.3*(end-start)
		.time [3] = midpoint
		.time [4] = start + 0.7*(end-start)
		.time [5] = start + 0.9*(end-start)

	# 5-10-20-50-80-90-95
	elif interval_measurement_option = 6
		.time [1] = start + 0.05*(end-start)
		.time [2] = start + 0.1*(end-start)
		.time [3] = start + 0.2*(end-start)
		.time [4] = midpoint
		.time [5] = start + 0.8*(end-start)
		.time [6] = start + 0.9*(end-start)
		.time [7] = start + 0.95*(end-start)
	endif
endproc

procedure getFormants
	editor TextGrid 'filename$'
		for i from 1 to pointsPerInterval.pts
			Move cursor to... getMeasureTimes.time[i]
			.f3 [i] = Get third formant
			.f2 [i] = Get second formant
			.f1 [i] = Get first formant
		endfor
	endeditor
endproc

procedure makeFormantTable
# NOTE: THE EXTRA SPACES ARE INTENTIONAL, TO GET EVERYTHING TO LINE UP PROPERLY IN COLUMNS IN THE PAUSE WINDOW
	# MIDPOINT ONLY
	if interval_measurement_option = 1
		.header$ = "'tab$''tab$'midpoint"
		.f3$ = "'tab$'F3'tab$' 'getFormants.f3[1]:0'"
		.f2$ = "'tab$'F2'tab$' 'getFormants.f2[1]:0'"
		.f1$ = "'tab$'F1'tab$' 'getFormants.f1[1]:0'"

	# ONSET-MIDPOINT-OFFSET
	elif interval_measurement_option = 2
		.header$ = "'tab$''tab$'onset'tab$' mid'tab$'offset"
		.f3$ = "'tab$'F3'tab$' 'getFormants.f3[1]:0''tab$' 'getFormants.f3[2]:0''tab$' 'getFormants.f3[3]:0'"
		.f2$ = "'tab$'F2'tab$' 'getFormants.f2[1]:0''tab$' 'getFormants.f2[2]:0''tab$' 'getFormants.f2[3]:0'"
		.f1$ = "'tab$'F1'tab$' 'getFormants.f1[1]:0''tab$' 'getFormants.f1[2]:0''tab$' 'getFormants.f1[3]:0'"

	# 20-50-80
	elif interval_measurement_option = 3
		.header$ = "'tab$''tab$' 20%'tab$' 50%'tab$' 80%"
		.f3$ = "'tab$'F3'tab$' 'getFormants.f3[1]:0''tab$' 'getFormants.f3[2]:0''tab$' 'getFormants.f3[3]:0'"
		.f2$ = "'tab$'F2'tab$' 'getFormants.f2[1]:0''tab$' 'getFormants.f2[2]:0''tab$' 'getFormants.f2[3]:0'"
		.f1$ = "'tab$'F1'tab$' 'getFormants.f1[1]:0''tab$' 'getFormants.f1[2]:0''tab$' 'getFormants.f1[3]:0'"

	# 25-50-75
	elif interval_measurement_option = 4
		.header$ = "'tab$''tab$' 25%'tab$' 50%'tab$' 75%"
		.f3$ = "'tab$'F3'tab$' 'getFormants.f3[1]:0''tab$' 'getFormants.f3[2]:0''tab$' 'getFormants.f3[3]:0'"
		.f2$ = "'tab$'F2'tab$' 'getFormants.f2[1]:0''tab$' 'getFormants.f2[2]:0''tab$' 'getFormants.f2[3]:0'"
		.f1$ = "'tab$'F1'tab$' 'getFormants.f1[1]:0''tab$' 'getFormants.f1[2]:0''tab$' 'getFormants.f1[3]:0'"

	# 10-30-50-70-90
	elif interval_measurement_option = 5
		.header$ = "'tab$''tab$' 10%'tab$' 30%'tab$' 50%'tab$' 70%'tab$' 90%"
		.f3$ = "'tab$'F3'tab$' 'getFormants.f3[1]:0''tab$' 'getFormants.f3[2]:0''tab$' 'getFormants.f3[3]:0''tab$' 'getFormants.f3[4]:0''tab$' 'getFormants.f3[5]:0'"
		.f2$ = "'tab$'F2'tab$' 'getFormants.f2[1]:0''tab$' 'getFormants.f2[2]:0''tab$' 'getFormants.f2[3]:0''tab$' 'getFormants.f2[4]:0''tab$' 'getFormants.f2[5]:0'"
		.f1$ = "'tab$'F1'tab$' 'getFormants.f1[1]:0''tab$' 'getFormants.f1[2]:0''tab$' 'getFormants.f1[3]:0''tab$' 'getFormants.f1[4]:0''tab$' 'getFormants.f1[5]:0'"

	# 5-10-20-50-80-90-95
	elif interval_measurement_option = 6
		.header$ = "'tab$''tab$' 5%'tab$''tab$' 10%'tab$' 20%'tab$' 50%'tab$' 80%'tab$' 90%'tab$' 95%"
		.f3$ = "'tab$'F3'tab$' 'getFormants.f3[1]:0''tab$' 'getFormants.f3[2]:0''tab$' 'getFormants.f3[3]:0''tab$' 'getFormants.f3[4]:0''tab$' 'getFormants.f3[5]:0''tab$' 'getFormants.f3[6]:0''tab$' 'getFormants.f3[7]:0'"
		.f2$ = "'tab$'F2'tab$' 'getFormants.f2[1]:0''tab$' 'getFormants.f2[2]:0''tab$' 'getFormants.f2[3]:0''tab$' 'getFormants.f2[4]:0''tab$' 'getFormants.f2[5]:0''tab$' 'getFormants.f2[6]:0''tab$' 'getFormants.f2[7]:0'"
		.f1$ = "'tab$'F1'tab$' 'getFormants.f1[1]:0''tab$' 'getFormants.f1[2]:0''tab$' 'getFormants.f1[3]:0''tab$' 'getFormants.f1[4]:0''tab$' 'getFormants.f1[5]:0''tab$' 'getFormants.f1[6]:0''tab$' 'getFormants.f1[7]:0'"
	endif
endproc
