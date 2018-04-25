#!/usr/bin/env python
# -*- coding: UTF-8 -*-
import os
import sys
import pwd
import subprocess
import tempfile
import logging
import time
import datetime
from logging.handlers import TimedRotatingFileHandler
from pyinotify import WatchManager, IN_DELETE, IN_CREATE, IN_CLOSE_WRITE, ProcessEvent, Notifier
from apscheduler.schedulers.background import BackgroundScheduler
from optparse import OptionParser
from itertools import chain
from dbdict import dbdict

# nfs file system flag 
nfs_flag = True 

# Store m_time of all files to check if the file has been updated by the user
# or by the system itself
filechecks = {}

# monitor default folder is current folder
folders = ''

check = lambda filepath: os.stat(filepath).st_mtime
# Logger
logger = logging.getLogger("")
log_file = "/var/log/transcoder/transcoder"

# List of group of filetypes. Each dictionary in the list is all extensions 
# and codecs that needs to exist for this kind of file
file_in_types = [
	{
		'.webm': {'c:v':'libvpx','c:a':'libvorbis'},
	},
]
file_out_types = [
	{
		'.mp4': {'c:v':'libx264','crf':'36','c:a':'libfdk_aac','profile:a':'aac_he_v2','b:a':'32k'},
	},
]
# FFmpeg executable name or path
ffmpeg_exec = 'ffmpeg -hide_banner -y -acodec libopus'
ffprobe_exec = 'ffprobe -v quiet -print_format json -show_entries \
			format=filename,duration:format_tags=creation_time'
				
def valid_check(filepath):
	if os.path.exists(filepath):
		#logger.debug("file:%s is valid", filepath)
		return True 
	else:
		logger.error("file:%s is not exist!!!", filepath)
		return False
			
def diff_stamp(filepath, delay):
	tag = False
	# Max modified delay
	max_delay = 60 * delay # 30 min convert to secs
	logger.debug("max delay:%s", str(max_delay))
	# Curent time
	now = time.time()
	
	# Get last modified time, [8] would be last create time
	file_mtime = os.stat(filepath)[7] 	
	diff = now-file_mtime
	
	if diff < max_delay:
		logger.info("File not reached timeout period:%s", filepath)
		tag = False
	else:
		logger.info("File reached timeout period:%s", filepath)
		tag = True
	return tag
		
def log_init(log_filename):
	# Initialize Logger
	logger.setLevel(logging.INFO)
	log_format = logging.Formatter("%(asctime)s %(funcName)s %(lineno)d [%(levelname)s]: %(message)s")

	# when executing the collector separately, log directly on the output stream
	stream_handler = logging.StreamHandler()
	stream_handler.setFormatter(log_format)
	logger.addHandler(stream_handler)
	
	# time rotating file handler
	try:
		file_time_handler = TimedRotatingFileHandler(log_filename,"D",1,0)
		file_time_handler.suffix="%Y-%m-%d_%H_%M_%S"
		file_time_handler.setFormatter(log_format)
		logger.addHandler(file_time_handler)
		logger.info("Log Handler added for file: %s", log_filename)
	except Exception, e:
		logger.warn("Could not create logfile: %s")
		logger.exception(e)
		pass
		
def remove_invalid_files(filepath):
	""" Remove filepath from filesystem and filechecks
	"""
	logger.debug("remove invalid file:%s", filepath)
	if not filepath:
		logger.info("File is null")
		return
	path, extension = os.path.splitext(filepath)
	file_in_type = get_in_type(extension)
	file_out_type = get_out_type(extension)
	# remove file is input
	if file_in_type:
		for ext in file_in_type:
			filepath=path+ext
			logger.info("Deleting filepath and related files: %s", filepath)
			if filechecks.has_key(filepath):
				del filechecks[filepath]
			if os.path.exists(filepath):
				os.remove(filepath)
	# remove file is output
	elif file_out_type:
		for ext in file_out_type:
			filepath=path+ext
			logger.info("Deleting filepath and related files: %s", filepath)
			if filechecks.has_key(filepath):
				del filechecks[filepath]
			if os.path.exists(filepath):
				os.remove(filepath)
	else:
		logger.error("Deleting file %s is illegal",filepath)

def modify_owner(filepath):
	""" Modify file owner from root to waypal
	"""
	logger.info("Call chown to modify file owner to waypal:%s", filepath)
	command = " ".join(["chown","waypal:waypal","'%s'" %filepath])
	logger.info("Call command:%s", command)
	with tempfile.TemporaryFile() as tmp:
		try:
			exit_code = subprocess.call(command, stderr=tmp, shell=True)
			if exit_code !=0:
				tmp.seek(0)
				error_output = tmp.read()
				logger.info("Error while modifid.")
				logger.error("error code: %d", exit_code)
				logger.error("error info: %s", error_output)
				return error_output
			logger.info("modified done.")
		except Exception, e:
			logger.error("process stopped. Reason:")
			logger.exception(e)
			return "ExceptionError"
			pass
			
