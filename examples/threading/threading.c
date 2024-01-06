#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void *threadfunc( void *thread_param )
{
    struct thread_data *thread_func_args = (struct thread_data *)thread_param;

    // Sleep for wait_to_obtain_ms milliseconds
    usleep( thread_func_args->wait_to_obtain_ms * 1000 );

    // Attempt to obtain the mutex
    if( pthread_mutex_lock( thread_func_args->mutex ) != 0 ) 
    {
        // Failed to obtain the mutex
        thread_func_args->thread_complete_success = false;
    }
    else
    {
        // Sleep for wait_to_release_ms milliseconds
        usleep( thread_func_args->wait_to_release_ms * 1000 );

        // Attempt to release the mutex
        if( pthread_mutex_unlock( thread_func_args->mutex ) != 0 ) 
        {
            // Failed to release the mutex
            thread_func_args->thread_complete_success = false;
        }
        else
        {
            // Set thread completion status to true
            thread_func_args->thread_complete_success = true;
        }
    }

    // Return the thread_data structure
    return thread_param;
}


bool start_thread_obtaining_mutex(  pthread_t *thread, 
                                    pthread_mutex_t *mutex, 
                                    int wait_to_obtain_ms, 
                                    int wait_to_release_ms )
{
    // Allocate memory for thread_data
    struct thread_data *thread_data = (struct thread_data *)malloc( sizeof( struct thread_data ) );
    if( thread_data == NULL ) 
    {
        return false; // Memory allocation failed
    }

    // Set up thread_data structure
    thread_data->mutex = mutex;
    thread_data->wait_to_obtain_ms = wait_to_obtain_ms;
    thread_data->wait_to_release_ms = wait_to_release_ms;
    thread_data->thread_complete_success = false;

    // Create the thread
    // - Save thread Id in Thread
    // - Use default thread attributes
    // - Routine = threadfunc
    // - thread_data is input arg to threadfunc
    int result = pthread_create( thread, NULL, threadfunc, (void *)thread_data );

    if( result != 0 ) 
    {
        // Release memory if thread creation fails
        free( thread_data ); 
        return false;
    }

    return true;
}


