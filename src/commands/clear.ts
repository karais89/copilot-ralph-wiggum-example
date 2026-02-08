import { loadTodos, saveTodos } from "../storage/json-store.js";

export async function clearCommand(): Promise<void> {
  const todos = await loadTodos();
  const completedTodos = todos.filter((todo) => todo.completed);
  const clearedCount = completedTodos.length;

  if (clearedCount === 0) {
    console.log("No completed todos to clear.");
    return;
  }

  const remainingTodos = todos.filter((todo) => !todo.completed);
  await saveTodos(remainingTodos);

  console.log(`✔ Cleared ${clearedCount} completed todo(s)`);
}
