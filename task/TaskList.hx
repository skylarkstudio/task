package task;


import com.eclecticdesignstudio.utils.MessageLog;
import flash.events.Event;


class TaskList {
	
	
	private var completedTasks:Map <String, Task>;
	private var pendingTasks:Array <Task>;
	
	
	public function new () {
		
		completedTasks = new Map <String, Task> ();
		pendingTasks = new Array <Task> ();
		
	}
	
	
	/**
	 * Add a new task to the pending tasks list
	 * @param	task		A new task
	 * @param	prerequisiteTasks		(Optional) An array of task objects or IDs which must be completed before running the task
	 * @param	autoComplete		(Optional) Determines whether to automatically mark tasks as complete after they are run. Does not affect tasks which use TaskList.handleEvent. Default is true.
	 */
	public function addTask (task:Task, prerequisiteTasks:Array <Dynamic> = null, autoComplete:Bool = true):Void {
		
		task.autoComplete = autoComplete;
		task.prerequisiteTasks = prerequisiteTasks;
		pendingTasks.push (task);
		processTasks ();
		
	}
	
	
	/**
	 * Marks a task as complete
	 * @param	reference		A task object or ID to mark as complete
	 */
	public function completeTask (reference:Dynamic):Void {
		
		var task:Task = qualifyReference (reference);
		
		if (task == null) {
			
			task = new Task (reference);
			
		}
		
		if (task != null) {
			
			MessageLog.debug (this, "Completed task \"" + task.id + "\"");
			
			completedTasks.set (Std.string (task.id), task);
			pendingTasks.remove (task);
			
			if (task.completeHandler != null) {
				
				task.completeHandler (task.result);
				
			}
			
			processTasks ();
			
		}
		
	}
	
	
	/**
	 * Creates an event handler in-place of TaskList.handleEvent
	 * @param	task		A task object to create a handler for
	 * @return		A custom event handler
	 */
	private function createEventHandler (task:Task, handledEvent:HandledEvent):Dynamic {
		
		var completeReference:Dynamic = completeTask;
		
		var eventHandler:Dynamic = function (event:Dynamic = null):Void {
			
			if (event != null) {
				
				handledEvent.handler (event);
				
			} else {
				
				handledEvent.handler ();
				
			}
			
			if (task.autoComplete) {
				
				completeReference (task);
				
			}
			
		}
		
		return eventHandler;
		
	}
	
	
	/**
	 * Looks up a task by an ID reference to find a matching task object
	 * @param	id		An ID to search for
	 * @return		A task object or null if the task was not found
	 */
	private function getTaskByID (id:Dynamic):Task {
		
		var task:Task;
		
		for (task in pendingTasks) {
			
			if (task.id == id) {
				
				return task;
				
			}
			
		}
		
		if (completedTasks.exists (Std.string (id))) {
			
			return completedTasks.get (Std.string (id));
			
		}
		
		MessageLog.error (this, "Bad reference to task \"" + id + "\"");
		
		return null;
		
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
		
		return new HandledEvent (handler);
		
	}
	
	
	/**
	 * Check to see if a task object or task ID has been completed
	 * @param	reference		A task object or task ID to check
	 * @return		A boolean value representing whether the task has been completed
	 */
	public function isCompleted (reference:Dynamic):Bool {
		
		var task:Task = cast (qualifyReference (reference), Task);
		
		if (task != null && completedTasks.exists (Std.string (task.id))) {
			return true;
		} else {
			return false;
		}
		
	}
	
	
	/**
	 * Check for any tasks which are ready to be run
	 */
	private function processTasks ():Void {
		
		for (task in pendingTasks) {
			
			if (task.target != null && !task.run) {
				
				var taskReady:Bool = true;
				
				if (task.prerequisiteTasks != null) {
					
					for (reference in task.prerequisiteTasks) {
						
						var prerequisiteTask = qualifyReference (reference);
						
						if (prerequisiteTask == null || !completedTasks.exists (Std.string (prerequisiteTask.id))) {
							
							taskReady = false;
							
						}
						
					}
					
				}
				
				if (taskReady) {
					
					runTask (task);
					
				}
				
			}
			
		}
		
	}
	
	
	/**
	 * Determines if a reference is a task object or a task ID. If it is a task ID it is converted into the appropriate object.
	 * @param	reference		A task object or task ID
	 * @return		A task object or null if no matching task is found
	 */
	private function qualifyReference (reference:Dynamic):Task {
		
		var task:Task;
		
		if (Std.is (reference, Task)) {
			
			task = cast (reference, Task);
			
		} else {
			
			task = getTaskByID (reference);
			
		}
		
		return task;
		
	}
	
	
	/**
	 * Runs a task and marks it as complete if autoComplete is true
	 * @param	reference		A task object or task ID
	 */
	private function runTask (reference:Dynamic):Void {
		
		var task:Task = qualifyReference (reference);
		
		if (task != null) {
			
			MessageLog.debug (this, "Running task \"" + task.id + "\"");
			
			task.run = true;
			
			var params = task.params;
			var handlingEvent = false;
			
			if (params != null) {
				for (i in 0...params.length) {
					if (Std.is (params[i], HandledEvent)) {
						params[i] = createEventHandler (task, params[i]);
						handlingEvent = true;
					}
				}
			}
			
			if (params == null) params = [];
			
			#if neko
			
			var diff = untyped ($nargs)(task.target) - params.length;
			
			for (i in 0...diff) {
				
				params.push (null);
				
			}
			
			#end
			
			task.result = Reflect.callMethod (task.target, task.target, params);
			
			if (task.autoComplete && !handlingEvent) {
				
				completeTask (task);
				
			}
			
		}
		
	}
	
	
}




class HandledEvent {
	
	
	public var handler:Dynamic;
	
	
	public function new (handler:Dynamic = null) {
		
		if (handler == null) {
			
			this.handler = function (_) {};
			
		} else {
			
			this.handler = handler;
			
		}
		
	}
	
	
}