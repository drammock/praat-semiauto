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
# "Show analyses" (lines 214 & 217).  If you want to change the underlying spectrogram settings, change lines 205-206.
# VERSION 0.2 (2012.05.25)
#
# CHANGELOG
# VERSION 0.2:	No significant code changes.  Moderate improvements to documentation.  License changed from CC to GPL.
#
# AUTHORS: DANIEL MCCLOY: (drmccloy@uw.edu) & AUGUST MCGRATH
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

# CALCULATE HOW MANY FORMANT MEASUREMENTS PER INTERVAL
if interval_measurement_option = 1
	total_interval_measurements = 1
elif interval_measurement_option = 2 or interval_measurement_option = 3 or interval_measurement_option = 4
	total_interval_measurements = 3
elif interval_measurement_option = 5
	total_interval_measurements = 5
elif interval_measurement_option = 6
	total_interval_measurements = 7
endif

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
			else
				zoom_start = 0
				zoom_end = total_duration
			endif

			# CALCULATE TIME POINTS FOR FORMANT MEASUREMENTS
			# MIDPOINT ONLY
			if interval_measurement_option = 1
				intrvl_meas_time [1] = midpoint

			# ONSET-MIDPOINT-OFFSET
			elif interval_measurement_option = 2
				intrvl_meas_time [1] = start
				intrvl_meas_time [2] = midpoint
				intrvl_meas_time [3] = end

			# 20%-50%-80%
			elif interval_measurement_option = 3
				intrvl_meas_time [1] = start + 0.2*(end-start)
				intrvl_meas_time [2] = midpoint
				intrvl_meas_time [3] = start + 0.8*(end-start)

			# 25%-50%-75%
			elif interval_measurement_option = 4
				intrvl_meas_time [1] = start + 0.25*(end-start)
				intrvl_meas_time [2] = midpoint
				intrvl_meas_time [3] = start + 0.75*(end-start)

			# 10%-30%-50%-70%-90%
			elif interval_measurement_option = 5
				intrvl_meas_time [1] = start + 0.1*(end-start)
				intrvl_meas_time [2] = start + 0.3*(end-start)
				intrvl_meas_time [3] = midpoint
				intrvl_meas_time [4] = start + 0.7*(end-start)
				intrvl_meas_time [5] = start + 0.9*(end-start)

			# 5%-10%-20%-50%-80%-90%-95%
			elif interval_measurement_option = 6
				intrvl_meas_time [1] = start + 0.05*(end-start)
				intrvl_meas_time [2] = start + 0.1*(end-start)
				intrvl_meas_time [3] = start + 0.2*(end-start)
				intrvl_meas_time [4] = midpoint
				intrvl_meas_time [5] = start + 0.8*(end-start)
				intrvl_meas_time [6] = start + 0.9*(end-start)
				intrvl_meas_time [7] = start + 0.95*(end-start)
			endif
			current_time_point = intrvl_meas_time [1]

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

					# PLACE CURSOR AT FIRST MEASUREMENT POINT AND SHOW THE FORMANT TRACKS
					Move cursor to... current_time_point
					if not zoom_duration = 0
						# MAKE SURE THE "MAX ANALYSIS" SETTING IS LONG ENOUGH SO THE SPECTROGRAM ACTUALLY SHOWS UP
						Show analyses... yes no no yes no zoom_duration+1
					else
						# THE USER SPECIFED "WHOLE FILE" SO WE ASSUME THE FILES ARE SHORT AND 10 SECONDS SHOULD BE ENOUGH
						Show analyses... yes yes no yes no 10
					endif
				endeditor
			else
				# WE'RE NOT IN THE FIRST LABELED INTERVAL, SO THE EDITOR IS ALREADY OPEN & THE SETTINGS ARE ALREADY SET,
				# SO JUST MOVE TO THE RIGHT PART OF THE FILE
				editor TextGrid 'filename$'
					Zoom... zoom_start zoom_end
					Move cursor to... current_time_point
				endeditor
			endif
			new_file = 0

			# INITIALIZE SOME VARIABLES FOR THE PAUSE U.I.
			clicked = 4
			max_formant = default_max_formant
			formant_number = default_formant_number
			current_interval_measurement = 1

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

					# CREATE HEADER ROW FOR THE FORMANT TABLE.  NOTE THERE ARE SOME EXTRA SPACES TO GET EVERYTHING TO LINE UP.
					# MIDPOINT LABEL
					if interval_measurement_option = 1
						comment ("'tab$''tab$'midpoint")
						
					# ONSET-MIDPOINT-OFFSET LABEL
					elif interval_measurement_option = 2
						comment ("'tab$''tab$'onset'tab$' mid'tab$'offset")
						
					# 20-50-80 LABEL
					elif interval_measurement_option = 3
						comment ("'tab$''tab$' 20%'tab$' 50%'tab$' 80%")
						
					# 25-50-75 LABEL
					elif interval_measurement_option = 4
						comment ("'tab$''tab$' 25%'tab$' 50%'tab$' 75%")
						
					# 10-30-50-70-90 LABEL
					elif interval_measurement_option = 5
						comment ("'tab$''tab$' 10%'tab$' 30%'tab$' 50%'tab$' 70%'tab$' 90%")
						
					# 5-10-20-50-80-90-95 LABEL
					elif interval_measurement_option = 6
						comment ("'tab$''tab$' 5%'tab$''tab$' 10%'tab$' 20%'tab$' 50%'tab$' 80%'tab$' 90%'tab$' 95%")
					endif

					# CREATE THE FORMANT TABLE
					# MIDPOINT TABLE
					if interval_measurement_option = 1
						editor TextGrid 'filename$'
							f3_50 = Get third formant
							f2_50 = Get second formant
							f1_50 = Get first formant
						endeditor
						comment ("'tab$'F3'tab$' 'f3_50:0'")
						comment ("'tab$'F2'tab$' 'f2_50:0'")
						comment ("'tab$'F1'tab$' 'f1_50:0'")
					# THREE POINT TABLE
					elif interval_measurement_option = 2 or interval_measurement_option = 3 or interval_measurement_option = 4
						editor TextGrid 'filename$'
							for i from 1 to total_interval_measurements
								Move cursor to... intrvl_meas_time[i]
								f3[i] = Get third formant
								f2[i] = Get second formant
								f1[i] = Get first formant
							endfor
						endeditor
						comment ("'tab$'F3'tab$' 'f3[1]:0''tab$' 'f3[2]:0''tab$' 'f3[3]:0'")
						comment ("'tab$'F2'tab$' 'f2[1]:0''tab$' 'f2[2]:0''tab$' 'f2[3]:0'")
						comment ("'tab$'F1'tab$' 'f1[1]:0''tab$' 'f1[2]:0''tab$' 'f1[3]:0'")
					# FIVE POINT TABLE
					elif interval_measurement_option = 5
						editor TextGrid 'filename$'
							for i from 1 to total_interval_measurements
								Move cursor to... intrvl_meas_time[i]
								f3[i] = Get third formant
								f2[i] = Get second formant
								f1[i] = Get first formant
							endfor
						endeditor
						comment ("'tab$'F3'tab$' 'f3[1]:0''tab$' 'f3[2]:0''tab$' 'f3[3]:0''tab$' 'f3[4]:0''tab$' 'f3[5]:0'")
						comment ("'tab$'F2'tab$' 'f2[1]:0''tab$' 'f2[2]:0''tab$' 'f2[3]:0''tab$' 'f2[4]:0''tab$' 'f2[5]:0'")
						comment ("'tab$'F1'tab$' 'f1[1]:0''tab$' 'f1[2]:0''tab$' 'f1[3]:0''tab$' 'f1[4]:0''tab$' 'f1[5]:0'")
					# SEVEN POINT TABLE
					elif interval_measurement_option = 6
						editor TextGrid 'filename$'
							for i from 1 to total_interval_measurements
								Move cursor to... intrvl_meas_time[i]
								f3[i] = Get third formant
								f2[i] = Get second formant
								f1[i] = Get first formant
							endfor
						endeditor
						comment ("'tab$'F3'tab$' 'f3[1]:0''tab$' 'f3[2]:0''tab$' 'f3[3]:0''tab$' 'f3[4]:0''tab$' 'f3[5]:0''tab$' 'f3[6]:0''tab$' 'f3[7]:0'")
						comment ("'tab$'F2'tab$' 'f2[1]:0''tab$' 'f2[2]:0''tab$' 'f2[3]:0''tab$' 'f2[4]:0''tab$' 'f2[5]:0''tab$' 'f2[6]:0''tab$' 'f2[7]:0'")
						comment ("'tab$'F1'tab$' 'f1[1]:0''tab$' 'f1[2]:0''tab$' 'f1[3]:0''tab$' 'f1[4]:0''tab$' 'f1[5]:0''tab$' 'f1[6]:0''tab$' 'f1[7]:0'")
					endif
					comment (" ")
					sentence ("Notes_or_comments", "")
				clicked = endPause ("Play", "Redraw", "Skip", "Accept", 4)
				max_formant = new_max_formant
				formant_number = new_number_formants
				editor TextGrid 'filename$'
					Formant settings... max_formant formant_number window_length dynamic_range dot_size
				endeditor

				# IF THEY CLICKED "PLAY"
				if clicked = 1
					editor TextGrid 'filename$'
						Play... start end
					endeditor
				endif

			until clicked >2
			# END OF THE PAUSE U.I.

			# IF THE USER SKIPS THE INTERVAL...
			if clicked = 3
				# WRITE ZEROES
				for i from 1 to total_interval_measurements
					time = intrvl_meas_time [i]
					printline 'time'
					percent = ((time-start)/(end-start))*100
					f1 = 0
					f2 = 0
					f3 = 0
					# WRITE TO FILE
					resultline$ = "'current_file''tab$''filename$''tab$''label$''tab$''percent:0''tab$''time''tab$''f1''tab$''f2''tab$''f3''tab$''max_formant''tab$''formant_number''tab$''notes_or_comments$''newline$'"
					fileappend "'output_file$'" 'resultline$'
				endfor

			# IF THE USER ACCEPTS THE FORMANT VALUES...
			elif clicked = 4
				# CREATE A FORMANT OBJECT WITH THE CURRENT SETTINGS AND TAKE THE MEASUREMENT
				select LongSound 'filename$'
				Extract part... start end yes
				select Sound 'filename$'
				To Formant (burg)... time_step formant_number max_formant window_length preemphasis_from
				select Formant 'filename$'
				for i from 1 to total_interval_measurements
					time = intrvl_meas_time [i]
					percent = ((time-start)/(end-start))*100
					f1 = Get value at time... 1 time Hertz Linear
					f2 = Get value at time... 2 time Hertz Linear
					f3 = Get value at time... 3 time Hertz Linear
					# WRITE TO FILE
					resultline$ = "'current_file''tab$''filename$''tab$''label$''tab$''percent:0''tab$''time''tab$''f1''tab$''f2''tab$''f3''tab$''max_formant''tab$''formant_number''tab$''notes_or_comments$''newline$'"
					fileappend "'output_file$'" 'resultline$'
				endfor

				# REMOVE THE EXTRACTED SOUND AND FORMANT OBJECT, SINCE LATER INTERVALS IN THIS FILE MAY GET DIFFERENT SETTINGS AND THUS GET EXTRACTED ANEW
				plus Sound 'filename$'
				Remove
			endif
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
	headerline$ = "number'tab$'filename'tab$'label'tab$'percent through interval'tab$'measurement time'tab$'F1'tab$'F2'tab$'F3'tab$'max formant'tab$'number of formants'tab$'notes'newline$'"
	fileappend "'output_file$'" 'headerline$'
endproc
