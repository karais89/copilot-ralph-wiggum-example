import { loadTodos } from "../storage/json-store.js";

/**
 * Handles the 'list' command to display all todos.
 */
export async function listCommand(): Promise<void> {
  // Load todos from storage
  const todos = await loadTodos();

  // Check if there are any todos
  if (todos.length === 0) {
    console.log("No todos found");
    return;
  }

  // Build the table output
  console.log("\n--- Todos ---\n");
  
  todos.forEach((todo) => {
    const statusIcon = todo.completed ? "[✓]" : "[ ]";
    const idShort = todo.id.slice(0, 8);
    console.log(`${statusIcon} ${idShort} — ${todo.title}`);
  });

  console.log(`\nTotal: ${todos.length} todo(s)\n`);
}
