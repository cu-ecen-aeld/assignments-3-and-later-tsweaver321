#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

int main( int argc, char *argv[] )
{
    // Initialize syslog with the identity "writer", 
    // LOG_PID -    include PID in log
    // LOG_NDELAY - open connection to syslog daemon right away
    // LOG_USER -   facility
    openlog( "writer", LOG_PID | LOG_NDELAY, LOG_USER );

    // Check if the correct number of arguments are provided
    if( argc != 3 ) 
    {
        syslog( LOG_ERR, "Exactly 2 arguments are required, but %d %s given.", 
            argc-1, (argc > 2) ? "were" : "was" );
        closelog();
        exit(1);
    }

    const char *writefile = argv[1];
    const char *writestr = argv[2];

    // Attempt to open the file for writing
    FILE *file = fopen( writefile, "w" );
    if( file == NULL ) 
    {
        // Log an error message if file opening fails
        syslog( LOG_ERR, "Error opening file: %s", writefile );
        closelog();
        exit(1);
    }

    // Write the string to the file
    fputs( writestr, file );

    // Close the file
    fclose( file );

    // Log the action with DEBUG level
    syslog( LOG_DEBUG, "Writing %s to %s", writestr, writefile );

    // Close syslog
    closelog();

    return 0;
}
