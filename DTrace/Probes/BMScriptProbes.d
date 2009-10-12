/*
 * Copyright (c) 2009 André Berg (Berg Media)
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

typedef long NSInteger;
typedef unsigned long NSUInteger;
typedef int BOOL;
typedef NSInteger TerminationStatus;

typedef struct {
  NSUInteger location;
  NSUInteger length;
} NSRange;

provider BMScript {

    /* Atomic Probes */
    /*
    probe enter_execute(char * scriptSource, char * isTemplate, char * launchPath);
    probe  exit_execute(char * result);
    
    probe enter_execute_and_return_result(char * scriptSource, char * isTemplate, char * launchPath);
    probe  exit_execute_and_return_result(char * result);
    
    probe enter_execute_and_return_result_error(char * scriptSource, char * isTemplate, char * launchPath);
    probe  exit_execute_and_return_result_error(char * result);
            
    probe enter_launch_task_and_store_last_result(char * taskIsRunning, char * lastResult);
    probe  exit_launch_task_and_store_last_result(char * taskIsRunning, char * lastResult);
    
    probe enter_setup_and_launch_background_task(char * bgTaskIsRunning, char * lastResult);
    probe  exit_setup_and_launch_background_task(char * bgTaskIsRunning, char * lastResult);
    
    probe enter_stop_task();
    probe  exit_stop_task(char * bgTaskIsRunning, char * lastResult);
    
    probe enter_data_received();
    probe  exit_data_received();
    
    probe enter_data_complete();
    probe  exit_data_complete(char * lastResult);
    
    probe enter_append_data();
    probe  exit_append_data(char * partialResult);
    
    probe enter_task_terminated();
    probe  exit_task_terminated(char * lastResult, char * partialResult);
    */
    
    /* Deallocation */
    
    probe setup_task_begin();
    probe   setup_task_end();
    
    probe cleanup_task_begin();
    probe cleanup_task_end();
        
    probe setup_bg_task_begin();
    probe   setup_bg_task_end();
    
    probe stop_bg_task_begin(); /* stopTask calls cleanupTask for bg task, */
    probe stop_bg_task_end();   /* so this is more interesting than just cleanup */
    
    probe cleanup_bg_task_begin();
    probe cleanup_bg_task_end();
    
    /* Initialization */
    
    probe init_begin(char * source, char * options);
    probe init_end(char * debugDescription); 
        
    /* Execution */
    
    probe execute_begin(char * launchPath, char * scriptSource, char * isTemplate);
    probe execute_end(char * result);
    
    probe bg_execute_begin( char * launchPath, char * scriptSource, char * isTemplate);
    probe bg_execute_end(char * result);
    
    probe net_execution_begin(char * statusText); /* net execution is just [[task launch] waitUntilExit] */
    probe net_execution_end(char * statusText);
    
    probe append_data_begin(char * newData);
    probe append_data_end(char * partialResult);
    
    /* Templates */
    
    probe saturate_with_argument_begin(char * theArg);
    probe saturate_with_argument_end(char * saturatedScript);
    
    probe saturate_with_arguments_begin();
    probe saturate_with_arguments_end(char * saturatedScript);
    
    probe saturate_with_dictionary_begin(char * theDict);
    probe saturate_with_dictionary_end(char * saturatedScript);
    
    /* History */
    
    probe script_at_index_begin(NSInteger index, int historySize);
    probe script_at_index_end(char * script, int historySize);
    
    probe result_at_index_begin(NSInteger index, int historySize);
    probe result_at_index_end(char * result, int historySize);
    
    probe last_script_begin(int historySize);
    probe last_script_end(char * script, int historySize);
    
    probe last_result_begin(int historySize);
    probe last_result_end(char * result, int historySize);
    
    /* Locking */
    
    probe acquire_lock_start(char * usesPthread);
    probe acquire_lock_end(char * usesPthread);

};