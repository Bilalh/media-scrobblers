#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdbool.h>

#define FIFO_NAME   "/Users/bilalh/.mplayer/pipe"
#define FIFO_OUTPUT "~/.mplayer/output"
#define SCRIPT      "/usr/local/bin/lastfm_from_mplayer_output.rb"
#define INFO        "/usr/local/bin/audio_info_display.rb"

static const char *command           = "print_text ${percent-pos}\n";
static const char *pos_command       = "print_text ${=length}\n";
static const long  scroble           = 50; // %
static const long  epScroble         = 65; // sec

int main (int argc, char const *argv[]) {
	const int command_length = strlen(command);
	const int pos_length = strlen(pos_command);
	
	int fd = open(FIFO_NAME, O_WRONLY);
	FILE *fp;
	char buff[27];
	long pos = 0,len = 0;
	bool current_done = false;
	
	while(true){
		// write to the pipe.
		write(fd, command, command_length);
		usleep(300000);
		
		// get %
		fp = popen("tail -n1 " FIFO_OUTPUT , "r");
		fgets(buff, sizeof(buff)-1, fp);
		pclose(fp);
		pos = strtol(buff, NULL, 10);
		
		// get time-length
		write(fd, pos_command, pos_length);
		usleep(300000);
		
		fp = popen("tail -n1 " FIFO_OUTPUT , "r");
		fgets(buff, sizeof(buff)-1, fp);
		len = strtol(buff, NULL, 10);
		pclose(fp);
		
#ifdef SHOW_INFO
		if (pos < 3){
			system(INFO);
		}
#endif
		
		// scrobble to lastfm.
		if (!current_done && (pos >= scroble || (len > 1200 && pos > 4) )) {
			system(SCRIPT);
			current_done = true;
		}
		
		// we are on the next track.
		else if (current_done  && ((len < 1200 && pos < scroble) || (len > 1200 && pos <4) ) ) {
			current_done = false;
			
		}
		
		
		sleep(5);
	}
	return 0;
}
