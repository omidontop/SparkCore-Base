//
// This file is part of the GNU ARM Eclipse distribution.
// Copyright (c) 2014 Liviu Ionescu.
//

// ----------------------------------------------------------------------------

#include <stdio.h>
#include "Trace.h"
#include "cmsis_os.h"
#include "BlinkLed.h"

// ----------------------------------------------------------------------------
//
// STM32F1 led blink sample (trace via ITM).
//
// In debug configurations, demonstrate how to print a greeting message
// on the trace device. In release configurations the message is
// simply discarded.
//
// To demonstrate POSIX retargetting, reroute the STDOUT and STDERR to the
// trace device and display messages on both of them.
//
// Then demonstrates how to blink a led with 1Hz, using a
// continuous loop and SysTick delays.
//
// On DEBUG, the uptime in seconds is also displayed on the trace device.
//
// Trace support is enabled by adding the TRACE macro definition.
// By default the trace messages are forwarded to the ITM output,
// but can be rerouted to any device or completely suppressed, by
// changing the definitions required in system/src/diag/trace_impl.c
// (currently OS_USE_TRACE_SEMIHOSTING_DEBUG/_STDOUT).
//
// The external clock frequency is specified as a preprocessor definition
// passed to the compiler via a command line option (see the 'C/C++ General' ->
// 'Paths and Symbols' -> the 'Symbols' tab, if you want to change it).
// The value selected during project creation was HSE_VALUE=8000000.
//
// Note: The default clock settings take the user defined HSE_VALUE and try
// to reach the maximum possible system clock. For the default 8MHz input
// the result is guaranteed, but for other values it might not be possible,
// so please adjust the PLL settings in system/src/cmsis/system_stm32f10x.c
//

void Thread_LedBlink (void const *arg); // function prototype for Thread_LedBlink
osThreadDef (Thread_LedBlink, osPriorityNormal, 1, 0); // define Thread_LedBlink

// ----- main() ---------------------------------------------------------------

// Sample pragmas to cope with warnings. Please note the related line at
// the end of this function, used to pop the compiler diagnostics status.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wmissing-declarations"
#pragma GCC diagnostic ignored "-Wreturn-type"

int main(int argc, char* argv[])
{
	// By customising __initialize_args() it is possible to pass arguments,
	// for example when running tests with semihosting you can pass various
	// options to the test.
	// trace_dump_args(argc, argv);

	// Send a greeting to the trace device (skipped on Release).
	trace_puts("Hello!");

	// The standard output and the standard error should be forwarded to
	// the trace device. For this to work, a redirection in _write.c is
	// required.
	// puts( "Standard output message." );
	// fprintf(stderr, "Standard error message.\n");

	// At this stage the system clock should have already been configured
	// at high speed.
	trace_printf("System Clock: %uHz\n", SystemCoreClock);

	trace_printf( "Initializing Kernel..." );
	if( osKernelInitialize() == osOK )
	{
		trace_printf( "OK\n" );
	}
	else
	{
		trace_printf( "FAILED\n" );
	}

	osThreadId id;
	trace_printf( "Creating a thread..." );
	osThreadDef( Thread_LedBlink, osPriorityBelowNormal, 1, 500 );
	id = osThreadCreate( osThread (Thread_LedBlink), NULL ); // create the thread
	if (id == NULL)
	{
		// Failed to create a thread
		trace_printf( "FAILED\n" );
	}
	else
	{
		trace_printf( "OK\n" );
	}

	trace_printf( "Starting Kernel..." );
	if( osKernelStart() == osOK )
	{
		trace_printf( "OK\n" );
	}
	else
	{
		trace_printf( "FAILED\n" );
	}

	// Infinite loop
	while (1)
	{

		//blinkLed.turnOff();

	}
  // Infinite loop, never return.
}

void Thread_LedBlink (void const *arg)
{
	uint32_t period = 1000;
	float32_t dutycycle = 0.1;

	uint32_t seconds = 0;
	BlinkLed blinkLed;

	const uint32_t on_period = (uint32_t)( dutycycle * period );
	const uint32_t off_period = period - on_period;
	/*
	** Perform the initializations necessary.
	*/

	blinkLed.powerUp();

	while( 1 )
	{
		blinkLed.turnOn();
		osDelay( on_period );
		blinkLed.turnOff();
		osDelay( off_period );

		++seconds;
		trace_printf("Seconds Elapsed: %u\n", seconds);
	}
}

#pragma GCC diagnostic pop

// ----------------------------------------------------------------------------
