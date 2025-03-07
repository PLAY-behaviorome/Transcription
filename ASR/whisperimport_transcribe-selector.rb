## Before running this script: put all your zoom exported transcript .vtt files
## and/or .txt files into a folder on your desktop called zoom_transcript.
## Running this script will insert and populate a transcribe column in your
## currently open datavyu spreadsheet.

## This script imports time-stamped transcriptions exported from zoom video chats
## in the form of .vtt files (or .txt files) into the currently open datavyu
## spreadsheet.
## It will create a new column called transcript with codes <source> and
## <content> with a cell for each transcription.

## Parameters
# name of column in which to import transcription data
whisper_col_name = 'whisper'
transcript_col_name = 'transcribe'
# name of code with speaker id
speaker_id_code = 'source_mc'
# name of code with actual transcription
transcript_code = 'content'

cliponset = 0 #set to 0 to not change onset, set to 1 to clip onset by amount below.
cliponset_amt = 3000

# Change to 1 for to import speaker, 0 to leave blank.
addspeaker = 0

mom_speaker = 'mom'
child_speaker = 'child'
mom_code = 'm'
child_code = 'c'



## Body
require 'Datavyu_API.rb'
java_import javax::swing::JFileChooser
java_import javax::swing::filechooser::FileNameExtensionFilter

# Prompt user for input file.
chaFilter = FileNameExtensionFilter.new('Whisper file','vtt')
jfc = JFileChooser.new()
jfc.setAcceptAllFileFilterUsed(false)
jfc.setFileFilter(chaFilter)
jfc.setMultiSelectionEnabled(false)
jfc.setDialogTitle('Select file to import.')

ret = jfc.showSaveDialog(javax.swing.JPanel.new())

if ret != JFileChooser::APPROVE_OPTION
	puts "Invalid selection. Aborting."
	return
end

input_file = jfc.getSelectedFile().getPath()

infile = File.open(input_file, 'r')

# initialize arrays in which to store each transcription's onset, offset, source,
# and content
onset_list = []
offset_list = []
source_list = []
content_list = []

# now iterate over vtt file and populate arrays with onset, offset,
# source, and content
  header = infile.readline()
  # transcriptions are done in batches of 3 with one empty line between
  while true
    # empty line
    empty_line = infile.readline()
    # break out of loop if you've reached the end of the file
    if infile.eof?
      break
    end
    # contains timestamps
    timestamp_line = infile.readline()
    # contains source and content
    source_content_line = infile.readline()

    # get characters denoting onset HH:MM:SS.mmm
    whisp_onset = timestamp_line[0..11]
    # get characters denoting onset HH:MM:SS.mmm
    whisp_offset = timestamp_line[17..-3]
    # parse hours, minutes, seconds, and milliseconds
    whisp_onset_HH = whisp_onset.split(':')[0]
    whisp_onset_MM = whisp_onset.split(':')[1]
    whisp_onset_SS = whisp_onset.split(':')[2].split('.')[0]
    whisp_onset_mmm = whisp_onset.split(':')[2].split('.')[1]
    # same for offset
    whisp_offset_HH = whisp_offset.split(':')[0]
    whisp_offset_MM = whisp_offset.split(':')[1]
    whisp_offset_SS = whisp_offset.split(':')[2].split('.')[0]
    whisp_offset_mmm = whisp_offset.split(':')[2].split('.')[1]
    # convert to absolute milliseconds for datavyu times
    dv_onset = whisp_onset_HH.to_i*60*60*1000 + whisp_onset_MM.to_i*60*1000 +
    whisp_onset_SS.to_i*1000 + whisp_onset_mmm.to_i
    dv_offset = whisp_offset_HH.to_i*60*60*1000 + whisp_offset_MM.to_i*60*1000 +
    whisp_offset_SS.to_i*1000 + whisp_offset_mmm.to_i
    # if the utterance is long, keep the offset as is but shorten the onset
    onoff_diff = dv_offset - dv_onset
        if onoff_diff >= cliponset_amt && cliponset==1
            dv_onset = dv_offset - cliponset_amt
        end 
    onset_list << dv_onset
    offset_list << dv_offset


    # seems that some lines don't have a source preceeding the colon
    if source_content_line.include?(':')
        if source_content_line.split(':').length == 1
        source = ''
        content = source_content_line.split(':')[0][0..-3]
        else
        source = source_content_line.split(':')[0]
        content = source_content_line.split(':')[1][1..-2]
        end
    else
        content = source_content_line
    end

    content = content.delete('.')
    content = content.delete('!')
    content = content.delete(',')
    content = content.tr("-"," ")
    content = content.tr(">>"," ")
    #content.delete!("^\u{0000}-\u{007F}")
    content = content.strip
    content = content.downcase
    #content = content.gsub(/[i]\s/, "I ")
    #content = content.gsub(/[i]'[m]/,"I'm")
    content = content.gsub(/[(]/,"[")
    content = content.gsub(/[)]/,"]")
    content = content.gsub(/[**]/,"[")
    content = content.gsub(/[**]/,"]")


    source_list << source
    content_list << content

  end

# initialize new column with codes for transcript
transcribe = new_column(transcript_col_name, [speaker_id_code, transcript_code])
whisper = new_column(whisper_col_name, [speaker_id_code, transcript_code])

# loop through onsets and create a cell for each
onset_list.each_with_index do |x,i|
  # create new cell
  ncell = transcribe.new_cell
  # populate onset, offset, source, and content codes
  ncell.onset = x
  ncell.offset = offset_list[i]
  if addspeaker==1
   ncell.change_code(speaker_id_code, source_list[i])
  end
  ncell.change_code(transcript_code, content_list[i])
  # create new cell
  wcell = whisper.new_cell
  # populate onset, offset, source, and content codes
  wcell.onset = x
  wcell.offset = offset_list[i]
  wcell.change_code(speaker_id_code, source_list[i])
  wcell.change_code(transcript_code, content_list[i])
end

if addspeaker==1
transcribe.cells.each do |t|
  if t.get_code(speaker_id_code) == mom_speaker
      t.change_code(speaker_id_code,mom_code)
  end
  if t.get_code(speaker_id_code) == child_speaker
      t.change_code(speaker_id_code,child_code)
  end
end
end

whisper.cells.each do |t|
  if t.get_code(speaker_id_code) == mom_speaker
      t.change_code(speaker_id_code,mom_code)
  end
  if t.get_code(speaker_id_code) == child_speaker
      t.change_code(speaker_id_code,child_code)
  end 
end

# reflect these changes in the datavyu spreadsheet
set_column(transcript_col_name, transcribe)
set_column(whisper_col_name, whisper)
hide_columns(whisper_col_name)

