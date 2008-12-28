/*
  Copyright (C) 2004 Ian Esten
    
  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

  Testing git commit...
*/

#include <jack/jack.h>
#include <jack/midiport.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <unistd.h>//for close() for socket


#define MAX_EVENTS 1024

jack_client_t *client;
jack_port_t *output_port;

jack_nframes_t time_index;
int crude_lock;

typedef struct {
  jack_nframes_t time;
  int type;
  int num;
  int vel;
} event;

event events[MAX_EVENTS];

void usage()
{
  fprintf(stderr, "usage: relax\n");
}

int process(jack_nframes_t nframes, void *arg)
{ 
  int i;
  void* port_buf = jack_port_get_buffer(output_port, nframes);
  unsigned char* buffer;
  jack_midi_clear_buffer(port_buf);

  crude_lock = 1;

  for (i = 0; i < MAX_EVENTS; i++)
    {
      if (events[i].type &&
	  events[i].time >= time_index && 
	  events[i].time < time_index + (int)nframes)
	{
	  buffer = jack_midi_event_reserve(port_buf, events[i].time - time_index, 3);      
	  if (buffer)
	    {
	      buffer[0] = events[i].type;
	      buffer[1] = events[i].num;
	      buffer[2] = events[i].vel;
	    }
	}
    }
  time_index = time_index + nframes;

  crude_lock = 0;
  return 0;
}

int reset()
{
  int i;
  while (crude_lock)
    {
    }

  time_index = 0;

  for(i=0; i<MAX_EVENTS; i++)
    {
      events[i].type = 0;
    }

  return 0;
}


int main(int narg, char **args)
{
  int i;
  jack_nframes_t nframes;

  crude_lock = 0;

  fprintf (stderr, "sizeof jack_nframes_t %i\n",sizeof (jack_nframes_t));

  if((client = jack_client_new ("kseq")) == 0)
    {
      fprintf (stderr, "jack server not running?\n");
      return 1;
    }

  jack_set_process_callback (client, process, 0);
  output_port = jack_port_register (client, "out", JACK_DEFAULT_MIDI_TYPE, JackPortIsOutput, 0);
  nframes = jack_get_buffer_size(client);
  reset();

  if (jack_activate(client))
    {
      fprintf (stderr, "cannot activate client");
      return 1;
    }

  int r;
  if (r = jack_connect(client, "kseq:out" , "specimen:midi_input"))
    fprintf (stderr, "could not connect, error code %i\n", r);

  // socket shiet

  struct sockaddr_in sa;
  char buffer[10];
  sa.sin_addr.s_addr = INADDR_ANY;
  sa.sin_port = htons(1288);

  int fromlen = sizeof(sa);

  int sock = socket(PF_INET,SOCK_DGRAM,IPPROTO_UDP);
  int bound = bind(sock,(struct sockaddr *)&sa, sizeof(struct sockaddr));
  if (bound < 0)
    fprintf(stderr, "bind(): %s\n",strerror(bound));

  while (1) {
    int recsize = recvfrom(sock, (void *)buffer, 1024, 0, (struct sockaddr *)&sa, &fromlen);
    int free = -1;

    enum commands { command_reset = 0, command_event = 1 };

    switch ((unsigned char)buffer[0])
      {
      case command_reset:
	reset();
	fprintf(stderr, "time reset\n");
	break;
      case command_event:

	for(i=0; i<MAX_EVENTS; i++)
	  {
	    if(events[i].type == 0 || events[i].time < (time_index + 1024))
	      {
		free = i;
		break;
	      }
	  }
	if (free != -1)
	  {
	    events[free].type   = (unsigned char)buffer[1];
	    events[free].num    = (unsigned char)buffer[2];
	    events[free].vel    = (unsigned char)buffer[3];

	    events[free].time  = 
	      (unsigned char)buffer[4] +
	      (unsigned char)buffer[5] * 256 +
	      (unsigned char)buffer[6] * 256 * 256 +
	      (unsigned char)buffer[7] * 256 * 256 * 256;

	    //	    fprintf(stderr, "type: %i, note: %i, vel: %i, time: %i\n",events[free].type,events[free].num,events[free].vel,events[free].time);
	  }
	//	fprintf(stderr,"free: %i\n",free);
	break;
	//      default:
	//	fprintf(stderr, "unknown command\n");
      }
  }	
}
