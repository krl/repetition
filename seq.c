#include <jack/jack.h>
#include <jack/midiport.h>
#include <stdio.h>

#define RINGBUFFER_SIZE 2048

jack_client_t *client;
jack_port_t *output_port;

jack_nframes_t time_index = 0;
int read_index = 0;
int write_index = 0;
int client_active = 0;
int killed = 0;

typedef struct {
  jack_nframes_t time;
  unsigned char data[3];
} event;

event eventbuffer[RINGBUFFER_SIZE];

void usage()
{
  fprintf(stderr, "usage: relax\n");
}

int process(jack_nframes_t nframes, void *arg)
{ 
  int i;
  void* port_buf = jack_port_get_buffer(output_port, nframes);
  unsigned char *buffer;
  jack_midi_clear_buffer(port_buf);

  unsigned char all_notes_off = 123;

  while (!killed &&
	 write_index > read_index &&
	 eventbuffer[read_index].time <= (time_index + nframes))
    {
      /* printf("process, read: %i, write: %i\n", read_index, write_index); */
      /* fflush(stdout); */

      /* printf("%i: writing %i %i %i\n", */
      /* 	     eventbuffer[read_index].time,   */
      /* 	     eventbuffer[read_index].data[0], */
      /* 	     eventbuffer[read_index].data[1],  */
      /* 	     eventbuffer[read_index].data[2]); */
      /* fflush(stdout); */

      if (eventbuffer[read_index].data[0] == 252) // midi reset
	{	 
	  jack_midi_event_write(port_buf, 0, &all_notes_off , 1); // all notes off
	  printf("killed\n");
	  fflush(stdout);
	  killed = 1;
	}
      else
	{
	  jack_midi_event_write(port_buf, (int)(eventbuffer[read_index].time - time_index), eventbuffer[read_index].data , 3);
	  read_index++;
	}
    }

  time_index = time_index + nframes;
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

  if((client = jack_client_new ("kseq")) == 0)
    {
      fprintf (stderr, "jack server not running?\n");
      return 1;
    }

  jack_set_process_callback (client, process, 0);
  output_port = jack_port_register (client, "out", JACK_DEFAULT_MIDI_TYPE, JackPortIsOutput, 0);
  nframes = jack_get_buffer_size(client);

  // wait for data

  printf ("waiting for data...\n");

  fflush(stdout);

  while (!killed) 
    {
      //read loop
      if (write_index > RINGBUFFER_SIZE) write_index = 0;
      fread (&eventbuffer[write_index], 7, 1, stdin);

      printf ("time: %i, event: %i, key: %i, velocity: %i\n",
	       eventbuffer[write_index].time,
	       eventbuffer[write_index].data[0],
	       eventbuffer[write_index].data[1],
	       eventbuffer[write_index].data[2]);
      fflush(stdout);

      write_index++;

      if (!client_active)
	activate_and_connect();

    }

  jack_deactivate(client);
  return 0;

}