def ffprobe(file_in,file_out):
	""" Call ffprobe to get file info and save to roomInfo.json
	"""
	logger.info("Call ffprobe to get file info:%s", file_out)
	path = os.path.dirname(os.path.abspath(file_in))
	json = path+'/roomInfo.json'
	
	if os.path.exists(json):
		command = " ".join([ffprobe_exec, "'%s'"%file_in, ">>'%s'"%json])
	else:
		command = " ".join([ffprobe_exec, "'%s'"%file_in, ">'%s'"%json])
		
	logger.info("Call ffprobe command:%s", command)
	
	with tempfile.TemporaryFile() as tmp:
		try:
			exit_code = subprocess.call(command, stderr=tmp, shell=True)
			if exit_code !=0:
				tmp.seek(0)
				error_output = tmp.read()
				logger.info("Error while ffprobe.")
				logger.error("ffprobe error code: %d", exit_code)
				logger.error("ffprobe error info: %s", error_output)
				return error_output
			logger.info("Get and write file Info done.")
		except Exception, e:
			logger.error("ffprobe process stopped. Reason:")
			logger.exception(e)
			return "ExceptionError"
			pass
	
def ffmpeg(file_in, file_out, codecs):
	""" Calls ffmpeg to convert file_in to file_out using codecs
	"""
	logger.info("Call ffmpeg to convert %s->%s", file_in, file_out)
	
	path = os.path.dirname(os.path.abspath(file_in))
	tmp_out = path+'/tmp.mp4'
	
	codecs = " ".join(["-%s %s" %(t,c) for t,c in codecs.items()])
	#watermark = " ".join("-i","/transcoder/logo.png","-filter_complex 'overlay=overlay=0:main_h-overlay_h'")
	command = " ".join([ffmpeg_exec,"-i '%s'" %file_in,codecs,"-max_muxing_queue_size 1024 ","'%s'"%tmp_out])
	logger.info("Call ffmpeg command:%s", command)
	
	with tempfile.TemporaryFile() as tmp:
		try:
			exit_code = subprocess.call(command, stderr=tmp, shell=True)
			if exit_code !=0:
				tmp.seek(0)
				error_output = tmp.read()
				logger.info("Error while converting.")
				logger.error("ffmpeg error code: %d", exit_code)
				logger.error("ffmpeg error info: %s", error_output)
				return error_output
			logger.info("conversion done.")
			os.rename(tmp_out, file_out)
		except Exception, e:
			logger.error("ffmpeg process stopped. Reason:")
			logger.exception(e)
			return "ExceptionError"
			pass
    
def get_in_type(extension):
	""" Return the group of file_in_types, defined globally, that extension is part of.
	"""
	for filetype in file_in_types:
		if extension in filetype.keys():
			return filetype

def get_out_type(extension):
	""" Return the group of file_out_types, defined globally, that extension is part of.
	"""
	for filetype in file_out_types:
		if extension in filetype.keys():
			return filetype

def verify(filepath):
	""" Check if all the extensions has been created for filepath extension
			group, and creates if doesn't.
	"""
	ret = valid_check(filepath)
	if not ret:
		return
	
	path, extension = os.path.splitext(filepath)
	file_in_type = get_in_type(extension)
	file_out_type = get_out_type(".mp4")
	
	if not file_in_type:
		logger.debug("File:%s Input format is illegal",filepath)
		return
	
	if not file_out_type:
		logger.debug("File:%s Output format is illegal",filepath)
		return
	
	filecheck = filechecks.get(filepath,None)
	if filecheck == check(filepath):
		logger.debug("File had been watched:%s", filepath)
		# Todo 
		# Auto remove source file, 3days 3*24*60
		return
		
	# Max modified delay is 30 min
	if not diff_stamp(filepath, 3):
		return
		
	if filecheck:
		logger.info("File change detected:%s", filepath)
	else:
		logger.info("New file detected:%s", filepath)
	
	filechecks[filepath] = check(filepath)
	
	for ext,codecs in file_out_type.items():
		new_file = path+ext
		
		if new_file == filepath:
			logger.info("Agnore file which had been transcoded %s", filepath)
			continue
		
		if filecheck == None and os.path.exists(new_file):
			logger.info("A unknown file detected: %s. Assuming it is correct.", new_file)
			filechecks[new_file] = check(new_file)
			continue
		
		error = ffmpeg(filepath,new_file,codecs)
		if error:
			logger.info("Transcoder %s->%s is failed", filepath, new_file)
			if valid_check(new_file):
				os.remove(new_file)
			continue
		logger.info("Add transcode file to filecheck list:%s.", new_file)
		filechecks[new_file] = check(new_file)
		
		# Modify file ower
		modify_owner(filepath)
		modify_owner(new_file)
		
		error = ffprobe(filepath,new_file)
		if error:
			logger.info("Write file info %s is failed", new_file)
			continue

