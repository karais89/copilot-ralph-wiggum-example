import { createTodo } from "../models/todo.js";
import { loadTodos, saveTodos } from "../storage/json-store.js";

/**
 * Handles the 'add' command to create a new todo.
 * @param title - The title of the new todo
 */
export async function addCommand(title: string): Promise<void> {
  try {
    // Validate that title is provided and non-empty
    if (!title || title.trim().length === 0) {
      throw new Error("Title is required and cannot be empty");
    }

    // Load existing todos from storage
    const todos = await loadTodos();

    // Create new todo
    const newTodo = createTodo(title.trim());

    // Add to the list
    todos.push(newTodo);

    // Save back to storage
    await saveTodos(todos);

    // Print confirmation message
    console.log(`✓ Added: "${newTodo.title}" (id: ${newTodo.id})`);
  } catch (error) {
    if (error instanceof Error) {
      throw error;
    }
    throw new Error(`Failed to add todo: ${String(error)}`);
  }
}
