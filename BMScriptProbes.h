/*
 * Generated by dtrace(1M).
 */

#ifndef	_BMSCRIPTPROBES_H
#define	_BMSCRIPTPROBES_H

#include <unistd.h>

#ifdef	__cplusplus
extern "C" {
#endif

#define BMSCRIPT_STABILITY "___dtrace_stability$BMScript$v1$1_1_0_1_1_0_1_1_0_1_1_0_1_1_0"

#define BMSCRIPT_TYPEDEFS "___dtrace_typedefs$BMScript$v2$5465726d696e6174696f6e537461747573$4e53496e7465676572"

#define	BMSCRIPT_ACQUIRE_LOCK_END(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$acquire_lock_end$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_ACQUIRE_LOCK_END_ENABLED() \
	__dtrace_isenabled$BMScript$acquire_lock_end$v1()
#define	BMSCRIPT_ACQUIRE_LOCK_START(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$acquire_lock_start$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_ACQUIRE_LOCK_START_ENABLED() \
	__dtrace_isenabled$BMScript$acquire_lock_start$v1()
#define	BMSCRIPT_APPEND_DATA_BEGIN(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$append_data_begin$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_APPEND_DATA_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$append_data_begin$v1()
#define	BMSCRIPT_APPEND_DATA_END(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$append_data_end$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_APPEND_DATA_END_ENABLED() \
	__dtrace_isenabled$BMScript$append_data_end$v1()
#define	BMSCRIPT_BG_EXECUTE_BEGIN(arg0, arg1, arg2) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$bg_execute_begin$v1$63686172202a$63686172202a$63686172202a(arg0, arg1, arg2); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_BG_EXECUTE_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$bg_execute_begin$v1()
#define	BMSCRIPT_BG_EXECUTE_END(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$bg_execute_end$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_BG_EXECUTE_END_ENABLED() \
	__dtrace_isenabled$BMScript$bg_execute_end$v1()
#define	BMSCRIPT_CLEANUP_BG_TASK_BEGIN() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$cleanup_bg_task_begin$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_CLEANUP_BG_TASK_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$cleanup_bg_task_begin$v1()
#define	BMSCRIPT_CLEANUP_BG_TASK_END() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$cleanup_bg_task_end$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_CLEANUP_BG_TASK_END_ENABLED() \
	__dtrace_isenabled$BMScript$cleanup_bg_task_end$v1()
#define	BMSCRIPT_CLEANUP_TASK_BEGIN() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$cleanup_task_begin$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_CLEANUP_TASK_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$cleanup_task_begin$v1()
#define	BMSCRIPT_CLEANUP_TASK_END() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$cleanup_task_end$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_CLEANUP_TASK_END_ENABLED() \
	__dtrace_isenabled$BMScript$cleanup_task_end$v1()
#define	BMSCRIPT_INIT_BEGIN(arg0, arg1, arg2) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$init_begin$v1$63686172202a$63686172202a$63686172202a(arg0, arg1, arg2); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_INIT_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$init_begin$v1()
#define	BMSCRIPT_INIT_END(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$init_end$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_INIT_END_ENABLED() \
	__dtrace_isenabled$BMScript$init_end$v1()
#define	BMSCRIPT_INIT_SELF() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$init_self$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_INIT_SELF_ENABLED() \
	__dtrace_isenabled$BMScript$init_self$v1()
#define	BMSCRIPT_LAST_RESULT_BEGIN(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$last_result_begin$v1$696e74(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_LAST_RESULT_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$last_result_begin$v1()
#define	BMSCRIPT_LAST_RESULT_END(arg0, arg1) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$last_result_end$v1$63686172202a$696e74(arg0, arg1); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_LAST_RESULT_END_ENABLED() \
	__dtrace_isenabled$BMScript$last_result_end$v1()
#define	BMSCRIPT_LAST_SCRIPT_BEGIN(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$last_script_begin$v1$696e74(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_LAST_SCRIPT_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$last_script_begin$v1()
#define	BMSCRIPT_LAST_SCRIPT_END(arg0, arg1) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$last_script_end$v1$63686172202a$696e74(arg0, arg1); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_LAST_SCRIPT_END_ENABLED() \
	__dtrace_isenabled$BMScript$last_script_end$v1()
#define	BMSCRIPT_NET_EXECUTE_BEGIN(arg0, arg1, arg2) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$net_execute_begin$v1$63686172202a$63686172202a$63686172202a(arg0, arg1, arg2); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_NET_EXECUTE_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$net_execute_begin$v1()
#define	BMSCRIPT_NET_EXECUTE_END(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$net_execute_end$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_NET_EXECUTE_END_ENABLED() \
	__dtrace_isenabled$BMScript$net_execute_end$v1()
#define	BMSCRIPT_RESULT_AT_INDEX_BEGIN(arg0, arg1) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$result_at_index_begin$v1$4e53496e7465676572$696e74(arg0, arg1); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_RESULT_AT_INDEX_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$result_at_index_begin$v1()
#define	BMSCRIPT_RESULT_AT_INDEX_END(arg0, arg1) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$result_at_index_end$v1$63686172202a$696e74(arg0, arg1); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_RESULT_AT_INDEX_END_ENABLED() \
	__dtrace_isenabled$BMScript$result_at_index_end$v1()
#define	BMSCRIPT_SATURATE_WITH_ARGUMENT_BEGIN(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$saturate_with_argument_begin$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SATURATE_WITH_ARGUMENT_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$saturate_with_argument_begin$v1()
#define	BMSCRIPT_SATURATE_WITH_ARGUMENT_END(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$saturate_with_argument_end$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SATURATE_WITH_ARGUMENT_END_ENABLED() \
	__dtrace_isenabled$BMScript$saturate_with_argument_end$v1()
#define	BMSCRIPT_SATURATE_WITH_ARGUMENTS_BEGIN() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$saturate_with_arguments_begin$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SATURATE_WITH_ARGUMENTS_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$saturate_with_arguments_begin$v1()
#define	BMSCRIPT_SATURATE_WITH_ARGUMENTS_END(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$saturate_with_arguments_end$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SATURATE_WITH_ARGUMENTS_END_ENABLED() \
	__dtrace_isenabled$BMScript$saturate_with_arguments_end$v1()
#define	BMSCRIPT_SATURATE_WITH_DICTIONARY_BEGIN(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$saturate_with_dictionary_begin$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SATURATE_WITH_DICTIONARY_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$saturate_with_dictionary_begin$v1()
#define	BMSCRIPT_SATURATE_WITH_DICTIONARY_END(arg0) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$saturate_with_dictionary_end$v1$63686172202a(arg0); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SATURATE_WITH_DICTIONARY_END_ENABLED() \
	__dtrace_isenabled$BMScript$saturate_with_dictionary_end$v1()
#define	BMSCRIPT_SCRIPT_AT_INDEX_BEGIN(arg0, arg1) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$script_at_index_begin$v1$4e53496e7465676572$696e74(arg0, arg1); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SCRIPT_AT_INDEX_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$script_at_index_begin$v1()
#define	BMSCRIPT_SCRIPT_AT_INDEX_END(arg0, arg1) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$script_at_index_end$v1$63686172202a$696e74(arg0, arg1); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SCRIPT_AT_INDEX_END_ENABLED() \
	__dtrace_isenabled$BMScript$script_at_index_end$v1()
#define	BMSCRIPT_SETUP_BG_TASK_BEGIN() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$setup_bg_task_begin$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SETUP_BG_TASK_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$setup_bg_task_begin$v1()
#define	BMSCRIPT_SETUP_BG_TASK_END() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$setup_bg_task_end$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SETUP_BG_TASK_END_ENABLED() \
	__dtrace_isenabled$BMScript$setup_bg_task_end$v1()
#define	BMSCRIPT_SETUP_TASK_BEGIN() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$setup_task_begin$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SETUP_TASK_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$setup_task_begin$v1()
#define	BMSCRIPT_SETUP_TASK_END() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$setup_task_end$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_SETUP_TASK_END_ENABLED() \
	__dtrace_isenabled$BMScript$setup_task_end$v1()
#define	BMSCRIPT_STOP_BG_TASK_BEGIN() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$stop_bg_task_begin$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_STOP_BG_TASK_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$stop_bg_task_begin$v1()
#define	BMSCRIPT_STOP_BG_TASK_END() \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$stop_bg_task_end$v1(); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_STOP_BG_TASK_END_ENABLED() \
	__dtrace_isenabled$BMScript$stop_bg_task_end$v1()
#define	BMSCRIPT_TASK_LAUNCH_BEGIN(arg0, arg1) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$task_launch_begin$v1$5465726d696e6174696f6e537461747573$63686172202a(arg0, arg1); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_TASK_LAUNCH_BEGIN_ENABLED() \
	__dtrace_isenabled$BMScript$task_launch_begin$v1()
#define	BMSCRIPT_TASK_LAUNCH_END(arg0, arg1) \
do { \
	__asm__ volatile(".reference " BMSCRIPT_TYPEDEFS); \
	__dtrace_probe$BMScript$task_launch_end$v1$5465726d696e6174696f6e537461747573$63686172202a(arg0, arg1); \
	__asm__ volatile(".reference " BMSCRIPT_STABILITY); \
} while (0)
#define	BMSCRIPT_TASK_LAUNCH_END_ENABLED() \
	__dtrace_isenabled$BMScript$task_launch_end$v1()


extern void __dtrace_probe$BMScript$acquire_lock_end$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$acquire_lock_end$v1(void);
extern void __dtrace_probe$BMScript$acquire_lock_start$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$acquire_lock_start$v1(void);
extern void __dtrace_probe$BMScript$append_data_begin$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$append_data_begin$v1(void);
extern void __dtrace_probe$BMScript$append_data_end$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$append_data_end$v1(void);
extern void __dtrace_probe$BMScript$bg_execute_begin$v1$63686172202a$63686172202a$63686172202a(char *, char *, char *);
extern int __dtrace_isenabled$BMScript$bg_execute_begin$v1(void);
extern void __dtrace_probe$BMScript$bg_execute_end$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$bg_execute_end$v1(void);
extern void __dtrace_probe$BMScript$cleanup_bg_task_begin$v1(void);
extern int __dtrace_isenabled$BMScript$cleanup_bg_task_begin$v1(void);
extern void __dtrace_probe$BMScript$cleanup_bg_task_end$v1(void);
extern int __dtrace_isenabled$BMScript$cleanup_bg_task_end$v1(void);
extern void __dtrace_probe$BMScript$cleanup_task_begin$v1(void);
extern int __dtrace_isenabled$BMScript$cleanup_task_begin$v1(void);
extern void __dtrace_probe$BMScript$cleanup_task_end$v1(void);
extern int __dtrace_isenabled$BMScript$cleanup_task_end$v1(void);
extern void __dtrace_probe$BMScript$init_begin$v1$63686172202a$63686172202a$63686172202a(char *, char *, char *);
extern int __dtrace_isenabled$BMScript$init_begin$v1(void);
extern void __dtrace_probe$BMScript$init_end$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$init_end$v1(void);
extern void __dtrace_probe$BMScript$init_self$v1(void);
extern int __dtrace_isenabled$BMScript$init_self$v1(void);
extern void __dtrace_probe$BMScript$last_result_begin$v1$696e74(int);
extern int __dtrace_isenabled$BMScript$last_result_begin$v1(void);
extern void __dtrace_probe$BMScript$last_result_end$v1$63686172202a$696e74(char *, int);
extern int __dtrace_isenabled$BMScript$last_result_end$v1(void);
extern void __dtrace_probe$BMScript$last_script_begin$v1$696e74(int);
extern int __dtrace_isenabled$BMScript$last_script_begin$v1(void);
extern void __dtrace_probe$BMScript$last_script_end$v1$63686172202a$696e74(char *, int);
extern int __dtrace_isenabled$BMScript$last_script_end$v1(void);
extern void __dtrace_probe$BMScript$net_execute_begin$v1$63686172202a$63686172202a$63686172202a(char *, char *, char *);
extern int __dtrace_isenabled$BMScript$net_execute_begin$v1(void);
extern void __dtrace_probe$BMScript$net_execute_end$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$net_execute_end$v1(void);
extern void __dtrace_probe$BMScript$result_at_index_begin$v1$4e53496e7465676572$696e74(NSInteger, int);
extern int __dtrace_isenabled$BMScript$result_at_index_begin$v1(void);
extern void __dtrace_probe$BMScript$result_at_index_end$v1$63686172202a$696e74(char *, int);
extern int __dtrace_isenabled$BMScript$result_at_index_end$v1(void);
extern void __dtrace_probe$BMScript$saturate_with_argument_begin$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$saturate_with_argument_begin$v1(void);
extern void __dtrace_probe$BMScript$saturate_with_argument_end$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$saturate_with_argument_end$v1(void);
extern void __dtrace_probe$BMScript$saturate_with_arguments_begin$v1(void);
extern int __dtrace_isenabled$BMScript$saturate_with_arguments_begin$v1(void);
extern void __dtrace_probe$BMScript$saturate_with_arguments_end$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$saturate_with_arguments_end$v1(void);
extern void __dtrace_probe$BMScript$saturate_with_dictionary_begin$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$saturate_with_dictionary_begin$v1(void);
extern void __dtrace_probe$BMScript$saturate_with_dictionary_end$v1$63686172202a(char *);
extern int __dtrace_isenabled$BMScript$saturate_with_dictionary_end$v1(void);
extern void __dtrace_probe$BMScript$script_at_index_begin$v1$4e53496e7465676572$696e74(NSInteger, int);
extern int __dtrace_isenabled$BMScript$script_at_index_begin$v1(void);
extern void __dtrace_probe$BMScript$script_at_index_end$v1$63686172202a$696e74(char *, int);
extern int __dtrace_isenabled$BMScript$script_at_index_end$v1(void);
extern void __dtrace_probe$BMScript$setup_bg_task_begin$v1(void);
extern int __dtrace_isenabled$BMScript$setup_bg_task_begin$v1(void);
extern void __dtrace_probe$BMScript$setup_bg_task_end$v1(void);
extern int __dtrace_isenabled$BMScript$setup_bg_task_end$v1(void);
extern void __dtrace_probe$BMScript$setup_task_begin$v1(void);
extern int __dtrace_isenabled$BMScript$setup_task_begin$v1(void);
extern void __dtrace_probe$BMScript$setup_task_end$v1(void);
extern int __dtrace_isenabled$BMScript$setup_task_end$v1(void);
extern void __dtrace_probe$BMScript$stop_bg_task_begin$v1(void);
extern int __dtrace_isenabled$BMScript$stop_bg_task_begin$v1(void);
extern void __dtrace_probe$BMScript$stop_bg_task_end$v1(void);
extern int __dtrace_isenabled$BMScript$stop_bg_task_end$v1(void);
extern void __dtrace_probe$BMScript$task_launch_begin$v1$5465726d696e6174696f6e537461747573$63686172202a(TerminationStatus, char *);
extern int __dtrace_isenabled$BMScript$task_launch_begin$v1(void);
extern void __dtrace_probe$BMScript$task_launch_end$v1$5465726d696e6174696f6e537461747573$63686172202a(TerminationStatus, char *);
extern int __dtrace_isenabled$BMScript$task_launch_end$v1(void);

#ifdef	__cplusplus
}
#endif

#endif	/* _BMSCRIPTPROBES_H */
