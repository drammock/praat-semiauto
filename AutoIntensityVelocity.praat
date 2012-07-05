# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# PRAAT SCRIPT "CALCULATE INTENSITY VELOCITY"
# This script calculates the rate at which the intensity of a sound is changing over time.  It cycles through a directory of sound files, opens them one at a time, and saves intensity information to an output file, analysis frame by analysis frame, so that changes in intensity velocity can be tracked through the course of the file.
#
# VERSION 0.1 (2012 06 25)
#
# AUTHOR: DANIEL MCCLOY: (drmccloy@uw.edu)
# LICENSED UNDER THE GNU GENERAL PUBLIC LICENSE v3.0 OR HIGHER: http://www.gnu.org/licenses/gpl.html
# DEVELOPMENT OF THIS SCRIPT WAS FUNDED BY THE NATIONAL INSTITUTES OF HEALTH, GRANT # 10186254 TO PAMELA SOUZA
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 


# COLLECT ALL THE USER INPUT
form Measure intensity velocity
	sentence Output_file /home/dan/Desktop/intensityVelocity.tab
	sentence Sound_directory /home/dan/Desktop/sounds/
	sentence Sound_extension .wav
	comment You can pick up where you left off if you like:
	integer Starting_file 1
	comment Intensity analysis parameters
	real Intensity_time_step_(seconds) 0 (= auto)
	positive Minimum_pitch_(Hz) 100
	boolean Subtract_mean yes
endform

# BE FORGIVING IF THE USER FORGOT TRAILING PATH SLASHES OR LEADING FILE EXTENSION DOTS
call cleanPath 'sound_directory$'
sound_dir$ = "'cleanPath.output$'"
call cleanExtn 'sound_extension$'
sound_extn$ = "'cleanExtn.output$'"

# MAKE A LIST OF ALL SOUNDS IN THE FOLDER
Create Strings as file list... list 'sound_dir$'*'sound_extn$'
file_list = selected("Strings")
file_count = Get number of strings

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

# OPEN EACH SOUND FILE IN THE DIRECTORY
for filenum from starting_file to file_count
	filename$ = Get string... filenum
	Read from file... 'sound_directory$''filename$'
	echo analysing file 'filenum' of 'file_count' ('filename$')

	# GET THE NAME OF THE CURRENT SOUND OBJECT
	soundname$ = selected$ ("Sound", 1)

	# CREATE AN INTENSITY OBJECT
	To Intensity... minimum_pitch intensity_time_step subtract_mean

	# BECAUSE THESE FILES ARE SILENCE-PADDED BY 50ms AT THE BEGINNING AND END
	start = 0.05
	end = Get end time
	end = end - 0.05
	
	# GET BASIC INFO (MIN,MAX,ETC)
	sf = Get frame number from time... start
	ef = Get frame number from time... end
	start_frame = ceiling(sf)
	end_frame = floor(ef)
	frames = end_frame - start_frame
	min = Get minimum... start end Parabolic
	max = Get maximum... start end Parabolic
	avg = Get mean... start end dB
	std = Get standard deviation... start end
	
	for framenum from start_frame to end_frame
		# GET INTENSITY VALUE & FRAME DURATION
		int = Get value in frame... framenum
		tim = Get time from frame number... framenum
		dur = Get time step

		# CALCULATE VELOCITY, TAKING CARE AROUND ENDPOINTS
		if framenum = 1
			next_int = Get value in frame... framenum+1
			vel = (next_int-int)/dur
		elif framenum = end_frame
			prev_int = Get value in frame... framenum-1
			vel = (int-prev_int)/dur
		else
			prev_int = Get value in frame... framenum-1
			next_int = Get value in frame... framenum+1
			vel = (next_int-prev_int)/(2*dur)
		endif
		
		# WRITE THE DATA TO FILE
		resultline$ = "'filenum''tab$''soundname$''tab$''tim''tab$''framenum''tab$''frames''tab$''dur''tab$''int''tab$''vel''newline$'"
		fileappend "'output_file$'" 'resultline$'
		
	endfor

	# REMOVE THE SOUND AND INTENSITY OBJECTS AND CONTINUE TO NEXT SOUND
	select Sound 'soundname$'
	plus Intensity 'soundname$'
	Remove
	select Strings list
endfor

# WHEN EVERYTHING IS DONE, REMOVE THE STRINGS LIST
Remove
ending_file = filenum-1
echo files 'starting_file' through 'ending_file' of 'file_count' analysed.

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
	headerline$ = "number'tab$'filename'tab$'time'tab$'frameNumber'tab$'totalFrames'tab$'frameDuration'tab$'intensity_dB'tab$'velocity_dBperSecond'newline$'"
	fileappend "'output_file$'" 'headerline$'
endproc
