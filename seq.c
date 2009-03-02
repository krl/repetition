#include <jack/jack.h>
#include <jack/midiport.h>
#include <stdio.h>

#define RINGBUFFER_SIZE 1024 * 1024 

#define SYNC_TIME 10000

#define EVENT 0
#define PLAY 1
#define SYNC 2

enum status { STOPPED, RUNNING, KILLED };

jack_client_t *client;
jack_port_t *output_port;

jack_nframes_t time_index = 0;
jack_nframes_t last_event_time = 0;
int read_index = 0;
int write_index = 0;
int client_active = 0;
enum status status = STOPPED;

typedef struct {
  jack_nframes_t time;
  unsigned char type;
  unsigned char data[3];
} event;

event eventbuffer[RINGBUFFER_SIZE];

void usage()
{
  fprintf (stderr, "usage: relax\n");
}

int process(jack_nframes_t nframes, void *arg)
{ 
  int i;
  void* port_buf = jack_port_get_buffer(output_port, nframes);
  unsigned char *buffer;
  jack_midi_clear_buffer(port_buf);


  if (status == RUNNING)
    {
      while (write_index > read_index &&
	     eventbuffer[read_index].time <= (time_index + nframes))
	{
	  jack_midi_event_write(port_buf, (int)(eventbuffer[read_index].time - time_index), eventbuffer[read_index].data , 3);
	  read_index++;

	  fprintf(stderr, "sending midi message\n");
	  fflush(stdout);
	}

      time_index = time_index + nframes;
    }

  return 0;
}

int activate_and_connect()
{
  if (jack_activate(client))
    {
      fprintf (stderr, "cannot activate client");
      return 1;
    }

  int r;
  if (r = jack_connect(client, "kseq:out" , "specimen:midi_input"))
    fprintf (stderr, "could not connect, error code %i\n", r);

  client_active = 1;
}

int main(int narg, char **args)
{
  int i;
  jack_nframes_t nframes;
  event buffer;

  if((client = jack_client_new ("kseq")) == 0)
    {
      fprintf (stderr, "jack server not running?\n");
      return 1;
    }

  fprintf (stderr, "firing up... sizeof event: %i\n", sizeof(event));

  jack_set_process_callback (client, process, 0);
  output_port = jack_port_register (client, "out", JACK_DEFAULT_MIDI_TYPE, JackPortIsOutput, 0);
  nframes = jack_get_buffer_size(client);

  last_event_time = 0;

  // wait for data

  fprintf (stderr, "waiting for data...\n");
  fflush(stdout);

  while (status != KILLED) 
    {
      //read loop
      if (write_index > RINGBUFFER_SIZE) write_index = 0;
      fread (&buffer, sizeof(buffer), 1, stdin);

      fprintf (stderr, "got event type %i\n", buffer.type);

      switch (buffer.type)
	{
	case EVENT:
	  fprintf (stderr, "time: %i, event: %i, key: %i, velocity: %i\n",
		  buffer.time,
		  buffer.data[0],
		  buffer.data[1],
		  buffer.data[2]);

	  last_event_time = buffer.time;
	  eventbuffer[write_index++] = buffer;
	  break;

	case PLAY: 
	  fprintf (stderr, "playing\n");
	  time_index = 0;
	  status = RUNNING;
	  break;

	case SYNC:

	  if (status == RUNNING)
	    {
	      if ( time_index > last_event_time )
		{
		  last_event_time = time_index + SYNC_TIME;
		}
	      else
		{
		  fprintf (stderr, "waiting for sync.\n");
		  while ( time_index < (last_event_time - SYNC_TIME)) {}
		}
	    }

	  fprintf (stderr, "sync at offset %i.\n", last_event_time);

	  fwrite(&last_event_time, 4, 1, stdout);
	  fflush(stdout);
	  break;
	}

	  fflush(stderr);

      if (!client_active)
	activate_and_connect();
    }

  jack_deactivate(client);
  return 0;

}
