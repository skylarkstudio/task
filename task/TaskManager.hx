package task;


import com.eclecticdesignstudio.utils.MessageLog;
import task.TaskList;


class TaskManager {
	
	
	private static var list = new TaskList ();
	
	
	/**
	 * Add a new task to the pending tasks list
	 * @param	task		A new task
	 * @param	prerequisiteTasks		(Optional) An array of task objects or IDs which must be completed before running the task
	 * @param	autoComplete		(Optional) Determines whether to automatically mark tasks as complete after they are run. Does not affect tasks which use TaskList.handleEvent. Default is true.
	 */
	public static function addTask (task:Task, prerequisiteTasks:Array <Dynamic> = null, autoComplete:Bool = true):Void {
		
		list.addTask (task, prerequisiteTasks, autoComplete);
		
	}
	
	
	/**
	 * Marks a task as complete
	 * @param	reference		A task object or ID to mark as complete
	 */
	public static function completeTask (reference:Dynamic):Void {
		
		list.completeTask (reference);
		
	}
	
	
	/**
	 * When autoComplete is true, the TaskList will mark the task as complete once it has been run. This works correctly for synchronous function calls, but may not work as expected 
	 * for asynchronous function calls, such as when you are loading a file. In these situations, you can wrap the completion event with TaskList.handleEvent to autoComplete in these
	 * situations.
	 * 
	 * For example, here is a basic synchronous function call:
	 * 
	 * new Task ("Say Hello", trace, [ "Hello!" ]);
	 * 
	 * Here is an example of an asynchronous function call:
	 * 
	 * new Task ("Load XML", loadXML, [ xmlPath, loadXML_onComplete ]);
	 * 
	 * While the synchronous call is finished once the target method has been called, the asynchronous call is still waiting for the file to load. Here is an example of the same task, using
	 * TaskList.handleEvent to wrap the complete handler:
	 * 
	 * new Task ("Load XML", loadXML, [ xmlPath, TaskList.handleEvent (loadXML_onComplete) ]);
	 * 
	 * That will properly cause the TaskList to wait before flagging the task as complete, until after the complete handler has been called.
	 */
	public static function handleEvent (handler:Dynamic = null):HandledEvent {
		
		return TaskList.handleEvent (handler);
		
	}
	
	
	/**
	 * Check to see if a task object or task ID has been completed
	 * @param	reference		A task object or task ID to check
	 * @return		A boolean value representing whether the task has been completed
	 */
	public static function isCompleted (reference:Dynamic):Bool {
		
		return list.isCompleted (reference);
		
	}
	
	
	public static function showDebugMessages ():Void {
		
		MessageLog.showDebugMessages ();
		
	}
	
	
}