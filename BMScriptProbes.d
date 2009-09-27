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
    
    probe enter_execute(char * scriptSource, char * isTemplate, char * launchPath);
    probe  exit_execute(char * result);
    
    probe enter_execute_and_return_result(char * scriptSource, char * isTemplate, char * launchPath);
    probe  exit_execute_and_return_result(char * result);
    
    probe enter_execute_and_return_result_error(char * scriptSource, char * isTemplate, char * launchPath);
    probe  exit_execute_and_return_result_error(char * result);
    
    probe enter_setup_task(char * taskIsRunning);
    probe  exit_setup_task(char * taskIsRunning);
            
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
        
    /* Execution */
    
    probe start_net_execute(char * scriptSource, char * isTemplate, char * launchPath);
    probe end_net_execute(char * result);
    
    probe start_bg_execute(char * scriptSource, char * isTemplate, char * launchPath);
    probe end_bg_execute(char * result);
    
    probe start_task_launch(TerminationStatus status, char * statusText);
    probe end_task_launch(TerminationStatus status, char * statusText);
    
    /* Templates */
    
    probe start_saturate_with_argument(char * theArg);
    probe end_saturate_with_argument(char * saturatedScript);
    
    probe start_saturate_with_arguments();
    probe end_saturate_with_arguments(char * saturatedScript);
    
    probe start_saturate_with_dictionary(char * theDict);
    probe end_saturate_with_dictionary(char * saturatedScript);
    
    /* History */
    
    probe enter_script_source_from_history_at_index(NSInteger index, int historySize);
    probe  exit_script_source_from_history_at_index(char * script, int historySize);
    
    probe enter_result_from_history_at_index(NSInteger index, int historySize);
    probe  exit_result_from_history_at_index(char * result, int historySize);
    
    probe enter_last_script_source_from_history(int historySize);
    probe  exit_last_script_source_from_history(char * script, int historySize);
    
    probe enter_last_result_from_history(int historySize);
    probe  exit_last_result_from_history(char * result, int historySize);
    
    /* Locking */
    
    probe acquire_lock_start(char * usesPthread);
    probe acquire_lock_end(char * usesPthread);

};