import { loadTodos, saveTodos } from "../storage/json-store.js";

/**
 * Handles the 'delete' command to permanently remove a todo from storage.
 * @param idOrPrefix - The full todo id or a prefix of it
 */
export async function deleteCommand(idOrPrefix: string): Promise<void> {
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
  const matchingTodoIndex = todos.findIndex((todo) => todo.id.startsWith(idOrPrefix.trim()));

  if (matchingTodoIndex === -1) {
    throw new Error(`No todo found with id: ${idOrPrefix}`);
  }

  // Store the title for confirmation message before removing
  const deletedTodo = todos[matchingTodoIndex];

  // Remove the todo from the array
  todos.splice(matchingTodoIndex, 1);

  // Save back to storage
  await saveTodos(todos);

  // Print confirmation
  console.log(`✓ Deleted "${deletedTodo.title}"`);
}
