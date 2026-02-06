import { loadTodos, saveTodos } from "../storage/json-store.js";

/**
 * Handles the 'done' command to toggle the completed status of a todo.
 * @param idOrPrefix - The full todo id or a prefix of it
 */
export async function doneCommand(idOrPrefix: string): Promise<void> {
  // Validate that id is provided
  if (!idOrPrefix || idOrPrefix.trim().length === 0) {
    throw new Error("Todo ID is required");
  }

  // Load existing todos from storage
  const todos = await loadTodos();

  if (todos.length === 0) {
    console.log("No todos found");
    return;
  }

  // Find matching todo by full id or prefix
  const matchingTodo = todos.find((todo) => todo.id.startsWith(idOrPrefix.trim()));

  if (!matchingTodo) {
    throw new Error(`No todo found with id: ${idOrPrefix}`);
  }

  // Toggle the completed status
  matchingTodo.completed = !matchingTodo.completed;

  // Save back to storage
  await saveTodos(todos);

  // Print confirmation with updated status
  const statusText = matchingTodo.completed ? "completed" : "pending";
  console.log(`✓ Marked "${matchingTodo.title}" as ${statusText}`);
}