def get_all_files(folder):
	""" Returns a generator that lists all files from a specific folder,
			recursively.
	"""
	logger.info("Generator all files from a specific folder:%s", folder)
	for dirpath, dirnames, filenames in os.walk(folder):
		for filename in filenames:
			if filename.endswith(".webm"):
				if os.path.getsize(os.path.join(dirpath,filename)):
					yield os.path.join(dirpath, filename)

def verify_all():
	""" Calls verify for all files found on all specified folders,
			and remove all non existant files.
	"""
	logger.info("Verifying existing files...")
	# Add/Update all files
	for filepath in chain(*map(get_all_files,folders)):
		verify(filepath)
	
	#Remove non existant files
	for filepath in filechecks:
		if not os.path.exists(filepath):
			remove_invalid_files(filepath)
	
	logger.info("All files verified.")
	
class Process(ProcessEvent):
	""" Process class that is connected to WatchManager.
			Everytime an event happens the specific method
			from this class is called.
	"""
	def __init__(self, wm, mask):
		self.wm = wm
		self.mask = mask
			
	def process_IN_CREATE(self, event):
		""" File or directory has been created.
				If a folder is created, add it to be monitored
		"""
		logger.info("Create file:%s/%s", event.path,event.name)
		path = os.path.join(event.path, event.name)
		if os.path.isdir(path):
				self.wm.add_watch(path, self.mask, rec=True)

	def process_IN_CLOSE_WRITE(self, event):
		""" File has been closed after a write.
				The verification is done here to make sure
				that everything was written to the file before
				any conversion starts
		"""
		logger.info("File:%s/%s has been closed after a write", event.path, event.name)
		filepath = os.path.join(event.path, event.name)
		verify(filepath)
	
	def process_IN_DELETE(self, event):
		""" File or directory has been deleted.
				If a file is deleted, remove it from filechecks
		"""
		logger.info("File or directory:%s/%s has been deleted.", event.path, event.name)
		filepath = os.path.join(event.path, event.name)
		if filechecks.has_key(filepath):
			remove_invalid_files(filepath)

def monitor_loop():
	""" Main loop, create everything needed for the notification
			and waits for a notification. Loop again when notification
			happens.
	"""
	if nfs_flag:
		scheduler = BackgroundScheduler()
		scheduler.add_job(verify_all, 'interval', seconds=60*1)
		scheduler.start()
		try:
			# This is here to simulate application activity (which keeps the main thread alive).
			while True:
				time.sleep(10)    
				logger.info('sleep!')
		except (KeyboardInterrupt, SystemExit):
			# Not strictly necessary if daemonic mode is enabled but should be done if possible
			scheduler.shutdown()
			logger.info('Exit The Job!')
	else:
		wm = WatchManager()
		mask = IN_CLOSE_WRITE | IN_CREATE | IN_DELETE 
		process = Process(wm, mask)
		notifier = Notifier(wm, process)
		for folder in folders:
			logger.info("Monitor loop---folder:%s", folder)
			wdd = wm.add_watch(folder, mask, rec=True)
		try:
			while True:
				notifier.process_events()
				if notifier.check_events():
					notifier.read_events()
		except (KeyboardInterrupt, SystemExit):
			notifier.stop()

def command_line_args():
	""" Deals with command line arguments
	"""
	usage = "usage: %prog [options] folders"
	parser = OptionParser(usage=usage)
	parser.add_option("-v", "--no-verify", dest="verify", default=True,
			action="store_false", help="Does not verify all folders contents before start monitor")
	parser.add_option("-m", "--no-monitor", dest="monitor", default=True,
			action="store_false", help="Does not start folder monitor")
	parser.add_option("-d", "--database", dest="database", default=os.path.expanduser('/transcoderdb/waypal-transcoder.db'),
			help="Change SQLite database file")
			
	return parser.parse_args()

def start():
	""" Starts application
	"""
	logger.info("Starts application...")
	global filechecks
	global folders
	
	options, folders = command_line_args()
	filechecks = dbdict(options.database)
	logger.info("Transcoder Database is %s",options.database)
	
	if not folders:
		#monitor default folder is current folder
		folders.append(os.getcwd())
		
	folders = [os.path.abspath(folder) for folder in folders]
	logger.info("Monitor folder:%s", folders)
	
	if options.verify:		
		verify_all()
			
	if options.monitor:
		monitor_loop()

if __name__ == "__main__":
	log_init(log_file)
	start()