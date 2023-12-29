#include <stdio.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <fcntl.h>
#include "systemcalls.h"


/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system( const char *cmd )
{
    bool rval = false;

    // Use system() to execute the command
    int status = system( cmd );

    if( status == -1 ) 
    {
        // Handle the failure to create a new process
        perror( "Error executing system command" );
    } 
    else 
    {
        // Check if the command exited normally (status 0)
        if( WIFEXITED( status ) ) 
        {
            // Check if the exit status is 0 (success)
            if( WEXITSTATUS( status ) == 0 ) 
            {
                rval = true;
            } 
            else 
            {
                // Handle the case where the command returned a 
                // non-zero exit status
                printf( "Command exited with non-zero status: %d\n", 
                    WEXITSTATUS( status ) );
            }
        } 
        else 
        {
            // Handle the case where the command did not exit normally
            printf( "Command did not exit normally\n" );
        }
    }

    return rval;
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/
bool do_exec( int count, ... )
{
    va_list args;
    va_start( args, count );
    char *command[count + 1];
    int i;
    
    // Load command arguments into an array with the last element 
    // containing NULL
    for( i = 0; i < count; i++ ) 
    {
        command[i] = va_arg( args, char * );
    }
    command[count] = NULL;

    // Fork the child process
    pid_t child_pid = fork();

    if( child_pid == -1 ) 
    {
        perror( "Fork failed" );
        va_end( args );
        return false;
    }

    if( child_pid == 0 ) 
    {
        // This is the child process
        // Launch new command with arguments
        if( execv( command[0], command ) == -1 ) 
        {
            printf( "*** ERROR: exec failed with return value -1\n" );
            perror( "Execv failed" );
            exit( EXIT_FAILURE );
        }
    } 
    else 
    {
        // This is the parent process
        // Wait for Child process to complete
        int status;
        waitpid( child_pid, &status, 0 );

        va_end(args);

        // Check if the child process terminated successfully
        if( WIFEXITED( status ) && ( WEXITSTATUS( status ) ) == 0 ) 
        {
            // Success
            return true;
        } 
        else 
        {
            // Failed
            return false;
        }
    }

    return false;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect( const char *outputfile, int count, ... )
{
    va_list args;
    char *command[count + 1];
    int i;

    va_start(args, count);

    // Load command arguments into an array with the last element 
    // containing NULL
    for( i = 0; i < count; i++ ) 
    {
        command[i] = va_arg( args, char * );
    }
    command[count] = NULL;

    // Execute the command with the redirected standard output
    // Fork the child process
    pid_t child_pid = fork();

    if( child_pid == -1 ) 
    {
        perror( "Fork failed" );
        va_end( args );
        return false;
    }

    if( child_pid == 0 ) 
    {
        // This is the child process
        // Open the output file for writing, create it if it doesn't exist, truncate it if it does
        int outputFileDescriptor = open( outputfile, O_WRONLY | O_CREAT | O_TRUNC, 0644 );
        if( outputFileDescriptor == -1 ) 
        {
            perror( "open failed" );
            exit( EXIT_FAILURE );
        }

        // Redirect standard output to the output file
        if( dup2( outputFileDescriptor, STDOUT_FILENO ) == -1 ) 
        {
            perror( "dup2 failed" );
            close( outputFileDescriptor );
            exit( EXIT_FAILURE );
        }

        // Close the original file descriptor
        close( outputFileDescriptor );

        // Launch new command with arguments
        if( execv( command[0], command ) == -1 ) 
        {
            printf( "*** ERROR: exec failed with return value -1\n" );
            perror( "Execv failed" );
            exit( EXIT_FAILURE );
        }
    } 
    else 
    {
        // This is the parent process
        // Wait for Child process to complete
        int status;
        waitpid( child_pid, &status, 0 );

        va_end(args);

        // Check if the child process terminated successfully
        if( WIFEXITED( status ) && ( WEXITSTATUS( status ) ) == 0 ) 
        {
            // Success
            return true;
        } 
        else 
        {
            // Failed
            return false;
        }
    }

    return false;
}

