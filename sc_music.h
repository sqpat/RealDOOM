#ifndef __SC_MUSIC_H_
#define __SC_MUSIC_H_

#include "doomdef.h"
#include "m_near.h"


#define ctrlPatch 			0
#define ctrlBank 			1
#define ctrlModulation 		2
#define ctrlVolume 			3
#define ctrlPan 			4
#define ctrlExpression		5
#define ctrlReverb			6
#define ctrlChorus			7
#define ctrlSustainPedal	8
#define ctrlSoftPedal		9
#define ctrlSoundsOff		10
#define ctrlNotesOff		11
#define ctrlMono			12
#define ctrlPoly			13
#define ctrlResetCtrls		14







#define MIDI_NOTE_OFF	0x80	// release key,   <note#>, <velocity>
#define MIDI_NOTE_ON	0x90	// press key,     <note#>, <velocity>
#define MIDI_NOTE_TOUCH	0xA0	// key after-touch, <note#>, <velocity>
#define MIDI_CONTROL	0xB0	// control change, <controller>, <value>
#define MIDI_PATCH	0xC0	// patch change,  <patch#>
#define MIDI_CHAN_TOUCH	0xD0	// channel after-touch (??), <channel#>
#define MIDI_PITCH_WHEEL 0xE0	// pitch wheel,   <bottom>, <top 7 bits>
#define MIDI_EVENT_MASK	0xF0	// value to mask out the event number, not a command!

/* the following events contain no channel number */
#define MIDI_SYSEX	0xF0	// start of System Exclusive sequence
#define MIDI_SYSEX2	0xF7	// System Exclusive sequence continue
#define MIDI_TIMING	0xF8	// timing clock used when synchronization
				// is required
#define MIDI_START	0xFA	// start current sequence
#define MIDI_CONTINUE	0xFB	// continue a stopped sequence
#define MIDI_STOP	0xFC	// stop a sequence



void	MIDIplayNote(uint8_t channel, uint8_t note, int8_t noteVolume);
void	MIDIreleaseNote(uint8_t channel, uint8_t note);
void	MIDIpitchWheel(uint8_t channel, uint8_t pitch);
void	MIDIchangeControl(uint8_t channel, uint8_t controller, uint8_t value);
void	MIDIplayMusic();
void	MIDIstopMusic();
void	MIDIchangeSystemVolume(int16_t noteVolume);
int8_t  MIDIinitDriver(void);



//OPL stuff


/* MUS file header structure */
typedef struct  {
	char	ID[4];			// identifier "MUS" 0x1A
	uint16_t	scoreLen;		// score length
	uint16_t	scoreStart;		// score start
	uint16_t	channels;		// primary channels
	uint16_t	sec_channels;		// secondary channels (??)
	uint16_t    instrCnt;		// used instrument count
	uint16_t	dummy;
//	uint16_t	instruments[...];	// table of used instruments
} MUSheader;


#define FL_FIXED_PITCH	0x0001		// note has fixed pitch (see below)
#define FL_UNKNOWN	0x0002		// ??? (used in instrument #65 only)
#define FL_DOUBLE_VOICE	0x0004		// use two voices instead of one


#define OP2INSTRSIZE	sizeof( OP2instrEntry) // instrument size (36 uint8_ts)
#define OP2INSTRCOUNT	(128 + 81-35+1)	// instrument count


#define BT_EMPTY	0
#define BT_CONV		1		// conventional memory buffer
#define BT_EMS		2		// EMS memory buffer
#define BT_XMS		3		// XMS memory buffer
 


 
#define TIMER_CNT18_2	0		// INT 08h: system timer (18.2 Hz)
#define TIMER_CNT140	1		// INT 08h: system timer (140 Hz)
#define TIMER_RTC1024	2		// INT 70h: RTC periodic interrupt (1024 Hz)
#define TIMER_RTC512	3		// RTC: 512 Hz
#define TIMER_RTC256	4		// RTC: 256 Hz
#define TIMER_RTC128	5		// RTC: 128 Hz
#define TIMER_RTC64	6		// RTC: 64 Hz

#define TIMER_MIN	TIMER_CNT18_2
#define TIMER_MAX	TIMER_RTC64
 


 







uint8_t 	OPLwriteReg(uint16_t reg, uint8_t data);
int8_t		OPLconvertVolume(uint8_t data, int8_t noteVolume);
int8_t		OPLpanVolume(int8_t noteVolume, int8_t pan);
void	  	OPLinit(uint16_t port, uint8_t OPL3);
void	  	OPLdeinit(void);
int16_t		OPL2detect(uint16_t port);
int16_t		OPL3detect(uint16_t port);




#define NUM_CONTROLLERS 10



#define MIDI_NOTE_OFF	0x80	// release key,   <note#>, <velocity>
#define MIDI_NOTE_ON	0x90	// press key,     <note#>, <velocity>
#define MIDI_NOTE_TOUCH	0xA0	// key after-touch, <note#>, <velocity>
#define MIDI_CONTROL	0xB0	// control change, <controller>, <value>
#define MIDI_PATCH	0xC0	// patch change,  <patch#>
#define MIDI_CHAN_TOUCH	0xD0	// channel after-touch (??), <channel#>
#define MIDI_PITCH_WHEEL 0xE0	// pitch wheel,   <bottom>, <top 7 bits>
#define MIDI_EVENT_MASK	0xF0	// value to mask out the event number, not a command!

/* the following events contain no channel number */
#define MIDI_SYSEX	0xF0	// start of System Exclusive sequence
#define MIDI_SYSEX2	0xF7	// System Exclusive sequence continue
#define MIDI_TIMING	0xF8	// timing clock used when synchronization
				// is required
#define MIDI_START	0xFA	// start current sequence
#define MIDI_CONTINUE	0xFB	// continue a stopped sequence
#define MIDI_STOP	0xFC	// stop a sequence



void donothing();

#ifdef showerrors
	#define printerror printf
#else
	#define printerror(...) donothing
#endif

#ifdef showmessages
	#define printmessage printf
#else
	#define printmessage(...) donothing
#endif


#endif
